import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  String? error;
  int unreadCount = 0;
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      // Get current user ID from session
      final userData = await AuthService.getUserData();
      currentUserId = userData?['id'] ?? userData?['memberId'];

      if (currentUserId == null) {
        throw Exception('User not logged in');
      }

      print('🔔 Loading notifications for user: $currentUserId');

      // Fetch notifications from API
      final response = await NotificationService.getNotifications(
        userId: currentUserId!,
        page: 1,
        limit: 50,
      );

      if (response['success'] == true) {
        setState(() {
          notifications = List<Map<String, dynamic>>.from(response['data']);
          unreadCount = response['pagination']['unreadCount'];
          isLoading = false;
        });
        print('✅ Loaded ${notifications.length} notifications');
      } else {
        throw Exception(response['message'] ?? 'Failed to load notifications');
      }
    } catch (e) {
      print('❌ Error loading notifications: $e');
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    if (currentUserId == null) return;

    try {
      final success = await NotificationService.markAllAsRead(currentUserId!);
      if (success) {
        setState(() {
          for (var notification in notifications) {
            notification['isRead'] = true;
          }
          unreadCount = 0;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications marked as read'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error marking all as read: $e');
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final success = await NotificationService.markAsRead(notificationId);
      if (success) {
        setState(() {
          final notification = notifications.firstWhere(
            (n) => n['id'] == notificationId,
            orElse: () => {},
          );
          if (notification.isNotEmpty && notification['isRead'] == false) {
            notification['isRead'] = true;
            unreadCount = unreadCount > 0 ? unreadCount - 1 : 0;
          }
        });
      }
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Bell Icon and Title
                  const Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFF202124),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF202124),
                          ),
                        ),
                        Text(
                          '$unreadCount new',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF5F6368),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Mark all read button
                  if (unreadCount > 0)
                    TextButton(
                      onPressed: _markAllAsRead,
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF4285F4),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF5F6368)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Failed to load notifications',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _loadNotifications,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications yet',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: notifications.length,
                        itemBuilder: (context, index) {
                          return _buildNotificationCard(notifications[index]);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final type = notification['type'] ?? 'general';
    final isRead = notification['isRead'] ?? true;
    final sender = notification['sender'] ?? {};

    // Determine icon based on type
    IconData icon;
    Color iconColor;
    String badge;
    Color badgeColor;

    switch (type) {
      case 'connection_request':
        icon = Icons.person_add_outlined;
        iconColor = const Color(0xFF4285F4);
        badge = 'Connect';
        badgeColor = const Color(0xFF4285F4);
        break;
      case 'connection_accepted':
        icon = Icons.check_circle_outline;
        iconColor = const Color(0xFF34A853);
        badge = 'Accepted';
        badgeColor = const Color(0xFF34A853);
        break;
      case 'connection_declined':
        icon = Icons.cancel_outlined;
        iconColor = const Color(0xFFEA4335);
        badge = 'Declined';
        badgeColor = const Color(0xFFEA4335);
        break;
      default:
        icon = Icons.notifications_outlined;
        iconColor = const Color(0xFF5F6368);
        badge = 'General';
        badgeColor = const Color(0xFF5F6368);
    }

    return GestureDetector(
      onTap: () {
        if (!isRead) {
          _markAsRead(notification['id']);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead ? Colors.white : const Color(0xFFE8F0FE),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon, title, and unread indicator
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Icon(icon, color: iconColor, size: 20),
                const SizedBox(width: 8),

                // Title
                Expanded(
                  child: Text(
                    notification['title'] ?? 'Notification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF202124),
                    ),
                  ),
                ),

                // Unread indicator
                if (!isRead)
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 6, left: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4285F4),
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 8),

            // Message
            Text(
              notification['message'] ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5F6368),
                height: 1.4,
              ),
            ),

            if (sender['name'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'From: ${sender['name']}',
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF5F6368),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Time and Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  notification['timeAgo'] ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5F6368),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
