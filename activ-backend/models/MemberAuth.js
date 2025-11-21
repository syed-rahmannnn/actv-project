const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const memberAuthSchema = new mongoose.Schema({
  email: {
    type: String,
    lowercase: true,
    trim: true,
    default: '',
    sparse: true,
    match: [/^$|^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
  },
  password: {
    type: String,
    default: '',
    minlength: [0, 'Password must be at least 8 characters long']
  },
  isActive: {
    type: Boolean,
    default: true
  },
  lastLogin: {
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

// Hash password before saving
memberAuthSchema.pre('save', async function(next) {
  // Only hash the password if it has been modified (or is new) and is not empty
  if (!this.isModified('password') || !this.password || this.password === '') return next();
  
  try {
    // Hash password with cost of 12
    const hashedPassword = await bcrypt.hash(this.password, 12);
    this.password = hashedPassword;
    this.updatedAt = Date.now();
    next();
  } catch (error) {
    next(error);
  }
});

// Compare password method
memberAuthSchema.methods.comparePassword = async function(candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

// Update last login method
memberAuthSchema.methods.updateLastLogin = function() {
  this.lastLogin = new Date();
  return this.save();
};

module.exports = mongoose.model('MemberAuth', memberAuthSchema);
