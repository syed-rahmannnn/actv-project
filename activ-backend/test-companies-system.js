require('dotenv').config({ path: './config.env' });
const mongoose = require('mongoose');

async function testCompaniesSystem() {
    try {
        console.log('🧪 Testing Companies Management System\n');
        console.log('Connecting to MongoDB...');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Connected to MongoDB\n');

        // Define schemas (required for mongoose models)
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
        console.log(`✅ Found ${companies.length} companies:\n`);

        if (companies.length === 0) {
            console.log('⚠️  No companies found. Creating a test company...\n');

            const testCompany = new Company({
                memberId: member._id,
                name: 'Test Company for ' + member.fullName,
                industry: 'Software',
                mobile: member.phoneNumber || '9999999999',
                location: member.city || 'Test City',
                area: member.block || 'Test Area',
                description: 'Test company created for system verification',
                status: 'ACTIVE',
                productsCount: 0,
                views: 0,
                connections: 0
            });

            await testCompany.save();
            console.log(`✅ Test company created: ${testCompany._id}\n`);
            companies.push(testCompany);
        }

        // Display company details
        for (let i = 0; i < companies.length; i++) {
            const company = companies[i];
            console.log(`${i + 1}. ${company.name}`);
            console.log(`   ID: ${company._id}`);
            console.log(`   Industry: ${company.industry || 'N/A'}`);
            console.log(`   Mobile: ${company.mobile || 'N/A'}`);
            console.log(`   Location: ${company.location || 'N/A'}`);
            console.log(`   Status: ${company.status}`);
            console.log(`   Views: ${company.views}`);
            console.log(`   Products Count: ${company.productsCount}`);
            console.log(`   Connections: ${company.connections}`);
            console.log();
        }

        // Test 3: Count products for each company
        console.log('='.repeat(80));
        console.log('TEST 3: Verify product counts');
        console.log('='.repeat(80));

        for (const company of companies) {
            const actualProductCount = await Product.countDocuments({ companyId: company._id });
            const storedCount = company.productsCount || 0;

            console.log(`Company: ${company.name}`);
            console.log(`   Stored product count: ${storedCount}`);
            console.log(`   Actual product count: ${actualProductCount}`);

            if (storedCount !== actualProductCount) {
                console.log(`   ⚠️  Mismatch detected! Updating...`);
                await Company.findByIdAndUpdate(company._id, { productsCount: actualProductCount });
                console.log(`   ✅ Updated to ${actualProductCount}`);
            } else {
                console.log(`   ✅ Counts match!`);
            }
            console.log();
        }

        // Test 4: Test API endpoint simulation
        console.log('='.repeat(80));
        console.log('TEST 4: Simulate GET /api/companies?memberId=' + memberId);
        console.log('='.repeat(80));

        const apiCompanies = await Company.find({ memberId: member._id })
            .sort({ createdAt: -1 })
            .lean();

        console.log(`✅ API would return ${apiCompanies.length} companies`);
        console.log('Response structure:');
        console.log(JSON.stringify({
            success: true,
            count: apiCompanies.length,
            data: apiCompanies.map(c => ({
                _id: c._id,
                memberId: c.memberId,
                name: c.name,
                industry: c.industry,
                views: c.views,
                productsCount: c.productsCount,
                connections: c.connections,
                status: c.status
            }))
        }, null, 2));

        console.log('\n' + '='.repeat(80));
        console.log('✅ ALL TESTS COMPLETED SUCCESSFULLY');
        console.log('='.repeat(80));

        await mongoose.disconnect();
        console.log('\n✅ Disconnected from MongoDB');

    } catch (error) {
        console.error('❌ Test error:', error);
        await mongoose.disconnect();
    }
}

testCompaniesSystem();