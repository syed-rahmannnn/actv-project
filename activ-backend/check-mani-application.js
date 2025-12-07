require('dotenv').config({ path: './config.env' });
const mongoose = require('mongoose');
const MemberDetails = require('./models/MemberDetails');
const Application = require('./models/applicationModel');

const run = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI);
        console.log('✅ Connected to MongoDB');

        // Find user "mani"
        const member = await MemberDetails.findOne({ 
            email: 'user_1765131182004_ps9sd3nbp@temp.local' 
        });

        if (!member) {
            console.log('❌ Member not found');
            process.exit(0);
        }

        console.log('\n📧 Member found:');
        console.log(`   Name: ${member.fullName}`);
        console.log(`   ID: ${member._id}`);
        console.log(`   Email: ${member.email}`);

        // Find ALL applications for this user
        const applications = await Application.find({ 
            userId: member._id.toString() 
        }).sort({ createdAt: -1 });

        console.log(`\n📋 Found ${applications.length} application(s):`);

        if (applications.length === 0) {
            console.log('   ✅ No applications found (this is correct for new user)');
        } else {
            applications.forEach((app, index) => {
                console.log(`\n   Application ${index + 1}:`);
                console.log(`   - ID: ${app._id}`);
                console.log(`   - Status: ${app.status}`);
                console.log(`   - Created: ${app.createdAt}`);
                console.log(`   - Updated: ${app.updatedAt}`);
                console.log(`   - MemberType: ${app.formData?.memberType || 'NOT SET'}`);
            });

            // If there are applications but user says they don't have one,
            // we should delete the old ones
            console.log('\n⚠️ WARNING: This user has existing application(s) but they should be a new user');
            console.log('❓ Do you want to delete these applications? (Run delete-mani-applications.js to delete)');
        }

        process.exit(0);
    } catch (err) {
        console.error('❌ Error:', err);
        process.exit(1);
    }
};

run();
