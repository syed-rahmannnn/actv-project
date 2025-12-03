const http = require('http');

const memberId = '692e685ce47750d07c018b50';
const url = `http://localhost:3000/api/companies?memberId=${memberId}`;

console.log(`Testing: ${url}\n`);

const req = http.get(url, (res) => {
  console.log(`Status Code: ${res.statusCode}`);
  console.log(`Headers:`, res.headers);
  
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    console.log(`\nResponse:\n${data}`);
  });
});

req.on('error', (e) => {
  console.error(`Error: ${e.message}`);
});

req.setTimeout(5000, () => {
  req.destroy();
  console.error('Request timeout after 5s');
});
