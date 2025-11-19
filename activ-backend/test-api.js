const http = require('http');

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/browse-members?page=1&limit=10',
  method: 'GET',
  headers: {
    'Content-Type': 'application/json'
  }
};

console.log('🔍 Testing Browse Members API...\n');

const req = http.request(options, (res) => {
  let data = '';

  res.on('data', (chunk) => {
    data += chunk;
  });

  res.on('end', () => {
    console.log(`Status Code: ${res.statusCode}\n`);
    
    try {
      const jsonData = JSON.parse(data);
      console.log('✅ API Response:');
      console.log(`   Success: ${jsonData.success}`);
      console.log(`   Total Members: ${jsonData.data?.length || 0}\n`);
      
      if (jsonData.data && jsonData.data.length > 0) {
        console.log('📋 Members List:');
        jsonData.data.forEach((member, index) => {
          console.log(`\n   ${index + 1}. ${member.name}`);
          console.log(`      Email: ${member.email}`);
          console.log(`      Organization: ${member.organization}`);
          console.log(`      Location: ${member.location?.block || 'N/A'}`);
          console.log(`      Approval: ${member.approvalStatus}`);
          console.log(`      Payment: ${member.paymentStatus}`);
        });
      } else {
        console.log('⚠️  No members found');
      }
    } catch (e) {
      console.log('❌ Error parsing JSON:');
      console.log(data);
    }
  });
});

req.on('error', (error) => {
  console.error('❌ Error:', error.message);
});

req.end();
