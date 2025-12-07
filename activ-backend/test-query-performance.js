const mongoose = require('mongoose');
require('dotenv').config({ path: './config.env' });

const Activity = require('./models/Activity');
const MemberBusinessInfo = require('./models/MemberBusinessInfo');
const Product = require('./models/Product');

/**
 * Test query performance after index creation
 * This will show the dramatic improvement in query speeds
 */

async function testQueryPerformance() {
    try {
        console.log('🚀 Connecting to MongoDB Atlas...');
        await mongoose.connect(process.env.MONGODB_URI, {
            maxPoolSize: 10,
            serverSelectionTimeoutMS: 10000
        });
        console.log('✅ Connected\n');

        const db = mongoose.connection.db;

        // Get a sample companyId and memberId for testing
        const sampleCompany = await db.collection('companies').findOne({});
        const sampleMember = await db.collection('memberbusinessinfos').findOne({});

        if (!sampleCompany || !sampleMember) {
            console.log('⚠️  No test data found. Create some companies and members first.');
            return;
        }

        const companyId = sampleCompany._id;
        const memberId = sampleMember.memberId;

        console.log('📊 Running performance tests...\n');

        // =====================================================
        // TEST 1: Activities Query (was 11,214ms)
        // =====================================================
        console.log('Test 1: GET /dashboard/activities');
        console.log(`   Query: { companyId: "${companyId}" }`);

        const start1 = Date.now();
        const activities = await Activity.find({ companyId })
            .select('activityType entityName description createdAt')
            .sort({ createdAt: -1 })
            .limit(10)
            .lean()
            .maxTimeMS(5000);
        const duration1 = Date.now() - start1;

        console.log(`   ✅ Found ${activities.length} activities in ${duration1}ms`);
        if (duration1 < 100) {
            console.log(`   🎉 EXCELLENT! (Target: <50ms, Previously: 11,214ms)\n`);
        } else if (duration1 < 500) {
            console.log(`   ✅ GOOD! (Target: <50ms, Previously: 11,214ms)\n`);
        } else {
            console.log(`   ⚠️  Still slow (check if indexes are active)\n`);
        }

        // =====================================================
        // TEST 2: Business Info Query (was 2,934ms)
        // =====================================================
        console.log('Test 2: GET /profile/business-info');
        console.log(`   Query: { memberId: "${memberId}" }`);

        const start2 = Date.now();
        const businessInfo = await MemberBusinessInfo.findOne({ memberId })
            .select('memberId organizationName mobile industry area location status')
            .lean()
            .maxTimeMS(3000);
        const duration2 = Date.now() - start2;

        console.log(`   ✅ Found business info in ${duration2}ms`);
        if (duration2 < 100) {
            console.log(`   🎉 EXCELLENT! (Target: <100ms, Previously: 2,934ms)\n`);
        } else if (duration2 < 500) {
            console.log(`   ✅ GOOD! (Target: <100ms, Previously: 2,934ms)\n`);
        } else {
            console.log(`   ⚠️  Still slow (check if indexes are active)\n`);
        }

        // =====================================================
        // TEST 3: Product Count Query (part of stats - was 2,818ms)
        // =====================================================
        console.log('Test 3: GET /dashboard/stats (productsCount)');
        console.log(`   Query: { companyId: "${companyId}" }`);

        const start3 = Date.now();
        const productsCount = await Product.countDocuments({ companyId })
            .maxTimeMS(500);
        const duration3 = Date.now() - start3;

        console.log(`   ✅ Found ${productsCount} products in ${duration3}ms`);
        if (duration3 < 50) {
            console.log(`   🎉 EXCELLENT! (Target: <50ms)\n`);
        } else if (duration3 < 200) {
            console.log(`   ✅ GOOD! (Target: <50ms)\n`);
        } else {
            console.log(`   ⚠️  Still slow (check if indexes are active)\n`);
        }

        // =====================================================
        // TEST 4: Companies by Member (list view)
        // =====================================================
        console.log('Test 4: GET /companies (by memberId)');
        console.log(`   Query: { memberId: "${memberId}" }`);

        const start4 = Date.now();
        const companies = await db.collection('companies')
            .find({ memberId })
            .limit(10)
            .toArray();
        const duration4 = Date.now() - start4;

        console.log(`   ✅ Found ${companies.length} companies in ${duration4}ms`);
        if (duration4 < 50) {
            console.log(`   🎉 EXCELLENT! (Target: <50ms)\n`);
        } else if (duration4 < 200) {
            console.log(`   ✅ GOOD! (Target: <50ms)\n`);
        } else {
            console.log(`   ⚠️  Still slow (check if indexes are active)\n`);
        }

        // =====================================================
        // SUMMARY
        // =====================================================
        console.log('\n📊 Performance Summary:');
        console.log('═══════════════════════════════════════════════════════════');
        console.log(`Activities query:       ${duration1}ms (was 11,214ms)`);
        console.log(`Business info query:    ${duration2}ms (was 2,934ms)`);
        console.log(`Products count query:   ${duration3}ms`);
        console.log(`Companies list query:   ${duration4}ms`);
        console.log('═══════════════════════════════════════════════════════════');

        const totalBefore = 11214 + 2934 + 2818; // ~17 seconds
        const totalAfter = duration1 + duration2 + duration3 + duration4;
        const improvement = ((totalBefore - totalAfter) / totalBefore * 100).toFixed(1);

        console.log(`\nTotal time: ${totalAfter}ms (was ~17,000ms)`);
        console.log(`Improvement: ${improvement}% faster! 🚀\n`);

        if (totalAfter < 500) {
            console.log('✅ PRODUCTION READY! All queries are fast.\n');
        } else if (totalAfter < 2000) {
            console.log('⚠️  IMPROVED but still needs optimization.\n');
        } else {
            console.log('❌ INDEXES MAY NOT BE ACTIVE YET. Wait a few minutes and retry.\n');
        }

    } catch (error) {
        console.error('❌ Error testing performance:', error);
    } finally {
        await mongoose.disconnect();
        console.log('🔌 Disconnected from MongoDB\n');
    }
}

// Run the test
testQueryPerformance();