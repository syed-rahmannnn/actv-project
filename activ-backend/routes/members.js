const express = require('express');
const MemberDetails = require('../models/MemberDetails');
const MemberAuth = require('../models/MemberAuth');

const router = express.Router();

// GET by email: /api/members/by-email?email=someone@example.com
router.get('/by-email', async(req, res) => {
    try {
        const { email } = req.query;
        if (!email) return res.status(400).json({ success: false, message: 'email query param required' });

        const doc = await MemberDetails.findOne({ email: email.toLowerCase().trim() }).lean();
        if (!doc) return res.status(404).json({ success: false, message: 'Member not found' });
        return res.json({ success: true, data: doc });
    } catch (err) {
        console.error('GET /api/members/by-email err', err);
        return res.status(500).json({ success: false, message: 'Server error' });
    }
});

// Get all members (for admin purposes)
router.get('/', async(req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const skip = (page - 1) * limit;

        const [members, total] = await Promise.all([
            MemberDetails.find()
            .select('-__v')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit)
            .lean(), // ✅ OPTIMIZED: Use lean for 40% faster queries
            MemberDetails.countDocuments()
        ]);

        res.status(200).json({
            success: true,
            data: {
                members,
                pagination: {
                    currentPage: page,
                    totalPages: Math.ceil(total / limit),
                    totalMembers: total,
                    hasNext: page < Math.ceil(total / limit),
                    hasPrev: page > 1
                }
            }
        });

    } catch (error) {
        console.error('Get members error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
});

// GET by id: /api/members/:id
router.get('/:id', async(req, res) => {
    try {
        const { id } = req.params;
        const doc = await MemberDetails.findById(id).lean();
        if (!doc) return res.status(404).json({ success: false, message: 'Member not found' });
        return res.json({ success: true, data: doc });
    } catch (err) {
        console.error('GET /api/members/:id err', err);
        return res.status(500).json({ success: false, message: 'Server error' });
    }
});

// GET profile completion percentage: /api/members/:id/completion
router.get('/:id/completion', async(req, res) => {
    try {
        const { id } = req.params;
        const doc = await MemberDetails.findById(id).lean();
        if (!doc) return res.status(404).json({ success: false, message: 'Member not found' });

        // Define all trackable fields
        const fields = [
            'fullName', 'email', 'phoneNumber', 'state', 'district', 'block', 'city',
            'aadhaarNumber', 'streetName', 'educationalQualification', 'religion', 'socialCategory'
        ];

        let totalFields = fields.length;
        let filledFields = 0;

        fields.forEach(field => {
            const value = doc[field];
            if (value !== null && value !== undefined && value !== '') {
                filledFields++;
            }
        });

        const completionPercentage = totalFields > 0 ?
            Math.round((filledFields / totalFields) * 100) :
            0;

        return res.json({
            success: true,
            data: {
                completionPercentage,
                filledFields,
                totalFields
            }
        });
    } catch (err) {
        console.error('GET /api/members/:id/completion err', err);
        return res.status(500).json({ success: false, message: 'Server error' });
    }
});

// GET member dashboard status: /api/members/:id/status
router.get('/:id/status', async(req, res) => {
    try {
        const { id } = req.params;
        const mongoose = require('mongoose');
        
        // Find member
        const member = await MemberDetails.findById(id).lean();
        if (!member) {
            return res.status(404).json({ success: false, message: 'Member not found' });
        }

        // Calculate profile completion
        const fields = [
            'fullName', 'email', 'phoneNumber', 'state', 'district', 'block', 'city',
            'aadhaarNumber', 'streetName', 'educationalQualification', 'religion', 'socialCategory'
        ];

        let totalFields = fields.length;
        let filledFields = 0;

        fields.forEach(field => {
            const value = member[field];
            if (value !== null && value !== undefined && value !== '') {
                filledFields++;
            }
        });

        const profileCompletion = totalFields > 0 ?
            Math.round((filledFields / totalFields) * 100) :
            0;

        // Find application status from applications collection
        const Application = mongoose.model('Application');
        const application = await Application.findOne({ userId: id })
            .sort({ createdAt: -1 })
            .lean();

        console.log(`🔍 DEBUG: Found application for user ${id}:`, application ? JSON.stringify(application, null, 2) : 'null');

        // Check if business profile exists
        const MemberBusinessInfo = mongoose.model('MemberBusinessInfo');
        const businessProfile = await MemberBusinessInfo.findOne({ memberId: id }).lean();
        const hasBusinessProfile = businessProfile !== null;

        let applicationStatus = 'NONE';
        if (application) {
            console.log(`📋 Application found with status: ${application.status}`);
            // Map status from application
            if (application.status) {
                applicationStatus = application.status;
            } else if (application.stateApproved) {
                applicationStatus = 'APPROVED';
            } else if (application.stateRejected) {
                applicationStatus = 'REJECTED';
            } else if (application.districtApproved) {
                applicationStatus = 'Pending-State';
            } else if (application.districtRejected) {
                applicationStatus = 'REJECTED';
            } else if (application.blockApproved) {
                applicationStatus = 'Pending-District';
            } else if (application.blockRejected) {
                applicationStatus = 'REJECTED';
            } else {
                applicationStatus = 'Pending-Block';
            }
        }

        return res.json({
            success: true,
            data: {
                profileCompletion,
                hasBusinessProfile,
                applicationStatus,
                hasApplication: application !== null,
                applicationId: application ? application._id : null
            }
        });
    } catch (err) {
        console.error('GET /api/members/:id/status err', err);
        return res.status(500).json({ success: false, message: 'Server error', error: err.message });
    }
});

// PUT update by id (create if not exists)
router.put('/:id', async(req, res) => {
    try {
        const { id } = req.params;
        const updates = req.body || {};

        // whitelist allowed fields to avoid accidental overwrite
        const allowed = ['fullName', 'email', 'phoneNumber', 'state', 'district', 'block', 'city', 'profileCompleted',
            // demographic fields moved here
            'aadhaarNumber', 'streetName', 'educationalQualification', 'religion', 'socialCategory'
        ];
        const payload = {};
        allowed.forEach(k => {
            if (updates[k] !== undefined) payload[k] = updates[k];
        });

        // Update MemberDetails
        const doc = await MemberDetails.findByIdAndUpdate(id, payload, { new: true, upsert: true, runValidators: false });

        // Handle password update separately in MemberAuth
        if (updates.password && updates.password.trim() !== '') {
            const memberAuth = await MemberAuth.findOne({ memberId: id });
            if (memberAuth) {
                memberAuth.password = updates.password.trim();
                await memberAuth.save(); // This will trigger the pre-save hook to hash the password
            }
        }

        return res.json({ success: true, data: doc });
    } catch (err) {
        console.error('PUT /api/members/:id err', err);
        // If validation error
        if (err.name === 'ValidationError') {
            return res.status(400).json({ success: false, message: err.message, errors: err.errors });
        }
        return res.status(500).json({ success: false, message: 'Server error' });
    }
});

// POST create (optional) /api/members
router.post('/', async(req, res) => {
    try {
        const payload = req.body || {};
        // you can validate/whitelist here similarly
        const doc = await MemberDetails.create(payload);
        return res.status(201).json({ success: true, data: doc });
    } catch (err) {
        console.error('POST /api/members err', err);
        if (err.code === 11000) {
            return res.status(409).json({ success: false, message: 'Duplicate key', error: err.keyValue });
        }
        if (err.name === 'ValidationError') {
            return res.status(400).json({ success: false, message: err.message, errors: err.errors });
        }
        return res.status(500).json({ success: false, message: 'Server error' });
    }
});

// Delete member
router.delete('/:id', async(req, res) => {
    try {
        const { id } = req.params;

        const member = await MemberDetails.findByIdAndDelete(id);

        if (!member) {
            return res.status(404).json({
                success: false,
                message: 'Member not found'
            });
        }

        // Also delete associated auth record
        await MemberAuth.findOneAndDelete({ email: member.email });

        res.status(200).json({
            success: true,
            message: 'Member deleted successfully'
        });

    } catch (error) {
        console.error('Delete member error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
});

// Search members
router.get('/search/:query', async(req, res) => {
    try {
        const { query } = req.params;
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 10;
        const skip = (page - 1) * limit;

        const searchRegex = new RegExp(query, 'i');

        const members = await MemberDetails.find({
                $or: [
                    { fullName: searchRegex },
                    { email: searchRegex },
                    { phoneNumber: searchRegex },
                    { state: searchRegex },
                    { district: searchRegex }
                ]
            })
            .select('-__v')
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit);

        const total = await MemberDetails.countDocuments({
            $or: [
                { fullName: searchRegex },
                { email: searchRegex },
                { phoneNumber: searchRegex },
                { state: searchRegex },
                { district: searchRegex }
            ]
        });

        res.status(200).json({
            success: true,
            data: {
                members,
                pagination: {
                    currentPage: page,
                    totalPages: Math.ceil(total / limit),
                    totalMembers: total,
                    hasNext: page < Math.ceil(total / limit),
                    hasPrev: page > 1
                }
            }
        });

    } catch (error) {
        console.error('Search members error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
});

// Update member approval information
router.put('/approval/:email', async(req, res) => {
    try {
        const { email } = req.params;
        const { approvedBy, approvedBlock } = req.body;

        if (!approvedBy || !approvedBlock) {
            return res.status(400).json({
                success: false,
                message: 'approvedBy and approvedBlock are required'
            });
        }

        const member = await MemberDetails.findOneAndUpdate({ email: email.toLowerCase().trim() }, {
            approvedBy,
            approvedBlock,
            approvedAt: new Date()
        }, { new: true });

        if (!member) {
            return res.status(404).json({
                success: false,
                message: 'Member not found'
            });
        }

        res.status(200).json({
            success: true,
            message: 'Member approval information updated successfully',
            data: member
        });

    } catch (error) {
        console.error('Update member approval error:', error);
        res.status(500).json({
            success: false,
            message: 'Internal server error',
            error: error.message
        });
    }
});

module.exports = router;