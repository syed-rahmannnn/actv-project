require('dotenv').config({ path: './config.env' });
const mongoose = require('mongoose');

const companySchema = new mongoose.Schema({}, { strict: false });
const Company = mongoose.model('Company', companySchema, 'companies');

async function checkTypes() {
  try {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected\n');

    const companies = await Company.find();
    
    companies.forEach((company, i) => {
      console.log(`${i + 1}. ${company.name}`);
      console.log(`   memberId value: "${company.memberId}"`);
      console.log(`   memberId type: ${typeof company.memberId}`);
      console.log(`   memberId is ObjectId: ${company.memberId instanceof mongoose.Types.ObjectId}`);
      console.log('');
    });

    // Test queries
    const testId = '692e685ce47750d07c018b50';
    console.log('='.repeat(60));
    console.log(`Testing queries for: ${testId}\n`);

    console.log('1. Query as STRING:');
    const asString = await Company.find({ memberId: testId });
    console.log(`   Found: ${asString.length} companies`);

    console.log('\n2. Query as ObjectId:');
    const asObjectId = await Company.find({ memberId: new mongoose.Types.ObjectId(testId) });
    console.log(`   Found: ${asObjectId.length} companies`);

    console.log('\n3. Query with $eq (strict):');
    const withEq = await Company.find({ memberId: { $eq: testId } });
    console.log(`   Found: ${withEq.length} companies`);

    await mongoose.disconnect();
  } catch (error) {
    console.error('Error:', error);
    process.exit(1);
  }
}

checkTypes();
