require('dotenv').config({ path: './config.env' });
const mongoose = require('mongoose');

const businessInfoSchema = new mongoose.Schema({}, { strict: false });
const BusinessInfo = mongoose.model('BusinessInfo', businessInfoSchema, 'memberbusinessinfos');

async function checkBusinessInfo() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected\n');

    const memberId = '692e685ce47750d07c018b50';
    
    console.log('='.repeat(80));
    console.log('🔍 SEARCHING BUSINESS INFO');
    console.log('='.repeat(80));
    console.log(`Member ID (string): ${memberId}\n`);

    // Try as string
    console.log('1. Query with STRING memberId:');
    const asString = await BusinessInfo.findOne({ memberId: memberId });
    console.log(`   Result: ${asString ? 'FOUND' : 'NOT FOUND'}`);
    if (asString) {
      console.log(`   mobile: ${asString.mobile}`);
      console.log(`   organizationName: ${asString.organizationName}`);
    }

    // Try as ObjectId
    console.log('\n2. Query with ObjectId memberId:');
    const asObjectId = await BusinessInfo.findOne({ memberId: new mongoose.Types.ObjectId(memberId) });
    console.log(`   Result: ${asObjectId ? 'FOUND' : 'NOT FOUND'}`);
    if (asObjectId) {
      console.log(`   mobile: ${asObjectId.mobile}`);
      console.log(`   organizationName: ${asObjectId.organizationName}`);
      console.log(`   Full document:`);
      console.log(JSON.stringify(asObjectId, null, 2));
    }

    // Show ALL business info documents
    console.log('\n' + '='.repeat(80));
    console.log('📦 ALL BUSINESS INFO DOCUMENTS:');
    console.log('='.repeat(80));
    const all = await BusinessInfo.find();
    console.log(`Total: ${all.length}\n`);
    all.forEach((doc, i) => {
      console.log(`${i + 1}. ${doc.organizationName || 'Unnamed'}`);
      console.log(`   _id: ${doc._id}`);
      console.log(`   memberId: ${doc.memberId} (type: ${typeof doc.memberId})`);
      console.log(`   mobile: ${doc.mobile}`);
      console.log(`   email: ${doc.email}`);
      console.log('');
    });

    await mongoose.disconnect();
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

checkBusinessInfo();
