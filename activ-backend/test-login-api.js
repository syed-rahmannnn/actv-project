const axios = require('axios');

async function testLogin() {
    try {
        console.log('🧪 Testing login API endpoint...');
        console.log('URL: http://localhost:3000/api/auth/login');
        console.log('Email: sairam12@gmail.com');
        console.log('Password: sairam123\n');

        const response = await axios.post('http://localhost:3000/api/auth/login', {
            email: 'sairam12@gmail.com',
            password: 'sairam123'
        }, {
            headers: {
                'Content-Type': 'application/json'
            },
            validateStatus: () => true // Don't throw on any status code
        });

        console.log('📊 Response Status:', response.status);
        console.log('📋 Response Data:', JSON.stringify(response.data, null, 2));

        if (response.status === 200) {
            console.log('\n✅ LOGIN SUCCESSFUL!');
            console.log('Token:', response.data.data ? .token ? .substring(0, 20) + '...');
            console.log('Member ID:', response.data.data ? .member ? .id);
        } else {
            console.log('\n❌ LOGIN FAILED!');
            console.log('Error Message:', response.data.message);
        }

    } catch (error) {
        console.error('❌ Error making request:', error.message);
        if (error.response) {
            console.error('Response status:', error.response.status);
            console.error('Response data:', error.response.data);
        } else if (error.request) {
            console.error('No response received');
        }
    }
}

testLogin();