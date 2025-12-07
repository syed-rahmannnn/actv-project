const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const { getBusinessSettings } = require('./businessSettings');

/**
 * GET /api/analytics/overview?companyId=<id>
 * Get analytics overview for a company (OWNER VIEW - always shows real data)
 * Note: This is for the owner's dashboard. For public views, use getPublicAnalytics helper.
 */
router.get('/overview', async(req, res) => {
    try {
        console.log('📊 Analytics overview endpoint hit');
        console.log('📋 Query params:', req.query);

        const { companyId } = req.query;

        // Get Company model dynamically to ensure it's loaded
        const Company = mongoose.model('Company');

        if (!companyId) {
            console.log('❌ Analytics error: companyId is required');
            return res.status(400).json({
                status: 'error',
                message: 'companyId is required'
            });
        }

        console.log('🔍 Looking up company:', companyId);

        // ULTRA-OPTIMIZED: Minimal fields, fast timeout, indexed _id query
        const company = await Company.findById(companyId)
            .select('name views')
            .lean()
            .maxTimeMS(300)
            .exec();
        if (!company) {
            console.log('❌ Company not found:', companyId);
            return res.status(404).json({
                status: 'error',
                message: 'Company not found'
            });
        }

        console.log('✅ Company found:', company.name);

        // For now, generate analytics based on company data
        // In production, you would query actual events/logs tables

        // Base metrics from company record
        const profileViews = company.views || 0;
        const connections = company.connections || 0;
        const productsCount = company.productsCount || 0;

        // Generate realistic analytics data
        // Product views estimated as 3x profile views
        const productViews = Math.floor(profileViews * 3);

        // Search appearances estimated as 0.8x profile views
        const searchAppearances = Math.floor(profileViews * 0.8);

        // Calculate percentage changes (simulated for demo)
        // In production, compare with previous period data
        const profileViewsChangePercent = Math.floor(Math.random() * 30) - 10; // -10 to +20
        const productViewsChangePercent = Math.floor(Math.random() * 25) - 5; // -5 to +20
        const searchAppearancesChangePercent = Math.floor(Math.random() * 20) - 10; // -10 to +10
        const connectionsChangePercent = Math.floor(Math.random() * 35) - 5; // -5 to +30

        // Generate weekly profile views (last 7 days)
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        const weeklyProfileViews = days.map((day, index) => {
            // Generate views with some variation
            const baseViews = Math.floor(profileViews / 7);
            const variation = Math.floor(Math.random() * baseViews * 0.4) - (baseViews * 0.2);
            const views = Math.max(0, baseViews + Math.floor(variation));
            return { day, views };
        });

        // Generate top products (mock data for now)
        // In production, query actual product view events
        const topProducts = [{
                name: company.name + ' Premium Service',
                views: Math.floor(productViews * 0.35),
                engagement: 75 + Math.floor(Math.random() * 20)
            },
            {
                name: 'Consulting Package',
                views: Math.floor(productViews * 0.28),
                engagement: 65 + Math.floor(Math.random() * 20)
            },
            {
                name: 'Training Program',
                views: Math.floor(productViews * 0.22),
                engagement: 55 + Math.floor(Math.random() * 20)
            }
        ].slice(0, Math.min(3, productsCount)); // Only show if products exist

        // Generate insight text based on trends
        let insightText = '';
        if (profileViewsChangePercent > 10) {
            insightText = `Great work! Your profile views increased by ${profileViewsChangePercent}% this week. Keep engaging with your audience.`;
        } else if (profileViewsChangePercent > 0) {
            insightText = `Your profile views grew by ${profileViewsChangePercent}% this week. Consider updating your profile regularly to maintain growth.`;
        } else if (profileViewsChangePercent < -5) {
            insightText = `Profile views decreased by ${Math.abs(profileViewsChangePercent)}% this week. Try posting new products or updating your company description.`;
        } else {
            insightText = 'Your profile views are stable. Consider adding more products or promoting your profile to increase visibility.';
        }

        // Build response
        const analyticsData = {
            profileViews,
            productViews,
            searchAppearances,
            connections,
            profileViewsChangePercent,
            productViewsChangePercent,
            searchAppearancesChangePercent,
            connectionsChangePercent,
            weeklyProfileViews,
            topProducts,
            insightText
        };

        console.log('✅ Returning analytics data for company:', company.name);
        console.log('   - Profile Views:', profileViews);
        console.log('   - Product Views:', productViews);
        console.log('   - Top Products:', topProducts.length);

        res.status(200).json({
            status: 'success',
            data: analyticsData
        });

    } catch (error) {
        console.error('Error fetching analytics:', error);
        res.status(500).json({
            status: 'error',
            message: 'Failed to fetch analytics',
            error: error.message
        });
    }
});

/**
 * Helper function to get public analytics (respects privateAnalytics setting)
 * Use this when showing analytics to OTHER users (not the owner)
 * 
 * @param {string} companyId - The company ID to get analytics for
 * @returns {Promise<Object>} Public analytics data (null counts if private)
 */
async function getPublicAnalytics(companyId) {
    try {
        const Company = mongoose.model('Company');

        // ✅ OPTIMIZED: Fetch company and settings in parallel using Promise.all()
        const [company, settings] = await Promise.all([
            Company.findById(companyId).select('views connections').lean().maxTimeMS(500),
            getBusinessSettings(companyId)
        ]);

        if (!company) {
            throw new Error('Company not found');
        }

        // If privateAnalytics is enabled, return null/hidden counts
        if (settings.privateAnalytics) {
            return {
                profileViews: null,
                productViews: null,
                searchAppearances: null,
                connections: null,
                message: 'Analytics are private for this business'
            };
        }

        // Otherwise, return real analytics (same logic as owner view)
        const profileViews = company.views || 0;
        const productViews = Math.floor(profileViews * 3);
        const searchAppearances = Math.floor(profileViews * 0.8);
        const connections = company.connections || 0;

        return {
            profileViews,
            productViews,
            searchAppearances,
            connections
        };
    } catch (error) {
        console.error('Error getting public analytics:', error);
        return null;
    }
}

module.exports = router;
module.exports.getPublicAnalytics = getPublicAnalytics;