const mongoose = require('mongoose');
const MemberDetails = require('./models/MemberDetails');
const MemberAuth = require('./models/MemberAuth');
require('dotenv').config({ path: './config.env' });

async function createTestUser() {
  try {
    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB');

    // Check if any users exist
    const memberCount = await MemberDetails.countDocuments();
    const authCount = await MemberAuth.countDocuments();
    
    console.log(`Found ${memberCount} members and ${authCount} auth records`);

    // List first few users if they exist
    if (memberCount > 0) {
      const members = await MemberDetails.find().limit(5).select('fullName email');
      console.log('Existing members:');
      members.forEach(member => {
        console.log(`- ${member.fullName} (${member.email})`);
      });
    }

    // Check if test user already exists
    const testEmail = 'test@activ.com';
    const existingMember = await MemberDetails.findOne({ email: testEmail });
    const existingAuth = await MemberAuth.findOne({ email: testEmail });

    if (existingMember && existingAuth) {
      console.log(`Test user ${testEmail} already exists`);
      console.log('You can login with:');
      console.log(`Email: ${testEmail}`);
      console.log('Password: test12345');
      return;
    }

    // Create test user
    console.log('Creating test user...');

    // Create member details
    const memberDetails = new MemberDetails({
      fullName: 'Test User',
      email: testEmail,
      phoneNumber: '+919876543210',
      dateOfBirth: '1990-01-01',
      gender: 'Male',
      state: 'Tamil Nadu',
      district: 'Salem',
      block: 'Attur',
      city: 'Salem',
      profileCompleted: true
    });

    await memberDetails.save();
    console.log('Member details created');

    // Create auth record
    const memberAuth = new MemberAuth({
      email: testEmail,
      password: 'test12345', // Will be hashed automatically (8+ chars required)
      isActive: true
    });

    await memberAuth.save();
    console.log('Member auth created');

    console.log('✅ Test user created successfully!');
    console.log('You can now login with:');
    console.log(`Email: ${testEmail}`);
    console.log('Password: test12345');

  } catch (error) {
    console.error('Error:', error);
  } finally {
    await mongoose.disconnect();
    console.log('Disconnected from MongoDB');
  }
}

createTestUser();