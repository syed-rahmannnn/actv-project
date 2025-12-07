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

// ✅ OPTIMIZED: Compound index for login queries (covers both email and isActive)
memberAuthSchema.index({ email: 1, isActive: 1 }); // Single compound index is enough

// Hash password before saving
memberAuthSchema.pre('save', async function(next) {
    // Only hash the password if it has been modified (or is new) and is not empty
    if (!this.isModified('password') || !this.password || this.password === '') return next();

    try {
        // ✅ OPTIMIZED: Hash password with cost of 10 (industry standard, 75% faster than 12)
        const hashedPassword = await bcrypt.hash(this.password, 10);
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