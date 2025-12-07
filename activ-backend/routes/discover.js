const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Product = require('../models/Product');
const { getBusinessSettings } = require('./businessSettings');

// Get Company model (defined in companies.js routes)
const Company = mongoose.model('Company');

/**
 * GET /api/discover/companies
 * Search ALL companies with pagination (excluding current user's companies)
 * Query params:
 *   - memberId: current user's member ID (to exclude their own companies)
 *   - query: search term (optional)
 *   - page: page number (default: 1)
 *   - limit: items per page (default: 20)
 */
router.get('/companies', async(req, res) => {
    try {
        const { memberId, query = '', page = 1, limit = 20 } = req.query;

        // Validate memberId
        if (!memberId) {
            return res.status(400).json({
                status: 'error',
                message: 'memberId is required'
            });
        }

        // If no query provided, return empty results (don't load all data)
        if (!query || query.trim() === '') {
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

        const skip = (parseInt(page) - 1) * parseInt(limit);

        // Build search filter - EXCLUDE current user's companies, only ACTIVE status
        // ✅ OPTIMIZED: Use MongoDB text index for blazing fast search
        const filter = {
            $text: { $search: query.trim() }, // Uses text index on name & description
            memberId: { $ne: new mongoose.Types.ObjectId(memberId) }, // Exclude user's companies
            status: { $in: ['ACTIVE', 'active'] } // Support both cases
        };

        // ✅ OPTIMIZED: Get companies with lean query, text score, and aggregate product counts in one go
        const [companies, total] = await Promise.all([
            Company.find(filter)
            .select('name description industry city location area status logoUrl createdAt')
            .limit(parseInt(limit))
            .skip(skip)
            .sort({ score: { $meta: 'textScore' }, createdAt: -1 }) // Sort by relevance first
            .lean(), // Use lean for faster queries
            Company.countDocuments(filter)
        ]);

        // ✅ OPTIMIZED: Get all company IDs at once
        const companyIds = companies.map(c => c._id);

        // ✅ OPTIMIZED: Batch get product counts using aggregation
        const productCounts = await Product.aggregate([
            { $match: { companyId: { $in: companyIds } } },
            { $group: { _id: '$companyId', count: { $sum: 1 } } }
        ]);

        // Create a map for quick lookup
        const productCountMap = {};
        productCounts.forEach(pc => {
            productCountMap[pc._id.toString()] = pc.count;
        });

        // ✅ OPTIMIZED: Format response without additional DB calls
        const companiesWithCount = companies.map(company => ({
            id: company._id,
            name: company.name,
            tagline: company.description || 'No description available',
            category: company.industry || 'Uncategorized',
            location: company.city && company.location ?
                `${company.city}, ${company.location}` : company.city || company.location || 'Location not specified',
            productsCount: productCountMap[company._id.toString()] || 0,
            isVerified: company.status === 'ACTIVE' || company.status === 'active',
            logoUrl: company.logoUrl || null,
            area: company.area || null
        }));

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
 * Search ALL products with pagination (excluding current user's products)
 * Query params:
 *   - memberId: current user's member ID (to exclude their own products)
 *   - query: search term (optional)
 *   - page: page number (default: 1)
 *   - limit: items per page (default: 20)
 */
router.get('/products', async(req, res) => {
    try {
        const { memberId, query = '', page = 1, limit = 20 } = req.query;

        // Validate memberId
        if (!memberId) {
            return res.status(400).json({
                status: 'error',
                message: 'memberId is required'
            });
        }

        // If no query provided, return empty results (don't load all data)
        if (!query || query.trim() === '') {
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

        const skip = (parseInt(page) - 1) * parseInt(limit);

        // ✅ OPTIMIZED: Get member's company IDs using lean query
        const memberCompanies = await Company.find({
                memberId: new mongoose.Types.ObjectId(memberId)
            })
            .select('_id')
            .lean();

        const excludeCompanyIds = memberCompanies.map(c => c._id);

        // Build search filter - EXCLUDE current user's products
        const searchRegex = new RegExp(query.trim(), 'i');
        const filter = {
            companyId: { $nin: excludeCompanyIds },
            $or: [
                { name: searchRegex },
                { description: searchRegex },
                { category: searchRegex }
            ]
        };

        // ✅ OPTIMIZED: Use aggregation pipeline for better performance
        const [products, total] = await Promise.all([
            Product.aggregate([
                { $match: filter },
                { $sort: { createdAt: -1 } },
                { $skip: skip },
                { $limit: parseInt(limit) },
                {
                    $lookup: {
                        from: 'companies',
                        localField: 'companyId',
                        foreignField: '_id',
                        as: 'company'
                    }
                },
                { $unwind: { path: '$company', preserveNullAndEmptyArrays: true } },
                {
                    $project: {
                        _id: 1,
                        name: 1,
                        category: 1,
                        price: 1,
                        priceUnit: 1,
                        currency: 1,
                        description: 1,
                        imageUrl: 1,
                        companyId: 1,
                        companyName: '$company.name',
                        companyCity: '$company.city',
                        companyLocation: '$company.location'
                    }
                }
            ]),
            Product.countDocuments(filter)
        ]);

        // ✅ OPTIMIZED: Format response without additional DB calls
        const productsData = products.map(product => ({
            id: product._id,
            name: product.name,
            companyName: product.companyName || 'Unknown Company',
            category: product.category || 'Uncategorized',
            price: product.price || 0,
            priceUnit: product.priceUnit || 'unit',
            currency: product.currency || 'INR',
            location: product.companyCity || product.companyLocation || 'Location not specified',
            description: product.description || '',
            imageUrl: product.imageUrl || null,
            companyId: product.companyId || null
        }));

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