const mongoose = require('mongoose');

const memberFinancialInfoSchema = new mongoose.Schema({
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
  // Financial & Compliance Information
  panNumber: {
    type: String,
    trim: true,
    uppercase: true,
    match: [/^[A-Z]{5}[0-9]{4}[A-Z]{1}$/, 'PAN number must be in format: ABCDE1234F']
  },
  gstNumber: {
    type: String,
    trim: true,
    uppercase: true,
    match: [/^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$/, 'GST number must be 15 characters']
  },
  udyamNumber: {
    type: String,
    trim: true
  },
  filedITR: {
    type: Boolean,
    default: false
  },
  itrYears: {
    type: String,
    trim: true
  },
  turnoverRange: {
    type: String,
    enum: ['Less than 25 Lakhs', '25 Lakhs - 50 Lakhs', '50 Lakhs - 1 Crore', '1 Crore - 5 Crores', '5 Crores - 10 Crores', 'More than 10 Crores']
  },
  fy2021: {
    type: String,
    trim: true
  },
  fy2020: {
    type: String,
    trim: true
  },
  fy2019: {
    type: String,
    trim: true
  },
  govtSchemeBenefit: {
    type: Boolean,
    default: false
  },
  scheme1: {
    type: String,
    trim: true
  },
  scheme2: {
    type: String,
    trim: true
  },
  scheme3: {
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
memberFinancialInfoSchema.index({ memberId: 1 });

// Update the updatedAt field before saving
memberFinancialInfoSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('MemberFinancialInfo', memberFinancialInfoSchema);
