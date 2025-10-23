const mongoose = require('mongoose');

const memberBusinessInfoSchema = new mongoose.Schema({
  memberId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'MemberDetails',
    required: true
  },
  // Required for every collection
  fullName: {
    type: String,
    required: true,
    trim: true
  },
  email: {
    type: String,
    required: true,
    lowercase: true,
    trim: true
  },
  // Business Information (only specified fields)
  doingBusiness: {
    type: Boolean,
    default: false
  },
  organizationName: {
    type: String,
    trim: true
  },
  constitutionType: {
    type: String,
    enum: ['Proprietorship', 'Partnership', 'Private Limited', 'Public Limited', 'LLP', 'Sole Proprietorship', 'Other']
  },
  businessType: {
    type: String,
    enum: ['Agriculture', 'Manufacturing', 'Trader', 'Retailer', 'Service Provider', 'Others']
  },
  businessActivities: {
    type: String,
    trim: true
  },
  businessCommencementYear: {
    type: String,
    trim: true
  },
  numberOfEmployees: {
    type: String,
    trim: true
  },
  memberOfOtherChamber: {
    type: Boolean,
    default: false
  },
  otherChamber: {
    type: String,
    trim: true
  },
  registeredWithGovtOrganization: [{
    type: String,
    enum: ['MSME', 'KVIC', 'NABARD', 'None', 'Others']
  }]
}, {
  timestamps: true
});

// Index for better query performance
memberBusinessInfoSchema.index({ memberId: 1 });

// Update the updatedAt field before saving
memberBusinessInfoSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('MemberBusinessInfo', memberBusinessInfoSchema);
