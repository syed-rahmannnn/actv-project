const express = require('express');
const mongoose = require('mongoose');
const MemberDetails = require('../models/MemberDetails');
const MemberBusinessInfo = require('../models/MemberBusinessInfo');
const MemberFinancialInfo = require('../models/MemberFinancialInfo');
const MemberDeclaration = require('../models/MemberDeclaration');
const { clearCacheByPattern } = require('../middleware/hybrid-cache');

const router = express.Router();

// Get complete member profile
router.get('/:memberId', async(req, res) => {
    try {
        const { memberId } = req.params;

        // Parallel queries for better performance
        const [member, businessInfo, financialInfo, declaration] = await Promise.all([
            MemberDetails.findById(memberId),
            MemberBusinessInfo.findOne({ memberId: memberId }),
            MemberFinancialInfo.findOne({ memberId: memberId }),
            MemberDeclaration.findOne({ memberId: memberId })
        ]);

        if (!member) {
            return res.status(404).json({
                success: false,
                message: 'Member not found'
            });
        }

        res.status(200).json({
            success: true,
            data: {
                member,
                businessInfo,
                financialInfo,
                declaration
            }
        });

    } catch (error) {
        console.error('Get profile error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
});

// Get business information by member ID - PRODUCTION OPTIMIZED
router.get('/business-info/:memberId', async(req, res) => {
    const startTime = Date.now();

    try {
        const { memberId } = req.params;

        console.log(`\n📥 GET /business-info/${memberId}`);

        // Fast ObjectId validation
        if (!mongoose.Types.ObjectId.isValid(memberId)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid memberId format'
            });
        }

        const memberObjectId = new mongoose.Types.ObjectId(memberId);

        // Quick connection check (non-blocking)
        if (mongoose.connection.readyState !== 1) {
            return res.status(503).json({
                success: false,
                message: 'Database temporarily unavailable',
                error: 'SERVICE_UNAVAILABLE'
            });
        }

        // ULTRA-OPTIMIZED: Minimal fields, 1 second timeout, indexed query
        const businessInfo = await MemberBusinessInfo.findOne({ memberId: memberObjectId })
            .select('organizationName mobile industry area location status') // Minimal fields
            .lean() // Return plain JS object (much faster)
            .maxTimeMS(1000) // 1 second max
            .exec();

        if (!businessInfo) {
            return res.status(404).json({
                success: false,
                message: 'Business information not found'
            });
        }

        const duration = Date.now() - startTime;
        console.log(`✅ Business info: ${businessInfo.organizationName} (${duration}ms)`);

        // Warn if slow
        if (duration > 500) {
            console.warn(`⚠️  SLOW: ${duration}ms for /business-info/${memberId}`);
        }

        res.status(200).json({
            success: true,
            data: { businessInfo }
        });

    } catch (error) {
        console.error('Get business info error:', error);

        // Check if it's a network/connection error
        if (error.name === 'MongoServerSelectionError' || error.name === 'MongoNetworkError') {
            return res.status(503).json({
                success: false,
                message: 'Database connection error. Please check your network and try again.',
                error: 'DATABASE_CONNECTION_ERROR'
            });
        }

        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
});

// Save business information
router.post('/business-info', async(req, res) => {
    try {
        console.log('\n==========================================');
        console.log('📥 POST /business-info REQUEST RECEIVED');
        console.log('==========================================');

        const { memberId, ...businessData } = req.body;

        console.log('📦 Full request body:', JSON.stringify(req.body, null, 2));
        console.log('📱 Mobile from request:', businessData.mobile);
        console.log('🏢 Organization name from request:', businessData.organizationName);

        if (!memberId) {
            return res.status(400).json({
                success: false,
                message: 'Member ID is required'
            });
        }

        // Convert memberId to ObjectId for queries
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

        // Check if member exists - ✅ OPTIMIZED: Use lean and select only needed fields
        const member = await MemberDetails.findById(memberObjectId)
            .select('fullName email')
            .lean();
        if (!member) {
            return res.status(404).json({
                success: false,
                message: 'Member not found'
            });
        }

        // Ensure name/email are stored in collection
        const common = {
            fullName: member.fullName,
            email: member.email
        };

        // Whitelist allowed business fields
        const allowed = [
            'organizationName',
            'constitutionType',
            'businessType',
            'businessActivities',
            'businessCommencementYear',
            'numberOfEmployees',
            'memberOfOtherChamber',
            'otherChamber',
            'registeredWithGovtOrganization',
            // Extended when doingBusiness is yes
            'doingBusiness',
            'additionalBusiness',
            'businessLocation',
            'businessWebsite',
            'businessScale',
            'exportStatus',
            'hasExportLicense',
            'exportLicense',
            'businessDescription',
            // Dashboard fields
            'mobile',
            'area',
            'location',
            'logoUrl',
            'status'
        ];
        const payload = {};
        allowed.forEach(k => { if (businessData[k] !== undefined) payload[k] = businessData[k]; });

        console.log('📱 Business Info Payload:', JSON.stringify(payload, null, 2));
        console.log('📱 Mobile number received:', payload.mobile);

        // Build update object - common fields should NOT overwrite business data
        const updateData = {
            ...common, // Add common fields first
            ...payload, // Then business data (this can override common if needed)
            memberId: memberObjectId // Use ObjectId
        };

        // Ensure mobile is explicitly set if provided
        if (payload.mobile !== undefined) {
            updateData.mobile = payload.mobile;
            console.log('🔥 FORCING MOBILE UPDATE:', payload.mobile);
        }

        // Ensure organizationName is preserved if provided
        if (payload.organizationName !== undefined) {
            updateData.organizationName = payload.organizationName;
            console.log('🏢 FORCING ORGANIZATION NAME UPDATE:', payload.organizationName);
        }

        console.log('🔍 FINAL UPDATE DATA OBJECT:');
        console.log(JSON.stringify(updateData, null, 2));

        // Update or create business info - use ObjectId for query
        const businessInfo = await MemberBusinessInfo.findOneAndUpdate({ memberId: memberObjectId }, { $set: updateData }, {
            upsert: true,
            new: true,
            runValidators: true
        });

        console.log('✅ Business info saved to DB');
        console.log('📱 Saved mobile number:', businessInfo.mobile);
        console.log('🏢 Saved organization name:', businessInfo.organizationName);
        console.log('📊 FULL DOCUMENT AFTER SAVE:');
        console.log(JSON.stringify(businessInfo, null, 2));

        // 🔥 AUTO-CREATE COMPANY RECORD
        // Check if a company already exists for this member with this organization name
        const Company = mongoose.model('Company');
        const existingCompany = await Company.findOne({
            memberId: memberObjectId,
            name: businessInfo.organizationName
        }).select('_id name').lean(); // ✅ OPTIMIZED: Use lean and select only needed fields

        if (!existingCompany && businessInfo.organizationName) {
            const newCompany = new Company({
                memberId: memberObjectId,
                name: businessInfo.organizationName,
                industry: businessInfo.businessType || 'General',
                location: businessInfo.location || businessInfo.area,
                city: businessInfo.location,
                area: businessInfo.area,
                description: businessInfo.businessDescription || '',
                mobile: businessInfo.mobile,
                email: businessInfo.email,
                status: businessInfo.status || 'UNDER_REVIEW',
                productsCount: 0,
                views: 0,
                connections: 0
            });

            const savedCompany = await newCompany.save();

            // Optimized: Use the returned document instead of additional query
            if (!savedCompany || !savedCompany._id) {
                throw new Error('Company creation verification failed');
            }

            console.log('✅ AUTO-CREATED COMPANY:', savedCompany._id);
            console.log('   Company Name:', savedCompany.name);
            console.log('   Member ID:', savedCompany.memberId);
        } else if (existingCompany) {
            console.log('ℹ️  Company already exists:', existingCompany._id);
        }

        // 🗑️ CRITICAL: ALWAYS clear cache after business profile save
        // Clear both companies AND business profile cache to ensure fresh data
        // Note: Cache keys have 'api:' prefix, so we clear by matching the memberId
        await clearCacheByPattern(`memberId=${memberId}`);
        console.log('🗑️  Cleared all caches for member:', memberId);

        console.log('==========================================\n');

        res.status(200).json({
            success: true,
            message: 'Business information saved successfully',
            data: { businessInfo }
        });

    } catch (error) {
        console.error('Save business info error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
});

// Save financial information
router.post('/financial-info', async(req, res) => {
    try {
        const { memberId, ...financialData } = req.body;

        if (!memberId) {
            return res.status(400).json({
                success: false,
                message: 'Member ID is required'
            });
        }

        // Check if member exists
        const member = await MemberDetails.findById(memberId);
        if (!member) {
            return res.status(404).json({
                success: false,
                message: 'Member not found'
            });
        }

        const common = {
            fullName: member.fullName,
            email: member.email
        };

        // Whitelist allowed financial fields
        const allowed = [
            'panNumber', 'gstNumber', 'udyamNumber', 'filedITR', 'itrYears', 'turnoverRange',
            'fy2021', 'fy2020', 'fy2019', 'govtSchemeBenefit', 'scheme1', 'scheme2', 'scheme3'
        ];
        const payload = {};
        allowed.forEach(k => { if (financialData[k] !== undefined) payload[k] = financialData[k]; });

        // Update or create financial info
        const financialInfo = await MemberFinancialInfo.findOneAndUpdate({ memberId: memberId }, {
            ...payload,
            ...common,
            memberId: memberId
        }, {
            upsert: true,
            new: true,
            runValidators: true
        });

        res.status(200).json({
            success: true,
            message: 'Financial information saved successfully',
            data: { financialInfo }
        });

    } catch (error) {
        console.error('Save financial info error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
});

// Save declaration
router.post('/declaration', async(req, res) => {
    try {
        const { memberId, ...declarationData } = req.body;

        if (!memberId) {
            return res.status(400).json({
                success: false,
                message: 'Member ID is required'
            });
        }

        // Check if member exists
        const member = await MemberDetails.findById(memberId);
        if (!member) {
            return res.status(404).json({
                success: false,
                message: 'Member not found'
            });
        }

        const common = {
            fullName: member.fullName,
            email: member.email
        };

        // Whitelist allowed declaration fields
        const allowed = ['sisterConcerns', 'companyNames', 'showOneFieldPerName', 'agreeToDeclaration', 'profileCompleted', 'submissionDate'];
        const payload = {};
        allowed.forEach(k => { if (declarationData[k] !== undefined) payload[k] = declarationData[k]; });

        // Update or create declaration
        const declaration = await MemberDeclaration.findOneAndUpdate({ memberId: memberId }, {
            ...payload,
            ...common,
            memberId: memberId
        }, {
            upsert: true,
            new: true,
            runValidators: true
        });

        // Update member profile completion status
        await MemberDetails.findByIdAndUpdate(memberId, {
            profileCompleted: true
        });

        res.status(200).json({
            success: true,
            message: 'Declaration submitted successfully',
            data: { declaration }
        });

    } catch (error) {
        console.error('Save declaration error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
});

// Update member profile completion status
router.put('/complete-profile/:memberId', async(req, res) => {
    try {
        const { memberId } = req.params;

        const member = await MemberDetails.findByIdAndUpdate(
            memberId, { profileCompleted: true }, { new: true }
        );

        if (!member) {
            return res.status(404).json({
                success: false,
                message: 'Member not found'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Profile marked as completed',
            data: { member }
        });

    } catch (error) {
        console.error('Complete profile error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
});

module.exports = router;