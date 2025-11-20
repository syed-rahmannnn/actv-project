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
    if (businessInfo) {
      console.log('  - Organization Name:', businessInfo.organizationName || '(empty)');
      console.log('  - Doing Business:', businessInfo.doingBusiness);
      console.log('  - Business Type:', businessInfo.businessType || '(empty)');
      console.log('  - Number of Employees:', businessInfo.numberOfEmployees || '(empty)');
      console.log('  - Govt Registrations:', businessInfo.registeredWithGovtOrganization || '(empty)');
    }
    console.log('- financialInfo:', financialInfo ? 'FOUND ✅' : 'NOT FOUND ❌');
    if (financialInfo) {
      console.log('  - PAN:', financialInfo.panNumber || '(empty)');
      console.log('  - GST:', financialInfo.gstNumber || '(empty)');
      console.log('  - Turnover Range:', financialInfo.turnoverRange || '(empty)');
      console.log('  - FY2021:', financialInfo.fy2021 || '(empty)');
    }
    console.log('- declaration:', declaration ? 'FOUND ✅' : 'NOT FOUND ❌');
    if (declaration) {
      console.log('  - Agree to Declaration:', declaration.agreeToDeclaration);
      console.log('  - Submitted At:', declaration.submittedAt || '(empty)');
    }

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
      _id: personalDetails?._id || null,
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
        number_of_employees: businessInfo.numberOfEmployees || '',
        member_of_other_chamber: businessInfo.memberOfOtherChamber || false,
        other_chamber: businessInfo.otherChamber || '',
        govt_registrations: businessInfo.registeredWithGovtOrganization || [],
      } : {
        doing_business: false,
        organization_name: '',
        constitution_type: '',
        business_type: '',
        activities: '',
        commencement_year: '',
        number_of_employees: '',
        member_of_other_chamber: false,
        other_chamber: '',
        govt_registrations: [],
      },
      
      financial_information: financialInfo ? {
        pan_number: financialInfo.panNumber || '',
        gst_number: financialInfo.gstNumber || '',
        udyam_number: financialInfo.udyamNumber || '',
        filed_itr: financialInfo.filedITR || false,
        itr_years: financialInfo.itrYears || '',
        turnover_range: financialInfo.turnoverRange || '',
        fy_2021: financialInfo.fy2021 || '',
        fy_2020: financialInfo.fy2020 || '',
        fy_2019: financialInfo.fy2019 || '',
        govt_scheme_benefit: financialInfo.govtSchemeBenefit || false,
        scheme_1: financialInfo.scheme1 || '',
        scheme_2: financialInfo.scheme2 || '',
        scheme_3: financialInfo.scheme3 || '',
      } : {},
      
      declaration: declaration ? {
        agree_terms: declaration.agreeToDeclaration || false,
        submitted_at: declaration.submittedAt || null,
      } : {
        agree_terms: false,
        submitted_at: null,
      }
    };

    console.log('📤 Sending member data response');
    console.log(JSON.stringify(memberData, null, 2));

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
