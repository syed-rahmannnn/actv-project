const express = require('express');
const router = express.Router();
const MemberDetails = require('../models/MemberDetails');
const MemberBusinessInfo = require('../models/MemberBusinessInfo');
const MemberFinancialInfo = require('../models/MemberFinancialInfo');
const MemberDeclaration = require('../models/MemberDeclaration');

// GET member details by identifier (email or memberId)
router.get('/:identifier/details', async (req, res) => {
  try {
    const { identifier } = req.params;
    const decodedIdentifier = decodeURIComponent(identifier).toLowerCase();

    // Debug logging
    console.log('\n=== MEMBER DETAILS API CALLED ===');
    console.log('Requested identifier:', decodedIdentifier);
    console.log('Identifier type:', typeof decodedIdentifier);

    // Determine if identifier is email (contains @) or memberId
    let personalDetails, businessInfo, financialInfo, declaration;
    
    if (decodedIdentifier.includes('@')) {
      // Query by email
      console.log('🔍 Querying by EMAIL');
      personalDetails = await MemberDetails.findOne({ email: decodedIdentifier });
      businessInfo = await MemberBusinessInfo.findOne({ email: decodedIdentifier });
      financialInfo = await MemberFinancialInfo.findOne({ email: decodedIdentifier });
      declaration = await MemberDeclaration.findOne({ email: decodedIdentifier });
    } else {
      // Query by memberId (ObjectId)
      console.log('🔍 Querying by MEMBER ID');
      try {
        const mongoose = require('mongoose');
        const objectId = new mongoose.Types.ObjectId(decodedIdentifier);
        
        personalDetails = await MemberDetails.findById(objectId);
        businessInfo = await MemberBusinessInfo.findOne({ memberId: objectId });
        financialInfo = await MemberFinancialInfo.findOne({ memberId: objectId });
        declaration = await MemberDeclaration.findOne({ memberId: objectId });
      } catch (err) {
        console.log('⚠️ Invalid ObjectId format, trying as string');
        // Fallback: try as string
        personalDetails = await MemberDetails.findOne({ _id: decodedIdentifier });
        businessInfo = await MemberBusinessInfo.findOne({ memberId: decodedIdentifier });
        financialInfo = await MemberFinancialInfo.findOne({ memberId: decodedIdentifier });
        declaration = await MemberDeclaration.findOne({ memberId: decodedIdentifier });
      }
    }

    console.log('Query results:');
    console.log('- personalDetails:', personalDetails ? 'FOUND ✅' : 'NOT FOUND ❌');
    console.log('- businessInfo:', businessInfo ? 'FOUND ✅' : 'NOT FOUND ❌');
    console.log('- financialInfo:', financialInfo ? 'FOUND ✅' : 'NOT FOUND ❌');
    console.log('- declaration:', declaration ? 'FOUND ✅' : 'NOT FOUND ❌');

    // If no data found for this user
    if (!personalDetails && !businessInfo && !financialInfo && !declaration) {
      console.log('❌ No data found for identifier:', decodedIdentifier);
      return res.status(404).json({
        success: false,
        message: 'No member details found for this identifier'
      });
    }

    // Construct the response
    const memberData = {
      personal_and_demographic_details: personalDetails ? {
        full_name: personalDetails.fullName || '',
        date_of_birth: personalDetails.dateOfBirth || '',
        gender: personalDetails.gender || '',
        email: personalDetails.email || '',
        phone: personalDetails.phoneNumber || '',
        address: personalDetails.streetName || '',
        state: personalDetails.state || '',
        district: personalDetails.district || '',
        block: personalDetails.block || '',
        city: personalDetails.city || '',
        aadhar_number: personalDetails.aadhaarNumber || '',
        category: personalDetails.socialCategory || '',
        education: personalDetails.educationalQualification || '',
        religion: personalDetails.religion || '',
      } : {},
      
      business_information: businessInfo ? {
        doing_business: businessInfo.doingBusiness || false,
        organization_name: businessInfo.organizationName || '',
        constitution_type: businessInfo.constitutionType || '',
        business_type: businessInfo.businessType || '',
        activities: businessInfo.businessActivities || '',
        commencement_year: businessInfo.businessCommencementYear || '',
        employee_count: businessInfo.numberOfEmployees || '',
        chamber_membership: businessInfo.memberOfOtherChamber || false,
        chamber_details: businessInfo.otherChamber || '',
        govt_registrations: businessInfo.registeredWithGovtOrganization || [],
      } : {},
      
      financial_and_compliance: financialInfo ? {
        pan_number: financialInfo.panNumber || '',
        gst_number: financialInfo.gstNumber || '',
        udyam_number: financialInfo.udyamNumber || '',
        it_returns_filed: financialInfo.filedITR || false,
        itr_years: financialInfo.itrYears || '',
        turnover_range: financialInfo.turnoverRange || '',
        turnover_last_3_years: {
          fy2021: financialInfo.fy2021 || '',
          fy2020: financialInfo.fy2020 || '',
          fy2019: financialInfo.fy2019 || ''
        },
        govt_schemes_benefitted: financialInfo.govtSchemeBenefit || false,
        govt_scheme_list: [
          financialInfo.scheme1 || '',
          financialInfo.scheme2 || '',
          financialInfo.scheme3 || ''
        ].filter(s => s !== ''),
      } : {},
      
      declaration: declaration ? {
        sister_concerns_count: declaration.sisterConcerns || 0,
        company_names: declaration.companyNames || [],
        confirmation: declaration.agreeToDeclaration || false,
      } : {}
    };

    res.status(200).json({
      success: true,
      data: memberData
    });

  } catch (error) {
    console.error('Error fetching member details:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while fetching member details',
      error: error.message
    });
  }
});

// PUT update member details by identifier (email or memberId)
router.put('/:identifier/details', async (req, res) => {
  try {
    const { identifier } = req.params;
    const decodedIdentifier = decodeURIComponent(identifier).toLowerCase();
    const {
      personal_and_demographic_details,
      business_information,
      financial_and_compliance,
      declaration
    } = req.body;

    console.log('\n=== UPDATE MEMBER DETAILS API CALLED ===');
    console.log('Identifier:', decodedIdentifier);

    // Determine query criteria based on identifier type
    let queryCriteria;
    if (decodedIdentifier.includes('@')) {
      queryCriteria = { email: decodedIdentifier };
      console.log('Updating by EMAIL');
    } else {
      try {
        const mongoose = require('mongoose');
        const objectId = new mongoose.Types.ObjectId(decodedIdentifier);
        queryCriteria = { _id: objectId };
        console.log('Updating by MEMBER ID');
      } catch (err) {
        queryCriteria = { _id: decodedIdentifier };
      }
    }

    // Update each section if provided
    if (personal_and_demographic_details) {
      await MemberDetails.findOneAndUpdate(
        queryCriteria,
        personal_and_demographic_details,
        { new: true }
      );
    }

    if (business_information) {
      await MemberBusinessInfo.findOneAndUpdate(
        decodedIdentifier.includes('@') ? { email: decodedIdentifier } : { memberId: queryCriteria._id },
        business_information,
        { new: true }
      );
    }

    if (financial_and_compliance) {
      await MemberFinancialInfo.findOneAndUpdate(
        decodedIdentifier.includes('@') ? { email: decodedIdentifier } : { memberId: queryCriteria._id },
        financial_and_compliance,
        { new: true }
      );
    }

    if (declaration) {
      await MemberDeclaration.findOneAndUpdate(
        decodedIdentifier.includes('@') ? { email: decodedIdentifier } : { memberId: queryCriteria._id },
        declaration,
        { new: true }
      );
    }

    console.log('✅ Member details updated successfully');
    res.status(200).json({
      success: true,
      message: 'Member details updated successfully'
    });

  } catch (error) {
    console.error('❌ Error updating member details:', error);
    res.status(500).json({
      success: false,
      message: 'Server error while updating member details',
      error: error.message
    });
  }
});

module.exports = router;
