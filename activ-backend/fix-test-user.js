const mongoose = require('mongoose');
const MemberDetails = require('./models/MemberDetails');
const MemberAuth = require('./models/MemberAuth');
require('dotenv').config({ path: './config.env' });

async function fixTestUser() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    const testEmail = 'test@activ.com';

    // Check existing records
    const memberDetails = await MemberDetails.findOne({ email: testEmail });
    const memberAuth = await MemberAuth.findOne({ email: testEmail });

    console.log('Member Details exists:', !!memberDetails);
    console.log('Member Auth exists:', !!memberAuth);

    if (memberAuth) {
      console.log('Member Auth active:', memberAuth.isActive);
    }

    // Create or update auth record
    if (!memberAuth) {
      console.log('Creating MemberAuth record...');
      const newAuth = new MemberAuth({
        email: testEmail,
        password: 'test12345',
        isActive: true
      });
      await newAuth.save();
      console.log('✅ MemberAuth record created');
    } else if (!memberAuth.isActive) {
      console.log('Activating MemberAuth record...');
      memberAuth.isActive = true;
      await memberAuth.save();
      console.log('✅ MemberAuth record activated');
    } else {
      console.log('MemberAuth record is already active');
    }

    // Test login
    console.log('\n🧪 Testing login...');
    const testAuth = await MemberAuth.findOne({ email: testEmail });
    if (testAuth) {
      const isPasswordValid = await testAuth.comparePassword('test12345');
      console.log('Password validation:', isPasswordValid);
    }

    console.log('\n✅ Test user is ready!');
    console.log('Login credentials:');
    console.log(`Email: ${testEmail}`);
    console.log('Password: test12345');

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('\nDisconnected from MongoDB');
  }
}

fixTestUser();