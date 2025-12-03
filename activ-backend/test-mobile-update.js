require('dotenv').config({ path: './config.env' });
const mongoose = require('mongoose');
const MemberBusinessInfo = require('./models/MemberBusinessInfo');

async function testUpdate() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB\n');

    const memberId = new mongoose.Types.ObjectId('692e685ce47750d07c018b50');
    const testMobile = '9999888877';

    console.log('='.repeat(80));
    console.log('🧪 TEST: Update Mobile Number');
    console.log('='.repeat(80));
    console.log(`Member ID: ${memberId}`);
    console.log(`Test Mobile: ${testMobile}\n`);

    // Get current value
    console.log('1. BEFORE UPDATE:');
    const before = await MemberBusinessInfo.findOne({ memberId });
    if (before) {
      console.log(`   Mobile: ${before.mobile}`);
      console.log(`   Organization: ${before.organizationName}`);
    } else {
      console.log('   ❌ No business info found!');
      await mongoose.disconnect();
      return;
    }

    // Update
    console.log('\n2. UPDATING...');
    const updated = await MemberBusinessInfo.findOneAndUpdate(
      { memberId },
      { $set: { mobile: testMobile } },
      { new: true, runValidators: true }
    );

    console.log(`   Mobile after update: ${updated.mobile}`);

    // Verify
    console.log('\n3. VERIFY - Read again:');
    const after = await MemberBusinessInfo.findOne({ memberId });
    console.log(`   Mobile: ${after.mobile}`);
    
    if (after.mobile === testMobile) {
      console.log('\n✅ SUCCESS: Mobile updated and saved correctly!');
    } else {
      console.log('\n❌ FAILED: Mobile not saved correctly!');
    }

    // Restore original
    console.log('\n4. RESTORING original value...');
    await MemberBusinessInfo.findOneAndUpdate(
      { memberId },
      { $set: { mobile: before.mobile } }
    );
    console.log(`   Restored to: ${before.mobile}`);

    console.log('\n' + '='.repeat(80));
    await mongoose.disconnect();
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

testUpdate();
