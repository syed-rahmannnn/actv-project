const mongoose = require('mongoose');
require('dotenv').config({ path: './config.env' });
const getAdminModels = require('./models/adminModels');

(async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    const { BlockAdmin } = getAdminModels(mongoose.connection);

    const admins = await BlockAdmin.find().select('email adminId fullName active').lean();
    
    console.log(`📋 Found ${admins.length} Block Admin(s):\n`);
    
    admins.forEach((admin, index) => {
      console.log(`${index + 1}. Email: ${admin.email}`);
      console.log(`   Admin ID: ${admin.adminId}`);
      console.log(`   Name: ${admin.fullName}`);
      console.log(`   Active: ${admin.active}`);
      console.log(`   Password: ChangeMe@123`);
      console.log('');
    });

    await mongoose.disconnect();
    console.log('✅ Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
})();
