const mongoose = require('mongoose');
const Activity = require('./models/Activity');
require('dotenv').config({ path: './config.env' });

async function checkActivities() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Connected to MongoDB\n');

        const companyId = '69307a8c213683c33a69ad85';
        console.log(`Checking activities for company: ${companyId}\n`);

        const activities = await Activity.find({ companyId })
            .sort({ createdAt: -1 })
            .limit(10);

        console.log(`📊 Found ${activities.length} activities:\n`);

        if (activities.length === 0) {
            console.log('❌ No activities found for this company!');
            console.log('\n💡 Activities should be created when:');
            console.log('   - Products are created (PRODUCT_CREATED)');
            console.log('   - Products are deleted (PRODUCT_DELETED)');
            console.log('   - Company profile is updated');
        } else {
            activities.forEach((a, i) => {
                console.log(`${i + 1}. ${a.activityType}`);
                console.log(`   Entity: ${a.entityName}`);
                console.log(`   Description: ${a.description}`);
                console.log(`   Time: ${a.createdAt}`);
                console.log('');
            });
        }

        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

checkActivities();