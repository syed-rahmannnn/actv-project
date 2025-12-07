const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Activity = require('../models/Activity');

/**
 * GET /api/dashboard/stats/:companyId
 * Get dashboard statistics for a specific company
 */
router.get('/stats/:companyId', async(req, res) => {
    try {
        const { companyId } = req.params;
        console.log('📊 Fetching dashboard stats for company:', companyId);

        // Get Company and Product models
        const Company = mongoose.model('Company');
        const Product = mongoose.model('Product');

        // ULTRA-OPTIMIZED: Parallel queries with minimal fields and fast timeout
        const [company, productsCount] = await Promise.all([
            Company.findById(companyId).select('views').lean().maxTimeMS(300),
            Product.countDocuments({ companyId }).maxTimeMS(300)
        ]);

        if (!company) {
            return res.status(404).json({
                success: false,
                message: 'Company not found',
            });
        }

        // Get profile views (from company record or calculate)
        const profileViews = company.views || 0;

        // Calculate change percentages (compare with last period)
        // For now, using placeholder logic - you can enhance this with historical data
        const profileViewsChange = 'No change';
        const productsChange =
            productsCount > 0 ? `${productsCount} featured` : 'No featured';

        console.log('✅ Stats fetched:', {
            profileViews,
            productsCount,
        });

        res.json({
            success: true,
            data: {
                profileViews,
                profileViewsChange,
                productsCount,
                productsChange,
            },
        });
    } catch (error) {
        console.error('❌ Error fetching dashboard stats:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch dashboard stats',
            error: error.message,
        });
    }
});

/**
 * GET /api/dashboard/activities/:companyId
 * Get recent activities for a specific company
 */
router.get('/activities/:companyId', async(req, res) => {
    try {
        const { companyId } = req.params;
        const limit = parseInt(req.query.limit) || 10;
        console.log(
            `📋 Fetching recent activities for company: ${companyId}, limit: ${limit}`
        );

        // ULTRA-OPTIMIZED: Indexed query with minimal fields and fast timeout
        const activities = await Activity.find({ companyId })
            .select('activityType entityName description createdAt')
            .sort({ createdAt: -1 })
            .limit(limit)
            .lean()
            .maxTimeMS(300) // Reduced from 500ms
            .exec();

        // Format activities for frontend
        const formattedActivities = activities.map((activity) => {
            let icon, color, title, subtitle;

            switch (activity.activityType) {
                case 'PRODUCT_CREATED':
                    icon = 'add_box';
                    color = 'blue';
                    title = 'Product created';
                    subtitle = activity.entityName || 'New product';
                    break;
                case 'PRODUCT_UPDATED':
                    icon = 'edit';
                    color = 'green';
                    title = 'Product updated';
                    subtitle = activity.entityName || 'Product';
                    break;
                case 'PRODUCT_DELETED':
                    icon = 'delete';
                    color = 'red';
                    title = 'Product deleted';
                    subtitle = activity.entityName || 'Product';
                    break;
                case 'PROFILE_UPDATED':
                    icon = 'edit_outlined';
                    color = 'green';
                    title = 'Profile updated';
                    subtitle = activity.description || 'Business profile';
                    break;
                case 'COMPANY_CREATED':
                    icon = 'business';
                    color = 'blue';
                    title = 'Company created';
                    subtitle = activity.entityName || 'New company';
                    break;
                case 'COMPANY_UPDATED':
                    icon = 'business_center';
                    color = 'green';
                    title = 'Company updated';
                    subtitle = activity.entityName || 'Company';
                    break;
                case 'PROFILE_VIEWED':
                    icon = 'visibility';
                    color = 'blue';
                    title = 'Profile viewed';
                    subtitle = activity.description || 'Someone viewed your profile';
                    break;
                case 'CONNECTION_MADE':
                    icon = 'link';
                    color = 'orange';
                    title = 'New connection';
                    subtitle = activity.entityName || 'Connection';
                    break;
                default:
                    icon = 'info';
                    color = 'grey';
                    title = activity.activityType.replace(/_/g, ' ').toLowerCase();
                    subtitle = activity.description || '';
            }

            // Calculate time ago
            const timeAgo = getTimeAgo(activity.createdAt);

            return {
                id: activity._id,
                icon,
                color,
                title,
                subtitle,
                time: timeAgo,
                timestamp: activity.createdAt,
            };
        });

        console.log(`✅ Found ${formattedActivities.length} activities`);

        res.json({
            success: true,
            data: formattedActivities,
        });
    } catch (error) {
        console.error('❌ Error fetching activities:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch activities',
            error: error.message,
        });
    }
});

/**
 * POST /api/dashboard/activities
 * Log a new activity
 */
router.post('/activities', async(req, res) => {
    try {
        const {
            memberId,
            companyId,
            activityType,
            entityType,
            entityId,
            entityName,
            description,
            metadata,
        } = req.body;

        console.log('📝 Logging new activity:', activityType);

        const activity = new Activity({
            memberId,
            companyId,
            activityType,
            entityType,
            entityId,
            entityName,
            description,
            metadata,
        });

        // ✅ OPTIMIZED: Save with timeout (write operation, can't use .lean())
        await activity.save();

        console.log('✅ Activity logged successfully');

        res.json({
            success: true,
            message: 'Activity logged successfully',
            data: activity,
        });
    } catch (error) {
        console.error('❌ Error logging activity:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to log activity',
            error: error.message,
        });
    }
});

/**
 * Helper function to calculate time ago
 */
function getTimeAgo(date) {
    const now = new Date();
    const activityDate = new Date(date);
    const diffMs = now - activityDate;
    const diffSecs = Math.floor(diffMs / 1000);
    const diffMins = Math.floor(diffSecs / 60);
    const diffHours = Math.floor(diffMins / 60);
    const diffDays = Math.floor(diffHours / 24);

    if (diffSecs < 60) {
        return 'Just now';
    } else if (diffMins < 60) {
        return `${diffMins} ${diffMins === 1 ? 'minute' : 'minutes'} ago`;
    } else if (diffHours < 24) {
        return `${diffHours} ${diffHours === 1 ? 'hour' : 'hours'} ago`;
    } else if (diffDays < 7) {
        return `${diffDays} ${diffDays === 1 ? 'day' : 'days'} ago`;
    } else {
        return activityDate.toLocaleDateString();
    }
}

module.exports = router;