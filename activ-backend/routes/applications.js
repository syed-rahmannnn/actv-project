const express = require("express");
const router = express.Router();
const Application = require("../models/applicationModel");
const getAdminModels = require("../models/adminModels");

module.exports = (mongooseConnection) => {
  const { BlockAdmin, DistrictAdmin, StateAdmin } = getAdminModels(mongooseConnection || require("mongoose").connection);

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

      // Normalize location strings to ensure matching
      const norm = (s) => (typeof s === 'string' ? s.trim() : s);
      const S = norm(state);
      const D = norm(district);
      const B = norm(block);

      // Find matching admins based on location
      const blockAdmin = await BlockAdmin.findOne({
        "meta.state": S,
        "meta.district": D,
        "meta.block": B,
        active: true
      });

      const districtAdmin = await DistrictAdmin.findOne({
        "meta.state": S,
        "meta.district": D,
        active: true
      });

      const stateAdmin = await StateAdmin.findOne({
        "meta.state": S,
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
      if (app.assignedBlockAdmin.toString() !== adminId) {
        return res.status(403).json({
          success: false,
          message: "You are not authorized to review this application"
        });
      }

      if (action === "approve") {
        app.status = "Pending-District";
        app.blockApprovedAt = new Date();
        app.reviewedBy.blockAdmin = adminId;
      } else if (action === "reject") {
        app.status = "Rejected";
        app.rejectionReason = reason || "No reason provided";
        app.reviewedBy.blockAdmin = adminId;
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
      if (app.assignedDistrictAdmin.toString() !== adminId) {
        return res.status(403).json({
          success: false,
          message: "You are not authorized to review this application"
        });
      }

      if (action === "approve") {
        app.status = "Pending-State";
        app.districtApprovedAt = new Date();
        app.reviewedBy.districtAdmin = adminId;
      } else if (action === "reject") {
        app.status = "Rejected";
        app.rejectionReason = reason || "No reason provided";
        app.reviewedBy.districtAdmin = adminId;
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
      const apps = await Application.find({
        assignedBlockAdmin: req.params.blockAdminId,
        status: "Pending-Block",
      }).sort({ createdAt: -1 });

      res.json({ 
        success: true, 
        applications: apps,
        count: apps.length 
      });
    } catch (err) {
      console.error("Fetch block applications error:", err);
      res.status(500).json({ success: false, message: "Server error" });
    }
  });

  // ---------- GET APPLICATIONS FOR DISTRICT ADMIN ----------
  router.get("/district/:districtAdminId", async (req, res) => {
    try {
      const apps = await Application.find({
        assignedDistrictAdmin: req.params.districtAdminId,
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
      const apps = await Application.find({
        assignedStateAdmin: req.params.stateAdminId,
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

      if (app.assignedStateAdmin.toString() !== adminId) {
        return res.status(403).json({ success: false, message: "You are not authorized to review this application" });
      }

      if (action === "approve") {
        app.status = "Approved";
        app.stateApprovedAt = new Date();
        app.reviewedBy.stateAdmin = adminId;
      } else if (action === "reject") {
        app.status = "Rejected";
        app.rejectionReason = reason || "No reason provided";
        app.reviewedBy.stateAdmin = adminId;
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
      const { adminId } = req.params;
      const { role, status } = req.query;

      if (!role || !status) {
        return res.status(400).json({
          success: false,
          message: "Role and status query parameters are required"
        });
      }

      let query = {};
      
      // Build query based on role and status
      if (role === 'block') {
        query.assignedBlockAdmin = adminId;
        if (status === 'Approved') {
          query.status = { $in: ['Pending-District', 'Pending-State', 'Approved'] };
          query['reviewedBy.blockAdmin'] = { $exists: true };
        } else if (status === 'Rejected') {
          query.status = 'Rejected';
          query['reviewedBy.blockAdmin'] = { $exists: true };
        }
      } else if (role === 'district') {
        query.assignedDistrictAdmin = adminId;
        if (status === 'Approved') {
          query.status = { $in: ['Pending-State', 'Approved'] };
          query['reviewedBy.districtAdmin'] = { $exists: true };
        } else if (status === 'Rejected') {
          query.status = 'Rejected';
          query['reviewedBy.districtAdmin'] = { $exists: true };
        }
      } else if (role === 'state') {
        query.assignedStateAdmin = adminId;
        if (status === 'Approved') {
          query.status = 'Approved';
          query['reviewedBy.stateAdmin'] = { $exists: true };
        } else if (status === 'Rejected') {
          query.status = 'Rejected';
          query['reviewedBy.stateAdmin'] = { $exists: true };
        }
      }

      const count = await Application.countDocuments(query);
      
      res.json({
        success: true,
        count: count,
        role: role,
        status: status
      });
    } catch (err) {
      console.error("Get applications by admin error:", err);
      res.status(500).json({ success: false, message: "Server error" });
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