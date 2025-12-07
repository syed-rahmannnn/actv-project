const mongoose = require('mongoose');
require('dotenv').config({ path: './config.env' });

const MONGODB_URI = process.env.MONGODB_URI;

if (!MONGODB_URI) {
  console.error('❌ MONGODB_URI not found in config.env');
  process.exit(1);
}

const getAdminsDbModels = require('./models/adminModels');

async function updateAdminLocation() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log('Connected to MongoDB\n');

    const { BlockAdmin } = getAdminsDbModels();

    // Update the Block Admin with email block.andimadam.ariyalur.tamil.nadu@activ.com
    const email = 'block.andimadam.ariyalur.tamil.nadu@activ.com';
    
    const admin = await BlockAdmin.findOne({ email: email.toLowerCase() });
    
    if (!admin) {
      console.error(`❌ Block Admin not found with email: ${email}`);
      process.exit(1);
    }

    console.log('Found Block Admin:');
    console.log(`  Email: ${admin.email}`);
    console.log(`  Admin ID: ${admin.adminId}`);
    console.log(`  Current meta:`, admin.meta);

    // Update with location metadata
    admin.meta = {
      block: 'Andimadam',
      district: 'Ariyalur',
      state: 'Tamil Nadu'
    };

    await admin.save();

    console.log('\n✅ Updated Block Admin location metadata:');
    console.log(`  Block: ${admin.meta.block}`);
    console.log(`  District: ${admin.meta.district}`);
    console.log(`  State: ${admin.meta.state}`);

    await mongoose.disconnect();
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

updateAdminLocation();
