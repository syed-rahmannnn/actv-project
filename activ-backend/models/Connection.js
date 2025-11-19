const mongoose = require('mongoose');

const connectionSchema = new mongoose.Schema({
  senderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'MemberDetails',
    required: true
  },
  recipientId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'MemberDetails',
    required: true
  },
  status: {
    type: String,
    enum: ['pending', 'accepted', 'declined'],
    default: 'pending'
  },
  message: {
    type: String,
    default: 'Wants to connect with you'
  },
  createdAt: {
    type: Date,
    default: Date.now
  },
  updatedAt: {
    type: Date,
    default: Date.now
  }
});

// Index for faster queries
connectionSchema.index({ senderId: 1, recipientId: 1 });
connectionSchema.index({ recipientId: 1, status: 1 });

module.exports = mongoose.model('Connection', connectionSchema);
