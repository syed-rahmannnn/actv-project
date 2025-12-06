const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Product = require('../models/Product');
const { getBusinessSettings } = require('./businessSettings');

// Get Company model (defined in companies.js routes)
const Company = mongoose.model('Company');

/**
 * GET /api/discover/companies
 * Search companies with pagination - filtered by memberId (business account)
 * Query params:
 *   - memberId: current user's member ID (required)
 *   - query: search term (optional)
 *   - page: page number (default: 1)
 *   - limit: items per page (default: 20)
 */
router.get('/companies', async (req, res) => {
  try {
    const { memberId, query = '', page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Require memberId to ensure business-scoped results
    if (!memberId) {
      return res.status(400).json({
        status: 'error',
        message: 'memberId is required to fetch companies'
      });
    }

    // Convert memberId to ObjectId
    let memberObjectId;
    try {
      memberObjectId = new mongoose.Types.ObjectId(memberId);
    } catch (err) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid memberId format'
      });
    }

    // Build search filter - ALWAYS scoped to the current business (memberId)
    let filter = { memberId: memberObjectId };
    
    if (query && query.trim() !== '') {
      const searchRegex = new RegExp(query.trim(), 'i');
      filter.$or = [
        { name: searchRegex },
        { description: searchRegex },
        { industry: searchRegex },
        { city: searchRegex },
        { location: searchRegex }
      ];
    }

    // Find companies
    const companies = await Company.find(filter)
      .select('name description industry city location area status logoUrl createdAt')
      .limit(parseInt(limit))
      .skip(skip)
      .sort({ createdAt: -1 }); // Most recent first

    // Filter by publicProfile setting and get product count
    const companiesWithCount = [];
    for (const company of companies) {
      // Check if company has public profile enabled
      const settings = await getBusinessSettings(company._id);
      
      // Skip companies with public profile disabled
      if (!settings.publicProfile) {
        continue;
      }

      const productsCount = await Product.countDocuments({ companyId: company._id });
      
      companiesWithCount.push({
        id: company._id,
        name: company.name,
        tagline: company.description || 'No description available',
        category: company.industry || 'Uncategorized',
        location: company.city && company.location 
          ? `${company.city}, ${company.location}` 
          : company.city || company.location || 'Location not specified',
        productsCount,
        isVerified: company.status === 'active', // Consider active companies as verified
        logoUrl: company.logoUrl || null,
        area: company.area || null
      });
    }

    // Get total count for pagination (also scoped to memberId)
    const total = await Company.countDocuments(filter);

    console.log(`🔍 Discover Companies - memberId: ${memberId}, found: ${companiesWithCount.length} companies`);

    res.status(200).json({
      status: 'success',
      data: companiesWithCount,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(total / parseInt(limit)),
        totalItems: total,
        itemsPerPage: parseInt(limit)
      }
    });
  } catch (error) {
    console.error('Error fetching companies for discover:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch companies',
      error: error.message
    });
  }
});

/**
 * GET /api/discover/products
 * Search products with pagination - filtered by memberId (business account)
 * Query params:
 *   - memberId: current user's member ID (required)
 *   - query: search term (optional)
 *   - page: page number (default: 1)
 *   - limit: items per page (default: 20)
 */
router.get('/products', async (req, res) => {
  try {
    const { memberId, query = '', page = 1, limit = 20 } = req.query;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    // Require memberId to ensure business-scoped results
    if (!memberId) {
      return res.status(400).json({
        status: 'error',
        message: 'memberId is required to fetch products'
      });
    }

    // Convert memberId to ObjectId
    let memberObjectId;
    try {
      memberObjectId = new mongoose.Types.ObjectId(memberId);
    } catch (err) {
      return res.status(400).json({
        status: 'error',
        message: 'Invalid memberId format'
      });
    }

    // First, find all companies belonging to this member (business)
    const memberCompanies = await Company.find({ memberId: memberObjectId })
      .select('_id');
    
    const companyIds = memberCompanies.map(c => c._id);

    // If no companies found for this member, return empty results
    if (companyIds.length === 0) {
      return res.status(200).json({
        status: 'success',
        data: [],
        pagination: {
          currentPage: parseInt(page),
          totalPages: 0,
          totalItems: 0,
          itemsPerPage: parseInt(limit)
        }
      });
    }

    // Build search filter - ALWAYS scoped to companies owned by this member
    let filter = { companyId: { $in: companyIds } };
    
    if (query && query.trim() !== '') {
      const searchRegex = new RegExp(query.trim(), 'i');
      filter.$or = [
        { name: searchRegex },
        { description: searchRegex },
        { category: searchRegex }
      ];
    }

    // Find products and populate company info
    const products = await Product.find(filter)
      .populate('companyId', 'name city location')
      .limit(parseInt(limit))
      .skip(skip)
      .sort({ createdAt: -1 }); // Most recent first

    // Filter by showProductsPublicly setting and format response
    const productsData = [];
    for (const product of products) {
      if (!product.companyId) continue;
      
      // Check if company allows public product display
      const settings = await getBusinessSettings(product.companyId._id);
      
      // Skip products from companies with showProductsPublicly disabled
      if (!settings.showProductsPublicly) {
        continue;
      }

      productsData.push({
        id: product._id,
        name: product.name,
        companyName: product.companyId.name || 'Unknown Company',
        category: product.category || 'Uncategorized',
        price: product.price || 0,
        priceUnit: product.priceUnit || 'unit',
        currency: product.currency || 'INR',
        location: product.companyId.city || product.companyId.location || 'Location not specified',
        description: product.description || '',
        imageUrl: product.imageUrl || null,
        companyId: product.companyId._id || null
      });
    }

    // Get total count for pagination (also scoped to member's companies)
    const total = await Product.countDocuments(filter);

    console.log(`🔍 Discover Products - memberId: ${memberId}, found: ${productsData.length} products across ${companyIds.length} companies`);

    res.status(200).json({
      status: 'success',
      data: productsData,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(total / parseInt(limit)),
        totalItems: total,
        itemsPerPage: parseInt(limit)
      }
    });
  } catch (error) {
    console.error('Error fetching products for discover:', error);
    res.status(500).json({
      status: 'error',
      message: 'Failed to fetch products',
      error: error.message
    });
  }
});

module.exports = router;
