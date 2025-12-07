const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config({ path: './config.env' });
const getAdminModels = require('./models/adminModels');

const testEmail = 'block.thandrampet.thiruvannamalai.tamil.nadu@activ.com';
const testPassword = 'ChangeMe@123';

(async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    const { BlockAdmin, DistrictAdmin, StateAdmin, SuperAdmin } = getAdminModels(mongoose.connection);

    console.log(`🔍 Searching for: ${testEmail}\n`);

    // Check all admin collections
    const collections = [
      { name: 'BlockAdmin', model: BlockAdmin },
      { name: 'DistrictAdmin', model: DistrictAdmin },
      { name: 'StateAdmin', model: StateAdmin },
      { name: 'SuperAdmin', model: SuperAdmin }
    ];

    let found = false;

    for (const { name, model } of collections) {
      const admin = await model.findOne({ email: testEmail.toLowerCase().trim() }).lean();
      
      if (admin) {
        found = true;
        console.log(`✅ FOUND in ${name} collection:`);
        console.log('   - Email:', admin.email);
        console.log('   - Admin ID:', admin.adminId);
        console.log('   - Full Name:', admin.fullName);
        console.log('   - Active:', admin.active);
        console.log('   - Password Hash:', admin.passwordHash ? 'EXISTS' : 'MISSING');
        
        if (admin.passwordHash) {
          const isValid = await bcrypt.compare(testPassword, admin.passwordHash);
          console.log(`   - Password "${testPassword}":`, isValid ? '✅ CORRECT' : '❌ WRONG');
        }
        break;
      } else {
        console.log(`❌ NOT FOUND in ${name}`);
      }
    }

    if (!found) {
      console.log(`\n❌ Email "${testEmail}" NOT FOUND in any admin collection`);
      console.log('\n💡 This email is NOT an admin account.');
      console.log('   It might be a member account or needs to be created as admin.');
    }

    await mongoose.disconnect();
    console.log('\n✅ Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
})();
