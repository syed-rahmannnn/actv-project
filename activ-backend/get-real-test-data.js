/**
 * GET REAL TEST DATA FROM DATABASE
 * Finds actual IDs to use for testing
 */

const mongoose = require('mongoose');
require('dotenv').config({ path: './config.env' });

async function getRealTestData() {
    try {
        console.log('🔌 Connecting to MongoDB...');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Connected\n');

        const MemberDetails = mongoose.model('MemberDetails', new mongoose.Schema({}, { strict: false }));
        const Company = mongoose.model('Company', new mongoose.Schema({}, { strict: false }));
        const MemberBusinessInfo = mongoose.model('MemberBusinessInfo', new mongoose.Schema({}, { strict: false }));

        // Find a real member
        const member = await MemberDetails.findOne().lean();
        console.log('👤 Found Member:');
        console.log('   ID:', member ? ._id);
        console.log('   Email:', member ? .email);
        console.log('   Name:', member ? .fullName);

        // Find a real company
        const company = await Company.findOne().lean();
        console.log('\n🏢 Found Company:');
        console.log('   ID:', company ? ._id);
        console.log('   Name:', company ? .name);
        console.log('   Member ID:', company ? .memberId);

        // Find a real business info
        const businessInfo = await MemberBusinessInfo.findOne().lean();
        console.log('\n💼 Found Business Info:');
        console.log('   Member ID:', businessInfo ? .memberId);
        console.log('   Organization:', businessInfo ? .organizationName);

        console.log('\n📋 Update your test-optimizations.js with:');
        console.log('   TEST_MEMBER_ID:', member ? ._id ? .toString() || 'NOT_FOUND');
        console.log('   TEST_COMPANY_ID:', company ? ._id ? .toString() || 'NOT_FOUND');
        console.log('   TEST_EMAIL:', member ? .email || 'NOT_FOUND');

        await mongoose.disconnect();
        console.log('\n✅ Disconnected');
        process.exit(0);

    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

getRealTestData();