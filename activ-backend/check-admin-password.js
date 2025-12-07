const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config({ path: './config.env' });
const getAdminModels = require('./models/adminModels');

(async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    const { BlockAdmin } = getAdminModels(mongoose.connection);

    // Get first block admin
    const admin = await BlockAdmin.findOne().lean();
    
    if (!admin) {
      console.log('❌ No Block Admin found in database');
      process.exit(1);
    }

    console.log('📋 Block Admin Details:');
    console.log('   - Email:', admin.email);
    console.log('   - Admin ID:', admin.adminId);
    console.log('   - Full Name:', admin.fullName);
    console.log('   - Password Hash:', admin.passwordHash ? 'EXISTS' : 'MISSING');
    console.log('   - Active:', admin.active);
    
    // Test password
    const testPassword = 'ChangeMe@123';
    const isValid = await bcrypt.compare(testPassword, admin.passwordHash);
    console.log(`\n🔐 Password test for "${testPassword}":`, isValid ? '✅ CORRECT' : '❌ WRONG');

    await mongoose.disconnect();
    console.log('\n✅ Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
})();
