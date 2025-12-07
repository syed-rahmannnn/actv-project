/**
 * Diagnostic script to check old member's data
 */

require('dotenv').config({ path: './config.env' });
const mongoose = require('mongoose');

async function checkOldMember() {
    try {
        console.log('\n🔍 CHECKING OLD MEMBER DATA');
        console.log('='.repeat(80));

        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Connected to MongoDB');

        const MemberDetails = mongoose.model('MemberDetails', new mongoose.Schema({}, { strict: false }));
        const MemberBusinessInfo = mongoose.model('MemberBusinessInfo', new mongoose.Schema({}, { strict: false }));
        const Company = mongoose.model('Company', new mongoose.Schema({}, { strict: false }));

        const email = 'sairam12@gmail.com';
        console.log('\n📧 Searching for email:', email);

        // Find member
        const member = await MemberDetails.findOne({ email: email.toLowerCase() });
        if (!member) {
            console.log('❌ Member not found');
            process.exit(1);
        }

        console.log('\n👤 MEMBER DETAILS:');
        console.log('   _id:', member._id);
        console.log('   fullName:', member.fullName);
        console.log('   email:', member.email);
        console.log('   phoneNumber:', member.phoneNumber);

        const memberId = member._id;

        // Find business info
        console.log('\n🏢 BUSINESS INFO:');
        const businessInfo = await MemberBusinessInfo.findOne({ memberId: memberId });
        if (businessInfo) {
            console.log('   ✅ Found business info');
            console.log('   _id:', businessInfo._id);
            console.log('   organizationName:', businessInfo.organizationName);
            console.log('   businessType:', businessInfo.businessType);
            console.log('   mobile:', businessInfo.mobile);
            console.log('   status:', businessInfo.status);
        } else {
            console.log('   ❌ No business info found');
        }

        // Find companies
        console.log('\n🏭 COMPANIES:');
        const companies = await Company.find({ memberId: memberId });
        console.log('   Found', companies.length, 'companies:');
        companies.forEach((c, i) => {
            console.log(`   ${i + 1}. ${c.name} (${c._id})`);
            console.log(`      Status: ${c.status}`);
            console.log(`      Products: ${c.productsCount}`);
        });

        console.log('\n' + '='.repeat(80));
        console.log('✅ Diagnostic complete');
        console.log('='.repeat(80) + '\n');

    } catch (error) {
        console.error('\n❌ Error:', error.message);
        console.error(error);
    } finally {
        await mongoose.connection.close();
        console.log('👋 Disconnected from MongoDB\n');
    }
}

checkOldMember();