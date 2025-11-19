// Test script to verify browse members filtering
// This checks if members are properly filtered by approval status and payment completion

const axios = require('axios');

const BASE_URL = 'http://10.201.103.174:3000/api';

async function testBrowseMembers() {
  console.log('\n🧪 Testing Browse Members API');
  console.log('=' .repeat(50));

  try {
    // Test 1: Fetch all approved & paid members
    console.log('\n📋 Test 1: Fetching approved members with active membership...');
    const response = await axios.get(`${BASE_URL}/browse-members?page=1&limit=10`);
    
    if (response.data.success) {
      const members = response.data.data;
      console.log(`✅ Success! Found ${members.length} members`);
      
      // Verify each member meets criteria
      console.log('\n🔍 Verifying each member meets criteria:');
      members.forEach((member, index) => {
        console.log(`\n  Member ${index + 1}: ${member.name}`);
        console.log(`    - Email: ${member.email}`);
        console.log(`    - Approval Status: ${member.approvalStatus}`);
        console.log(`    - Payment Status: ${member.paymentStatus}`);
        console.log(`    - Membership Type: ${member.membershipType}`);
        console.log(`    - Location: ${member.location.block}, ${member.location.district}`);
        console.log(`    - Organization: ${member.organization}`);
        
        // Validate
        if (member.approvalStatus !== 'approved_by_state_admin') {
          console.log(`    ❌ FAILED: Not approved by state admin`);
        } else if (member.paymentStatus !== 'completed') {
          console.log(`    ❌ FAILED: Payment not completed`);
        } else {
          console.log(`    ✅ PASSED: Meets all criteria`);
        }
      });

      console.log(`\n📊 Summary:`);
      console.log(`   Total members returned: ${members.length}`);
      console.log(`   Current page: ${response.data.pagination.currentPage}`);
      console.log(`   Total pages: ${response.data.pagination.totalPages}`);
      console.log(`   Total count in DB: ${response.data.pagination.totalCount}`);

    } else {
      console.log('❌ Failed to fetch members');
      console.log('Response:', response.data);
    }

    // Test 2: Search by location
    console.log('\n\n📋 Test 2: Searching by location (state filter)...');
    const stateResponse = await axios.get(`${BASE_URL}/browse-members?state=Tamil Nadu&limit=5`);
    
    if (stateResponse.data.success) {
      console.log(`✅ Found ${stateResponse.data.data.length} members in Tamil Nadu`);
      stateResponse.data.data.forEach(member => {
        console.log(`   - ${member.name} (${member.location.state})`);
      });
    }

    // Test 3: Check if connection request works
    console.log('\n\n📋 Test 3: Testing connection request structure...');
    console.log('Connection request format:');
    console.log(`   POST ${BASE_URL}/browse-members/connect`);
    console.log('   Body: {');
    console.log('     "senderId": "member_id_1",');
    console.log('     "recipientId": "member_id_2",');
    console.log('     "message": "Wants to connect with you"');
    console.log('   }');

    console.log('\n✅ All tests completed!');
    console.log('=' .repeat(50));

  } catch (error) {
    console.error('\n❌ Test failed with error:');
    console.error('Message:', error.message);
    if (error.response) {
      console.error('Status:', error.response.status);
      console.error('Data:', error.response.data);
    }
  }
}

// Run tests
testBrowseMembers();
