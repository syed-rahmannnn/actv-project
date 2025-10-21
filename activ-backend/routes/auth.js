const express = require('express');
const jwt = require('jsonwebtoken');
const MemberDetails = require('../models/MemberDetails');
const MemberAuth = require('../models/MemberAuth');

const router = express.Router();

// Login endpoint
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required'
      });
    }

    // Check if member exists
    const member = await MemberDetails.findOne({ email: email.toLowerCase() });
    if (!member) {
      return res.status(404).json({
        success: false,
        message: 'Member not found'
      });
    }

    // Check authentication
    const memberAuth = await MemberAuth.findOne({ email: email.toLowerCase() });
    if (!memberAuth || !memberAuth.isActive) {
      return res.status(403).json({
        success: false,
        message: 'Account is inactive or not found'
      });
    }

    // Verify password
    const isPasswordValid = await memberAuth.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid password'
      });
    }

    // Update last login
    await memberAuth.updateLastLogin();

    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: member._id, 
        email: member.email 
      },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    return res.status(200).json({
      success: true,
      message: 'Login successful',
      data: {
        token: token,
        member: {
          id: member._id,
          fullName: member.fullName,
          email: member.email,
          phoneNumber: member.phoneNumber,
          dateOfBirth: member.dateOfBirth,
          gender: member.gender,
          state: member.state,
          district: member.district,
          block: member.block,
          city: member.city,
          profileCompleted: member.profileCompleted
        }
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// Register new member
router.post('/register', async (req, res) => {
  try {
    const {
      fullName,
      phoneNumber,
      email,
      dateOfBirth,
      gender,
      password,
      block,
      city,
      district,
      state,
      pincode,
      profilePicture,
      memberType
    } = req.body;

    // Validate required fields
    if (!fullName || !phoneNumber || !email || !dateOfBirth || !gender || !password || !city || !block || !district || !state) {
      return res.status(400).json({
        success: false,
        message: 'All required fields must be provided'
      });
    }

    // Check if member already exists
    const existingMember = await MemberDetails.findOne({ email: email.toLowerCase() });
    if (existingMember) {
      return res.status(409).json({
        success: false,
        message: 'Member with this email already exists'
      });
    }

    // Create member details
    const memberDetails = new MemberDetails({
      fullName,
      email: email.toLowerCase(),
      phoneNumber,
      dateOfBirth,
      gender,
      state,
      district,
      block,
      city
    });

    await memberDetails.save();

    // Create member auth
    const memberAuth = new MemberAuth({
      email: email.toLowerCase(),
      password
    });

    await memberAuth.save();

    // Generate JWT token
    const token = jwt.sign(
      { 
        userId: memberDetails._id, 
        email: memberDetails.email 
      },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    return res.status(201).json({
      success: true,
      message: 'Member registered successfully',
      data: {
        token: token,
        member: {
          id: memberDetails._id,
          fullName: memberDetails.fullName,
          email: memberDetails.email,
          phoneNumber: memberDetails.phoneNumber,
          dateOfBirth: memberDetails.dateOfBirth,
          gender: memberDetails.gender,
          state: memberDetails.state,
          district: memberDetails.district,
          block: memberDetails.block,
          city: memberDetails.city,
          profileCompleted: memberDetails.profileCompleted
        }
      }
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// Get member by ID
router.get('/member/:memberId', async (req, res) => {
  try {
    const { memberId } = req.params;

    const member = await MemberDetails.findById(memberId);

    if (!member) {
      return res.status(404).json({
        success: false,
        message: 'Member not found'
      });
    }

    return res.status(200).json({
      success: true,
      data: {
        member: {
          id: member._id,
          fullName: member.fullName,
          email: member.email,
          phoneNumber: member.phoneNumber,
          dateOfBirth: member.dateOfBirth,
          gender: member.gender,
          state: member.state,
          district: member.district,
          block: member.block,
          city: member.city,
          profileCompleted: member.profileCompleted
        }
      }
    });

  } catch (error) {
    console.error('Get member error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

// Get member by email
router.get('/member-by-email/:email', async (req, res) => {
  try {
    const { email } = req.params;

    const member = await MemberDetails.findOne({ email: email.toLowerCase() });

    if (!member) {
      return res.status(404).json({
        success: false,
        message: 'Member not found'
      });
    }

    return res.status(200).json({
      success: true,
      data: {
        member: {
          id: member._id,
          fullName: member.fullName,
          email: member.email,
          phoneNumber: member.phoneNumber,
          dateOfBirth: member.dateOfBirth,
          gender: member.gender,
          state: member.state,
          district: member.district,
          block: member.block,
          city: member.city,
          profileCompleted: member.profileCompleted
        }
      }
    });

  } catch (error) {
    console.error('Get member by email error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error',
      error: error.message
    });
  }
});

module.exports = router;
