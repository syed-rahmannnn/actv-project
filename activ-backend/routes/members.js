const express = require('express');
const MemberDetails = require('../models/MemberDetails');
const MemberAuth = require('../models/MemberAuth');

const router = express.Router();

// GET by email: /api/members/by-email?email=someone@example.com
router.get('/by-email', async (req, res) => {
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
router.get('/', async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const members = await MemberDetails.find()
      .select('-__v')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await MemberDetails.countDocuments();

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
router.get('/:id', async (req, res) => {
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

// PUT update by id (create if not exists)
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const updates = req.body || {};
    // whitelist allowed fields to avoid accidental overwrite
    const allowed = ['fullName','email','phoneNumber','dateOfBirth','gender','state','district','block','city','profileCompleted',
      // demographic fields moved here
      'aadhaarNumber','streetName','educationalQualification','religion','socialCategory'
    ];
    const payload = {};
    allowed.forEach(k => {
      if (updates[k] !== undefined) payload[k] = updates[k];
    });

    const doc = await MemberDetails.findByIdAndUpdate(id, payload, { new: true, upsert: true, runValidators: true });
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
router.post('/', async (req, res) => {
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
router.delete('/:id', async (req, res) => {
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
router.get('/search/:query', async (req, res) => {
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

module.exports = router;
