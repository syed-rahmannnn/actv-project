/**
 * Fix script to create Company record for new member
 * Run this to create missing Company for Tamilarasan
 */

require('dotenv').config({ path: './config.env' });
const mongoose = require('mongoose');

async function fixNewMemberCompany() {
    try {
        console.log('\n🔧 FIX NEW MEMBER COMPANY SCRIPT');
        console.log('='.repeat(80));

        // Connect to MongoDB
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Connected to MongoDB');

        const MemberBusinessInfo = mongoose.model('MemberBusinessInfo', new mongoose.Schema({}, { strict: false }));
        const Company = mongoose.model('Company', new mongoose.Schema({}, { strict: false }));

        // Find the new member's business info
        const newMemberId = '6933eaa6828756fd6cdd5734';
        console.log('\n🔍 Searching for member:', newMemberId);

        const businessInfo = await MemberBusinessInfo.findOne({
            memberId: new mongoose.Types.ObjectId(newMemberId)
        });

        if (!businessInfo) {
            console.log('❌ Business info not found for this member');
            process.exit(1);
        }

        console.log('\n📋 Found Business Info:');
        console.log('   Organization Name:', businessInfo.organizationName);
        console.log('   Business Type:', businessInfo.businessType);
        console.log('   Mobile:', businessInfo.mobile);
        console.log('   Location:', businessInfo.location);

        // Check if company already exists
        const existingCompany = await Company.findOne({
            memberId: new mongoose.Types.ObjectId(newMemberId)
        });

        if (existingCompany) {
            console.log('\n✅ Company already exists:', existingCompany._id);
            console.log('   Company Name:', existingCompany.name);
            process.exit(0);
        }

        // Create new company
        console.log('\n🏢 Creating new Company record...');
        const newCompany = new Company({
            memberId: new mongoose.Types.ObjectId(newMemberId),
            name: businessInfo.organizationName,
            industry: businessInfo.businessType || 'General',
            location: businessInfo.location || businessInfo.area,
            city: businessInfo.location,
            area: businessInfo.area,
            description: businessInfo.businessDescription || '',
            mobile: businessInfo.mobile,
            email: businessInfo.email,
            status: businessInfo.status || 'UNDER_REVIEW',
            productsCount: 0,
            views: 0,
            connections: 0
        });

        await newCompany.save();

        console.log('\n✅ SUCCESS! Company created:');
        console.log('   Company ID:', newCompany._id);
        console.log('   Company Name:', newCompany.name);
        console.log('   Member ID:', newCompany.memberId);
        console.log('   Status:', newCompany.status);
        console.log('   Mobile:', newCompany.mobile);

        console.log('\n' + '='.repeat(80));
        console.log('✅ Fix completed! The new member can now see their company.');
        console.log('='.repeat(80) + '\n');

    } catch (error) {
        console.error('\n❌ Error:', error.message);
        console.error(error);
    } finally {
        await mongoose.connection.close();
        console.log('👋 Disconnected from MongoDB\n');
    }
}

fixNewMemberCompany();