const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { clearCacheByPattern } = require('../middleware/hybrid-cache');

// Company Schema
const companySchema = new mongoose.Schema({
    memberId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'MemberDetails',
        required: true,
        index: true
    },
    name: {
        type: String,
        required: true,
        trim: true
    },
    industry: {
        type: String,
        trim: true
    },
    location: {
        type: String,
        trim: true
    },
    city: {
        type: String,
        trim: true
    },
    area: {
        type: String,
        trim: true
    },
    description: {
        type: String,
        trim: true
    },
    website: {
        type: String,
        trim: true
    },
    mobile: {
        type: String,
        trim: true
    },
    email: {
        type: String,
        trim: true,
        lowercase: true
    },
    logoUrl: {
        type: String,
        trim: true
    },
    status: {
        type: String,
        enum: ['ACTIVE', 'UNDER_REVIEW', 'PENDING', 'REJECTED'],
        default: 'UNDER_REVIEW'
    },
    productsCount: {
        type: Number,
        default: 0
    },
    views: {
        type: Number,
        default: 0
    },
    connections: {
        type: Number,
        default: 0
    }
}, {
    timestamps: true
});

// ✅ OPTIMIZED: Add compound indexes for faster queries
companySchema.index({ memberId: 1, createdAt: -1 }); // Get companies by member, sorted
companySchema.index({ name: 'text', description: 'text' }); // Text search
companySchema.index({ status: 1 }); // Filter by status
companySchema.index({ industry: 1 }); // Filter by industry
companySchema.index({ city: 1, location: 1 }); // Location-based queries

// Create model
const Company = mongoose.model('Company', companySchema);

// GET /api/companies?memberId={currentUserId}
// Get all companies for a member
router.get('/', async(req, res) => {
    try {
        const { memberId } = req.query;

        console.log('\n' + '='.repeat(80));
        console.log('📥 GET /api/companies REQUEST');
        console.log('='.repeat(80));
        console.log('📋 memberId from query:', memberId);
        console.log('📋 memberId type:', typeof memberId);

        if (!memberId) {
            return res.status(400).json({
                success: false,
                message: 'memberId is required'
            });
        }

        // Convert string to ObjectId for correct query
        let memberObjectId;
        try {
            memberObjectId = new mongoose.Types.ObjectId(memberId);
            console.log('✅ Converted to ObjectId:', memberObjectId);
        } catch (err) {
            console.error('❌ Invalid ObjectId format:', err.message);
            return res.status(400).json({
                success: false,
                message: 'Invalid memberId format'
            });
        }

        console.log('🔍 Querying companies with ObjectId...');
        const companies = await Company.find({ memberId: memberObjectId })
            .sort({ createdAt: -1 })
            .lean();

        console.log(`✅ Found ${companies.length} companies`);
        companies.forEach((c, i) => {
            console.log(`   ${i + 1}. ${c.name} (${c._id})`);
        });
        console.log('='.repeat(80) + '\n');

        res.status(200).json({
            success: true,
            count: companies.length,
            data: companies
        });

    } catch (error) {
        console.error('❌ Get companies error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch companies',
            error: error.message
        });
    }
});

// GET /api/companies/:companyId
// Get a single company by ID
router.get('/:companyId', async(req, res) => {
    try {
        const { companyId } = req.params;

        const company = await Company.findById(companyId).lean();

        if (!company) {
            return res.status(404).json({
                success: false,
                message: 'Company not found'
            });
        }

        res.status(200).json({
            success: true,
            data: company
        });

    } catch (error) {
        console.error('Get company error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch company',
            error: error.message
        });
    }
});

// POST /api/companies
// Create a new company
router.post('/', async(req, res) => {
    try {
        const {
            memberId,
            name,
            industry,
            location,
            city,
            area,
            description,
            website,
            mobile,
            email,
            logoUrl,
            status
        } = req.body;

        console.log('\n' + '='.repeat(80));
        console.log('📥 POST /api/companies - CREATE COMPANY');
        console.log('='.repeat(80));
        console.log('📋 memberId received:', memberId, 'type:', typeof memberId);
        console.log('🏢 Company name:', name);

        if (!memberId || !name) {
            return res.status(400).json({
                success: false,
                message: 'memberId and name are required'
            });
        }

        // Convert memberId to ObjectId
        let memberObjectId;
        try {
            memberObjectId = new mongoose.Types.ObjectId(memberId);
            console.log('✅ Converted memberId to ObjectId:', memberObjectId);
        } catch (err) {
            console.error('❌ Invalid memberId format:', err.message);
            return res.status(400).json({
                success: false,
                message: 'Invalid memberId format'
            });
        }

        const newCompany = new Company({
            memberId: memberObjectId, // Save as ObjectId
            name,
            industry,
            location,
            city,
            area,
            description,
            website,
            mobile,
            email,
            logoUrl,
            status: status || 'UNDER_REVIEW',
            productsCount: 0,
            views: 0,
            connections: 0
        });

        await newCompany.save();
        console.log('✅ Company created successfully:', newCompany._id);

        // 🗑️ Clear companies cache for this member
        await clearCacheByPattern(`memberId=${memberId}`);
        console.log(`🗑️ Cleared companies cache for member: ${memberId}`);

        console.log('='.repeat(80) + '\n');

        res.status(201).json({
            success: true,
            message: 'Company created successfully',
            data: newCompany
        });

    } catch (error) {
        console.error('Create company error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to create company',
            error: error.message
        });
    }
});

// PUT /api/companies/:companyId
// Update a company
router.put('/:companyId', async(req, res) => {
    try {
        const { companyId } = req.params;
        const updateData = req.body;

        // Remove fields that shouldn't be updated directly
        delete updateData._id;
        delete updateData.createdAt;
        delete updateData.updatedAt;
        delete updateData.memberId; // Don't allow changing owner

        const company = await Company.findByIdAndUpdate(
            companyId, { $set: updateData }, { new: true, runValidators: true }
        );

        if (!company) {
            return res.status(404).json({
                success: false,
                message: 'Company not found'
            });
        }

        // 🗑️ Clear companies cache for this member
        await clearCacheByPattern(`memberId=${company.memberId}`);
        console.log(`🗑️ Cleared companies cache for member: ${company.memberId}`);

        res.status(200).json({
            success: true,
            message: 'Company updated successfully',
            data: company
        });

    } catch (error) {
        console.error('Update company error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update company',
            error: error.message
        });
    }
});

// DELETE /api/companies/:companyId
// Delete a company
router.delete('/:companyId', async(req, res) => {
    try {
        const { companyId } = req.params;

        const company = await Company.findByIdAndDelete(companyId);

        if (!company) {
            return res.status(404).json({
                success: false,
                message: 'Company not found'
            });
        }

        // 🗑️ Clear companies cache for this member
        await clearCacheByPattern(`memberId=${company.memberId}`);
        console.log(`🗑️ Cleared companies cache for member: ${company.memberId}`);

        res.status(200).json({
            success: true,
            message: 'Company deleted successfully'
        });

    } catch (error) {
        console.error('Delete company error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to delete company',
            error: error.message
        });
    }
});

// PATCH /api/companies/:companyId/increment-views
// Increment views count
router.patch('/:companyId/increment-views', async(req, res) => {
    try {
        const { companyId } = req.params;

        const company = await Company.findByIdAndUpdate(
            companyId, { $inc: { views: 1 } }, { new: true }
        );

        if (!company) {
            return res.status(404).json({
                success: false,
                message: 'Company not found'
            });
        }

        res.status(200).json({
            success: true,
            data: company
        });

    } catch (error) {
        console.error('Increment views error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to increment views',
            error: error.message
        });
    }
});

module.exports = router;