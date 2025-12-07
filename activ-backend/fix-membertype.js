const mongoose = require('mongoose');
require('dotenv').config({ path: './config.env' });

// Import Application model
const Application = require('./models/applicationModel');

async function fixMemberType() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Connected to MongoDB');

        // Find application for tharunroobika@gmail.com
        const application = await Application.findOne({ email: 'tharunroobika@gmail.com' });
        
        if (!application) {
            console.log('❌ Application not found for tharunroobika@gmail.com');
            process.exit(1);
        }

        console.log('📋 Current application data:');
        console.log('  - Email:', application.email);
        console.log('  - Status:', application.status);
        console.log('  - FormData keys:', Object.keys(application.formData));
        console.log('  - Current memberType:', application.formData.memberType);
        console.log('  - businessInfo:', application.formData.businessInfo);

        // Check if it's a business application
        if (application.formData.businessInfo || application.formData.businessType) {
            // Update memberType to COMPANY
            application.formData.memberType = 'COMPANY';
            await application.save();
            console.log('✅ Updated memberType to COMPANY');
            console.log('✅ New formData.memberType:', application.formData.memberType);
        } else if (application.formData.memberType === 'ASPIRANT') {
            console.log('ℹ️ This is an ASPIRANT member - no change needed');
        } else {
            console.log('⚠️ Cannot determine member type - setting to COMPANY since businessInfo exists');
            application.formData.memberType = 'COMPANY';
            await application.save();
            console.log('✅ Set memberType to COMPANY');
        }

        await mongoose.disconnect();
        console.log('✅ Done');
        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

fixMemberType();
