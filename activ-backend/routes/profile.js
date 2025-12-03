const express = require('express');
const mongoose = require('mongoose');
const MemberDetails = require('../models/MemberDetails');
const MemberBusinessInfo = require('../models/MemberBusinessInfo');
const MemberFinancialInfo = require('../models/MemberFinancialInfo');
const MemberDeclaration = require('../models/MemberDeclaration');

const router = express.Router();

// Get complete member profile
router.get('/:memberId', async (req, res) => {
  try {
    const { memberId } = req.params;

    const member = await MemberDetails.findById(memberId);
    if (!member) {
      return res.status(404).json({
        success: false,
        message: 'Member not found'
      });
    }

    const businessInfo = await MemberBusinessInfo.findOne({ memberId: memberId });
    const financialInfo = await MemberFinancialInfo.findOne({ memberId: memberId });
    const declaration = await MemberDeclaration.findOne({ memberId: memberId });

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

// Get business information by member ID
router.get('/business-info/:memberId', async (req, res) => {
  try {
    const { memberId } = req.params;

    console.log('\n' + '='.repeat(80));
    console.log('📥 GET /business-info/:memberId');
    console.log('='.repeat(80));
    console.log('📋 memberId:', memberId);

    // Convert to ObjectId
    let memberObjectId;
    try {
      memberObjectId = new mongoose.Types.ObjectId(memberId);
      console.log('✅ Converted to ObjectId');
    } catch (err) {
      return res.status(400).json({
        success: false,
        message: 'Invalid memberId format'
      });
    }

    const businessInfo = await MemberBusinessInfo.findOne({ memberId: memberObjectId });

    if (!businessInfo) {
      console.log('⚠️  Business information not found');
      console.log('='.repeat(80) + '\n');
      return res.status(404).json({
        success: false,
        message: 'Business information not found'
      });
    }

    console.log('✅ Business info found');
    console.log('📱 Returning business info - mobile:', businessInfo.mobile);
    console.log('🏢 organizationName:', businessInfo.organizationName);
    console.log('='.repeat(80) + '\n');

    res.status(200).json({
      success: true,
      data: { businessInfo }
    });

  } catch (error) {
    console.error('Get business info error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// Save business information
router.post('/business-info', async (req, res) => {
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

    // Check if member exists
    const member = await MemberDetails.findById(memberObjectId);
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
      ...common,      // Add common fields first
      ...payload,     // Then business data (this can override common if needed)
      memberId: memberObjectId  // Use ObjectId
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
    const businessInfo = await MemberBusinessInfo.findOneAndUpdate(
      { memberId: memberObjectId },
      { $set: updateData },
      { 
        upsert: true, 
        new: true, 
        runValidators: true 
      }
    );

    console.log('✅ Business info saved to DB');
    console.log('📱 Saved mobile number:', businessInfo.mobile);
    console.log('🏢 Saved organization name:', businessInfo.organizationName);
    console.log('📊 FULL DOCUMENT AFTER SAVE:');
    console.log(JSON.stringify(businessInfo, null, 2));
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
router.post('/financial-info', async (req, res) => {
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
      'panNumber','gstNumber','udyamNumber','filedITR','itrYears','turnoverRange',
      'fy2021','fy2020','fy2019','govtSchemeBenefit','scheme1','scheme2','scheme3'
    ];
    const payload = {};
    allowed.forEach(k => { if (financialData[k] !== undefined) payload[k] = financialData[k]; });

    // Update or create financial info
    const financialInfo = await MemberFinancialInfo.findOneAndUpdate(
      { memberId: memberId },
      {
        ...payload,
        ...common,
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
router.post('/declaration', async (req, res) => {
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
    const allowed = ['sisterConcerns','companyNames','showOneFieldPerName','agreeToDeclaration','profileCompleted','submissionDate'];
    const payload = {};
    allowed.forEach(k => { if (declarationData[k] !== undefined) payload[k] = declarationData[k]; });

    // Update or create declaration
    const declaration = await MemberDeclaration.findOneAndUpdate(
      { memberId: memberId },
      {
        ...payload,
        ...common,
        memberId: memberId
      },
      { 
        upsert: true, 
        new: true, 
        runValidators: true 
      }
    );

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
router.put('/complete-profile/:memberId', async (req, res) => {
  try {
    const { memberId } = req.params;

    const member = await MemberDetails.findByIdAndUpdate(
      memberId,
      { profileCompleted: true },
      { new: true }
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
