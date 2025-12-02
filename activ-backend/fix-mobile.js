const mongoose = require('mongoose');
require('dotenv').config({ path: './config.env' });

const MemberBusinessInfo = require('./models/MemberBusinessInfo');

async function fixMobile() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Find the business profile with name "sairam conceltancy"
    const business = await MemberBusinessInfo.findOne({ 
      organizationName: /sairam/i 
    });

    if (!business) {
      console.log('❌ Business profile not found');
      process.exit(1);
    }

    console.log('Found business:', business.organizationName);
    console.log('Current mobile:', business.mobile);

    // Update with mobile number - CHANGE THIS TO YOUR ACTUAL NUMBER
    const MOBILE_NUMBER = '9876543210'; // CHANGE THIS TO YOUR REAL MOBILE NUMBER

    business.mobile = MOBILE_NUMBER;
    await business.save();

    console.log('✅ Mobile number updated to:', business.mobile);
    
    // Verify
    const updated = await MemberBusinessInfo.findById(business._id);
    console.log('Verified mobile in DB:', updated.mobile);

    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

fixMobile();
