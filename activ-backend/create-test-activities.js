const mongoose = require('mongoose');
const Activity = require('./models/Activity');
const MemberAuth = require('./models/MemberAuth');
require('dotenv').config({ path: './config.env' });

// Define Company schema (as it's defined inline in routes/companies.js)
const companySchema = new mongoose.Schema({
  memberId: { type: mongoose.Schema.Types.ObjectId, ref: 'MemberDetails', required: true },
  name: { type: String, required: true },
  industry: String,
  location: String,
  area: String,
  views: { type: Number, default: 0 }
}, { timestamps: true });

const Company = mongoose.model('Company', companySchema);

async function createTestActivities() {
  try {
    console.log('🔌 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    // Get a company and member from your database
    const company = await Company.findOne();
    const member = await MemberAuth.findOne();

    if (!company || !member) {
      console.log('❌ No company or member found. Please create them first.');
      process.exit(1);
    }

    console.log('📋 Found company:', company.name);
    console.log('👤 Found member:', member.email);

    // Clear existing activities for this company (optional)
    await Activity.deleteMany({ companyId: company._id.toString() });
    console.log('🗑️  Cleared old activities');

    // Create sample activities
    const activities = [
      {
        memberId: member._id,
        companyId: company._id.toString(),
        activityType: 'PRODUCT_CREATED',
        entityType: 'PRODUCT',
        entityId: 'prod_123',
        entityName: 'Premium Software Suite',
        description: 'Created a new product listing',
        metadata: { price: 4999 },
      },
      {
        memberId: member._id,
        companyId: company._id.toString(),
        activityType: 'PROFILE_UPDATED',
        entityType: 'PROFILE',
        entityId: company._id.toString(),
        entityName: company.name,
        description: 'Business description updated',
        metadata: { fields: ['description', 'tagline'] },
      },
      {
        memberId: member._id,
        companyId: company._id.toString(),
        activityType: 'PRODUCT_UPDATED',
        entityType: 'PRODUCT',
        entityId: 'prod_456',
        entityName: 'Cloud Hosting Service',
        description: 'Updated product pricing',
        metadata: { oldPrice: 2999, newPrice: 3499 },
      },
      {
        memberId: member._id,
        companyId: company._id.toString(),
        activityType: 'PROFILE_VIEWED',
        entityType: 'PROFILE',
        entityId: company._id.toString(),
        entityName: company.name,
        description: 'Your profile was viewed',
        metadata: { viewerLocation: 'Mumbai' },
      },
      {
        memberId: member._id,
        companyId: company._id.toString(),
        activityType: 'COMPANY_UPDATED',
        entityType: 'COMPANY',
        entityId: company._id.toString(),
        entityName: company.name,
        description: 'Company information updated',
        metadata: { fields: ['location', 'area'] },
      },
    ];

    // Insert activities with different timestamps
    for (let i = 0; i < activities.length; i++) {
      const activity = new Activity(activities[i]);
      
      // Set different created dates (spread over last few days)
      const hoursAgo = i * 12; // 0, 12, 24, 36, 48 hours ago
      activity.createdAt = new Date(Date.now() - hoursAgo * 60 * 60 * 1000);
      
      await activity.save();
      console.log(`✅ Created activity ${i + 1}: ${activity.activityType}`);
    }

    console.log('✅ Successfully created test activities!');
    console.log(`\n📊 You can now check your dashboard for:`);
    console.log(`   - Products Listed: Shows actual count from database`);
    console.log(`   - Recent Activity: Shows ${activities.length} test activities`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Error:', error);
    process.exit(1);
  }
}

createTestActivities();
