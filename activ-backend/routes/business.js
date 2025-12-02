const express = require('express');
const MemberBusinessInfo = require('../models/MemberBusinessInfo');
const router = express.Router();

// Get business metrics
router.get('/metrics', async (req, res) => {
  try {
    const { businessId } = req.query;

    if (!businessId) {
      return res.status(400).json({
        success: false,
        message: 'Business ID is required'
      });
    }

    // For now, return mock data
    // TODO: Implement actual metrics tracking in database
    const metrics = {
      profileViews: 0,
      profileViewsChangePercent: 0,
      productsCount: 0,
      featuredProductsCount: 0
    };

    res.status(200).json({
      success: true,
      data: metrics
    });

  } catch (error) {
    console.error('Get business metrics error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// Get business associations
router.get('/associations', async (req, res) => {
  try {
    const { businessId } = req.query;

    if (!businessId) {
      return res.status(400).json({
        success: false,
        message: 'Business ID is required'
      });
    }

    // For now, return empty array
    // TODO: Implement associations in database
    const associations = [];

    res.status(200).json({
      success: true,
      data: associations
    });

  } catch (error) {
    console.error('Get business associations error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// Get all companies for a member
router.get('/companies', async (req, res) => {
  try {
    const { memberId } = req.query;

    if (!memberId) {
      return res.status(400).json({
        success: false,
        message: 'Member ID is required'
      });
    }

    // Fetch all business profiles for this member
    // For now, we return the single business profile as an array
    // In the future, if you support multiple companies per member, adjust the query
    const companies = await MemberBusinessInfo.find({ memberId: memberId });

    // Map to frontend-friendly format
    const companiesData = companies.map(company => ({
      _id: company._id,
      organizationName: company.organizationName,
      businessType: company.businessType,
      mobile: company.mobile,
      status: company.status || 'ACTIVE'
    }));

    res.status(200).json({
      success: true,
      data: companiesData
    });

  } catch (error) {
    console.error('Get member companies error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// Save/update business profile
router.post('/profile', async (req, res) => {
  try {
    const { 
      businessId, 
      memberId,
      name,
      tagline,
      description,
      industry,
      city,
      location,
      logoUrl,
      website 
    } = req.body;

    if (!memberId) {
      return res.status(400).json({
        success: false,
        message: 'Member ID is required'
      });
    }

    // Map frontend fields to backend schema
    const businessData = {
      organizationName: name,
      businessType: industry,
      businessDescription: description,
      location: location || city,
      businessWebsite: website,
      logoUrl: logoUrl
    };

    // Update or create business info using profile route
    const businessInfo = await MemberBusinessInfo.findOneAndUpdate(
      { memberId: memberId },
      {
        ...businessData,
        memberId: memberId
      },
      { 
        upsert: true, 
        new: true, 
        runValidators: true 
      }
    );

    res.status(200).json({
      success: true,
      message: 'Business profile saved successfully',
      data: { businessInfo }
    });

  } catch (error) {
    console.error('Save business profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

module.exports = router;
