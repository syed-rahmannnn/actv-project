const mongoose = require('mongoose');

const activitySchema = new mongoose.Schema(
  {
    memberId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Member',
      required: true,
      index: true,
    },
    companyId: {
      type: String,
      required: true,
      index: true,
    },
    activityType: {
      type: String,
      required: true,
      enum: [
        'PRODUCT_CREATED',
        'PRODUCT_UPDATED',
        'PRODUCT_DELETED',
        'PROFILE_UPDATED',
        'COMPANY_CREATED',
        'COMPANY_UPDATED',
        'PROFILE_VIEWED',
        'CONNECTION_MADE',
      ],
    },
    entityType: {
      type: String,
      enum: ['PRODUCT', 'PROFILE', 'COMPANY', 'CONNECTION'],
    },
    entityId: {
      type: String,
    },
    entityName: {
      type: String,
    },
    description: {
      type: String,
    },
    metadata: {
      type: mongoose.Schema.Types.Mixed,
    },
  },
  {
    timestamps: true,
  }
);

// Create compound indexes for efficient queries
activitySchema.index({ memberId: 1, companyId: 1, createdAt: -1 });
activitySchema.index({ companyId: 1, createdAt: -1 });

module.exports = mongoose.model('Activity', activitySchema);
