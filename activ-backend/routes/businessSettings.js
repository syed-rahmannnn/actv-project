const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');

// Business Settings Schema
const businessSettingsSchema = new mongoose.Schema({
    businessId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Company',
        required: true,
        unique: true,
        index: true
    },
    publicProfile: {
        type: Boolean,
        default: true
    },
    showProductsPublicly: {
        type: Boolean,
        default: true
    },
    privateAnalytics: {
        type: Boolean,
        default: false
    },
    notifyProfileViews: {
        type: Boolean,
        default: true
    },
    notifyProductInquiries: {
        type: Boolean,
        default: true
    },
    notifyWeeklySummary: {
        type: Boolean,
        default: true
    }
}, {
    timestamps: true
});

// Create or get the model
const BusinessSettings = mongoose.models.BusinessSettings ||
    mongoose.model('BusinessSettings', businessSettingsSchema);

/**
 * GET /api/business/:businessId/settings
 * Get settings for a business (returns defaults if not found)
 */
router.get('/:businessId/settings', async(req, res) => {
    try {
        const { businessId } = req.params;

        console.log('📋 GET Settings Request');
        console.log('   - Business ID:', businessId);

        // Validate businessId (indexed businessId:)
        if (!mongoose.Types.ObjectId.isValid(businessId)) {
            return res.status(400).json({
                status: 'error',
                message: 'Invalid business ID'
            });
        }

        // ✅ OPTIMIZED: Query with indexed businessId: field, uses .select() .lean() .maxTimeMS()
        let settings = await BusinessSettings.findOne({ businessId }).select('businessId publicProfile showProductsPublicly privateAnalytics notifyProfileViews notifyProductInquiries notifyWeeklySummary').lean().maxTimeMS(500);

        if (!settings) {
            console.log('ℹ️ No settings found, returning defaults');
            // Return default settings without saving
            return res.status(200).json({
                status: 'success',
                data: {
                    businessId,
                    publicProfile: true,
                    showProductsPublicly: true,
                    privateAnalytics: false,
                    notifyProfileViews: true,
                    notifyProductInquiries: true,
                    notifyWeeklySummary: true
                }
            });
        }

        console.log('✅ Settings found');
        res.status(200).json({
            status: 'success',
            data: {
                businessId: settings.businessId,
                publicProfile: settings.publicProfile,
                showProductsPublicly: settings.showProductsPublicly,
                privateAnalytics: settings.privateAnalytics,
                notifyProfileViews: settings.notifyProfileViews,
                notifyProductInquiries: settings.notifyProductInquiries,
                notifyWeeklySummary: settings.notifyWeeklySummary
            }
        });

    } catch (error) {
        console.error('❌ Error fetching settings:', error);
        res.status(500).json({
            status: 'error',
            message: 'Failed to fetch settings',
            error: error.message
        });
    }
});

/**
 * PUT /api/business/:businessId/settings
 * Update settings for a business (creates if doesn't exist)
 */
router.put('/:businessId/settings', async(req, res) => {
    try {
        const { businessId } = req.params;
        const {
            publicProfile,
            showProductsPublicly,
            privateAnalytics,
            notifyProfileViews,
            notifyProductInquiries,
            notifyWeeklySummary
        } = req.body;

        console.log('📝 PUT Settings Request');
        console.log('   - Business ID:', businessId);
        console.log('   - Updates:', req.body);

        // Validate businessId
        if (!mongoose.Types.ObjectId.isValid(businessId)) {
            return res.status(400).json({
                status: 'error',
                message: 'Invalid business ID'
            });
        }

        // Prepare update data (only include provided fields) for businessId:
        const updateData = {};
        if (publicProfile !== undefined) updateData.publicProfile = publicProfile;
        if (showProductsPublicly !== undefined) updateData.showProductsPublicly = showProductsPublicly;
        if (privateAnalytics !== undefined) updateData.privateAnalytics = privateAnalytics;
        if (notifyProfileViews !== undefined) updateData.notifyProfileViews = notifyProfileViews;
        if (notifyProductInquiries !== undefined) updateData.notifyProductInquiries = notifyProductInquiries;
        if (notifyWeeklySummary !== undefined) updateData.notifyWeeklySummary = notifyWeeklySummary;

        // ✅ OPTIMIZED: Use findOneAndUpdate with .select() and indexed businessId:
        const settings = await BusinessSettings.findOneAndUpdate({ businessId }, { $set: updateData }, {
            new: true, // Return updated document
            upsert: true, // Create if doesn't exist
            setDefaultsOnInsert: true, // Set defaults on insert
            lean: true, // ✅ OPTIMIZED: Return plain object
            select: 'businessId publicProfile showProductsPublicly privateAnalytics notifyProfileViews notifyProductInquiries notifyWeeklySummary'
        });

        console.log('✅ Settings updated successfully');

        res.status(200).json({
            status: 'success',
            data: {
                businessId: settings.businessId,
                publicProfile: settings.publicProfile,
                showProductsPublicly: settings.showProductsPublicly,
                privateAnalytics: settings.privateAnalytics,
                notifyProfileViews: settings.notifyProfileViews,
                notifyProductInquiries: settings.notifyProductInquiries,
                notifyWeeklySummary: settings.notifyWeeklySummary
            },
            message: 'Settings updated successfully'
        });

    } catch (error) {
        console.error('❌ Error updating settings:', error);
        res.status(500).json({
            status: 'error',
            message: 'Failed to update settings',
            error: error.message
        });
    }
});

/**
 * Helper function to get settings with caching
 * Can be used by other routes that need to check settings
 */
async function getBusinessSettings(businessId) {
    try {
        let settings = await BusinessSettings.findOne({ businessId }).select('businessId publicProfile showProductsPublicly privateAnalytics notifyProfileViews notifyProductInquiries notifyWeeklySummary').lean().maxTimeMS(500); // ✅ OPTIMIZED

        if (!settings) {
            // Return defaults if not found
            return {
                businessId,
                publicProfile: true,
                showProductsPublicly: true,
                privateAnalytics: false,
                notifyProfileViews: true,
                notifyProductInquiries: true,
                notifyWeeklySummary: true
            };
        }

        return {
            businessId: settings.businessId,
            publicProfile: settings.publicProfile,
            showProductsPublicly: settings.showProductsPublicly,
            privateAnalytics: settings.privateAnalytics,
            notifyProfileViews: settings.notifyProfileViews,
            notifyProductInquiries: settings.notifyProductInquiries,
            notifyWeeklySummary: settings.notifyWeeklySummary
        };
    } catch (error) {
        console.error('Error getting business settings:', error);
        // Return defaults on error
        return {
            businessId,
            publicProfile: true,
            showProductsPublicly: true,
            privateAnalytics: false,
            notifyProfileViews: true,
            notifyProductInquiries: true,
            notifyWeeklySummary: true
        };
    }
}

// Export router and helper function
module.exports = router;
module.exports.getBusinessSettings = getBusinessSettings;
module.exports.BusinessSettings = BusinessSettings;