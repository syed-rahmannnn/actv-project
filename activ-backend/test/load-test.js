/**
 * Load Testing Script for ACTV Project APIs
 * Tests concurrent requests and measures performance
 */

const axios = require('axios');

const BASE_URL = process.env.API_URL || 'http://localhost:3000/api';
const TEST_MEMBER_ID = '674d1234567890abcdef1234'; // Replace with valid test ID

// Test configuration
const LOAD_TESTS = [{
        name: 'Login API',
        method: 'POST',
        url: `${BASE_URL}/auth/login`,
        data: {
            email: 'sairam12@gmail.com',
            password: 'sairam123'
        },
        concurrent: 10
    },
    {
        name: 'Get Companies',
        method: 'GET',
        url: `${BASE_URL}/companies?memberId=${TEST_MEMBER_ID}`,
        concurrent: 20
    },
    {
        name: 'Discover Companies',
        method: 'GET',
        url: `${BASE_URL}/discover/companies?memberId=${TEST_MEMBER_ID}&query=company&page=1&limit=20`,
        concurrent: 15
    },
    {
        name: 'Get Products',
        method: 'GET',
        url: `${BASE_URL}/products?companyId=674e1234567890abcdef5678`,
        concurrent: 20
    },
    {
        name: 'Discover Products',
        method: 'GET',
        url: `${BASE_URL}/discover/products?memberId=${TEST_MEMBER_ID}&query=product&page=1&limit=20`,
        concurrent: 15
    }
];

/**
 * Perform single API request and measure time
 */
async function makeRequest(config) {
    const start = Date.now();

    try {
        const response = await axios({
            method: config.method,
            url: config.url,
            data: config.data,
            timeout: 10000,
            headers: {
                'Content-Type': 'application/json'
            }
        });

        const duration = Date.now() - start;

        return {
            success: true,
            duration,
            status: response.status,
            size: JSON.stringify(response.data).length
        };
    } catch (error) {
        const duration = Date.now() - start;

        return {
            success: false,
            duration,
            status: error.response ? .status || 500,
            error: error.message
        };
    }
}

/**
 * Run load test for specific endpoint
 */
async function runLoadTest(testConfig) {
    console.log(`\n${'='.repeat(80)}`);
    console.log(`🧪 Testing: ${testConfig.name}`);
    console.log(`   URL: ${testConfig.url}`);
    console.log(`   Concurrent Requests: ${testConfig.concurrent}`);
    console.log('='.repeat(80));

    const requests = Array(testConfig.concurrent).fill().map(() =>
        makeRequest(testConfig)
    );

    const startTime = Date.now();
    const results = await Promise.all(requests);
    const totalTime = Date.now() - startTime;

    // Calculate statistics
    const successful = results.filter(r => r.success).length;
    const failed = results.filter(r => !r.success).length;
    const durations = results.map(r => r.duration);
    const avgDuration = durations.reduce((a, b) => a + b, 0) / durations.length;
    const minDuration = Math.min(...durations);
    const maxDuration = Math.max(...durations);
    const requestsPerSecond = (testConfig.concurrent / (totalTime / 1000)).toFixed(2);

    // Print results
    console.log('\n📊 Results:');
    console.log(`   Total Requests: ${testConfig.concurrent}`);
    console.log(`   ✅ Successful: ${successful}`);
    console.log(`   ❌ Failed: ${failed}`);
    console.log(`   ⏱️  Total Time: ${totalTime}ms`);
    console.log(`   📈 Requests/Second: ${requestsPerSecond}`);
    console.log(`   ⚡ Avg Response Time: ${avgDuration.toFixed(2)}ms`);
    console.log(`   🏃 Fastest: ${minDuration}ms`);
    console.log(`   🐌 Slowest: ${maxDuration}ms`);

    // Performance assessment
    if (avgDuration < 200) {
        console.log('   🎯 Performance: EXCELLENT');
    } else if (avgDuration < 500) {
        console.log('   ✅ Performance: GOOD');
    } else if (avgDuration < 1000) {
        console.log('   ⚠️  Performance: MODERATE');
    } else {
        console.log('   🔴 Performance: NEEDS OPTIMIZATION');
    }

    return {
        name: testConfig.name,
        successful,
        failed,
        totalTime,
        avgDuration,
        requestsPerSecond
    };
}

/**
 * Run all load tests
 */
async function runAllTests() {
    console.log('\n' + '🚀'.repeat(40));
    console.log('ACTV PROJECT - API LOAD TESTING');
    console.log('🚀'.repeat(40));
    console.log(`\nBase URL: ${BASE_URL}`);
    console.log(`Test Started: ${new Date().toISOString()}\n`);

    const allResults = [];

    for (const test of LOAD_TESTS) {
        const result = await runLoadTest(test);
        allResults.push(result);

        // Wait 2 seconds between tests
        await new Promise(resolve => setTimeout(resolve, 2000));
    }

    // Summary
    console.log('\n' + '='.repeat(80));
    console.log('📋 SUMMARY');
    console.log('='.repeat(80));

    allResults.forEach(result => {
        console.log(`\n${result.name}:`);
        console.log(`   Success Rate: ${((result.successful / (result.successful + result.failed)) * 100).toFixed(2)}%`);
        console.log(`   Avg Response: ${result.avgDuration.toFixed(2)}ms`);
        console.log(`   Throughput: ${result.requestsPerSecond} req/s`);
    });

    console.log('\n' + '='.repeat(80));
    console.log(`Test Completed: ${new Date().toISOString()}`);
    console.log('='.repeat(80) + '\n');
}

// Run tests if called directly
if (require.main === module) {
    runAllTests()
        .then(() => {
            console.log('✅ All tests completed');
            process.exit(0);
        })
        .catch(error => {
            console.error('❌ Test failed:', error);
            process.exit(1);
        });
}

module.exports = { runLoadTest, runAllTests };