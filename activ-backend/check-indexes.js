/**
 * CHECK EXISTING DATABASE INDEXES
 */

const mongoose = require('mongoose');
require('dotenv').config({ path: './config.env' });

async function checkIndexes() {
    try {
        console.log('🔌 Connecting to MongoDB...');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Connected\n');

        const db = mongoose.connection.db;

        const collections = [
            'memberbusinessinfos',
            'companies',
            'memberdetails',
            'products',
            'activities'
        ];

        for (const collectionName of collections) {
            console.log(`\n📁 ${collectionName}:`);
            try {
                const indexes = await db.collection(collectionName).indexes();
                indexes.forEach(idx => {
                    console.log(`   ${idx.name}: ${JSON.stringify(idx.key)}`);
                });
            } catch (error) {
                console.log(`   ⚠️  Collection not found`);
            }
        }

        await mongoose.disconnect();
        console.log('\n✅ Disconnected');
        process.exit(0);

    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

checkIndexes();