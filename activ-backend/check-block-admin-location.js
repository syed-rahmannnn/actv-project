const mongoose = require('mongoose');
require('dotenv').config({ path: './config.env' });
const getAdminModels = require('./models/adminModels');

(async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    const { BlockAdmin } = getAdminModels(mongoose.connection);

    const admin = await BlockAdmin.findOne({ 
      adminId: 'BA_THIRU' 
    }).lean();
    
    if (!admin) {
      console.log('❌ Admin not found');
      process.exit(1);
    }

    console.log('📋 Block Admin Details:');
    console.log('   - Admin ID:', admin.adminId);
    console.log('   - Email:', admin.email);
    console.log('   - Full Name:', admin.fullName);
    console.log('   - Location:', JSON.stringify(admin.location, null, 2));
    console.log('   - Meta:', JSON.stringify(admin.meta, null, 2));

    await mongoose.disconnect();
    console.log('\n✅ Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
})();
