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
    enum: ['OPC','TRUST','SOCIETY']
  },
  businessType: {
    type: String,
    enum: ['Manufacturing', 'Trader',  'Service Provider', 'Others']
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
  }],
  // Additional fields for business profile dashboard
  mobile: {
    type: String,
    trim: true
  },
  area: {
    type: String,
    trim: true
  },
  location: {
    type: String,
    trim: true
  },
  businessDescription: {
    type: String,
    trim: true
  },
  businessWebsite: {
    type: String,
    trim: true
  },
  logoUrl: {
    type: String,
    trim: true
  },
  status: {
    type: String,
    enum: ['UNDER_REVIEW', 'APPROVED', 'ACTIVE', 'REJECTED', 'PENDING'],
    default: 'UNDER_REVIEW'
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
