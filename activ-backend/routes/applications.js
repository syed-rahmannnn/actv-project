const express = require("express");
const router = express.Router();
const Application = require("../models/applicationModel");
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

      res.json(apps); // Return applications directly for compatibility with Flutter
    } catch (err) {
      console.error("Fetch block applications error:", err);
      res.status(500).json({ success: false, message: "Server error" });
    }
  });

  // ---------- GET APPLICATIONS FOR DISTRICT ADMIN ----------
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

      const apps = await Application.find({
        assignedDistrictAdmin: _id,
        status: "Pending-District",
      }).sort({ createdAt: -1 });

      res.json({ 
        success: true, 
        applications: apps,
        count: apps.length 
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

      const apps = await Application.find({
        assignedStateAdmin: _id,
        status: "Pending-State",
      }).sort({ createdAt: -1 });

      res.json({ success: true, applications: apps, count: apps.length });
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
        .populate('assignedBlockAdmin', 'fullName email')
        .populate('assignedDistrictAdmin', 'fullName email')
        .populate('assignedStateAdmin', 'fullName email')
        .sort({ createdAt: -1 });

      res.json({ 
        success: true, 
        applications: apps,
        count: apps.length 
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
      const app = await Application.findById(req.params.appId)
        .populate('assignedBlockAdmin', 'fullName email adminId')
        .populate('assignedDistrictAdmin', 'fullName email adminId')
        .populate('assignedStateAdmin', 'fullName email adminId')
        .populate('reviewedBy.blockAdmin', 'fullName email adminId')
        .populate('reviewedBy.districtAdmin', 'fullName email adminId')
        .populate('reviewedBy.stateAdmin', 'fullName email adminId');

      if (!app) {
        return res.status(404).json({ 
          success: false, 
          message: "Application not found" 
        });
      }

      res.json({ 
        success: true, 
        application: app 
      });
    } catch (err) {
      console.error("Fetch application details error:", err);
      res.status(500).json({ success: false, message: "Server error" });
    }
  });

  return router;
};