require('dotenv').config({ path: './config.env' });
const mongoose = require('mongoose');

const companySchema = new mongoose.Schema({
  memberId: { type: String, required: true },
  name: { type: String, required: true },
  industry: String,
  location: String,
  city: String,
  area: String,
  description: String,
  website: String,
  mobile: String,
  email: String,
  logoUrl: String,
  status: { type: String, default: 'UNDER_REVIEW' },
  productsCount: { type: Number, default: 0 },
  views: { type: Number, default: 0 },
  connections: { type: Number, default: 0 },
}, { timestamps: true });

const Company = mongoose.model('Company', companySchema);

async function checkCompanies() {
  try {
    console.log('Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const companies = await Company.find().select('_id name memberId createdAt').lean();
    
    console.log('\n📦 Total companies in DB:', companies.length);
    console.log('\n' + '='.repeat(80));
    
    companies.forEach((company, index) => {
      console.log(`\n${index + 1}. ${company.name}`);
      console.log(`   ID: ${company._id}`);
      console.log(`   Member ID: ${company.memberId}`);
      console.log(`   Created: ${company.createdAt}`);
    });
    
    console.log('\n' + '='.repeat(80));
    
    // Also check what memberIds exist
    const memberIds = [...new Set(companies.map(c => c.memberId))];
    console.log('\n🔍 Unique Member IDs:');
    memberIds.forEach(id => console.log(`   - ${id}`));
    
    await mongoose.disconnect();
    console.log('\n✅ Disconnected from MongoDB');
  } catch (error) {
    console.error('❌ Error:', error.message);
    process.exit(1);
  }
}

checkCompanies();
