const mongoose = require('mongoose');
require('dotenv').config({ path: './config.env' });

const Application = require('./models/applicationModel');
const { DistrictAdmin } = require('./models/adminModels');

async function assignPendingApplications() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Connected to MongoDB');

        // Find the Ariyalur district admin
        const districtAdmin = await DistrictAdmin.findOne({ 
            districtName: 'Ariyalur' 
        });
        
        if (!districtAdmin) {
            console.log('❌ No Ariyalur district admin found!');
            process.exit(1);
        }

        console.log(`\n📋 Found District Admin:`);
        console.log(`   ID: ${districtAdmin._id}`);
        console.log(`   Email: ${districtAdmin.email}`);
        console.log(`   District: ${districtAdmin.districtName}`);

        // Find all Pending-District applications for Ariyalur
        const pendingApps = await Application.find({
            district: 'Ariyalur',
            status: 'Pending-District'
        });

        console.log(`\n📊 Found ${pendingApps.length} Pending-District applications for Ariyalur`);

        // Assign them to this district admin
        for (const app of pendingApps) {
            app.assignedDistrictAdmin = districtAdmin._id;
            await app.save();
            console.log(`✅ Assigned ${app.fullName} (${app._id}) to District Admin`);
        }

        console.log(`\n✨ Successfully assigned ${pendingApps.length} applications to District Admin`);
        process.exit(0);

    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

assignPendingApplications();
