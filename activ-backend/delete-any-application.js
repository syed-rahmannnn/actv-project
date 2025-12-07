const mongoose = require('mongoose');
require('dotenv').config({ path: './config.env' });

const applicationSchema = new mongoose.Schema({}, { strict: false, collection: 'applications' });
const Application = mongoose.model('Application', applicationSchema);

async function deleteApplications(email) {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to MongoDB\n');

    const apps = await Application.find({ email: email.toLowerCase() });
    console.log(`Found ${apps.length} application(s) for ${email}`);
    
    if (apps.length > 0) {
      apps.forEach(app => {
        console.log(`- Status: ${app.status}, Created: ${app.createdAt}`);
      });
    }

    const result = await Application.deleteMany({ email: email.toLowerCase() });
    console.log(`\n✅ Deleted ${result.deletedCount} application(s) for ${email}`);
    
    process.exit(0);
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

const email = process.argv[2];
if (!email) {
  console.log('Usage: node delete-any-application.js <email>');
  process.exit(1);
}

deleteApplications(email);
