const mongoose = require('mongoose');

const memberDeclarationSchema = new mongoose.Schema({
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
  // Declaration Information
  sisterConcerns: {
    type: Number,
    min: [0, 'Sister concerns cannot be negative']
  },
  companyNames: [{
    type: String,
    trim: true
  }],
  showOneFieldPerName: {
    type: Boolean,
    default: false
  },
  agreeToDeclaration: {
    type: Boolean,
    required: [true, 'Declaration agreement is required'],
    default: false
  },
  profileCompleted: {
    type: Boolean,
    default: false
  },
  submissionDate: {
    type: Date,
    default: Date.now
  },
  status: {
    type: String,
    enum: ['pending', 'under_review', 'approved', 'rejected'],
    default: 'pending'
  },
  reviewNotes: {
    type: String,
    trim: true
  },
  reviewedBy: {
    type: String,
    trim: true
  },
  reviewedAt: {
    type: Date
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
memberDeclarationSchema.index({ memberId: 1 });
memberDeclarationSchema.index({ status: 1 });

// Update the updatedAt field before saving
memberDeclarationSchema.pre('save', function(next) {
  this.updatedAt = Date.now();
  next();
});

module.exports = mongoose.model('MemberDeclaration', memberDeclarationSchema);
