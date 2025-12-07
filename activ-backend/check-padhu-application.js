const mongoose = require('mongoose');
require('dotenv').config({ path: './config.env' });

const MONGODB_URI = process.env.MONGODB_URI;

if (!MONGODB_URI) {
  console.error('❌ MONGODB_URI not found in config.env');
  process.exit(1);
}

mongoose.connect(MONGODB_URI)
  .then(async () => {
    console.log('✅ Connected to MongoDB');

    const Application = require('./models/applicationModel');

    const email = 'padhu@gmail.com';

    console.log(`\n🔍 Checking ALL applications for email: ${email}`);
    console.log('─'.repeat(80));

    const applications = await Application.find({ email: email.toLowerCase() }).lean();

    if (applications.length === 0) {
      console.log('❌ No applications found for this email');
    } else {
      console.log(`📋 Found ${applications.length} application(s):\n`);
      applications.forEach((app, index) => {
        console.log(`\nApplication ${index + 1}:`);
        console.log(`  ID: ${app._id}`);
        console.log(`  User ID: ${app.userId}`);
        console.log(`  Status: ${app.status}`);
        console.log(`  Member Type: ${app.memberType || app.formData?.memberType || 'Not specified'}`);
        console.log(`  Doing Business: ${app.doingBusiness || app.formData?.doingBusiness}`);
        console.log(`  Email: ${app.email}`);
        console.log(`  Block: ${app.block || 'Not specified'}`);
        console.log(`  District: ${app.district || 'Not specified'}`);
        console.log(`  State: ${app.state || 'Not specified'}`);
        console.log(`  Created: ${app.createdAt}`);
        console.log(`  Block Admin:`);
        console.log(`    - Assigned: ${app.assignedBlockAdmin ? 'Yes (' + app.assignedBlockAdmin + ')' : 'No'}`);
        console.log(`    - Approved: ${app.isBlockApproved ? 'Yes' : 'No'}`);
        console.log(`    - Approved At: ${app.blockApprovedAt || 'Not approved'}`);
        console.log(`  District Admin:`);
        console.log(`    - Assigned: ${app.assignedDistrictAdmin ? 'Yes (' + app.assignedDistrictAdmin + ')' : 'No'}`);
        console.log(`    - Approved: ${app.isDistrictApproved ? 'Yes' : 'No'}`);
        console.log(`    - Approved At: ${app.districtApprovedAt || 'Not approved'}`);
        console.log(`  State Admin:`);
        console.log(`    - Assigned: ${app.assignedStateAdmin ? 'Yes (' + app.assignedStateAdmin + ')' : 'No'}`);
        console.log(`    - Approved: ${app.isStateApproved ? 'Yes' : 'No'}`);
        console.log(`    - Approved At: ${app.stateApprovedAt || 'Not approved'}`);
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
