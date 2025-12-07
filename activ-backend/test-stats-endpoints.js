const http = require('http');
require('dotenv').config({ path: './config.env' });

const baseUrl = 'localhost:3000';

function makeRequest(path) {
  return new Promise((resolve, reject) => {
    const options = {
      hostname: 'localhost',
      port: 3000,
      path: `/api${path}`,
      method: 'GET',
      headers: { 'Content-Type': 'application/json' }
    };
    
    const req = http.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    });
    
    req.on('error', reject);
    req.end();
  });
}

async function testBlockStats() {
  console.log('\n=== TESTING BLOCK ADMIN STATS ===');
  
  const blockAdminId = '690bf0eae63e1da8e4b0ad06';
  
  try {
    console.log('\n1. Fetching Block Pending Applications...');
    const pendingRes = await makeRequest(`/applications/block/${blockAdminId}`);
    const pendingCount = Array.isArray(pendingRes) ? pendingRes.length : 0;
    console.log(`   Pending count: ${pendingCount}`);
    
    console.log('\n2. Fetching Block Approved Applications...');
    const approvedRes = await makeRequest(`/applications/list-by-admin/${blockAdminId}?role=block&status=Approved`);
    const approvedCount = Array.isArray(approvedRes) ? approvedRes.length : 0;
    console.log(`   Approved count: ${approvedCount}`);
    
    console.log('\n3. Fetching Block Rejected Applications...');
    const rejectedRes = await makeRequest(`/applications/list-by-admin/${blockAdminId}?role=block&status=Rejected`);
    const rejectedCount = Array.isArray(rejectedRes) ? rejectedRes.length : 0;
    console.log(`   Rejected count: ${rejectedCount}`);
    
    const total = pendingCount + approvedCount + rejectedCount;
    console.log(`\n✅ Block Stats: Pending=${pendingCount}, Approved=${approvedCount}, Rejected=${rejectedCount}, Total=${total}`);
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

async function testDistrictStats() {
  console.log('\n=== TESTING DISTRICT ADMIN STATS ===');
  
  const districtAdminId = '6900c05f611665a07022c860';
  
  try {
    console.log('\n1. Fetching District Pending Applications...');
    const pendingRes = await makeRequest(`/applications/district/${districtAdminId}`);
    const pendingCount = Array.isArray(pendingRes) ? pendingRes.length : 0;
    console.log(`   Pending count: ${pendingCount}`);
    
    console.log('\n2. Fetching District Approved Applications...');
    const approvedRes = await makeRequest(`/applications/list-by-admin/${districtAdminId}?role=district&status=Approved`);
    const approvedCount = Array.isArray(approvedRes) ? approvedRes.length : 0;
    console.log(`   Approved count: ${approvedCount}`);
    
    console.log('\n3. Fetching District Rejected Applications...');
    const rejectedRes = await makeRequest(`/applications/list-by-admin/${districtAdminId}?role=district&status=Rejected`);
    const rejectedCount = Array.isArray(rejectedRes) ? rejectedRes.length : 0;
    console.log(`   Rejected count: ${rejectedCount}`);
    
    const total = pendingCount + approvedCount + rejectedCount;
    console.log(`\n✅ District Stats: Pending=${pendingCount}, Approved=${approvedCount}, Rejected=${rejectedCount}, Total=${total}`);
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

async function testStateStats() {
  console.log('\n=== TESTING STATE ADMIN STATS ===');
  
  const stateAdminId = '690dbcf90f6b10d8f7dc0e1e';
  
  try {
    console.log('\n1. Fetching State Pending Applications...');
    const pendingRes = await makeRequest(`/applications/state/${stateAdminId}`);
    const pendingCount = Array.isArray(pendingRes) ? pendingRes.length : 0;
    console.log(`   Pending count: ${pendingCount}`);
    
    console.log('\n2. Fetching State Approved Applications...');
    const approvedRes = await makeRequest(`/applications/list-by-admin/${stateAdminId}?role=state&status=Approved`);
    const approvedCount = Array.isArray(approvedRes) ? approvedRes.length : 0;
    console.log(`   Approved count: ${approvedCount}`);
    
    console.log('\n3. Fetching State Rejected Applications...');
    const rejectedRes = await makeRequest(`/applications/list-by-admin/${stateAdminId}?role=state&status=Rejected`);
    const rejectedCount = Array.isArray(rejectedRes) ? rejectedRes.length : 0;
    console.log(`   Rejected count: ${rejectedCount}`);
    
    const total = pendingCount + approvedCount + rejectedCount;
    console.log(`\n✅ State Stats: Pending=${pendingCount}, Approved=${approvedCount}, Rejected=${rejectedCount}, Total=${total}`);
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
}

async function main() {
  console.log('🚀 Testing Admin Statistics Endpoints...\n');
  
  await testBlockStats();
  await testDistrictStats();
  await testStateStats();
  
  console.log('\n✅ All tests completed!');
  process.exit(0);
}

main();
