const express = require('express');
const router = express.Router();
const Product = require('../models/Product');
const mongoose = require('mongoose');

// GET /api/products?companyId=xxx - Get all products for a company
router.get('/', async (req, res) => {
  try {
    const { companyId } = req.query;

    if (!companyId) {
      return res.status(400).json({
        success: false,
        message: 'companyId is required'
      });
    }

    console.log(`📦 GET /api/products - companyId: ${companyId}`);

    // Convert to ObjectId
    let companyObjectId;
    try {
      companyObjectId = new mongoose.Types.ObjectId(companyId);
    } catch (err) {
      return res.status(400).json({
        success: false,
        message: 'Invalid companyId format'
      });
    }

    const products = await Product.find({ companyId: companyObjectId })
      .sort({ featured: -1, createdAt: -1 }); // Featured first, then by date

    console.log(`✅ Found ${products.length} products`);

    res.json({
      success: true,
      count: products.length,
      data: products
    });
  } catch (error) {
    console.error('❌ Error fetching products:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch products',
      error: error.message
    });
  }
});

// POST /api/products - Create a new product
router.post('/', async (req, res) => {
  try {
    const { companyId, name, description, category, price, priceUnit, currency, featured, imageUrl } = req.body;

    console.log(`📦 POST /api/products - Creating product: ${name}`);
    console.log(`📋 Request body:`, req.body);

    // Validate required fields
    if (!companyId || !name || !category || price === undefined) {
      return res.status(400).json({
        success: false,
        message: 'companyId, name, category, and price are required'
      });
    }

    // Convert companyId to ObjectId
    let companyObjectId;
    try {
      companyObjectId = new mongoose.Types.ObjectId(companyId);
    } catch (err) {
      return res.status(400).json({
        success: false,
        message: 'Invalid companyId format'
      });
    }

    const product = new Product({
      companyId: companyObjectId,
      name,
      description,
      category,
      price: parseFloat(price),
      priceUnit: priceUnit || 'one-time',
      currency: currency || 'INR',
      featured: featured || false,
      imageUrl
    });

    await product.save();

    console.log(`✅ Product created: ${product._id}`);

    res.status(201).json({
      success: true,
      message: 'Product created successfully',
      data: product
    });
  } catch (error) {
    console.error('❌ Error creating product:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create product',
      error: error.message
    });
  }
});

// PUT /api/products/:id - Update a product
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, category, price, priceUnit, currency, featured, imageUrl, status } = req.body;

    console.log(`📦 PUT /api/products/${id} - Updating product`);

    // Convert to ObjectId
    let productObjectId;
    try {
      productObjectId = new mongoose.Types.ObjectId(id);
    } catch (err) {
      return res.status(400).json({
        success: false,
        message: 'Invalid product ID format'
      });
    }

    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (description !== undefined) updateData.description = description;
    if (category !== undefined) updateData.category = category;
    if (price !== undefined) updateData.price = parseFloat(price);
    if (priceUnit !== undefined) updateData.priceUnit = priceUnit;
    if (currency !== undefined) updateData.currency = currency;
    if (featured !== undefined) updateData.featured = featured;
    if (imageUrl !== undefined) updateData.imageUrl = imageUrl;
    if (status !== undefined) updateData.status = status;

    const product = await Product.findByIdAndUpdate(
      productObjectId,
      { $set: updateData },
      { new: true, runValidators: true }
    );

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    console.log(`✅ Product updated: ${product._id}`);

    res.json({
      success: true,
      message: 'Product updated successfully',
      data: product
    });
  } catch (error) {
    console.error('❌ Error updating product:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update product',
      error: error.message
    });
  }
});

// DELETE /api/products/:id - Delete a product
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    console.log(`📦 DELETE /api/products/${id}`);

    // Convert to ObjectId
    let productObjectId;
    try {
      productObjectId = new mongoose.Types.ObjectId(id);
    } catch (err) {
      return res.status(400).json({
        success: false,
        message: 'Invalid product ID format'
      });
    }

    const product = await Product.findByIdAndDelete(productObjectId);

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found'
      });
    }

    console.log(`✅ Product deleted: ${id}`);

    res.json({
      success: true,
      message: 'Product deleted successfully'
    });
  } catch (error) {
    console.error('❌ Error deleting product:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete product',
      error: error.message
    });
  }
});

module.exports = router;
