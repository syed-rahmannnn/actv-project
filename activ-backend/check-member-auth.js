const mongoose = require('mongoose');
require('dotenv').config({ path: './config.env' });

const MemberAuth = require('./models/MemberAuth');
const MemberDetails = require('./models/MemberDetails');

const email = 'meera123@gmail.com';

(async () => {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    // Check MemberAuth
    console.log('🔍 Checking MemberAuth collection...');
    const authDoc = await MemberAuth.findOne({ email: email.toLowerCase() }).lean();
    if (authDoc) {
      console.log('✅ Found in MemberAuth:');
      console.log('   - ID:', authDoc._id.toString());
      console.log('   - Email:', authDoc.email);
      console.log('   - Profile Completed:', authDoc.profileCompleted);
      console.log('   - Registration Form Profile Completed:', authDoc.registrationForm?.profileCompleted);
    } else {
      console.log('❌ Not found in MemberAuth');
    }

    // Check MemberDetails
    console.log('\n🔍 Checking MemberDetails collection...');
    const detailsDoc = await MemberDetails.findOne({ email: email.toLowerCase() }).lean();
    if (detailsDoc) {
      console.log('✅ Found in MemberDetails:');
      console.log('   - ID:', detailsDoc._id.toString());
      console.log('   - Email:', detailsDoc.email);
      console.log('   - Full Name:', detailsDoc.fullName);
    } else {
      console.log('❌ Not found in MemberDetails');
    }

    await mongoose.disconnect();
    console.log('\n✅ Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
})();
