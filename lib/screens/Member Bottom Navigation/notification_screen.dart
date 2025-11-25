import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
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
      appBar: AppBar(
        title: Text(
          'Notifications${unreadCount > 0 ? ' ($unreadCount)' : ''}',
          style: const TextStyle(
            fontFamily: 'YourFont',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        color: Colors.deepPurple.shade50,
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
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _loadNotifications,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                      ),
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
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadNotifications,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    return _buildNotificationCard(notifications[index]);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final type = notification['type'] ?? 'general';
    final isRead = notification['isRead'] ?? true;
    final sender = notification['sender'] ?? {};

    // Determine icon and color based on type
    IconData icon;
    Color iconColor;

    switch (type) {
      case 'connection_request':
        icon = Icons.person_add_outlined;
        iconColor = Colors.deepPurple;
        break;
      case 'connection_accepted':
        icon = Icons.check_circle_outline;
        iconColor = Colors.green;
        break;
      case 'connection_declined':
        icon = Icons.cancel_outlined;
        iconColor = Colors.red;
        break;
      default:
        icon = Icons.notifications;
        iconColor = Colors.deepPurple;
    }

    return Card(
      color: isRead ? Colors.white : Colors.deepPurple.shade50,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isRead
            ? BorderSide.none
            : BorderSide(color: Colors.deepPurple.shade200, width: 1),
      ),
      child: InkWell(
        onTap: () {
          if (!isRead) {
            _markAsRead(notification['id']);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'] ?? 'Notification',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.deepPurple.shade900,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.deepPurple,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['message'] ?? '',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    if (sender['name'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'From: ${sender['name']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      notification['timeAgo'] ?? '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
