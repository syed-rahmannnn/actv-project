const mongoose = require('mongoose');
require('dotenv').config({ path: './config.env' });

const Activity = require('./models/Activity');
const MemberBusinessInfo = require('./models/MemberBusinessInfo');
const Product = require('./models/Product');

/**
 * ULTRA-FAST Performance Test
 * Tests all optimizations applied for sub-200ms queries
 */

async function testUltraFastQueries() {
    try {
        console.log('🚀 Connecting to MongoDB Atlas (ULTRA-OPTIMIZED)...');

        const startConnect = Date.now();
        await mongoose.connect(process.env.MONGODB_URI, {
            maxPoolSize: 100,
            minPoolSize: 20,
            serverSelectionTimeoutMS: 10000,
            socketTimeoutMS: 30000,
            family: 4,
            maxIdleTimeMS: 60000,
            retryWrites: true,
            w: 1,
            autoIndex: false,
            connectTimeoutMS: 10000,
            heartbeatFrequencyMS: 5000,
            compressors: ['zlib']
        });
        const connectTime = Date.now() - startConnect;
        console.log(`✅ Connected in ${connectTime}ms\n`);

        const db = mongoose.connection.db;

        // Get sample IDs
        const sampleCompany = await db.collection('companies').findOne({});
        const sampleMember = await db.collection('memberbusinessinfos').findOne({});

        if (!sampleCompany || !sampleMember) {
            console.log('⚠️  No test data found.');
            return;
        }

        const companyId = sampleCompany._id;
        const memberId = sampleMember.memberId;

        console.log('⚡ Running ULTRA-FAST performance tests...\n');

        // Warm up connections (first query is always slower)
        await Activity.findOne({ companyId }).lean();
        console.log('🔥 Connection pool warmed up\n');

        // =====================================================
        // TEST 1: Activities Query (Target: <100ms)
        // =====================================================
        console.log('Test 1: GET /dashboard/activities (ULTRA-OPTIMIZED)');

        const runs1 = [];
        for (let i = 0; i < 5; i++) {
            const start = Date.now();
            const activities = await Activity.find({ companyId })
                .select('activityType entityName description createdAt')
                .sort({ createdAt: -1 })
                .limit(10)
                .lean()
                .maxTimeMS(300)
                .exec();
            const duration = Date.now() - start;
            runs1.push(duration);
            console.log(`   Run ${i + 1}: ${duration}ms (${activities.length} activities)`);
        }
        const avg1 = Math.round(runs1.reduce((a, b) => a + b) / runs1.length);
        const min1 = Math.min(...runs1);
        const max1 = Math.max(...runs1);
        console.log(`   📊 Average: ${avg1}ms | Min: ${min1}ms | Max: ${max1}ms`);
        console.log(`   ${avg1 < 100 ? '🎉 EXCELLENT!' : avg1 < 200 ? '✅ GOOD' : '⚠️  NEEDS WORK'} (Target: <100ms, Was: 11,214ms)\n`);

        // =====================================================
        // TEST 2: Business Info Query (Target: <200ms)
        // =====================================================
        console.log('Test 2: GET /profile/business-info (ULTRA-OPTIMIZED)');

        const runs2 = [];
        for (let i = 0; i < 5; i++) {
            const start = Date.now();
            const businessInfo = await MemberBusinessInfo.findOne({ memberId })
                .select('organizationName mobile industry area location status')
                .lean()
                .maxTimeMS(1000)
                .exec();
            const duration = Date.now() - start;
            runs2.push(duration);
            console.log(`   Run ${i + 1}: ${duration}ms`);
        }
        const avg2 = Math.round(runs2.reduce((a, b) => a + b) / runs2.length);
        const min2 = Math.min(...runs2);
        const max2 = Math.max(...runs2);
        console.log(`   📊 Average: ${avg2}ms | Min: ${min2}ms | Max: ${max2}ms`);
        console.log(`   ${avg2 < 200 ? '🎉 EXCELLENT!' : avg2 < 300 ? '✅ GOOD' : '⚠️  NEEDS WORK'} (Target: <200ms, Was: 2,934ms)\n`);

        // =====================================================
        // TEST 3: Product Count (Target: <50ms)
        // =====================================================
        console.log('Test 3: GET /dashboard/stats (productsCount)');

        const runs3 = [];
        for (let i = 0; i < 5; i++) {
            const start = Date.now();
            const count = await Product.countDocuments({ companyId }).maxTimeMS(300);
            const duration = Date.now() - start;
            runs3.push(duration);
            console.log(`   Run ${i + 1}: ${duration}ms (${count} products)`);
        }
        const avg3 = Math.round(runs3.reduce((a, b) => a + b) / runs3.length);
        const min3 = Math.min(...runs3);
        const max3 = Math.max(...runs3);
        console.log(`   📊 Average: ${avg3}ms | Min: ${min3}ms | Max: ${max3}ms`);
        console.log(`   ${avg3 < 50 ? '🎉 EXCELLENT!' : avg3 < 100 ? '✅ GOOD' : '⚠️  NEEDS WORK'} (Target: <50ms)\n`);

        // =====================================================
        // TEST 4: Parallel Query Test (Real Dashboard Load)
        // =====================================================
        console.log('Test 4: FULL DASHBOARD LOAD (Parallel Queries)');

        const runs4 = [];
        for (let i = 0; i < 5; i++) {
            const start = Date.now();
            await Promise.all([
                Activity.find({ companyId })
                .select('activityType entityName description createdAt')
                .sort({ createdAt: -1 })
                .limit(10)
                .lean()
                .maxTimeMS(300)
                .exec(),
                MemberBusinessInfo.findOne({ memberId })
                .select('organizationName mobile industry area location status')
                .lean()
                .maxTimeMS(1000)
                .exec(),
                Product.countDocuments({ companyId }).maxTimeMS(300)
            ]);
            const duration = Date.now() - start;
            runs4.push(duration);
            console.log(`   Run ${i + 1}: ${duration}ms (all 3 queries in parallel)`);
        }
        const avg4 = Math.round(runs4.reduce((a, b) => a + b) / runs4.length);
        const min4 = Math.min(...runs4);
        const max4 = Math.max(...runs4);
        console.log(`   📊 Average: ${avg4}ms | Min: ${min4}ms | Max: ${max4}ms`);
        console.log(`   ${avg4 < 300 ? '🎉 EXCELLENT!' : avg4 < 500 ? '✅ GOOD' : '⚠️  NEEDS WORK'} (Target: <300ms, Was: ~17,000ms)\n`);

        // =====================================================
        // FINAL SUMMARY
        // =====================================================
        console.log('\n═══════════════════════════════════════════════════════════');
        console.log('📊 ULTRA-FAST Performance Summary:');
        console.log('═══════════════════════════════════════════════════════════');
        console.log(`Activities (avg):         ${avg1}ms ⚡ (was 11,214ms)`);
        console.log(`Business Info (avg):      ${avg2}ms ⚡ (was 2,934ms)`);
        console.log(`Products Count (avg):     ${avg3}ms ⚡`);
        console.log(`Full Dashboard (avg):     ${avg4}ms ⚡ (was ~17,000ms)`);
        console.log('═══════════════════════════════════════════════════════════');

        const totalBefore = 11214 + 2934 + 63; // ~14,211ms
        const totalAfter = avg1 + avg2 + avg3;
        const improvement = ((totalBefore - totalAfter) / totalBefore * 100).toFixed(1);
        const speedup = (totalBefore / totalAfter).toFixed(1);

        console.log(`\nTotal Average: ${totalAfter}ms (was ${totalBefore}ms)`);
        console.log(`Improvement: ${improvement}% faster! 🚀`);
        console.log(`Speed Multiplier: ${speedup}x faster! ⚡\n`);

        // Final verdict
        if (avg4 < 300) {
            console.log('✅ PRODUCTION READY! Sub-300ms dashboard loads! 🎉\n');
        } else if (avg4 < 500) {
            console.log('✅ GOOD PERFORMANCE! Near production-ready.\n');
        } else {
            console.log('⚠️  STILL NEEDS OPTIMIZATION. Check MongoDB Atlas tier.\n');
        }

        // Performance grades
        console.log('Performance Grades:');
        console.log(`  Activities:     ${avg1 < 100 ? 'A+' : avg1 < 150 ? 'A' : avg1 < 200 ? 'B' : 'C'}`);
        console.log(`  Business Info:  ${avg2 < 200 ? 'A+' : avg2 < 300 ? 'A' : avg2 < 400 ? 'B' : 'C'}`);
        console.log(`  Products:       ${avg3 < 50 ? 'A+' : avg3 < 100 ? 'A' : avg3 < 150 ? 'B' : 'C'}`);
        console.log(`  Full Dashboard: ${avg4 < 300 ? 'A+' : avg4 < 400 ? 'A' : avg4 < 500 ? 'B' : 'C'}\n`);

    } catch (error) {
        console.error('❌ Error testing performance:', error);
    } finally {
        await mongoose.disconnect();
        console.log('🔌 Disconnected from MongoDB\n');
    }
}

// Run the ultra-fast test
testUltraFastQueries();