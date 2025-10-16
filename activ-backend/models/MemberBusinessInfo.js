const mongoose = require('mongoose');

const memberBusinessInfoSchema = new mongoose.Schema({
  memberId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'MemberDetails',
    required: true
  },
  // Personal & Demographic Details
  aadhaarNumber: {
    type: String,
    trim: true,
    match: [/^\d{12}$/, 'Aadhaar number must be 12 digits']
  },
  streetName: {
    type: String,
    trim: true
  },
  educationalQualification: {
    type: String,
    trim: true
  },
  religion: {
    type: String,
    trim: true
  },
  socialCategory: {
    type: String,
    enum: ['General', 'OBC', 'SC', 'ST', 'EWS', 'Other']
  },
  // Business Information
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
  businessTypes: [{
    type: String,
    enum: ['Agriculture', 'Manufacturing', 'Trader', 'Retailer', 'Service Provider', 'Others']
  }],
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
  govtOrganizations: [{
    type: String,
    enum: ['MSME', 'KVIC', 'NABARD', 'None', 'Others']
  }],
  // Extended Business Information
  additionalBusiness: {
    type: String,
    trim: true
  },
  businessLocation: {
    type: String,
    trim: true
  },
  businessWebsite: {
    type: String,
    trim: true
  },
  businessScale: {
    type: String,
    enum: ['Micro', 'Small', 'Medium', 'Large']
  },
  exportStatus: {
    type: String,
    enum: ['Domestic Only', 'Export to Neighboring Countries', 'International Export', 'Planning to Export']
  },
  hasExportLicense: {
    type: Boolean,
    default: false
  },
  exportLicense: {
    type: String,
    trim: true
  },
  businessDescription: {
    type: String,
    trim: true
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
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
