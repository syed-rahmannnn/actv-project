require('dotenv').config({ path: './config.env' });
const http = require('http');

const baseUrl = 'http://localhost:3000/api';
const memberId = '692e685ce47750d07c018b50';

function makeRequest(path) {
  return new Promise((resolve, reject) => {
    const url = `${baseUrl}${path}`;
    console.log(`\n🌐 Testing: GET ${url}\n`);
    
    http.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        try {
          const json = JSON.parse(data);
          resolve({ status: res.statusCode, data: json });
        } catch (e) {
          resolve({ status: res.statusCode, data });
        }
      });
    }).on('error', reject);
  });
}

async function testAPIs() {
  console.log('='.repeat(80));
  console.log('🧪 TESTING BACKEND APIs');
  console.log('='.repeat(80));
  console.log(`Member ID: ${memberId}\n`);

  try {
    // Test 1: Get companies
    console.log('1️⃣ TEST: Get Companies');
    console.log('-'.repeat(80));
    const companiesResult = await makeRequest(`/companies?memberId=${memberId}`);
    console.log(`Status: ${companiesResult.status}`);
    if (companiesResult.data.success) {
      console.log(`✅ Found ${companiesResult.data.count} companies:`);
      companiesResult.data.data.forEach((c, i) => {
        console.log(`   ${i + 1}. ${c.name}`);
      });
    } else {
      console.log(`❌ Error: ${companiesResult.data.message}`);
    }

    // Test 2: Get business info
    console.log('\n2️⃣ TEST: Get Business Info');
    console.log('-'.repeat(80));
    const businessResult = await makeRequest(`/profile/business-info/${memberId}`);
    console.log(`Status: ${businessResult.status}`);
    if (businessResult.data.success) {
      const info = businessResult.data.data.businessInfo;
      console.log(`✅ Business Info Found:`);
      console.log(`   Organization Name: ${info.organizationName}`);
      console.log(`   Mobile: ${info.mobile}`);
      console.log(`   Business Type: ${info.businessType}`);
      console.log(`   Email: ${info.email}`);
    } else {
      console.log(`❌ Error: ${businessResult.data.message}`);
    }

    // Test 3: Get complete profile
    console.log('\n3️⃣ TEST: Get Complete Profile');
    console.log('-'.repeat(80));
    const profileResult = await makeRequest(`/profile/${memberId}`);
    console.log(`Status: ${profileResult.status}`);
    if (profileResult.data.success) {
      const { member, businessInfo } = profileResult.data.data;
      console.log(`✅ Profile Found:`);
      console.log(`   Member: ${member.fullName} (${member.email})`);
      if (businessInfo) {
        console.log(`   Business: ${businessInfo.organizationName}`);
        console.log(`   Mobile: ${businessInfo.mobile}`);
      } else {
        console.log(`   Business Info: Not found`);
      }
    } else {
      console.log(`❌ Error: ${profileResult.data.message}`);
    }

    console.log('\n' + '='.repeat(80));
    console.log('✅ ALL TESTS COMPLETED');
    console.log('='.repeat(80));

  } catch (error) {
    console.error('\n❌ Test Error:', error.message);
  }
}

testAPIs();
