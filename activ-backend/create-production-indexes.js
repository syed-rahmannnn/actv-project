const mongoose = require('mongoose');
require('dotenv').config({ path: './config.env' });

const Activity = require('./models/Activity');
const MemberBusinessInfo = require('./models/MemberBusinessInfo');
const Product = require('./models/Product');

// Company model is defined inline in routes, we'll access it via db.collection()

/**
 * Create production-critical indexes
 * This script adds indexes that will dramatically speed up slow queries
 * 
 * Expected improvements:
 * - Activities query: 11,214ms → 50ms (224x faster)
 * - Business info: 2,934ms → 80ms (37x faster)
 * - Stats queries: 2,818ms → 100ms (28x faster)
 */

async function createProductionIndexes() {
    try {
        console.log('🚀 Connecting to MongoDB...');
        await mongoose.connect(process.env.MONGODB_URI, {
            maxPoolSize: 10,
            serverSelectionTimeoutMS: 10000
        });
        console.log('✅ Connected to MongoDB Atlas\n');

        const db = mongoose.connection.db;

        // =====================================================
        // CRITICAL INDEX 1: Activities by Company + Timestamp
        // =====================================================
        console.log('📊 Creating index: activities.companyId_1_createdAt_-1');
        console.log('   Impact: GET /dashboard/activities - 11s → 50ms');

        try {
            await Activity.collection.createIndex({ companyId: 1, createdAt: -1 }, {
                name: 'companyId_1_createdAt_-1',
                background: true
            });
            console.log('   ✅ Created successfully\n');
        } catch (err) {
            if (err.code === 85 || err.codeName === 'IndexOptionsConflict') {
                console.log('   ⚠️  Index already exists (skipping)\n');
            } else {
                throw err;
            }
        }

        // =====================================================
        // CRITICAL INDEX 2: Business Info by Member ID
        // =====================================================
        console.log('📊 Creating index: memberbusinessinfos.memberId_1');
        console.log('   Impact: GET /profile/business-info - 2.9s → 80ms');

        try {
            await MemberBusinessInfo.collection.createIndex({ memberId: 1 }, {
                name: 'memberId_1',
                background: true,
                unique: false
            });
            console.log('   ✅ Created successfully\n');
        } catch (err) {
            if (err.code === 85 || err.codeName === 'IndexOptionsConflict') {
                console.log('   ⚠️  Index already exists (skipping)\n');
            } else {
                throw err;
            }
        }

        // =====================================================
        // CRITICAL INDEX 3: Products by Company ID
        // =====================================================
        console.log('📊 Creating index: products.companyId_1');
        console.log('   Impact: GET /dashboard/stats (productsCount) - faster');

        try {
            await Product.collection.createIndex({ companyId: 1 }, {
                name: 'companyId_1',
                background: true
            });
            console.log('   ✅ Created successfully\n');
        } catch (err) {
            if (err.code === 85 || err.codeName === 'IndexOptionsConflict') {
                console.log('   ⚠️  Index already exists (skipping)\n');
            } else {
                throw err;
            }
        }

        // =====================================================
        // CRITICAL INDEX 4: Companies by Member ID
        // =====================================================
        console.log('📊 Creating index: companies.memberId_1');
        console.log('   Impact: GET /companies (list by member) - faster');

        try {
            await db.collection('companies').createIndex({ memberId: 1 }, {
                name: 'memberId_1',
                background: true
            });
            console.log('   ✅ Created successfully\n');
        } catch (err) {
            if (err.code === 85 || err.codeName === 'IndexOptionsConflict') {
                console.log('   ⚠️  Index already exists (skipping)\n');
            } else {
                throw err;
            }
        }

        // =====================================================
        // ADDITIONAL USEFUL INDEXES
        // =====================================================

        // Activities by Member (for member activity history)
        console.log('📊 Creating index: activities.memberId_1_createdAt_-1');
        try {
            await Activity.collection.createIndex({ memberId: 1, createdAt: -1 }, {
                name: 'memberId_1_createdAt_-1',
                background: true
            });
            console.log('   ✅ Created successfully\n');
        } catch (err) {
            if (err.code === 85 || err.codeName === 'IndexOptionsConflict') {
                console.log('   ⚠️  Index already exists (skipping)\n');
            } else {
                throw err;
            }
        }

        // Companies by status (for filtering active/inactive)
        console.log('📊 Creating index: companies.status_1');
        try {
            await db.collection('companies').createIndex({ status: 1 }, {
                name: 'status_1',
                background: true
            });
            console.log('   ✅ Created successfully\n');
        } catch (err) {
            if (err.code === 85 || err.codeName === 'IndexOptionsConflict') {
                console.log('   ⚠️  Index already exists (skipping)\n');
            } else {
                throw err;
            }
        }

        // =====================================================
        // VERIFY ALL INDEXES
        // =====================================================
        console.log('\n📋 Verifying all indexes...\n');

        const activitiesIndexes = await Activity.collection.getIndexes();
        console.log('Activities collection indexes:');
        Object.keys(activitiesIndexes).forEach(key => {
            console.log(`   - ${key}`);
        });

        const businessInfoIndexes = await MemberBusinessInfo.collection.getIndexes();
        console.log('\nMemberBusinessInfo collection indexes:');
        Object.keys(businessInfoIndexes).forEach(key => {
            console.log(`   - ${key}`);
        });

        const productsIndexes = await Product.collection.getIndexes();
        console.log('\nProducts collection indexes:');
        Object.keys(productsIndexes).forEach(key => {
            console.log(`   - ${key}`);
        });

        const companiesIndexes = await db.collection('companies').indexes();
        console.log('\nCompanies collection indexes:');
        companiesIndexes.forEach(index => {
            console.log(`   - ${index.name}`);
        });

        console.log('\n✅ Index creation complete!');
        console.log('\n📊 Expected Performance Improvements:');
        console.log('   • /dashboard/activities: 11.2s → <50ms (224x faster)');
        console.log('   • /profile/business-info: 2.9s → <100ms (29x faster)');
        console.log('   • /dashboard/stats: 2.8s → <100ms (28x faster)');
        console.log('\n🔄 Next step: Restart your backend server');
        console.log('   cd c:\\actv-project\\activ-backend');
        console.log('   pm2 restart activ-backend');
        console.log('   OR: node server.js\n');

    } catch (error) {
        console.error('❌ Error creating indexes:', error);
        process.exit(1);
    } finally {
        await mongoose.disconnect();
        console.log('🔌 Disconnected from MongoDB\n');
    }
}

// Run the script
createProductionIndexes();