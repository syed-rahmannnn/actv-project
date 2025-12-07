/**
 * Run Database Optimization
 * Creates indexes for better query performance
 */

require('dotenv').config({ path: './config.env' });
const mongoose = require('mongoose');

// Import models
require('./routes/companies'); // This defines Company model
const Product = require('./models/Product');
const MemberDetails = require('./models/MemberDetails');
const MemberAuth = require('./models/MemberAuth');

const { optimizeDatabase } = require('./scripts/optimize-database-comprehensive');

async function run() {
    try {
        // Connect to MongoDB
        console.log('🔌 Connecting to MongoDB...');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Connected to MongoDB\n');

        // Run optimization
        await optimizeDatabase();

        console.log('\n✅ Database optimization complete!');
        console.log('\n📝 Next steps:');
        console.log('   1. Restart your server: npm run dev');
        console.log('   2. Run load tests: npm run load-test');
        console.log('   3. Verify improvements in response times');

    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    } finally {
        await mongoose.connection.close();
        console.log('\n🔌 Disconnected from MongoDB');
        process.exit(0);
    }
}

run();