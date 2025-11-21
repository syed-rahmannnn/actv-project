const mongoose = require('mongoose');

const memberDetailsSchema = new mongoose.Schema({
  fullName: {
    type: String,
    trim: true,
    default: '',
    maxlength: [100, 'Full name cannot exceed 100 characters']
  },
  email: {
    type: String,
    lowercase: true,
    trim: true,
    default: '',
    sparse: true,
    match: [/^$|^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
  },
  phoneNumber: {
    type: String,
    trim: true,
    default: '',
    match: [/^$|^[\+]?[1-9][\d]{0,15}$/, 'Please enter a valid phone number']
  },
  state: {
    type: String,
    trim: true,
    default: ''
  },
  district: {
    type: String,
    trim: true,
    default: ''
  },
  block: {
    type: String,
    trim: true,
    default: ''
  },
  city: {
    type: String,
    trim: true,
    default: ''
  },
  // Demographic Details (moved from BusinessInfo)
  aadhaarNumber: {
    type: String,
    trim: true,
    match: [/^$|^\d{12}$/, 'Aadhaar number must be 12 digits']
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
    enum: ['', 'Christian SC', 'ST', 'Christian ST', 'Other', null],
    default: ''
  },
  profileCompleted: {
    type: Boolean,
    default: false
  },
  // Approval information
  approvedBy: {
    type: String,
    trim: true,
    default: null
  },
  approvedBlock: {
    type: String,
    trim: true,
    default: null
  },
  approvedAt: {
    type: Date,
    default: null
  },
  // Membership information
  membershipStatus: {
    type: String,
    enum: ['pending', 'active', 'expired', 'cancelled'],
    default: 'pending'
  },
  membershipType: {
    type: String,
    enum: ['annual', 'lifetime', 'none'],
    default: 'none'
  },
  membershipActivatedAt: {
    type: Date,
    default: null
  },
  membershipExpiresAt: {
    type: Date,
    default: null
  },
  paymentId: {
    type: String,
    default: null
  },
  paymentAmount: {
    type: Number,
    default: null
  },
  lastPaymentDate: {
    type: Date,
    default: null
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

// Email field already has unique: true which creates an index automatically
// Index for phone number query performance
memberDetailsSchema.index({ phoneNumber: 1 });

// Update the updatedAt field before saving
memberDetailsSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('MemberDetails', memberDetailsSchema);
