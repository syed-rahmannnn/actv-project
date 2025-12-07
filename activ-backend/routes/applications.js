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

      console.log('📋 Application submission received:', { userId, email, memberType: formData?.memberType });

      // Validate required fields
      if (!userId || !fullName || !email || !phone || !state || !district || !block || !formData) {
        return res.status(400).json({
          success: false,
          message: "All fields are required: userId, fullName, email, phone, state, district, block, formData"
        });
      }

      // Check if this is an Aspirant application
      const isAspirant = formData.memberType === 'ASPIRANT' || formData.doingBusiness === false;

      // Normalize input
      const norm = (s) => (typeof s === 'string' ? s.trim() : s);
      const S = norm(state);
      const D = norm(district);
      const B = norm(block);

      let blockAdmin, districtAdmin, stateAdmin;

      // Only find admins if NOT an Aspirant (Aspirants don't need admin approval)
      if (!isAspirant) {
        // helpers
        const escapeRx = (v) => v.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
        const rx = (v) => new RegExp(`^${escapeRx(norm(v))}$`, 'i');

        // Prefer *_lc fields when present (new seeder will add these)
        blockAdmin = await BlockAdmin.findOne({
          $or: [
            { "meta.stateLc": S.toLowerCase(), "meta.districtLc": D.toLowerCase(), "meta.blockLc": B.toLowerCase() },
            { "meta.state": rx(S), "meta.district": rx(D), "meta.block": rx(B) }
          ],
          active: true
        });

        districtAdmin = await DistrictAdmin.findOne({
          $or: [
            { "meta.stateLc": S.toLowerCase(), "meta.districtLc": D.toLowerCase() },
            { "meta.state": rx(S), "meta.district": rx(D) }
          ],
          active: true
        });

        stateAdmin = await StateAdmin.findOne({
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
      }

      // Check if user already has a pending application
      const existingApp = await Application.findOne({
        userId,
        status: { $in: ["Pending-Block", "Pending-District", "Pending-State", "PENDING"] }
      });

      if (existingApp) {
        return res.status(409).json({
          success: false,
          message: "You already have a pending application",
          application: existingApp
        });
      }

      // Create application with conditional admin assignment
      const appData = {
        userId,
        fullName,
        email,
        phone,
        state: S,
        district: D,
        block: B,
        formData,
        status: isAspirant ? "PENDING" : "Pending-Block",
      };

      // Only add admin fields if not an Aspirant
      if (!isAspirant) {
        appData.assignedBlockAdmin = blockAdmin._id;
        appData.assignedDistrictAdmin = districtAdmin._id;
        appData.assignedStateAdmin = stateAdmin._id;
      }

      const newApp = await Application.create(appData);

      console.log('✅ Application created:', { 
        id: newApp._id, 
        status: newApp.status, 
        memberType: formData.memberType 
      });

      // Update Member document to mark profile as completed
      const Member = require('../models/MemberAuth');
      await Member.findByIdAndUpdate(userId, {
        profileCompleted: true,
        'registrationForm.profileCompleted': true
      });

      console.log('✅ Member profile marked as completed');

      res.status(201).json({ 
        success: true, 
        message: isAspirant 
          ? "Aspirant application submitted successfully" 
          : "Application submitted successfully",
        application: newApp 
      });
    } catch (err) {
      console.error("❌ Application submission error:", err);
      res.status(500).json({ success: false, message: "Server Error", error: err.message });
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

      // Allow review if status is PENDING (Aspirant) or Pending-Block (Business)
      if (!['PENDING', 'Pending-Block'].includes(app.status)) {
        return res.status(400).json({
          success: false,
          message: `Application is not pending Block approval (current status: ${app.status})`
        });
      }

      // Verify the admin is authorized
      const resolved = await resolveAdminObjectId('block', adminId, { BlockAdmin, DistrictAdmin, StateAdmin });
      if (!resolved) {
        console.error("resolveAdminObjectId failed for block admin:", adminId);
        return res.status(400).json({
          success: false,
          message: `Admin not found for role 'block' and ID '${adminId}'`
        });
      }
      
      // For business members (Pending-Block), check if assigned to this admin
      if (app.status === 'Pending-Block' && app.assignedBlockAdmin && app.assignedBlockAdmin.toString() !== resolved) {
        return res.status(403).json({
          success: false,
          message: "You are not authorized to review this application"
        });
      }

      if (action === "approve") {
        // Move application to next stage
        app.status = "Pending-District";
        app.blockApprovedAt = new Date();
        app.reviewedBy.blockAdmin = resolved;
        
        // Assign district and state admins if not already assigned
        if (!app.assignedDistrictAdmin) {
          // Find district admin for this location
          const districtAdmin = await DistrictAdmin.findOne({
            $or: [
              { 'meta.district': new RegExp(`^${app.district}$`, 'i') },
              { email: new RegExp(app.district.replace(/\s+/g, '[-_]?'), 'i') }
            ]
          }).lean();
          if (districtAdmin) {
            app.assignedDistrictAdmin = districtAdmin._id;
          }
        }
        
        if (!app.assignedStateAdmin) {
          // Find state admin for this location
          const stateAdmin = await StateAdmin.findOne({
            $or: [
              { 'meta.state': new RegExp(`^${app.state}$`, 'i') },
              { email: new RegExp(app.state.replace(/\s+/g, '[-_]?'), 'i') }
            ]
          }).lean();
          if (stateAdmin) {
            app.assignedStateAdmin = stateAdmin._id;
          }
        }
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
      
      console.log(`✅ Block Admin ${adminId} ${action}d application ${app._id}. New status: ${app.status}`);
      
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
      console.log(`🔍 Block Admin endpoint called with ID: ${req.params.blockAdminId}`);
      const _id = await resolveAdminObjectId('block', req.params.blockAdminId, { BlockAdmin, DistrictAdmin, StateAdmin });
      console.log(`✅ Resolved to MongoDB _id: ${_id}`);
      if (!_id) {
        console.error("resolveAdminObjectId failed for block admin:", req.params.blockAdminId);
        return res.status(400).json({ 
          success: false, 
          message: `Admin not found for role 'block' and ID '${req.params.blockAdminId}'` 
        });
      }

      // Get the Block Admin's location details
      const blockAdmin = await BlockAdmin.findById(_id).lean();
      if (!blockAdmin) {
        return res.status(404).json({
          success: false,
          message: "Block Admin not found"
        });
      }

      // Extract location from admin's metadata or email
      // Email format: block.{blockName}.{districtName}.{stateName}@activ.com
      let adminBlock = null, adminDistrict = null, adminState = null;
      
      if (blockAdmin.meta && blockAdmin.meta.block) {
        adminBlock = blockAdmin.meta.block;
        adminDistrict = blockAdmin.meta.district;
        adminState = blockAdmin.meta.state;
      } else if (blockAdmin.email && blockAdmin.email.startsWith('block.')) {
        const parts = blockAdmin.email.replace('@activ.com', '').split('.');
        if (parts.length >= 4) {
          adminBlock = parts[1].replace(/[-_]/g, ' ');
          adminDistrict = parts[2].replace(/[-_]/g, ' ');
          adminState = parts[3].replace(/[-_]/g, ' ');
        }
      }

      // Query applications for this Block Admin's jurisdiction
      // Show ONLY applications with:
      // 1. Status = "PENDING" (Aspirants) or "Pending-Block" (Business members)
      // 2. Matching block/district/state location
      const query = {
        status: { $in: ['PENDING', 'Pending-Block'] },
        $and: []
      };

      // Add location filters if admin has location data
      if (adminBlock) {
        query.$and.push({ 
          $or: [
            { block: new RegExp(`^${adminBlock}$`, 'i') },
            { block: new RegExp(adminBlock.replace(/\s+/g, ''), 'i') }
          ]
        });
      }
      if (adminDistrict) {
        query.$and.push({ 
          $or: [
            { district: new RegExp(`^${adminDistrict}$`, 'i') },
            { district: new RegExp(adminDistrict.replace(/\s+/g, ''), 'i') }
          ]
        });
      }
      if (adminState) {
        query.$and.push({ 
          $or: [
            { state: new RegExp(`^${adminState}$`, 'i') },
            { state: new RegExp(adminState.replace(/\s+/g, ''), 'i') }
          ]
        });
      }

      // If no location data, fall back to showing all PENDING/Pending-Block applications
      if (query.$and.length === 0) {
        delete query.$and;
      }

      console.log(`🔎 Block Admin location: ${adminBlock}, ${adminDistrict}, ${adminState}`);
      console.log(`🔎 Executing query:`, JSON.stringify(query, null, 2));
      
      const apps = await Application.find(query).sort({ createdAt: -1 });

      console.log(`📊 Block Admin ${req.params.blockAdminId}: Found ${apps.length} applications (includes Aspirants)`);

      // Enhance applications with member approval information and reviewedBy details
      const enhancedApps = await Promise.all(apps.map(async (app) => {
        const appObj = app.toObject();
        
        console.log(`[ENRICHMENT DEBUG] Processing app ${appObj._id}, current gender:`, appObj.gender);
        
        // If gender is missing, try to fetch from MemberDetails
        if (!appObj.gender) {
          try {
            const memberDetails = await MemberDetails.findOne({ 
              email: app.email.toLowerCase().trim() 
            }, 'gender');
            
            if (memberDetails && memberDetails.gender) {
              console.log(`[ENRICHMENT DEBUG] Found gender in MemberDetails for ${app.email}:`, memberDetails.gender);
              appObj.gender = memberDetails.gender;
            } else {
              console.log(`[ENRICHMENT DEBUG] No gender found in MemberDetails for ${app.email}`);
            }
          } catch (memberError) {
            console.error(`[ENRICHMENT DEBUG] Error fetching gender from MemberDetails for ${app.email}:`, memberError);
          }
        } else {
          console.log(`[ENRICHMENT DEBUG] App ${appObj._id} already has gender:`, appObj.gender);
        }
        
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
        
        // Block-level status normalization (do NOT reflect district/state pending here)
        // Simple logic:
        // - If block admin rejected => "Rejected"
        // - If block admin approved (forwarded) => "Approved"
        // - If not yet reviewed by block admin => "Pending"
        try {
          const rb = appObj.reviewedBy || {};
          const hasBlockReview = !!rb.blockAdmin;
          const originalStatus = String(app.status || '');
          
          if (!hasBlockReview) {
            // Not reviewed by block admin yet
            appObj.status = 'Pending';
          } else {
            // Block admin has reviewed
            // Check if rejected at block level (status is Rejected AND no higher-level reviews)
            if (originalStatus === 'Rejected' && !rb.districtAdmin && !rb.stateAdmin) {
              appObj.status = 'Rejected';
            } else {
              // Block approved (may be Pending-District, Pending-State, or Approved)
              appObj.status = 'Approved';
            }
          }
        } catch (e) {
          console.error('Status normalization error:', e);
          // Fallback: keep original or default to Pending
          appObj.status = 'Pending';
        }

        console.log('Final enhanced app for ID:', appObj._id, 'reviewedBy:', JSON.stringify(appObj.reviewedBy, null, 2));
        return appObj;
      }));

      // Support optional wrapped response with top-level adminMeta, without breaking existing array shape
      const includeMetaParam = String(req.query.includeMeta || '').toLowerCase();
      const includeMeta = includeMetaParam === '1' || includeMetaParam === 'true' || includeMetaParam === 'yes';

      if (includeMeta) {
        let adminMeta = {};
        try {
          const ba = await BlockAdmin.findById(_id, 'fullName email adminId meta').lean();
          if (ba) {
            adminMeta = {
              fullName: ba.fullName,
              email: ba.email,
              adminId: ba.adminId,
              blockName: ba.meta?.block || ba.meta?.blockLc || 'Unknown Block',
              districtName: ba.meta?.district || ba.meta?.districtLc || 'Unknown District',
              stateName: ba.meta?.state || ba.meta?.stateLc || 'Unknown State',
            };
          } else {
            adminMeta = { blockName: 'Unknown Block' };
          }
        } catch (e) {
          console.error('Error fetching block admin meta:', e);
          adminMeta = { blockName: 'Unknown Block' };
        }
        return res.json({ applications: enhancedApps, count: enhancedApps.length, adminMeta });
      }

      // Default: return array for backward compatibility
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

      // Get the District Admin's location details
      const districtAdmin = await DistrictAdmin.findById(_id).lean();
      if (!districtAdmin) {
        return res.status(404).json({
          success: false,
          message: "District Admin not found"
        });
      }

      // Extract location from admin's metadata or email
      let adminDistrict = null, adminState = null;
      
      if (districtAdmin.meta && districtAdmin.meta.district) {
        adminDistrict = districtAdmin.meta.district;
        adminState = districtAdmin.meta.state;
      } else if (districtAdmin.email && districtAdmin.email.startsWith('district.')) {
        const parts = districtAdmin.email.replace('@activ.com', '').split('.');
        if (parts.length >= 3) {
          adminDistrict = parts[1].replace(/[-_]/g, ' ');
          adminState = parts[2].replace(/[-_]/g, ' ');
        }
      }

      // Query: ONLY show applications with status Pending-District that match this district
      const query = {
        status: 'Pending-District',
        $and: []
      };

      if (adminDistrict) {
        query.$and.push({ 
          $or: [
            { district: new RegExp(`^${adminDistrict}$`, 'i') },
            { district: new RegExp(adminDistrict.replace(/\s+/g, ''), 'i') }
          ]
        });
      }
      if (adminState) {
        query.$and.push({ 
          $or: [
            { state: new RegExp(`^${adminState}$`, 'i') },
            { state: new RegExp(adminState.replace(/\s+/g, ''), 'i') }
          ]
        });
      }

      if (query.$and.length === 0) {
        delete query.$and;
      }

      console.log(`🔎 District Admin location: ${adminDistrict}, ${adminState}`);
      console.log(`🔎 Executing query:`, JSON.stringify(query, null, 2));

      const apps = await Application.find(query).sort({ createdAt: -1 }).lean();

      // Batch fetch member details for all applications at once
      const emails = apps.map(app => app.email?.toLowerCase().trim()).filter(Boolean);
      const userIds = apps.map(app => app.userId).filter(Boolean);
      
      // Single query for all member details
      const memberDetailsMap = new Map();
      if (emails.length > 0 || userIds.length > 0) {
        const members = await MemberDetails.find({
          $or: [
            { email: { $in: emails } },
            { userId: { $in: userIds } }
          ]
        }, 'email userId gender approvedBy approvedAt').lean();
        
        members.forEach(member => {
          if (member.email) memberDetailsMap.set(member.email.toLowerCase(), member);
          if (member.userId) memberDetailsMap.set(member.userId, member);
        });
      }

      // Enhance applications with batched data
      const enhancedApps = apps.map(appObj => {
        // Add gender if missing
        if (!appObj.gender && appObj.email) {
          const memberByEmail = memberDetailsMap.get(appObj.email.toLowerCase().trim());
          if (memberByEmail && memberByEmail.gender) {
            appObj.gender = memberByEmail.gender;
          }
        }

        // Add member approval info
        const member = memberDetailsMap.get(appObj.userId);
        if (member && member.approvedBy) {
          appObj.memberApprovedBy = {
            blockAdmin: member.approvedBy.blockAdmin || null,
            districtAdmin: member.approvedBy.districtAdmin || null,
            stateAdmin: member.approvedBy.stateAdmin || null,
          };
          appObj.memberApprovedAt = member.approvedAt || null;
        }

        return appObj;
      });

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

      // Get the State Admin's location details
      const stateAdmin = await StateAdmin.findById(_id).lean();
      if (!stateAdmin) {
        return res.status(404).json({
          success: false,
          message: "State Admin not found"
        });
      }

      // Extract location from admin's metadata or email
      let adminState = null;
      
      if (stateAdmin.meta && stateAdmin.meta.state) {
        adminState = stateAdmin.meta.state;
      } else if (stateAdmin.email && stateAdmin.email.startsWith('state.')) {
        const parts = stateAdmin.email.replace('@activ.com', '').split('.');
        if (parts.length >= 2) {
          adminState = parts[1].replace(/[-_]/g, ' ');
        }
      }

      // Query: ONLY show applications with status Pending-State that match this state
      const query = {
        status: 'Pending-State'
      };

      if (adminState) {
        query.$or = [
          { state: new RegExp(`^${adminState}$`, 'i') },
          { state: new RegExp(adminState.replace(/\s+/g, ''), 'i') }
        ];
      }

      console.log(`🔎 State Admin location: ${adminState}`);
      console.log(`🔎 Executing query:`, JSON.stringify(query, null, 2));

      const apps = await Application.find(query).sort({ createdAt: -1 }).lean();

      // Batch fetch member details for all applications at once
      const emails = apps.map(app => app.email?.toLowerCase().trim()).filter(Boolean);
      const userIds = apps.map(app => app.userId).filter(Boolean);
      
      // Single query for all member details
      const memberDetailsMap = new Map();
      if (emails.length > 0 || userIds.length > 0) {
        const members = await MemberDetails.find({
          $or: [
            { email: { $in: emails } },
            { userId: { $in: userIds } }
          ]
        }, 'email userId gender approvedBy approvedAt').lean();
        
        members.forEach(member => {
          if (member.email) memberDetailsMap.set(member.email.toLowerCase(), member);
          if (member.userId) memberDetailsMap.set(member.userId, member);
        });
      }

      // Enhance applications with batched data
      const enhancedApps = apps.map(appObj => {
        // Add gender if missing
        if (!appObj.gender && appObj.email) {
          const memberByEmail = memberDetailsMap.get(appObj.email.toLowerCase().trim());
          if (memberByEmail && memberByEmail.gender) {
            appObj.gender = memberByEmail.gender;
          }
        }

        // Add member approval info
        const member = memberDetailsMap.get(appObj.userId);
        if (member && member.approvedBy) {
          appObj.memberApprovedBy = {
            blockAdmin: member.approvedBy.blockAdmin || null,
            districtAdmin: member.approvedBy.districtAdmin || null,
            stateAdmin: member.approvedBy.stateAdmin || null,
          };
          appObj.memberApprovedAt = member.approvedAt || null;
        }

        return appObj;
      });

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
      
      if (!role || !status) {
        return res.status(400).json({ 
          success: false, 
          message: "Role and status query parameters are required" 
        });
      }

      let adminObjId = await resolveAdminObjectId(role, req.params.adminId, { BlockAdmin, DistrictAdmin, StateAdmin });
      
      if (!adminObjId) {
        console.error("resolveAdminObjectId failed for:", role, req.params.adminId);
        return res.status(400).json({ 
          success: false, 
          message: `Admin not found for role '${role}' and ID '${req.params.adminId}'` 
        });
      }

      // Get admin location for filtering
      let Admin, adminDoc, locationQuery = {};
      if (role === 'block') {
        Admin = BlockAdmin;
        adminDoc = await Admin.findById(adminObjId).lean();
        if (adminDoc) {
          const { meta, email } = adminDoc;
          let block, district, state;
          
          if (meta && meta.block) {
            block = meta.block;
            district = meta.district;
            state = meta.state;
          } else if (email && email.startsWith('block.')) {
            const parts = email.replace('@activ.com', '').split('.');
            if (parts.length >= 4) {
              block = parts[1].replace(/[-_]/g, ' ');
              district = parts[2].replace(/[-_]/g, ' ');
              state = parts[3].replace(/[-_]/g, ' ');
            }
          }
          
          if (block && district && state) {
            locationQuery = {
              $and: [
                { $or: [
                  { block: new RegExp(`^${block}$`, 'i') },
                  { block: new RegExp(block.replace(/\s+/g, ''), 'i') }
                ]},
                { $or: [
                  { district: new RegExp(`^${district}$`, 'i') },
                  { district: new RegExp(district.replace(/\s+/g, ''), 'i') }
                ]},
                { $or: [
                  { state: new RegExp(`^${state}$`, 'i') },
                  { state: new RegExp(state.replace(/\s+/g, ''), 'i') }
                ]}
              ]
            };
          }
        }
      } else if (role === 'district') {
        Admin = DistrictAdmin;
        adminDoc = await Admin.findById(adminObjId).lean();
        if (adminDoc) {
          const { meta, email } = adminDoc;
          let district, state;
          
          if (meta && meta.district) {
            district = meta.district;
            state = meta.state;
          } else if (email && email.startsWith('district.')) {
            const parts = email.replace('@activ.com', '').split('.');
            if (parts.length >= 3) {
              district = parts[1].replace(/[-_]/g, ' ');
              state = parts[2].replace(/[-_]/g, ' ');
            }
          }
          
          if (district && state) {
            locationQuery = {
              $and: [
                { $or: [
                  { district: new RegExp(`^${district}$`, 'i') },
                  { district: new RegExp(district.replace(/\s+/g, ''), 'i') }
                ]},
                { $or: [
                  { state: new RegExp(`^${state}$`, 'i') },
                  { state: new RegExp(state.replace(/\s+/g, ''), 'i') }
                ]}
              ]
            };
          }
        }
      } else if (role === 'state') {
        Admin = StateAdmin;
        adminDoc = await Admin.findById(adminObjId).lean();
        if (adminDoc) {
          const { meta, email } = adminDoc;
          let state;
          
          if (meta && meta.state) {
            state = meta.state;
          } else if (email && email.startsWith('state.')) {
            const parts = email.replace('@activ.com', '').split('.');
            if (parts.length >= 2) {
              state = parts[1].replace(/[-_]/g, ' ');
            }
          }
          
          if (state) {
            locationQuery = {
              $or: [
                { state: new RegExp(`^${state}$`, 'i') },
                { state: new RegExp(state.replace(/\s+/g, ''), 'i') }
              ]
            };
          }
        }
      }

      // Build query based on status
      const q = { ...locationQuery };
      
      if (status === 'Approved') {
        if (role === 'block') {
          q.status = { $in: ['Pending-District', 'Pending-State', 'Approved'] };
          q['reviewedBy.blockAdmin'] = { $exists: true };
        } else if (role === 'district') {
          q.status = { $in: ['Pending-State', 'Approved'] };
          q['reviewedBy.districtAdmin'] = { $exists: true };
        } else if (role === 'state') {
          q.status = 'Approved';
          q['reviewedBy.stateAdmin'] = { $exists: true };
        }
      } else if (status === 'Rejected') {
        q.status = 'Rejected';
        if (role === 'block') q['reviewedBy.blockAdmin'] = { $exists: true };
        else if (role === 'district') q['reviewedBy.districtAdmin'] = { $exists: true };
        else if (role === 'state') q['reviewedBy.stateAdmin'] = { $exists: true };
      }

      console.log(`📊 Count query for ${role} admin ${status}:`, JSON.stringify(q, null, 2));
      const count = await Application.countDocuments(q);
      
      res.json({ success: true, count, role, status });
    } catch (err) {
      console.error("Get applications by admin error:", err);
      res.status(500).json({ success: false, message: "Server error" });
    }
  });

  // ---------- GET APPROVED/REJECTED APPLICATIONS LIST ----------
  router.get("/list-by-admin/:adminId", async (req, res) => {
    try {
      const { role, status } = req.query;
      
      if (!role || !status) {
        return res.status(400).json({ 
          success: false, 
          message: "Role and status query parameters are required" 
        });
      }

      let adminObjId = await resolveAdminObjectId(role, req.params.adminId, { BlockAdmin, DistrictAdmin, StateAdmin });
      
      if (!adminObjId) {
        console.error("resolveAdminObjectId failed for:", role, req.params.adminId);
        return res.status(400).json({ 
          success: false, 
          message: `Admin not found for role '${role}' and ID '${req.params.adminId}'` 
        });
      }

      // Get admin location for filtering
      let Admin, adminDoc, locationQuery = {};
      if (role === 'block') {
        Admin = BlockAdmin;
        adminDoc = await Admin.findById(adminObjId).lean();
        if (adminDoc) {
          const { meta, email } = adminDoc;
          let block, district, state;
          
          if (meta && meta.block) {
            block = meta.block;
            district = meta.district;
            state = meta.state;
          } else if (email && email.startsWith('block.')) {
            const parts = email.replace('@activ.com', '').split('.');
            if (parts.length >= 4) {
              block = parts[1].replace(/[-_]/g, ' ');
              district = parts[2].replace(/[-_]/g, ' ');
              state = parts[3].replace(/[-_]/g, ' ');
            }
          }
          
          if (block && district && state) {
            locationQuery = {
              $and: [
                { $or: [
                  { block: new RegExp(`^${block}$`, 'i') },
                  { block: new RegExp(block.replace(/\s+/g, ''), 'i') }
                ]},
                { $or: [
                  { district: new RegExp(`^${district}$`, 'i') },
                  { district: new RegExp(district.replace(/\s+/g, ''), 'i') }
                ]},
                { $or: [
                  { state: new RegExp(`^${state}$`, 'i') },
                  { state: new RegExp(state.replace(/\s+/g, ''), 'i') }
                ]}
              ]
            };
          }
        }
      } else if (role === 'district') {
        Admin = DistrictAdmin;
        adminDoc = await Admin.findById(adminObjId).lean();
        if (adminDoc) {
          const { meta, email } = adminDoc;
          let district, state;
          
          if (meta && meta.district) {
            district = meta.district;
            state = meta.state;
          } else if (email && email.startsWith('district.')) {
            const parts = email.replace('@activ.com', '').split('.');
            if (parts.length >= 3) {
              district = parts[1].replace(/[-_]/g, ' ');
              state = parts[2].replace(/[-_]/g, ' ');
            }
          }
          
          if (district && state) {
            locationQuery = {
              $and: [
                { $or: [
                  { district: new RegExp(`^${district}$`, 'i') },
                  { district: new RegExp(district.replace(/\s+/g, ''), 'i') }
                ]},
                { $or: [
                  { state: new RegExp(`^${state}$`, 'i') },
                  { state: new RegExp(state.replace(/\s+/g, ''), 'i') }
                ]}
              ]
            };
          }
        }
      } else if (role === 'state') {
        Admin = StateAdmin;
        adminDoc = await Admin.findById(adminObjId).lean();
        if (adminDoc) {
          const { meta, email } = adminDoc;
          let state;
          
          if (meta && meta.state) {
            state = meta.state;
          } else if (email && email.startsWith('state.')) {
            const parts = email.replace('@activ.com', '').split('.');
            if (parts.length >= 2) {
              state = parts[1].replace(/[-_]/g, ' ');
            }
          }
          
          if (state) {
            locationQuery = {
              $or: [
                { state: new RegExp(`^${state}$`, 'i') },
                { state: new RegExp(state.replace(/\s+/g, ''), 'i') }
              ]
            };
          }
        }
      }

      // Build query based on status
      const q = { ...locationQuery };
      
      if (status === 'Approved') {
        if (role === 'block') {
          q.status = { $in: ['Pending-District', 'Pending-State', 'Approved'] };
          q['reviewedBy.blockAdmin'] = { $exists: true };
        } else if (role === 'district') {
          q.status = { $in: ['Pending-State', 'Approved'] };
          q['reviewedBy.districtAdmin'] = { $exists: true };
        } else if (role === 'state') {
          q.status = 'Approved';
          q['reviewedBy.stateAdmin'] = { $exists: true };
        }
      } else if (status === 'Rejected') {
        q.status = 'Rejected';
        if (role === 'block') q['reviewedBy.blockAdmin'] = { $exists: true };
        else if (role === 'district') q['reviewedBy.districtAdmin'] = { $exists: true };
        else if (role === 'state') q['reviewedBy.stateAdmin'] = { $exists: true };
      }

      console.log(`📋 List query for ${role} admin ${status}:`, JSON.stringify(q, null, 2));
      const apps = await Application.find(q).sort({ createdAt: -1 }).lean();

      // Batch fetch gender from MemberDetails if missing
      const emailsNeedingGender = apps
        .filter(app => !app.gender && app.email)
        .map(app => app.email.toLowerCase().trim());
      
      let genderMap = new Map();
      if (emailsNeedingGender.length > 0) {
        const memberDetails = await MemberDetails.find(
          { email: { $in: emailsNeedingGender } },
          'email gender'
        ).lean();
        
        memberDetails.forEach(member => {
          if (member.email) {
            genderMap.set(member.email.toLowerCase(), member.gender);
          }
        });
      }

      // Enhance apps with gender data
      const enhancedApps = apps.map(appObj => {
        if (!appObj.gender && appObj.email) {
          const gender = genderMap.get(appObj.email.toLowerCase().trim());
          if (gender) {
            appObj.gender = gender;
          }
        }
        return appObj;
      });
      
      res.json(enhancedApps);
    } catch (err) {
      console.error("Get applications list by admin error:", err);
      res.status(500).json({ success: false, message: "Server error" });
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