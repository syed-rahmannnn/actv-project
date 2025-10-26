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

  return router;
};