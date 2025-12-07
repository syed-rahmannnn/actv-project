const mongoose = require('mongoose');
require('dotenv').config({ path: './config.env' });

// MongoDB Connection URI
const MONGO_URI = process.env.MONGODB_URI;

if (!MONGO_URI) {
  console.error('❌ MONGO_URI not found in config.env');
  process.exit(1);
}

// Connect to MongoDB
mongoose.connect(MONGO_URI)
  .then(async () => {
    console.log('✅ Connected to MongoDB');

    // Import Application model
    const Application = require('./models/applicationModel');

    // User ID to check
    const userId = '693516393b346665f061b45d';

    console.log(`\n🔍 Checking applications for user: ${userId}`);
    console.log('─'.repeat(80));

    const applications = await Application.find({ userId }).lean();

    if (applications.length === 0) {
      console.log('✅ No applications found for this user');
    } else {
      console.log(`📋 Found ${applications.length} application(s):\n`);
      applications.forEach((app, index) => {
        console.log(`Application ${index + 1}:`);
        console.log(`  ID: ${app._id}`);
        console.log(`  Status: ${app.status}`);
        console.log(`  Member Type: ${app.memberType || 'Not specified'}`);
        console.log(`  Doing Business: ${app.doingBusiness}`);
        console.log(`  Created: ${app.createdAt}`);
        console.log(`  Block Admin Assigned: ${app.assignedBlockAdmin ? 'Yes' : 'No'}`);
        console.log(`  District Admin Assigned: ${app.assignedDistrictAdmin ? 'Yes' : 'No'}`);
        console.log(`  State Admin Assigned: ${app.assignedStateAdmin ? 'Yes' : 'No'}`);
        console.log('─'.repeat(80));
      });
    }

    await mongoose.disconnect();
    console.log('\n✅ Disconnected from MongoDB');
  })
  .catch((error) => {
    console.error('❌ Error:', error);
    process.exit(1);
  });
