// models/adminModels.js
// Shared schema for admin collections, bound to a separate DB "adminsdb"
// Usage: const { BlockAdmin, DistrictAdmin, StateAdmin, SuperAdmin } = require('./models/adminModels');

const mongoose = require('mongoose');

const AdminSchema = new mongoose.Schema({
  adminId: { type: String, required: true, unique: true }, // e.g. BA001 / DA001
  email: { type: String, required: true, unique: true, lowercase: true, trim: true },
  passwordHash: { type: String, required: true }, // bcrypt hash
  fullName: { type: String, default: '' },
  role: { type: String, required: true }, // BlockAdmin, DistrictAdmin, StateAdmin, SuperAdmin
  active: { type: Boolean, default: true },
  createdAt: { type: Date, default: Date.now },
  lastLoginAt: { type: Date, default: null },
  meta: { type: mongoose.Schema.Types.Mixed, default: {} }
}, {
  timestamps: true // createdAt, updatedAt
});

// Add indexes
AdminSchema.index({ email: 1 }, { unique: true });
AdminSchema.index({ adminId: 1 }, { unique: true });

// Bind to adminsdb
function getAdminsDbModels(connection = mongoose.connection) {
  // useDb returns a new connection-like object scoped to a different DB on the same cluster
  const adminDb = connection.useDb('adminsdb', { useCache: true });

  // Third parameter ensures the actual collection name is correct (prevents model name pluralization surprises)
  const BlockAdmin = adminDb.model('BlockAdmin', AdminSchema, 'blockadmins');
  const DistrictAdmin = adminDb.model('DistrictAdmin', AdminSchema, 'districtadmins');
  const StateAdmin = adminDb.model('StateAdmin', AdminSchema, 'stateadmins');
  const SuperAdmin = adminDb.model('SuperAdmin', AdminSchema, 'superadmins');

  return { BlockAdmin, DistrictAdmin, StateAdmin, SuperAdmin };
}

module.exports = getAdminsDbModels;