const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const MemberDetails = require('../models/MemberDetails');
const Connection = require('../models/Connection');
const Notification = require('../models/Notification');
const MemberBusinessInfo = require('../models/MemberBusinessInfo');

// GET /api/browse-members - Get all approved members with completed payment
router.get('/', async (req, res) => {
  try {
    const { state, district, block, search, page = 1, limit = 10, exclude_user_id } = req.query;
    
    console.log('\n🔍 === BROWSE MEMBERS REQUEST ===');
    console.log('Query params:', { state, district, block, search, page, limit, exclude_user_id });
    
    // Build query for approved and payment completed members
    const query = {
      approvedBy: { $ne: null }, // Must be approved by someone (state admin)
      membershipStatus: 'active', // Must have active membership (payment completed)
      profileCompleted: true // Profile must be completed
    };
    
    // Exclude current user from results
    if (exclude_user_id) {
      // Convert string to ObjectId for proper MongoDB comparison
      query._id = { $ne: new mongoose.Types.ObjectId(exclude_user_id) };
      console.log('🚫 Excluding current user:', exclude_user_id);
    }
    
    // Add location filters if provided
    if (state) query.state = new RegExp(state, 'i');
    if (district) query.district = new RegExp(district, 'i');
    if (block) query.block = new RegExp(block, 'i');
    
    // Search by name if provided
    if (search) {
      query.fullName = new RegExp(search, 'i');
    }

    const skip = (page - 1) * limit;
    
    console.log('📋 Database Query:', JSON.stringify(query, null, 2));
    console.log('🔍 Filtering Criteria:');
    console.log('   ✓ approvedBy != null (approved by state admin)');
    console.log('   ✓ membershipStatus = "active" (payment completed)');
    console.log('   ✓ profileCompleted = true');
    
    // Get approved members with active membership
    const members = await MemberDetails.find(query)
      .select('fullName email phoneNumber gender state district block city profileCompleted approvedBy approvedAt membershipType membershipStatus')
      .skip(skip)
      .limit(parseInt(limit))
      .sort({ createdAt: -1 });

    console.log(`📊 Database returned: ${members.length} members`);

    if (members.length === 0) {
      console.log('⚠️  No members found matching criteria!');
      console.log('   Possible reasons:');
      console.log('   - No users have been approved (approvedBy is null)');
      console.log('   - No users have active membership (payment not completed)');
      console.log('   - No users have completed profiles');
      console.log('   - Location filters too restrictive');
    } else {
      console.log('✅ Sample member data:');
      members.slice(0, 2).forEach(m => {
        console.log(`   - ${m.fullName}: approved=${!!m.approvedBy}, status=${m.membershipStatus}, profile=${m.profileCompleted}`);
      });
    }

    // Get member IDs
    const memberEmails = members.map(m => m.email);
    
    // Get business info for each member
    const businessInfos = await MemberBusinessInfo.find({
      email: { $in: memberEmails }
    }).select('email organizationName');
    
    // Map business info
    const businessInfoMap = {};
    businessInfos.forEach(bi => {
      businessInfoMap[bi.email] = bi.organizationName;
    });
    
    // Format response with approved and paid members
    const formattedMembers = members.map(member => ({
      id: member._id,
      name: member.fullName,
      email: member.email,
      phone: member.phoneNumber,
      gender: member.gender,
      role: 'Member', // Can be enhanced based on membershipType
      organization: businessInfoMap[member.email] || 'N/A',
      location: {
        state: member.state,
        district: member.district,
        block: member.block,
        city: member.city
      },
      isActive: true,
      profileCompleted: member.profileCompleted,
      approvalStatus: 'approved_by_state_admin',
      paymentStatus: 'completed',
      membershipType: member.membershipType
    }));

    const total = await MemberDetails.countDocuments(query);

    console.log(`✅ Sending response: ${formattedMembers.length} members`);
    console.log('='.repeat(50));

    res.json({
      success: true,
      data: formattedMembers,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(total / limit),
        totalMembers: formattedMembers.length,
        totalCount: total
      }
    });

  } catch (error) {
    console.error('❌ Error fetching browse members:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch members',
      error: error.message
    });
  }
});

// POST /api/browse-members/connect - Send connection request
router.post('/connect', async (req, res) => {
  try {
    const { senderId, recipientId, message } = req.body;

    if (!senderId || !recipientId) {
      return res.status(400).json({
        success: false,
        message: 'Sender ID and Recipient ID are required'
      });
    }

    // Check if connection already exists
    const existingConnection = await Connection.findOne({
      senderId,
      recipientId
    });

    if (existingConnection) {
      return res.status(400).json({
        success: false,
        message: 'Connection request already exists',
        status: existingConnection.status
      });
    }

    // Create connection request
    const connection = new Connection({
      senderId,
      recipientId,
      message: message || 'Wants to connect with you',
      status: 'pending'
    });

    await connection.save();

    // Get sender details
    const sender = await MemberDetails.findById(senderId)
      .select('fullName email');

    // Create notification for recipient
    const notification = new Notification({
      recipientId,
      senderId,
      type: 'connection_request',
      title: 'New Connection Request',
      message: `${sender.fullName} has requested to connect with you`,
      connectionId: connection._id,
      isRead: false
    });

    await notification.save();

    res.status(201).json({
      success: true,
      message: 'Connection request sent successfully',
      data: {
        connectionId: connection._id,
        status: connection.status
      }
    });

  } catch (error) {
    console.error('Error sending connection request:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to send connection request',
      error: error.message
    });
  }
});

// GET /api/browse-members/connection-status/:senderId/:recipientId
router.get('/connection-status/:senderId/:recipientId', async (req, res) => {
  try {
    const { senderId, recipientId } = req.params;

    const connection = await Connection.findOne({
      senderId,
      recipientId
    }).select('status createdAt');

    if (!connection) {
      return res.json({
        success: true,
        data: {
          hasConnection: false,
          status: null
        }
      });
    }

    res.json({
      success: true,
      data: {
        hasConnection: true,
        status: connection.status,
        requestedAt: connection.createdAt
      }
    });

  } catch (error) {
    console.error('Error checking connection status:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to check connection status',
      error: error.message
    });
  }
});

// PUT /api/browse-members/connection/:connectionId/respond
router.put('/connection/:connectionId/respond', async (req, res) => {
  try {
    const { connectionId } = req.params;
    const { action } = req.body; // 'accept' or 'decline'

    if (!['accept', 'decline'].includes(action)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid action. Must be "accept" or "decline"'
      });
    }

    const connection = await Connection.findById(connectionId);

    if (!connection) {
      return res.status(404).json({
        success: false,
        message: 'Connection request not found'
      });
    }

    if (connection.status !== 'pending') {
      return res.status(400).json({
        success: false,
        message: `Connection request already ${connection.status}`
      });
    }

    // Update connection status
    connection.status = action === 'accept' ? 'accepted' : 'declined';
    connection.updatedAt = Date.now();
    await connection.save();

    // Get recipient (who is responding) details
    const recipient = await MemberDetails.findById(connection.recipientId)
      .select('fullName email');

    // Create notification for sender
    const notificationType = action === 'accept' ? 'connection_accepted' : 'connection_declined';
    const notificationMessage = action === 'accept' 
      ? `${recipient.fullName} accepted your connection request`
      : `${recipient.fullName} declined your connection request`;

    const notification = new Notification({
      recipientId: connection.senderId,
      senderId: connection.recipientId,
      type: notificationType,
      title: action === 'accept' ? 'Connection Accepted' : 'Connection Declined',
      message: notificationMessage,
      connectionId: connection._id,
      isRead: false
    });

    await notification.save();

    res.json({
      success: true,
      message: `Connection request ${action === 'accept' ? 'accepted' : 'declined'} successfully`,
      data: {
        connectionId: connection._id,
        status: connection.status
      }
    });

  } catch (error) {
    console.error('Error responding to connection request:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to respond to connection request',
      error: error.message
    });
  }
});

// GET /api/browse-members/notifications/:memberId
router.get('/notifications/:memberId', async (req, res) => {
  try {
    const { memberId } = req.params;
    const { page = 1, limit = 20, unreadOnly = false } = req.query;

    const query = { recipientId: memberId };
    if (unreadOnly === 'true') {
      query.isRead = false;
    }

    const skip = (page - 1) * limit;

    const notifications = await Notification.find(query)
      .populate('senderId', 'fullName email phoneNumber')
      .populate('connectionId', 'status message')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Notification.countDocuments(query);
    const unreadCount = await Notification.countDocuments({ 
      recipientId: memberId, 
      isRead: false 
    });

    res.json({
      success: true,
      data: notifications,
      unreadCount,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(total / limit),
        total
      }
    });

  } catch (error) {
    console.error('Error fetching notifications:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch notifications',
      error: error.message
    });
  }
});

// PUT /api/browse-members/notifications/:notificationId/read
router.put('/notifications/:notificationId/read', async (req, res) => {
  try {
    const { notificationId } = req.params;

    const notification = await Notification.findByIdAndUpdate(
      notificationId,
      { isRead: true },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    res.json({
      success: true,
      message: 'Notification marked as read',
      data: notification
    });

  } catch (error) {
    console.error('Error marking notification as read:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to mark notification as read',
      error: error.message
    });
  }
});

module.exports = router;
