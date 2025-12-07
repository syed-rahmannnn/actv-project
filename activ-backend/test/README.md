# Load Testing Guide for ACTV Backend APIs

This guide explains how to run load tests and interpret the results.

## Prerequisites

1. Install dependencies:
```bash
cd activ-backend
npm install
```

2. Ensure the server is running:
```bash
npm run dev
```

## Running Load Tests

### Quick Start
```bash
npm run load-test
```

### Custom Configuration

Edit `test/load-test.js` to modify:

```javascript
const BASE_URL = 'http://localhost:3000/api'; // Change to your API URL
const TEST_MEMBER_ID = '674d1234567890abcdef1234'; // Use valid test member ID
```

### Test Configuration

Each test can be configured with:
- `name`: Test description
- `method`: HTTP method (GET, POST, PUT, DELETE)
- `url`: Full endpoint URL
- `data`: Request body (for POST/PUT)
- `concurrent`: Number of simultaneous requests

Example:
```javascript
{
  name: 'Get Companies',
  method: 'GET',
  url: `${BASE_URL}/companies?memberId=${TEST_MEMBER_ID}`,
  concurrent: 20 // 20 simultaneous requests
}
```

## Interpreting Results

### Output Example

```
================================================================================
🧪 Testing: Get Companies
   URL: http://localhost:3000/api/companies?memberId=674d1234567890abcdef1234
   Concurrent Requests: 20
================================================================================

📊 Results:
   Total Requests: 20
   ✅ Successful: 20
   ❌ Failed: 0
   ⏱️  Total Time: 450ms
   📈 Requests/Second: 44.44
   ⚡ Avg Response Time: 42.50ms
   🏃 Fastest: 28ms
   🐌 Slowest: 78ms
   🎯 Performance: EXCELLENT
```

### Performance Ratings

| Rating | Avg Response Time | Status |
|--------|------------------|--------|
| 🎯 EXCELLENT | < 200ms | Optimal performance |
| ✅ GOOD | 200-500ms | Acceptable performance |
| ⚠️ MODERATE | 500-1000ms | Needs attention |
| 🔴 NEEDS OPTIMIZATION | > 1000ms | Action required |

## Key Metrics

### 1. Success Rate
- **Target**: 100%
- **Minimum acceptable**: 95%
- Lower rates indicate errors or timeout issues

### 2. Average Response Time
- **Excellent**: < 200ms
- **Good**: 200-500ms
- Affected by database queries, caching, and network

### 3. Requests/Second (Throughput)
- Higher is better
- Indicates how many requests the server can handle
- Typical good range: 40-100 req/s for standard APIs

### 4. Fastest/Slowest Response
- Shows performance consistency
- Large gap indicates:
  - Cache hits vs misses
  - Database query variations
  - Server load fluctuations

## Testing Different Scenarios

### 1. Light Load Test (Default)
```javascript
concurrent: 10-20 // Simulates normal usage
```

### 2. Medium Load Test
```javascript
concurrent: 50-100 // Simulates busy periods
```

### 3. Heavy Load Test
```javascript
concurrent: 200-500 // Simulates peak traffic
```

### 4. Stress Test
```javascript
concurrent: 1000+ // Tests breaking points
```

## Troubleshooting

### High Response Times

**Possible causes:**
- Database not optimized (missing indexes)
- Large data transfers
- No caching enabled
- Network latency

**Solutions:**
1. Check database indexes
2. Enable caching
3. Use field selection (lean queries)
4. Add pagination

### Low Success Rate

**Possible causes:**
- Rate limiting triggered
- Server timeout
- Database connection issues
- Invalid test data

**Solutions:**
1. Adjust rate limits in server.js
2. Increase timeout values
3. Check MongoDB connection
4. Verify test configuration

### Server Crashes

**Possible causes:**
- Memory leak
- Too many concurrent connections
- Unhandled errors

**Solutions:**
1. Check console for errors
2. Monitor memory usage
3. Add error handling
4. Reduce concurrent requests

## Best Practices

1. **Start Small**: Begin with 10 concurrent requests
2. **Gradually Increase**: Double the load each test
3. **Monitor Server**: Watch CPU, memory, and logs
4. **Test After Changes**: Run tests after each optimization
5. **Document Results**: Keep a log of improvements

## Advanced Testing

### Custom Endpoints

Add new tests to `LOAD_TESTS` array:

```javascript
{
  name: 'Custom Endpoint',
  method: 'POST',
  url: `${BASE_URL}/custom/endpoint`,
  data: {
    key: 'value'
  },
  concurrent: 15
}
```

### Environment Variables

Set different test environments:

```bash
# Test production
API_URL=https://actv-project.onrender.com/api npm run load-test

# Test local
API_URL=http://localhost:3000/api npm run load-test
```

## Benchmark Goals

### Target Performance (With Caching)

| Endpoint | Avg Response | Throughput |
|----------|--------------|------------|
| Login | < 150ms | 50+ req/s |
| Get Companies | < 50ms | 100+ req/s |
| Discover | < 100ms | 80+ req/s |
| Products | < 50ms | 100+ req/s |
| Analytics | < 200ms | 40+ req/s |

### Target Performance (No Cache)

| Endpoint | Avg Response | Throughput |
|----------|--------------|------------|
| Login | < 300ms | 30+ req/s |
| Get Companies | < 200ms | 50+ req/s |
| Discover | < 400ms | 30+ req/s |
| Products | < 200ms | 50+ req/s |
| Analytics | < 500ms | 20+ req/s |

## Continuous Monitoring

### Automated Testing

Add to CI/CD pipeline:

```yaml
# .github/workflows/load-test.yml
- name: Run Load Tests
  run: npm run load-test
```

### Scheduled Tests

Run tests periodically to catch performance degradation:

```bash
# Daily load test (cron)
0 2 * * * cd /path/to/activ-backend && npm run load-test >> logs/load-test.log
```

## Support

For issues or questions about load testing:
1. Check OPTIMIZATION_GUIDE.md
2. Review server logs
3. Monitor database performance
4. Contact development team

---

**Last Updated**: December 6, 2025
