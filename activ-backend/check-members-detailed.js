require('dotenv').config({ path: './config.env' });
const mongoose = require('mongoose');

const memberDetailsSchema = new mongoose.Schema({
    fullName: String,
    email: String,
    phoneNumber: String,
    state: String,
    district: String,
    block: String,
    city: String,
}, { timestamps: true });

const MemberDetails = mongoose.model('MemberDetails', memberDetailsSchema);

async function checkMembers() {
    try {
        console.log('Connecting to MongoDB...');
        await mongoose.connect(process.env.MONGODB_URI);
        console.log('✅ Connected to MongoDB');

        const members = await MemberDetails.find()
            .select('_id fullName email phoneNumber')
            .lean();

        console.log('\n👥 Total members in DB:', members.length);
        console.log('\n' + '='.repeat(80));

        members.forEach((member, index) => {
            console.log(`\n${index + 1}. ${member.fullName || 'No name'}`);
            console.log(`   Member ID: ${member._id}`);
            console.log(`   Email: ${member.email || 'N/A'}`);
            console.log(`   Phone: ${member.phoneNumber || 'N/A'}`);
        });

        console.log('\n' + '='.repeat(80));

        await mongoose.disconnect();
        console.log('\n✅ Disconnected from MongoDB');
    } catch (error) {
        console.error('❌ Error:', error);
        process.exit(1);
    }
}

checkMembers();