// routes/adminAuth.js
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const getAdminModels = require('../models/adminModels');

const router = express.Router();

const JWT_SECRET = process.env.JWT_SECRET || process.env.JWTSECRET || 'replace_with_strong_secret';
const JWT_EXPIRES = '2d'; // adjust as needed

module.exports = (mongooseConnection) => {
  // if you prefer to use default mongoose import, you can call getAdminModels(require('mongoose').connection)
  const { BlockAdmin, DistrictAdmin, StateAdmin, SuperAdmin } = getAdminModels(mongooseConnection || require('mongoose').connection);

  const roleMap = {
    BlockAdmin,
    DistrictAdmin,
    StateAdmin,
    SuperAdmin
  };

  router.post('/login', async (req, res) => {
    try {
      const { email, password, role } = req.body;
      if (!email || !password || !role) return res.status(400).json({ message: 'email, password and role are required' });

      const Model = roleMap[role];
      if (!Model) return res.status(400).json({ message: 'Invalid role' });

      const admin = await Model.findOne({ email: email.toLowerCase().trim() }).lean();
      if (!admin) return res.status(401).json({ message: 'Admin not found' });

      const valid = await bcrypt.compare(password, admin.passwordHash);
      if (!valid) return res.status(401).json({ message: 'Invalid credentials' });

      // Issue JWT payload: adminId, role
      const token = jwt.sign({ adminId: admin._id.toString(), role: admin.role, adminIdStr: admin.adminId }, JWT_SECRET, { expiresIn: JWT_EXPIRES });

      // update lastLoginAt (optional)
      await Model.updateOne({ _id: admin._id }, { $set: { lastLoginAt: new Date() } });

      return res.json({
        token,
        id: admin._id.toString(),     // <-- add this
        fullName: admin.fullName,
        role: admin.role,
        adminId: admin.adminId,       // human code (BA.../DA.../SA...)
        mustResetPassword: admin.meta?.mustResetPassword || false,
        location: {
          state: admin.meta?.state,
          district: admin.meta?.district,
          block: admin.meta?.block
        }
      });
    } catch (err) {
      console.error('admin login error', err);
      return res.status(500).json({ message: 'Server error' });
    }
  });

  // GET /api/admin/block/:adminId - Fetch block admin details
  router.get('/block/:adminId', async (req, res) => {
    try {
      const { adminId } = req.params;
      if (!adminId) {
        return res.status(400).json({ message: 'Admin ID is required' });
      }

      // Try to find admin by MongoDB ObjectId first, then by adminId field
      let admin;
      if (adminId.match(/^[0-9a-fA-F]{24}$/)) {
        // It's a MongoDB ObjectId
        admin = await BlockAdmin.findById(adminId).lean();
      } else {
        // It's an admin code (e.g., BA001)
        admin = await BlockAdmin.findOne({ adminId: adminId }).lean();
      }

      if (!admin) {
        return res.status(404).json({ message: 'Block admin not found' });
      }

      // Return admin details in the expected format
      return res.json({
        adminId: admin.adminId,
        fullName: admin.fullName,
        email: admin.email,
        meta: {
          blockName: admin.meta?.blockName || admin.meta?.block || '',
          districtName: admin.meta?.districtName || admin.meta?.district || '',
          stateName: admin.meta?.stateName || admin.meta?.state || ''
        },
        active: admin.active
      });
    } catch (err) {
      console.error('fetch block admin details error', err);
      return res.status(500).json({ message: 'Server error' });
    }
  });

  // GET /api/admin/district/:adminId - Fetch district admin details
  router.get('/district/:adminId', async (req, res) => {
    try {
      const { adminId } = req.params;
      if (!adminId) {
        return res.status(400).json({ message: 'Admin ID is required' });
      }

      let admin;
      if (adminId.match(/^[0-9a-fA-F]{24}$/)) {
        admin = await DistrictAdmin.findById(adminId).lean();
      } else {
        admin = await DistrictAdmin.findOne({ adminId: adminId }).lean();
      }

      if (!admin) {
        return res.status(404).json({ message: 'District admin not found' });
      }

      return res.json({
        adminId: admin.adminId,
        fullName: admin.fullName,
        email: admin.email,
        meta: {
          districtName: admin.meta?.districtName || admin.meta?.district || '',
          stateName: admin.meta?.stateName || admin.meta?.state || ''
        },
        active: admin.active
      });
    } catch (err) {
      console.error('fetch district admin details error', err);
      return res.status(500).json({ message: 'Server error' });
    }
  });

  // GET /api/admin/state/:adminId - Fetch state admin details
  router.get('/state/:adminId', async (req, res) => {
    try {
      const { adminId } = req.params;
      if (!adminId) {
        return res.status(400).json({ message: 'Admin ID is required' });
      }

      let admin;
      if (adminId.match(/^[0-9a-fA-F]{24}$/)) {
        admin = await StateAdmin.findById(adminId).lean();
      } else {
        admin = await StateAdmin.findOne({ adminId: adminId }).lean();
      }

      if (!admin) {
        return res.status(404).json({ message: 'State admin not found' });
      }

      return res.json({
        adminId: admin.adminId,
        fullName: admin.fullName,
        email: admin.email,
        meta: {
          stateName: admin.meta?.stateName || admin.meta?.state || ''
        },
        active: admin.active
      });
    } catch (err) {
      console.error('fetch state admin details error', err);
      return res.status(500).json({ message: 'Server error' });
    }
  });

  return router;
};