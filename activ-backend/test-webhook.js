// Test script to verify webhook endpoint
// Run this with: node test-webhook.js

const http = require('http');

console.log('🧪 Testing Webhook Endpoint...\n');

// Test GET request
const getOptions = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/webhook/instamojo',
  method: 'GET'
};

console.log('1️⃣ Testing GET request...');
const getReq = http.request(getOptions, (res) => {
  let data = '';
  
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    console.log(`   Status: ${res.statusCode}`);
    console.log(`   Response: ${data}\n`);
    
    if (res.statusCode === 200) {
      console.log('✅ GET request successful!\n');
      testPost();
    } else {
      console.log('❌ GET request failed!\n');
    }
  });
});

getReq.on('error', (error) => {
  console.error('❌ Error:', error.message);
  console.log('\n💡 Is the server running? Start it with: node server.js\n');
});

getReq.end();

// Test POST request
function testPost() {
  const testData = JSON.stringify({
    payment_id: 'TEST123',
    payment_request_id: 'TEST456',
    status: 'Credit',
    amount: '500.00',
    buyer_email: 'test@example.com',
    buyer_name: 'Test User',
    buyer_phone: '9876543210',
    mac: 'test_mac_hash'
  });
  
  const postOptions = {
    hostname: 'localhost',
    port: 3000,
    path: '/api/webhook/instamojo',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(testData)
    }
  };
  
  console.log('2️⃣ Testing POST request...');
  const postReq = http.request(postOptions, (res) => {
    let data = '';
    
    res.on('data', (chunk) => {
      data += chunk;
    });
    
    res.on('end', () => {
      console.log(`   Status: ${res.statusCode}`);
      console.log(`   Response: ${data}\n`);
      
      if (res.statusCode === 200 || res.statusCode === 400) {
        // 400 is expected because signature verification will fail
        console.log('✅ POST request successful!');
        console.log('   Note: Signature verification failure is expected for test data\n');
        console.log('🎉 Webhook endpoint is correctly configured!\n');
        console.log('📝 Next steps:');
        console.log('   1. Start ngrok: ngrok http 3000');
        console.log('   2. Copy ngrok URL');
        console.log('   3. Add to Instamojo dashboard: https://your-url.ngrok.io/api/webhook/instamojo\n');
      } else {
        console.log('❌ POST request failed!\n');
      }
    });
  });
  
  postReq.on('error', (error) => {
    console.error('❌ Error:', error.message);
  });
  
  postReq.write(testData);
  postReq.end();
}
