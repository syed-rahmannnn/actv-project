const mongoose = require("mongoose");
require('dotenv').config({ path: './config.env' });

const MONGODB_URI = process.env.MONGODB_URI;

if (!MONGODB_URI) {
  console.error('❌ MONGODB_URI not found in config.env');
  process.exit(1);
}

const Application = require("./models/applicationModel");

async function checkMemberType() {
  try {
    await mongoose.connect(MONGODB_URI);
    console.log("Connected to MongoDB\n");

    // Find all applications with status=PENDING
    const apps = await Application.find({ status: 'PENDING' })
      .select('email status memberType doingBusiness assignedBlockAdmin')
      .lean();

    console.log(`Found ${apps.length} PENDING applications:\n`);
    
    apps.forEach((app, i) => {
      console.log(`Application ${i + 1}:`);
      console.log(`  Email: ${app.email}`);
      console.log(`  Status: ${app.status}`);
      console.log(`  memberType: ${app.memberType} (type: ${typeof app.memberType})`);
      console.log(`  doingBusiness: ${app.doingBusiness}`);
      console.log(`  assignedBlockAdmin: ${app.assignedBlockAdmin}`);
      console.log(`  Has memberType field: ${app.hasOwnProperty('memberType')}`);
      console.log('');
    });

    await mongoose.disconnect();
  } catch (error) {
    console.error("Error:", error);
    process.exit(1);
  }
}

checkMemberType();
