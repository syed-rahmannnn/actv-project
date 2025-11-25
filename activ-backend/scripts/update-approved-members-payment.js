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

// Load model
const MemberDetails = require('../models/MemberDetails');

async function updateApprovedMembersPaymentStatus() {
  try {
    console.log('\n🔄 === UPDATING APPROVED MEMBERS PAYMENT STATUS ===\n');
    
    // Find members who are approved but don't have active membership
    const approvedMembers = await MemberDetails.find({
      approvedBy: { $ne: null },
      membershipStatus: { $ne: 'active' }
    }).select('fullName email approvedBy membershipStatus profileCompleted');
    
    console.log(`📊 Found ${approvedMembers.length} approved members with pending payment status:\n`);
    
    if (approvedMembers.length === 0) {
      console.log('✅ All approved members already have active membership status!');
      mongoose.connection.close();
      process.exit(0);
      return;
    }
    
    // Show members that will be updated
    approvedMembers.forEach(m => {
      console.log(`   - ${m.fullName} (${m.email})`);
      console.log(`     Current status: ${m.membershipStatus} → Will change to: active\n`);
    });
    
    console.log('\n🔄 Updating membershipStatus to "active" for approved members...\n');
    
    // Update all approved members to have active membership
    const result = await MemberDetails.updateMany(
      {
        approvedBy: { $ne: null },
        membershipStatus: { $ne: 'active' }
      },
      {
        $set: {
          membershipStatus: 'active',
          paymentStatus: 'completed'
        }
      }
    );
    
    console.log(`✅ Successfully updated ${result.modifiedCount} members!`);
    console.log(`   - membershipStatus set to "active"`);
    console.log(`   - paymentStatus set to "completed"\n`);
    
    // Verify the update
    console.log('🔍 Verifying update...\n');
    const verifyQuery = {
      approvedBy: { $ne: null },
      membershipStatus: 'active',
      profileCompleted: true
    };
    
    const qualifyingMembers = await MemberDetails.find(verifyQuery)
      .select('fullName email approvedBy membershipStatus profileCompleted');
    
    console.log(`✅ Now ${qualifyingMembers.length} members will appear in Browse Members:\n`);
    
    qualifyingMembers.forEach(m => {
      console.log(`   ✅ ${m.fullName}`);
      console.log(`      - Approved by: ${m.approvedBy}`);
      console.log(`      - Membership: ${m.membershipStatus}`);
      console.log(`      - Profile: ${m.profileCompleted ? 'Completed ✅' : 'Incomplete ❌'}\n`);
    });
    
    console.log('='.repeat(70));
    console.log('✅ Payment status update complete!');
    console.log('📱 Refresh your Browse Members screen to see the members.');
    console.log('='.repeat(70) + '\n');
    
  } catch (error) {
    console.error('❌ Error updating members:', error);
  } finally {
    mongoose.connection.close();
    process.exit(0);
  }
}

updateApprovedMembersPaymentStatus();
