require('dotenv').config({ path: './config.env' });
const mongoose = require('mongoose');
const MemberAuth = require('./models/MemberAuth');
const MemberDetails = require('./models/MemberDetails');

async function checkLogin() {
    try {
        console.log('Connecting to MongoDB...');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Connected to MongoDB\n');

        const testEmail = 'sairam12@gmail.com';
        const testPassword = 'sairam123';

        console.log('='.repeat(80));
        console.log(`🔍 CHECKING LOGIN FOR: ${testEmail}`);
        console.log('='.repeat(80));

        // Check MemberDetails
        const member = await MemberDetails.findOne({ email: testEmail });
        if (!member) {
            console.log('❌ Member not found in memberdetails collection!');
            await mongoose.disconnect();
            return;
        }

        console.log('\n✅ Member found in memberdetails:');
        console.log('   _id:', member._id);
        console.log('   email:', member.email);
        console.log('   fullName:', member.fullName);
        console.log('   membershipStatus:', member.membershipStatus);
        console.log('   profileCompleted:', member.profileCompleted);

        // Check MemberAuth
        const memberAuth = await MemberAuth.findOne({ email: testEmail.toLowerCase() });
        if (!memberAuth) {
            console.log('\n❌ MemberAuth record not found!');
            console.log('   The user exists in memberdetails but NOT in memberauths collection.');
            console.log('   This means the account was never properly registered.');

            // Let's check all memberauths to see what exists
            const allAuths = await MemberAuth.find({});
            console.log(`\n📊 Total records in memberauths: ${allAuths.length}`);
            if (allAuths.length > 0) {
                console.log('\n   First few emails in memberauths:');
                allAuths.slice(0, 5).forEach((auth, idx) => {
                    console.log(`   ${idx + 1}. ${auth.email} (active: ${auth.isActive})`);
                });
            }

            await mongoose.disconnect();
            return;
        }

        console.log('\n✅ MemberAuth record found:');
        console.log('   _id:', memberAuth._id);
        console.log('   email:', memberAuth.email);
        console.log('   memberId:', memberAuth.memberId);
        console.log('   isActive:', memberAuth.isActive);
        console.log('   lastLogin:', memberAuth.lastLogin);
        console.log('   hashedPassword exists:', !!memberAuth.hashedPassword);
        console.log('   hashedPassword length:', memberAuth.hashedPassword ? .length || 0);

        // Test password verification
        console.log('\n🔐 Testing password verification...');
        const isPasswordValid = await memberAuth.comparePassword(testPassword);
        console.log('   Password match:', isPasswordValid ? '✅ YES' : '❌ NO');

        if (!isPasswordValid) {
            console.log('\n⚠️  PASSWORD VERIFICATION FAILED!');
            console.log('   Possible reasons:');
            console.log('   1. Password in database is different from "sairam123"');
            console.log('   2. Password was not properly hashed during registration');
            console.log('   3. The comparePassword method is not working correctly');
        }

        if (!memberAuth.isActive) {
            console.log('\n⚠️  ACCOUNT IS INACTIVE!');
            console.log('   The account exists but isActive is set to false');
        }

        await mongoose.disconnect();
        console.log('\n✅ Disconnected from MongoDB');

    } catch (error) {
        console.error('❌ Error:', error);
        await mongoose.disconnect();
    }
}

checkLogin();