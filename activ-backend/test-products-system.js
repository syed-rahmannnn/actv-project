require('dotenv').config({ path: './config.env' });
const mongoose = require('mongoose');

async function testProductsSystem() {
    try {
        console.log('🧪 Testing Products System\n');
        console.log('Connecting to MongoDB...');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Connected to MongoDB\n');

        // Define schemas
        const companySchema = new mongoose.Schema({}, { strict: false });
        const productSchema = new mongoose.Schema({}, { strict: false });
        const memberSchema = new mongoose.Schema({}, { strict: false });

        // Get or create models
        const Company = mongoose.models.Company || mongoose.model('Company', companySchema, 'companies');
        const Product = mongoose.models.Product || mongoose.model('Product', productSchema, 'products');
        const MemberDetails = mongoose.models.MemberDetails || mongoose.model('MemberDetails', memberSchema, 'memberdetails');

        // Test 1: Find test user
        console.log('='.repeat(80));
        console.log('TEST 1: Find test user (sairam12@gmail.com)');
        console.log('='.repeat(80));

        const member = await MemberDetails.findOne({ email: 'sairam12@gmail.com' });
        if (!member) {
            console.log('❌ Test user not found!');
            await mongoose.disconnect();
            return;
        }

        const memberId = member._id.toString();
        console.log(`✅ Found member: ${member.fullName} (${memberId})\n`);

        // Test 2: Fetch companies for this member
        console.log('='.repeat(80));
        console.log('TEST 2: Fetch companies for member');
        console.log('='.repeat(80));

        const companies = await Company.find({ memberId: member._id });
        console.log(`✅ Found ${companies.length} companies\n`);

        if (companies.length === 0) {
            console.log('❌ No companies found. Cannot test products.');
            await mongoose.disconnect();
            return;
        }

        // Test 3: Check products for each company
        console.log('='.repeat(80));
        console.log('TEST 3: Check products for each company');
        console.log('='.repeat(80));

        for (let i = 0; i < companies.length; i++) {
            const company = companies[i];
            const products = await Product.find({ companyId: company._id });

            console.log(`\n${i + 1}. Company: ${company.name}`);
            console.log(`   Company ID: ${company._id}`);
            console.log(`   Stored Product Count: ${company.productsCount || 0}`);
            console.log(`   Actual Products: ${products.length}`);

            if (products.length > 0) {
                console.log(`   Products:`);
                products.forEach((p, idx) => {
                    console.log(`      ${idx + 1}. ${p.name} - ${p.category} - ₹${p.price}`);
                    console.log(`         ID: ${p._id}`);
                    console.log(`         Featured: ${p.featured || false}`);
                });
            } else {
                console.log(`   ⚠️  No products found for this company`);
            }

            // Update product count if mismatch
            if ((company.productsCount || 0) !== products.length) {
                await Company.findByIdAndUpdate(company._id, { productsCount: products.length });
                console.log(`   ✅ Updated product count to ${products.length}`);
            }
        }

        // Test 4: Simulate API call for active company (first company)
        console.log('\n' + '='.repeat(80));
        console.log('TEST 4: Simulate GET /api/products?companyId=' + companies[0]._id);
        console.log('='.repeat(80));

        const apiProducts = await Product.find({ companyId: companies[0]._id })
            .sort({ featured: -1, createdAt: -1 });

        console.log(`✅ API would return ${apiProducts.length} products`);
        console.log('Response structure:');
        console.log(JSON.stringify({
            success: true,
            count: apiProducts.length,
            data: apiProducts.map(p => ({
                _id: p._id,
                companyId: p.companyId,
                name: p.name,
                description: p.description,
                category: p.category,
                price: p.price,
                priceUnit: p.priceUnit,
                currency: p.currency,
                featured: p.featured,
                status: p.status
            }))
        }, null, 2));

        console.log('\n' + '='.repeat(80));
        console.log('✅ ALL TESTS COMPLETED SUCCESSFULLY');
        console.log('='.repeat(80));
        console.log('\n📊 Summary:');
        console.log(`   Total Companies: ${companies.length}`);
        console.log(`   Active Company: ${companies[0].name}`);
        console.log(`   Active Company ID: ${companies[0]._id}`);
        console.log(`   Products in Active Company: ${apiProducts.length}`);

        await mongoose.disconnect();
        console.log('\n✅ Disconnected from MongoDB');

    } catch (error) {
        console.error('❌ Test error:', error);
        await mongoose.disconnect();
    }
}

testProductsSystem();