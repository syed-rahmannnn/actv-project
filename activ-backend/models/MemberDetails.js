const mongoose = require('mongoose');

const memberDetailsSchema = new mongoose.Schema({
  fullName: {
    type: String,
    required: [true, 'Full name is required'],
    trim: true,
    maxlength: [100, 'Full name cannot exceed 100 characters']
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
  },
  phoneNumber: {
    type: String,
    required: [true, 'Phone number is required'],
    trim: true,
    match: [/^[\+]?[1-9][\d]{0,15}$/, 'Please enter a valid phone number']
  },
  dateOfBirth: {
    type: String,
    required: [true, 'Date of birth is required'],
    trim: true
  },
  gender: {
    type: String,
    required: [true, 'Gender is required'],
    enum: ['Male', 'Female', 'Other']
  },
  state: {
    type: String,
    required: [true, 'State is required'],
    trim: true
  },
  district: {
    type: String,
    required: [true, 'District is required'],
    trim: true
  },
  block: {
    type: String,
    required: [true, 'Block is required'],
    trim: true
  },
  city: {
    type: String,
    required: [true, 'City is required'],
    trim: true
  },
  // Personal & Demographic Details (moved from BusinessInfo)
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
  profileCompleted: {
    type: Boolean,
    default: false
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
