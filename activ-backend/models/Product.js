const mongoose = require('mongoose');

const productSchema = new mongoose.Schema({
  companyId: {
    type: mongoose.Schema.Types.ObjectId,
    required: true,
    ref: 'Company'
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    trim: true
  },
  category: {
    type: String,
    required: true,
    enum: ['Software', 'Services', 'Education', 'Product', 'Other']
  },
  price: {
    type: Number,
    required: true
  },
  priceUnit: {
    type: String,
    enum: ['one-time', 'monthly', 'hourly', 'yearly'],
    default: 'one-time'
  },
  currency: {
    type: String,
    default: 'INR'
  },
  featured: {
    type: Boolean,
    default: false
  },
  imageUrl: {
    type: String
  },
  status: {
    type: String,
    enum: ['ACTIVE', 'INACTIVE', 'OUT_OF_STOCK'],
    default: 'ACTIVE'
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('Product', productSchema);
