// Script to delete pending applications for testing
// Usage: node delete-pending-application.js <email>

const mongoose = require('mongoose');
require('dotenv').config({ path: './config.env' });

const Application = require('./models/applicationModel');

const email = process.argv[2];

if (!email) {
  console.log('Usage: node delete-pending-application.js <email>');
  console.log('Example: node delete-pending-application.js rajaa@gmail.com');
  process.exit(1);
}

mongoose
  .connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/membersdb')
  .then(async () => {
    console.log('Connected to MongoDB');

    // Find and delete pending applications for this email
    const result = await Application.deleteMany({
      email: email.toLowerCase(),
      status: 'PENDING',
    });

    console.log(`\n✅ Deleted ${result.deletedCount} pending application(s) for ${email}`);

    process.exit(0);
  })
  .catch((error) => {
    console.error('Error:', error);
    process.exit(1);
  });
