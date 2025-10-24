// create-admin.js
// Usage:
//   node create-admin.js <role> <adminId> <email> <password> [fullName]
// Example:
//   node create-admin.js BlockAdmin BA001 blockadmin@example.com 'StrongP@ssw0rd!' 'Block Admin'

require('dotenv').config({ path: './config.env' });
const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const getAdminModels = require('./models/adminModels');

async function main() {
  const args = process.argv.slice(2);
  if (args.length < 4) {
    console.error('Usage: node create-admin.js <role> <adminId> <email> <password> [fullName]');
    process.exit(1);
  }

  const [role, adminId, email, password, ...rest] = args;
  const fullName = rest.join(' ') || `${role}`;

  const MONGO_URI = process.env.MONGODB_URI || process.env.MONGO_URI;
  if (!MONGO_URI) {
    console.error('Please set MONGODB_URI or MONGO_URI in your .env');
    process.exit(1);
  }

  await mongoose.connect(MONGO_URI, { useNewUrlParser: true, useUnifiedTopology: true });
  const { BlockAdmin, DistrictAdmin, StateAdmin, SuperAdmin } = getAdminModels(mongoose.connection);

  const roleMap = {
    BlockAdmin,
    DistrictAdmin,
    StateAdmin,
    SuperAdmin
  };

  const Model = roleMap[role];
  if (!Model) {
    console.error('Invalid role. Must be one of: BlockAdmin, DistrictAdmin, StateAdmin, SuperAdmin');
    process.exit(1);
  }

  try {
    // check if email or adminId exists in the target collection
    const existsEmail = await Model.findOne({ email: email.toLowerCase().trim() });
    const existsAdminId = await Model.findOne({ adminId });
    if (existsEmail) {
      console.error('An admin with that email already exists in the chosen collection.');
      process.exit(1);
    }
    if (existsAdminId) {
      console.error('An admin with that adminId already exists in the chosen collection.');
      process.exit(1);
    }

    const passwordHash = await bcrypt.hash(password, 12);
    const doc = await Model.create({
      adminId,
      email: email.toLowerCase().trim(),
      passwordHash,
      fullName,
      role,
      active: true
    });

    console.log('Admin created:', { id: doc._id.toString(), adminId: doc.adminId, email: doc.email, role: doc.role });
    process.exit(0);
  } catch (err) {
    console.error('Error creating admin:', err);
    process.exit(2);
  }
}

main();