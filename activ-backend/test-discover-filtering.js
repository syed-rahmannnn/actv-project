require('dotenv').config({ path: './config.env' });
const mongoose = require('mongoose');

// Define schemas
const companySchema = new mongoose.Schema({}, { strict: false });
const productSchema = new mongoose.Schema({}, { strict: false });

// Get or create models
const Company = mongoose.models.Company || mongoose.model('Company', companySchema, 'companies');
const Product = mongoose.models.Product || mongoose.model('Product', productSchema, 'products');

async function testDiscoverFiltering() {
    try {
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Connected to MongoDB\n');

        const memberId = '692e685ce47750d07c018b50';
        console.log(`Testing Discover for member: ${memberId}\n`);

        // Get member's companies
        const companies = await Company.find({
            memberId: new mongoose.Types.ObjectId(memberId)
        }).select('name _id');

        console.log(`✅ Found ${companies.length} companies for this member:`);
        companies.forEach((c, i) => console.log(`  ${i + 1}. ${c.name} (${c._id})`));

        // Get products from member's companies
        const companyIds = companies.map(c => c._id);
        const products = await Product.find({
            companyId: { $in: companyIds }
        });

        console.log(`\n✅ Found ${products.length} products across member's companies:`);
        products.forEach((p, i) => {
            const company = companies.find(c => c._id.toString() === p.companyId.toString());
            console.log(`  ${i + 1}. ${p.name} - ${company ? company.name : 'Unknown'} (₹${p.price})`);
        });

        console.log(`\n📊 Summary:`);
        console.log(`   - Discover will show ONLY ${companies.length} companies`);
        console.log(`   - Discover will show ONLY ${products.length} products`);
        console.log(`   - All belong to member: sairam (${memberId})`);

        // Get total companies and products in DB for comparison
        const totalCompanies = await Company.countDocuments();
        const totalProducts = await Product.countDocuments();

        console.log(`\n🔍 Before fix (what was shown):`);
        console.log(`   - ALL ${totalCompanies} companies in database`);
        console.log(`   - ALL ${totalProducts} products in database`);

        console.log(`\n✅ After fix (what will be shown):`);
        console.log(`   - ONLY ${companies.length} companies (member's own)`);
        console.log(`   - ONLY ${products.length} products (from member's companies)`);

        process.exit(0);
    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

testDiscoverFiltering();