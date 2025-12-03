require('dotenv').config({ path: './config.env' });
const mongoose = require('mongoose');

// Define schemas
const companySchema = new mongoose.Schema({}, { strict: false });
const memberSchema = new mongoose.Schema({}, { strict: false });
const businessInfoSchema = new mongoose.Schema({}, { strict: false });

const Company = mongoose.model('Company', companySchema, 'companies');
const Member = mongoose.model('Member', memberSchema, 'memberdetails');
const BusinessInfo = mongoose.model('BusinessInfo', businessInfoSchema, 'memberbusinessinfos');

async function diagnoseData() {
  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    // Find the test user by email
    const testEmail = 'sairam12@gmail.com';
    console.log('='.repeat(80));
    console.log(`🔍 SEARCHING FOR USER: ${testEmail}`);
    console.log('='.repeat(80));

    const member = await Member.findOne({ email: testEmail });
    if (!member) {
      console.log('❌ Member not found!');
      await mongoose.disconnect();
      return;
    }

    console.log('\n📋 MEMBER DOCUMENT:');
    console.log('   _id:', member._id);
    console.log('   email:', member.email);
    console.log('   fullName:', member.fullName);
    console.log('   Full document:', JSON.stringify(member, null, 2));

    const memberId = member._id.toString();
    console.log('\n🆔 MEMBER ID TO USE:', memberId);

    // Check business info
    console.log('\n' + '='.repeat(80));
    console.log('🏢 BUSINESS INFO FOR THIS MEMBER:');
    console.log('='.repeat(80));
    
    const businessInfo = await BusinessInfo.findOne({ memberId: memberId });
    if (businessInfo) {
      console.log('✅ Business Info Found:');
      console.log('   _id:', businessInfo._id);
      console.log('   memberId:', businessInfo.memberId);
      console.log('   organizationName:', businessInfo.organizationName);
      console.log('   mobile:', businessInfo.mobile);
      console.log('   businessType:', businessInfo.businessType);
      console.log('   Full document:', JSON.stringify(businessInfo, null, 2));
    } else {
      console.log('❌ No business info found for memberId:', memberId);
    }

    // Check ALL companies in database
    console.log('\n' + '='.repeat(80));
    console.log('📦 ALL COMPANIES IN DATABASE:');
    console.log('='.repeat(80));
    
    const allCompanies = await Company.find();
    console.log(`\nTotal companies: ${allCompanies.length}\n`);
    
    allCompanies.forEach((company, index) => {
      console.log(`${index + 1}. ${company.name || 'Unnamed'}`);
      console.log(`   _id: ${company._id}`);
      console.log(`   memberId: ${company.memberId || 'NOT SET'}`);
      console.log(`   ownerId: ${company.ownerId || 'NOT SET'}`);
      console.log(`   businessId: ${company.businessId || 'NOT SET'}`);
      console.log(`   All fields:`, Object.keys(company.toObject()).filter(k => k !== '_id' && k !== '__v'));
      console.log('');
    });

    // Try to find companies by different field combinations
    console.log('='.repeat(80));
    console.log('🔍 SEARCHING COMPANIES FOR THIS USER:');
    console.log('='.repeat(80));

    console.log(`\n1. By memberId = ${memberId}:`);
    const byMemberId = await Company.find({ memberId: memberId });
    console.log(`   Found: ${byMemberId.length} companies`);
    byMemberId.forEach(c => console.log(`   - ${c.name}`));

    console.log(`\n2. By ownerId = ${memberId}:`);
    const byOwnerId = await Company.find({ ownerId: memberId });
    console.log(`   Found: ${byOwnerId.length} companies`);
    byOwnerId.forEach(c => console.log(`   - ${c.name}`));

    console.log(`\n3. By businessId = ${memberId}:`);
    const byBusinessId = await Company.find({ businessId: memberId });
    console.log(`   Found: ${byBusinessId.length} companies`);
    byBusinessId.forEach(c => console.log(`   - ${c.name}`));

    // Check if business info _id is used
    if (businessInfo) {
      const businessInfoId = businessInfo._id.toString();
      console.log(`\n4. By memberId = ${businessInfoId} (business info _id):`);
      const byBusinessInfoId = await Company.find({ memberId: businessInfoId });
      console.log(`   Found: ${byBusinessInfoId.length} companies`);
      byBusinessInfoId.forEach(c => console.log(`   - ${c.name}`));
    }

    console.log('\n' + '='.repeat(80));
    console.log('💡 RECOMMENDATIONS:');
    console.log('='.repeat(80));
    
    if (byMemberId.length > 0) {
      console.log('✅ Companies are stored with memberId - no changes needed');
    } else if (byOwnerId.length > 0) {
      console.log('⚠️  Companies use ownerId instead of memberId');
      console.log('    Fix: Update backend query to use ownerId');
    } else if (byBusinessId.length > 0) {
      console.log('⚠️  Companies use businessId instead of memberId');
      console.log('    Fix: Update backend query to use businessId');
    } else if (businessInfo && byBusinessInfoId.length > 0) {
      console.log('⚠️  Companies are linked to business info _id, not member _id');
      console.log('    Fix: Update create company to use member._id instead of businessInfo._id');
    } else {
      console.log('❌ No companies found with any ID combination');
      console.log('    Either no companies exist for this user, or field name is different');
    }

    await mongoose.disconnect();
    console.log('\n✅ Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

diagnoseData();
