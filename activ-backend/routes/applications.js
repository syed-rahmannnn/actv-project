const express = require("express");
const router = express.Router();
const Application = require("../models/applicationModel");
const MemberDetails = require("../models/MemberDetails");
const getAdminModels = require("../models/adminModels");

module.exports = (mongooseConnection) => {
  const { BlockAdmin, DistrictAdmin, StateAdmin } = getAdminModels(mongooseConnection || require("mongoose").connection);

  const isHex24 = (s) => typeof s === 'string' && /^[0-9a-fA-F]{24}$/.test(s);

  // Resolve a provided id to the Mongo _id of the admin document.
  // Accepts a Mongo _id string OR the human code (BA..., DA..., SA...).
  async function resolveAdminObjectId(role, id, Models) {
    const { BlockAdmin, DistrictAdmin, StateAdmin } = Models;
    if (!id) {
      console.warn(`resolveAdminObjectId: No id provided for role: ${role}`);
      return null;
    }

    if (isHex24(id)) return id; // already an ObjectId string

    const map = { block: BlockAdmin, district: DistrictAdmin, state: StateAdmin };
    const Model = map[role];
    if (!Model) {
      console.warn(`resolveAdminObjectId: Invalid role: ${role}`);
      return null;
    }

    try {
      // try by adminId code, then by email (nice-to-have)
      const doc = await Model.findOne({ $or: [{ adminId: id }, { email: id.toLowerCase?.() }] }, { _id: 1 }).lean();
      if (!doc) {
        console.warn(`resolveAdminObjectId: No ${role} record found for id: ${id}`);
        return null;
      }
      return doc._id.toString();
    } catch (error) {
      console.error(`resolveAdminObjectId: Database error for role ${role}, id ${id}:`, error);
      return null;
    }
  }

  // ---------- USER SUBMITS APPLICATION ----------
  router.post("/submit", async (req, res) => {
    try {
      const { userId, fullName, email, phone, state, district, block, formData } = req.body;

      // Validate required fields
      if (!userId || !fullName || !email || !phone || !state || !district || !block || !formData) {
        return res.status(400).json({
          success: false,
          message: "All fields are required: userId, fullName, email, phone, state, district, block, formData"
        });
      }

      // Normalize input
      const norm = (s) => (typeof s === 'string' ? s.trim() : s);
      const S = norm(state);
      const D = norm(district);
      const B = norm(block);

      // helpers
      const escapeRx = (v) => v.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      const rx = (v) => new RegExp(`^${escapeRx(norm(v))}$`, 'i');

      // Prefer *_lc fields when present (new seeder will add these)
      const blockAdmin = await BlockAdmin.findOne({
        $or: [
          { "meta.stateLc": S.toLowerCase(), "meta.districtLc": D.toLowerCase(), "meta.blockLc": B.toLowerCase() },
          { "meta.state": rx(S), "meta.district": rx(D), "meta.block": rx(B) }
        ],
        active: true
      });

      const districtAdmin = await DistrictAdmin.findOne({
        $or: [
          { "meta.stateLc": S.toLowerCase(), "meta.districtLc": D.toLowerCase() },
          { "meta.state": rx(S), "meta.district": rx(D) }
        ],
        active: true
      });

      const stateAdmin = await StateAdmin.findOne({
        $or: [
          { "meta.stateLc": S.toLowerCase() },
          { "meta.state": rx(S) }
        ],
        active: true
      });

      if (!blockAdmin || !districtAdmin || !stateAdmin) {
        return res.status(404).json({
          success: false,
          message: "No matching admins found for this location",
          details: {
            blockAdminFound: !!blockAdmin,
            districtAdminFound: !!districtAdmin,
            stateAdminFound: !!stateAdmin
          }
        });
      }

      // Check if user already has a pending application
      const existingApp = await Application.findOne({
        userId,
        status: { $in: ["Pending-Block", "Pending-District", "Pending-State"] }
      });

      if (existingApp) {
        return res.status(409).json({
          success: false,
          message: "You already have a pending application",
          application: existingApp
        });
      }

      const newApp = await Application.create({
        userId,
        fullName,
        email,
        phone,
        state: S,
        district: D,
        block: B,
        formData,
        assignedBlockAdmin: blockAdmin._id,
        assignedDistrictAdmin: districtAdmin._id,
        assignedStateAdmin: stateAdmin._id,
        status: "Pending-Block",
      });

      res.status(201).json({ 
        success: true, 
        message: "Application submitted successfully",
        application: newApp 
      });
    } catch (err) {
      console.error("Application submission error:", err);
      res.status(500).json({ success: false, message: "Server Error" });
    }
  });

  // ---------- BLOCK ADMIN REVIEW ----------
  router.post("/block-review/:appId", async (req, res) => {
    try {
      const { action, reason, adminId } = req.body; // action = "approve" or "reject"
      
      if (!action || !adminId) {
        return res.status(400).json({ 
          success: false, 
          message: "Action and adminId are required" 
        });
      }

      const app = await Application.findById(req.params.appId);
      if (!app) {
        return res.status(404).json({ 
          success: false, 
          message: "Application not found" 
        });
      }

      if (app.status !== "Pending-Block") {
        return res.status(400).json({
          success: false,
          message: "Application is not in Pending-Block status"
        });
      }

      // Verify the admin is authorized to review this application
      const resolved = await resolveAdminObjectId('block', adminId, { BlockAdmin, DistrictAdmin, StateAdmin });
      if (!resolved) {
        console.error("resolveAdminObjectId failed for block admin:", adminId);
        return res.status(400).json({
          success: false,
          message: `Admin not found for role 'block' and ID '${adminId}'`
        });
      }
      
      if (app.assignedBlockAdmin.toString() !== resolved) {
        return res.status(403).json({
          success: false,
          message: "You are not authorized to review this application"
        });
      }

      if (action === "approve") {
        app.status = "Pending-District";
        app.blockApprovedAt = new Date();
        app.reviewedBy.blockAdmin = resolved;
      } else if (action === "reject") {
        app.status = "Rejected";
        app.rejectionReason = reason || "No reason provided";
        app.reviewedBy.blockAdmin = resolved;
      } else {
        return res.status(400).json({
          success: false,
          message: "Invalid action. Must be 'approve' or 'reject'"
        });
      }

      await app.save();
      res.json({ 
        success: true, 
        message: `Application ${action}d successfully`,
        status: app.status 
      });
    } catch (err) {
      console.error("Block review error:", err);
      res.status(500).json({ success: false, message: "Server error" });
    }
  });

  // ---------- DISTRICT ADMIN REVIEW ----------
  router.post("/district-review/:appId", async (req, res) => {
    try {
      const { action, reason, adminId } = req.body;
      
      if (!action || !adminId) {
        return res.status(400).json({ 
          success: false, 
          message: "Action and adminId are required" 
        });
      }

      const app = await Application.findById(req.params.appId);
      if (!app) {
        return res.status(404).json({ 
          success: false, 
          message: "Application not found" 
        });
      }

      if (app.status !== "Pending-District") {
        return res.status(400).json({
          success: false,
          message: "Application is not in Pending-District status"
        });
      }

      // Verify the admin is authorized to review this application
      const resolved = await resolveAdminObjectId('district', adminId, { BlockAdmin, DistrictAdmin, StateAdmin });
      if (!resolved) {
        console.error("resolveAdminObjectId failed for district admin:", adminId);
        return res.status(400).json({
          success: false,
          message: `Admin not found for role 'district' and ID '${adminId}'`
        });
      }
      
      if (app.assignedDistrictAdmin.toString() !== resolved) {
        return res.status(403).json({
          success: false,
          message: "You are not authorized to review this application"
        });
      }

      if (action === "approve") {
        app.status = "Pending-State";
        app.districtApprovedAt = new Date();
        app.reviewedBy.districtAdmin = resolved;
      } else if (action === "reject") {
        app.status = "Rejected";
        app.rejectionReason = reason || "No reason provided";
        app.reviewedBy.districtAdmin = resolved;
      } else {
        return res.status(400).json({
          success: false,
          message: "Invalid action. Must be 'approve' or 'reject'"
        });
      }

      await app.save();
      res.json({ 
        success: true, 
        message: `Application ${action}d successfully`,
        status: app.status 
      });
    } catch (err) {
      console.error("District review error:", err);
      res.status(500).json({ success: false, message: "Server error" });
    }
  });

  // ---------- GET APPLICATIONS FOR BLOCK ADMIN ----------
  router.get("/block/:blockAdminId", async (req, res) => {
    try {
      const _id = await resolveAdminObjectId('block', req.params.blockAdminId, { BlockAdmin, DistrictAdmin, StateAdmin });
      if (!_id) {
        console.error("resolveAdminObjectId failed for block admin:", req.params.blockAdminId);
        return res.status(400).json({ 
          success: false, 
          message: `Admin not found for role 'block' and ID '${req.params.blockAdminId}'` 
        });
      }

      // Get all applications for this block admin, not just pending ones
      const apps = await Application.find({
        assignedBlockAdmin: _id,
      }).sort({ createdAt: -1 });

      // Enhance applications with member approval information and reviewedBy details
      const enhancedApps = await Promise.all(apps.map(async (app) => {
        const appObj = app.toObject();
        
        // For approved applications, get member approval details
        if (app.status === 'Approved') {
          try {
            const memberDetails = await MemberDetails.findOne({ 
              email: app.email.toLowerCase().trim() 
            });
            
            if (memberDetails) {
              appObj.approvedBy = memberDetails.approvedBy;
              appObj.approvedBlock = memberDetails.approvedBlock;
              appObj.approvedAt = memberDetails.approvedAt;
            }
          } catch (memberError) {
            console.error("Error fetching member details for app:", app._id, memberError);
            // Continue without member details if there's an error
          }
        }
        
        // Fetch reviewedBy admin data
        if (appObj.reviewedBy) {
          console.log('Processing reviewedBy for app:', appObj._id, 'reviewedBy:', JSON.stringify(appObj.reviewedBy, null, 2));
          
          if (appObj.reviewedBy.blockAdmin) {
            try {
              const blockAdmin = await BlockAdmin.findById(appObj.reviewedBy.blockAdmin, 'fullName email adminId meta').lean();
              console.log('Found block admin:', blockAdmin);
              if (blockAdmin) {
                appObj.reviewedBy.blockAdmin = {
                  fullName: blockAdmin.fullName,
                  email: blockAdmin.email,
                  adminId: blockAdmin.adminId,
                  meta: {
                    blockName: blockAdmin.meta?.block || blockAdmin.meta?.blockLc || 'Unknown Block',
                    districtName: blockAdmin.meta?.district || blockAdmin.meta?.districtLc || 'Unknown District',
                    stateName: blockAdmin.meta?.state || blockAdmin.meta?.stateLc || 'Unknown State'
                  }
                };
                console.log('Enhanced blockAdmin:', JSON.stringify(appObj.reviewedBy.blockAdmin, null, 2));
              } else {
                console.log('Block admin not found for ID:', appObj.reviewedBy.blockAdmin);
                appObj.reviewedBy.blockAdmin = null;
              }
            } catch (err) {
              console.error('Error fetching reviewed by block admin:', err);
              appObj.reviewedBy.blockAdmin = null;
            }
          }
          
          if (appObj.reviewedBy.districtAdmin) {
            try {
              const districtAdmin = await DistrictAdmin.findById(appObj.reviewedBy.districtAdmin, 'fullName email adminId meta').lean();
              if (districtAdmin) {
                appObj.reviewedBy.districtAdmin = {
                  fullName: districtAdmin.fullName,
                  email: districtAdmin.email,
                  adminId: districtAdmin.adminId,
                  meta: {
                    districtName: districtAdmin.meta?.district || districtAdmin.meta?.districtLc || 'Unknown District',
                    stateName: districtAdmin.meta?.state || districtAdmin.meta?.stateLc || 'Unknown State'
                  }
                };
              } else {
                appObj.reviewedBy.districtAdmin = null;
              }
            } catch (err) {
              console.error('Error fetching reviewed by district admin:', err);
              appObj.reviewedBy.districtAdmin = null;
            }
          }
          
          if (appObj.reviewedBy.stateAdmin) {
            try {
              const stateAdmin = await StateAdmin.findById(appObj.reviewedBy.stateAdmin, 'fullName email adminId meta').lean();
              if (stateAdmin) {
                appObj.reviewedBy.stateAdmin = {
                  fullName: stateAdmin.fullName,
                  email: stateAdmin.email,
                  adminId: stateAdmin.adminId,
                  meta: {
                    stateName: stateAdmin.meta?.state || stateAdmin.meta?.stateLc || 'Unknown State'
                  }
                };
              } else {
                appObj.reviewedBy.stateAdmin = null;
              }
            } catch (err) {
              console.error('Error fetching reviewed by state admin:', err);
              appObj.reviewedBy.stateAdmin = null;
            }
          }
        }
        
        console.log('Final enhanced app for ID:', appObj._id, 'reviewedBy:', JSON.stringify(appObj.reviewedBy, null, 2));
        return appObj;
      }));

      res.json(enhancedApps); // Return enhanced applications with member approval info
    } catch (err) {
      console.error("Fetch block applications error:", err);
      res.status(500).json({ success: false, message: "Server error" });
    }
  });

  // ---------- GET APPLICATIONS FOR DISTRICT ADMIN ----------
  // Return ALL applications assigned to the district admin (not only Pending-District),
  // mirroring the behavior of the block admin route.
  router.get("/district/:districtAdminId", async (req, res) => {
    try {
      const _id = await resolveAdminObjectId('district', req.params.districtAdminId, { BlockAdmin, DistrictAdmin, StateAdmin });
      if (!_id) {
        console.error("resolveAdminObjectId failed for district admin:", req.params.districtAdminId);
        return res.status(400).json({ 
          success: false, 
          message: `Admin not found for role 'district' and ID '${req.params.districtAdminId}'` 
        });
      }

      // Fetch all applications for this district admin, regardless of status
      const apps = await Application.find({
        assignedDistrictAdmin: _id,
      }).sort({ createdAt: -1 });

      // Enhance applications similarly to the block admin route with reviewedBy and member info
      const enhancedApps = await Promise.all(apps.map(async (app) => {
        const appObj = app.toObject();

        // ReviewedBy safety checks are handled in the GET /:appId route, but we add basic references here
        // (Keep lightweight to avoid extra DB calls unless necessary)
        // You can expand with DistrictAdmin/StateAdmin hydration if needed, matching the GET /:appId behavior.

        // Attach simple member approval info if present
        try {
          const member = await MemberDetails.findOne({ userId: appObj.userId }).lean();
          if (member && member.approvedBy) {
            appObj.memberApprovedBy = {
              blockAdmin: member.approvedBy.blockAdmin || null,
              districtAdmin: member.approvedBy.districtAdmin || null,
              stateAdmin: member.approvedBy.stateAdmin || null,
            };
            appObj.memberApprovedAt = member.approvedAt || null;
          }
        } catch (err) {
          console.error('Error fetching member details for app', appObj._id, err);
        }

        return appObj;
      }));

      res.json({ 
        success: true, 
        applications: enhancedApps,
        count: enhancedApps.length 
      });
    } catch (err) {
      console.error("Fetch district applications error:", err);
      res.status(500).json({ success: false, message: "Server error" });
    }
  });

  // ---------- GET APPLICATIONS FOR STATE ADMIN ----------
  router.get("/state/:stateAdminId", async (req, res) => {
    try {
      const _id = await resolveAdminObjectId('state', req.params.stateAdminId, { BlockAdmin, DistrictAdmin, StateAdmin });
      if (!_id) {
        console.error("resolveAdminObjectId failed for state admin:", req.params.stateAdminId);
        return res.status(400).json({ 
          success: false, 
          message: `Admin not found for role 'state' and ID '${req.params.stateAdminId}'` 
        });
      }

      // Fetch all applications for this state admin, regardless of status
      const apps = await Application.find({
        assignedStateAdmin: _id,
      }).sort({ createdAt: -1 });

      // Enhance applications similarly to the district admin route with member info
      const enhancedApps = await Promise.all(apps.map(async (app) => {
        const appObj = app.toObject();

        // Attach simple member approval info if present
        try {
          const member = await MemberDetails.findOne({ userId: appObj.userId }).lean();
          if (member && member.approvedBy) {
            appObj.memberApprovedBy = {
              blockAdmin: member.approvedBy.blockAdmin || null,
              districtAdmin: member.approvedBy.districtAdmin || null,
              stateAdmin: member.approvedBy.stateAdmin || null,
            };
            appObj.memberApprovedAt = member.approvedAt || null;
          }
        } catch (err) {
          console.error('Error fetching member details for app', appObj._id, err);
        }

        return appObj;
      }));

      res.json({ success: true, applications: enhancedApps, count: enhancedApps.length });
    } catch (err) {
      console.error("Fetch state applications error:", err);
      res.status(500).json({ success: false, message: "Server error" });
    }
  });

  // ---------- STATE ADMIN REVIEW ----------
  router.post("/state-review/:appId", async (req, res) => {
    try {
      const { action, reason, adminId } = req.body; // "approve" | "reject"
      if (!action || !adminId) {
        return res.status(400).json({ success: false, message: "Action and adminId are required" });
      }

      const app = await Application.findById(req.params.appId);
      if (!app) return res.status(404).json({ success: false, message: "Application not found" });

      if (app.status !== "Pending-State") {
        return res.status(400).json({ success: false, message: "Application is not in Pending-State status" });
      }

      const resolved = await resolveAdminObjectId('state', adminId, { BlockAdmin, DistrictAdmin, StateAdmin });
      if (!resolved) {
        console.error("resolveAdminObjectId failed for state admin:", adminId);
        return res.status(400).json({
          success: false,
          message: `Admin not found for role 'state' and ID '${adminId}'`
        });
      }
      
      if (app.assignedStateAdmin.toString() !== resolved) {
        return res.status(403).json({ 
          success: false, 
          message: "You are not authorized to review this application" 
        });
      }

      if (action === "approve") {
        app.status = "Approved";
        app.stateApprovedAt = new Date();
        app.reviewedBy.stateAdmin = resolved;

        // Update member approval information
        try {
          // Get the block admin who initially approved this application
          const blockAdmin = await BlockAdmin.findById(app.reviewedBy.blockAdmin);
          if (blockAdmin) {
            await MemberDetails.findOneAndUpdate(
              { email: app.email.toLowerCase().trim() },
              {
                approvedBy: blockAdmin.fullName,
                approvedBlock: app.block,
                approvedAt: new Date()
              }
            );
          }
        } catch (memberUpdateError) {
          console.error("Error updating member approval info:", memberUpdateError);
          // Don't fail the application approval if member update fails
        }
      } else if (action === "reject") {
        app.status = "Rejected";
        app.rejectionReason = reason || "No reason provided";
        app.reviewedBy.stateAdmin = resolved;
      } else {
        return res.status(400).json({ success: false, message: "Invalid action. Must be 'approve' or 'reject'" });
      }

      await app.save();
      res.json({ success: true, message: `Application ${action}d successfully`, status: app.status });
    } catch (err) {
      console.error("State review error:", err);
      res.status(500).json({ success: false, message: "Server error" });
    }
  });

  // ---------- GET APPLICATION STATUS FOR USER ----------
  router.get("/user/:userId", async (req, res) => {
    try {
      const apps = await Application.find({ userId: req.params.userId })
        .sort({ createdAt: -1 });

      // Manually fetch admin data for each application
      const appsWithAdminData = await Promise.all(apps.map(async (app) => {
        const appObj = app.toObject();
        
        // Fetch block admin data
        if (appObj.assignedBlockAdmin) {
          try {
            const blockAdmin = await BlockAdmin.findById(appObj.assignedBlockAdmin, 'fullName email').lean();
            appObj.assignedBlockAdmin = blockAdmin;
          } catch (err) {
            console.error('Error fetching block admin:', err);
            appObj.assignedBlockAdmin = null;
          }
        }
        
        // Fetch district admin data
        if (appObj.assignedDistrictAdmin) {
          try {
            const districtAdmin = await DistrictAdmin.findById(appObj.assignedDistrictAdmin, 'fullName email').lean();
            appObj.assignedDistrictAdmin = districtAdmin;
          } catch (err) {
            console.error('Error fetching district admin:', err);
            appObj.assignedDistrictAdmin = null;
          }
        }
        
        // Fetch state admin data
        if (appObj.assignedStateAdmin) {
          try {
            const stateAdmin = await StateAdmin.findById(appObj.assignedStateAdmin, 'fullName email').lean();
            appObj.assignedStateAdmin = stateAdmin;
          } catch (err) {
            console.error('Error fetching state admin:', err);
            appObj.assignedStateAdmin = null;
          }
        }
        
        return appObj;
      }));

      res.json({ 
        success: true, 
        applications: appsWithAdminData,
        count: appsWithAdminData.length 
      });
    } catch (err) {
      console.error("Fetch user applications error:", err);
      res.status(500).json({ success: false, message: "Server error" });
    }
  });

  // ---------- GET APPLICATIONS BY ADMIN (for stats) ----------
  router.get("/by-admin/:adminId", async (req, res) => {
    try {
      const { role, status } = req.query;
      let adminObjId = await resolveAdminObjectId(role, req.params.adminId, { BlockAdmin, DistrictAdmin, StateAdmin });
      
      if (!role || !status) {
        return res.status(400).json({ 
          success: false, 
          message: "Role and status query parameters are required" 
        });
      }
      
      if (!adminObjId) {
        console.error("resolveAdminObjectId failed for:", role, req.params.adminId);
        return res.status(400).json({ 
          success: false, 
          message: `Admin not found for role '${role}' and ID '${req.params.adminId}'` 
        });
      }

      const q = {};
      if (role === 'block') q.assignedBlockAdmin = adminObjId;
      if (role === 'district') q.assignedDistrictAdmin = adminObjId;
      if (role === 'state') q.assignedStateAdmin = adminObjId;

      if (status === 'Approved') {
        if (role === 'block') q.status = { $in: ['Pending-District','Pending-State','Approved'] }, q['reviewedBy.blockAdmin'] = { $exists:true };
        if (role === 'district') q.status = { $in: ['Pending-State','Approved'] }, q['reviewedBy.districtAdmin'] = { $exists:true };
        if (role === 'state') q.status = 'Approved', q['reviewedBy.stateAdmin'] = { $exists:true };
      } else if (status === 'Rejected') {
        q.status = 'Rejected';
        if (role === 'block') q['reviewedBy.blockAdmin'] = { $exists:true };
        if (role === 'district') q['reviewedBy.districtAdmin'] = { $exists:true };
        if (role === 'state') q['reviewedBy.stateAdmin'] = { $exists:true };
      }

      const count = await Application.countDocuments(q);
      res.json({ success:true, count, role, status });
    } catch (err) {
      console.error("Get applications by admin error:", err);
      res.status(500).json({ success:false, message:"Server error" });
    }
  });

  // ---------- GET APPLICATION DETAILS ----------
  router.get("/:appId", async (req, res) => {
    try {
      const app = await Application.findById(req.params.appId);

      if (!app) {
        return res.status(404).json({ 
          success: false, 
          message: "Application not found" 
        });
      }

      const appObj = app.toObject();
      
      // Manually fetch admin data
      if (appObj.assignedBlockAdmin) {
        try {
          const blockAdmin = await BlockAdmin.findById(appObj.assignedBlockAdmin, 'fullName email adminId').lean();
          appObj.assignedBlockAdmin = blockAdmin;
        } catch (err) {
          console.error('Error fetching block admin:', err);
          appObj.assignedBlockAdmin = null;
        }
      }
      
      if (appObj.assignedDistrictAdmin) {
        try {
          const districtAdmin = await DistrictAdmin.findById(appObj.assignedDistrictAdmin, 'fullName email adminId').lean();
          appObj.assignedDistrictAdmin = districtAdmin;
        } catch (err) {
          console.error('Error fetching district admin:', err);
          appObj.assignedDistrictAdmin = null;
        }
      }
      
      if (appObj.assignedStateAdmin) {
        try {
          const stateAdmin = await StateAdmin.findById(appObj.assignedStateAdmin, 'fullName email adminId').lean();
          appObj.assignedStateAdmin = stateAdmin;
        } catch (err) {
          console.error('Error fetching state admin:', err);
          appObj.assignedStateAdmin = null;
        }
      }
      
      // Fetch reviewedBy admin data
      if (appObj.reviewedBy) {
        if (appObj.reviewedBy.blockAdmin) {
          try {
            const blockAdmin = await BlockAdmin.findById(appObj.reviewedBy.blockAdmin, 'fullName email adminId meta').lean();
            if (blockAdmin) {
              appObj.reviewedBy.blockAdmin = {
                fullName: blockAdmin.fullName,
                email: blockAdmin.email,
                adminId: blockAdmin.adminId,
                blockName: blockAdmin.meta?.block || blockAdmin.meta?.blockLc || 'Unknown Block',
                districtName: blockAdmin.meta?.district || blockAdmin.meta?.districtLc || 'Unknown District',
                stateName: blockAdmin.meta?.state || blockAdmin.meta?.stateLc || 'Unknown State'
              };
            } else {
              appObj.reviewedBy.blockAdmin = null;
            }
          } catch (err) {
            console.error('Error fetching reviewed by block admin:', err);
            appObj.reviewedBy.blockAdmin = null;
          }
        }
        
        if (appObj.reviewedBy.districtAdmin) {
          try {
            const districtAdmin = await DistrictAdmin.findById(appObj.reviewedBy.districtAdmin, 'fullName email adminId meta').lean();
            if (districtAdmin) {
              appObj.reviewedBy.districtAdmin = {
                fullName: districtAdmin.fullName,
                email: districtAdmin.email,
                adminId: districtAdmin.adminId,
                districtName: districtAdmin.meta?.district || districtAdmin.meta?.districtLc || 'Unknown District',
                stateName: districtAdmin.meta?.state || districtAdmin.meta?.stateLc || 'Unknown State'
              };
            } else {
              appObj.reviewedBy.districtAdmin = null;
            }
          } catch (err) {
            console.error('Error fetching reviewed by district admin:', err);
            appObj.reviewedBy.districtAdmin = null;
          }
        }
        
        if (appObj.reviewedBy.stateAdmin) {
          try {
            const stateAdmin = await StateAdmin.findById(appObj.reviewedBy.stateAdmin, 'fullName email adminId meta').lean();
            if (stateAdmin) {
              appObj.reviewedBy.stateAdmin = {
                fullName: stateAdmin.fullName,
                email: stateAdmin.email,
                adminId: stateAdmin.adminId,
                stateName: stateAdmin.meta?.state || stateAdmin.meta?.stateLc || 'Unknown State'
              };
            } else {
              appObj.reviewedBy.stateAdmin = null;
            }
          } catch (err) {
            console.error('Error fetching reviewed by state admin:', err);
            appObj.reviewedBy.stateAdmin = null;
          }
        }
      }

      res.json({ 
        success: true, 
        application: appObj 
      });
    } catch (err) {
      console.error("Fetch application details error:", err);
      res.status(500).json({ success: false, message: "Server error" });
    }
  });

  return router;
};