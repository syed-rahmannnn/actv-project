const mongoose = require('mongoose');
require('dotenv').config({ path: './config.env' });

// MongoDB connection
const mongoURI = process.env.MONGODB_URI;

mongoose.connect(mongoURI)
  .then(() => console.log('✅ Connected to MongoDB'))
  .catch(err => {
    console.error('❌ MongoDB connection error:', err);
    process.exit(1);
  });

// Load models
const MemberDetails = require('../models/MemberDetails');
const MemberBusinessInfo = require('../models/MemberBusinessInfo');

async function checkApprovedMembers() {
  try {
    console.log('\n🔍 === CHECKING DATABASE FOR APPROVED & PAID MEMBERS ===\n');
    
    // Count all members
    const totalMembers = await MemberDetails.countDocuments({});
    console.log(`📊 Total members in database: ${totalMembers}`);
    
    // Count members with approvedBy set
    const approvedCount = await MemberDetails.countDocuments({
      approvedBy: { $ne: null }
    });
    console.log(`✅ Members with approvedBy != null: ${approvedCount}`);
    
    // Count members with active membership
    const activeCount = await MemberDetails.countDocuments({
      membershipStatus: 'active'
    });
    console.log(`💳 Members with membershipStatus = 'active': ${activeCount}`);
    
    // Count members with completed profile
    const completedProfileCount = await MemberDetails.countDocuments({
      profileCompleted: true
    });
    console.log(`📋 Members with profileCompleted = true: ${completedProfileCount}`);
    
    // Count members matching ALL criteria (approved + paid + completed)
    const query = {
      approvedBy: { $ne: null },
      membershipStatus: 'active',
      profileCompleted: true
    };
    
    console.log('\n🎯 Checking members matching ALL criteria:');
    console.log(JSON.stringify(query, null, 2));
    
    const qualifyingMembers = await MemberDetails.find(query)
      .select('fullName email phoneNumber approvedBy membershipStatus profileCompleted paymentId createdAt')
      .limit(10);
    
    console.log(`\n✅ Found ${qualifyingMembers.length} members meeting ALL criteria:\n`);
    
    if (qualifyingMembers.length === 0) {
      console.log('⚠️  NO MEMBERS FOUND! This explains why Browse Members shows empty.\n');
      console.log('Possible reasons:');
      console.log('1. No members have been approved yet (approvedBy is null)');
      console.log('2. No members have completed payment (membershipStatus != "active")');
      console.log('3. No members have completed their profile (profileCompleted != true)\n');
      
      // Show sample of what's in database
      console.log('📄 Sample of members in database (showing issues):\n');
      const sampleMembers = await MemberDetails.find({})
        .select('fullName email approvedBy membershipStatus profileCompleted')
        .limit(5);
      
      sampleMembers.forEach(m => {
        console.log(`   ${m.fullName}:`);
        console.log(`      - approvedBy: ${m.approvedBy || 'NULL ❌'}`);
        console.log(`      - membershipStatus: ${m.membershipStatus || 'NULL ❌'}`);
        console.log(`      - profileCompleted: ${m.profileCompleted ? 'true ✅' : 'false ❌'}\n`);
      });
      
    } else {
      // Show qualifying members
      for (const member of qualifyingMembers) {
        console.log(`✅ ${member.fullName}`);
        console.log(`   Email: ${member.email}`);
        console.log(`   Phone: ${member.phoneNumber}`);
        console.log(`   Approved By: ${member.approvedBy}`);
        console.log(`   Membership Status: ${member.membershipStatus}`);
        console.log(`   Profile Completed: ${member.profileCompleted}`);
        console.log(`   Payment ID: ${member.paymentId || 'N/A'}`);
        console.log(`   Created: ${member.createdAt}\n`);
      }
      
      // Get business info for these members
      const emails = qualifyingMembers.map(m => m.email);
      const businessInfos = await MemberBusinessInfo.find({
        email: { $in: emails }
      }).select('email organizationName');
      
      console.log('🏢 Business Information:');
      businessInfos.forEach(bi => {
        console.log(`   ${bi.email}: ${bi.organizationName}`);
      });
    }
    
    console.log('\n' + '='.repeat(70));
    console.log('✅ Database check complete!');
    console.log('='.repeat(70) + '\n');
    
  } catch (error) {
    console.error('❌ Error checking members:', error);
  } finally {
    mongoose.connection.close();
    process.exit(0);
  }
}

checkApprovedMembers();
