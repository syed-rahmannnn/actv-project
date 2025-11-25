const express = require('express');
const router = express.Router();
const mongoose = require('mongoose');
const Notification = require('../models/Notification');
const MemberDetails = require('../models/MemberDetails');

// GET /api/notifications/:userId - Get all notifications for a user
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { page = 1, limit = 20, unreadOnly = false } = req.query;

    console.log('\n📬 === FETCHING NOTIFICATIONS ===');
    console.log('User ID:', userId);
    console.log('Page:', page, 'Limit:', limit, 'Unread Only:', unreadOnly);

    // Build query
    const query = {
      recipientId: new mongoose.Types.ObjectId(userId)
    };

    if (unreadOnly === 'true') {
      query.isRead = false;
    }

    const skip = (page - 1) * limit;

    // Fetch notifications with sender details
    const notifications = await Notification.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .lean();

    // Get sender details for each notification
    const senderIds = [...new Set(notifications.map(n => n.senderId))];
    const senders = await MemberDetails.find({
      _id: { $in: senderIds }
    }).select('fullName email profilePicture');

    // Map sender details
    const senderMap = {};
    senders.forEach(sender => {
      senderMap[sender._id.toString()] = {
        id: sender._id.toString(),
        name: sender.fullName,
        email: sender.email,
        profilePicture: sender.profilePicture
      };
    });

    // Format notifications
    const formattedNotifications = notifications.map(notification => ({
      id: notification._id,
      type: notification.type,
      title: notification.title,
      message: notification.message,
      senderId: notification.senderId.toString(),
      sender: senderMap[notification.senderId.toString()],
      connectionId: notification.connectionId,
      isRead: notification.isRead,
      createdAt: notification.createdAt,
      timeAgo: getTimeAgo(notification.createdAt)
    }));

    // Get total count
    const totalCount = await Notification.countDocuments(query);
    const unreadCount = await Notification.countDocuments({
      recipientId: new mongoose.Types.ObjectId(userId),
      isRead: false
    });

    console.log(`✅ Found ${formattedNotifications.length} notifications (${unreadCount} unread)`);

    res.json({
      success: true,
      data: formattedNotifications,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(totalCount / limit),
        totalNotifications: totalCount,
        unreadCount
      }
    });

  } catch (error) {
    console.error('❌ Error fetching notifications:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch notifications',
      error: error.message
    });
  }
});

// PUT /api/notifications/:notificationId/read - Mark notification as read
router.put('/:notificationId/read', async (req, res) => {
  try {
    const { notificationId } = req.params;

    console.log('\n✅ Marking notification as read:', notificationId);

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
    console.error('❌ Error marking notification as read:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to mark notification as read',
      error: error.message
    });
  }
});

// PUT /api/notifications/:userId/read-all - Mark all notifications as read
router.put('/:userId/read-all', async (req, res) => {
  try {
    const { userId } = req.params;

    console.log('\n✅ Marking all notifications as read for user:', userId);

    const result = await Notification.updateMany(
      { recipientId: new mongoose.Types.ObjectId(userId), isRead: false },
      { isRead: true }
    );

    res.json({
      success: true,
      message: 'All notifications marked as read',
      data: {
        modifiedCount: result.modifiedCount
      }
    });

  } catch (error) {
    console.error('❌ Error marking all notifications as read:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to mark all notifications as read',
      error: error.message
    });
  }
});

// Helper function to calculate time ago
function getTimeAgo(date) {
  const seconds = Math.floor((new Date() - new Date(date)) / 1000);
  
  let interval = seconds / 31536000;
  if (interval > 1) return Math.floor(interval) + 'y ago';
  
  interval = seconds / 2592000;
  if (interval > 1) return Math.floor(interval) + 'mo ago';
  
  interval = seconds / 86400;
  if (interval > 1) return Math.floor(interval) + 'd ago';
  
  interval = seconds / 3600;
  if (interval > 1) return Math.floor(interval) + 'h ago';
  
  interval = seconds / 60;
  if (interval > 1) return Math.floor(interval) + 'm ago';
  
  return 'Just now';
}

module.exports = router;
