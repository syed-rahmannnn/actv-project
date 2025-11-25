import 'package:flutter/material.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../services/browse_members_service.dart';
import 'member_dashboard_screen.dart';

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
  Set<String> processingNotifications =
      {}; // Track notifications being processed

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
        final notificationsList = List<Map<String, dynamic>>.from(
          response['data'],
        );

        // Check connection status for each connection request notification
        for (var notification in notificationsList) {
          if (notification['type'] == 'connection_request' &&
              notification['connectionId'] != null) {
            try {
              // Check if this connection has already been accepted
              final connectionId = notification['connectionId'];
              final statusResponse =
                  await BrowseMembersService.getConnectionStatusById(
                    connectionId,
                  );

              if (statusResponse['success'] == true &&
                  statusResponse['data']?['status'] == 'accepted') {
                // Update notification to show View Profile button
                notification['type'] = 'connection_accepted';
                notification['title'] = 'Already Connected';
                notification['message'] =
                    'You are already connected with ${notification['sender']?['name'] ?? 'this member'}';
                notification['showViewProfile'] = true;
                print(
                  'ℹ️ Connection ${connectionId} already accepted, updated notification',
                );
              }
            } catch (e) {
              print('⚠️ Error checking connection status: $e');
              // Continue with original notification
            }
          }
        }

        setState(() {
          notifications = notificationsList;
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

  Future<void> _handleConnectionResponse({
    required String connectionId,
    required String action,
    required String notificationId,
    required String senderId,
    required String senderName,
  }) async {
    // Prevent duplicate processing
    if (processingNotifications.contains(notificationId)) {
      print('⚠️ Already processing this notification');
      return;
    }

    try {
      // Mark as processing
      setState(() {
        processingNotifications.add(notificationId);
      });

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'accept'
                  ? 'Accepting connection...'
                  : 'Rejecting connection...',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      // Respond to connection
      final response = await BrowseMembersService.respondToConnection(
        connectionId: connectionId,
        action: action,
      );

      if (response['success'] == true) {
        // Mark notification as read
        await NotificationService.markAsRead(notificationId);

        if (action == 'accept') {
          // Update notification to show "View Profile" button instead of removing it
          setState(() {
            final notificationIndex = notifications.indexWhere(
              (n) => n['id'] == notificationId,
            );
            if (notificationIndex != -1) {
              notifications[notificationIndex]['type'] = 'connection_accepted';
              notifications[notificationIndex]['title'] = 'Connection Accepted';
              notifications[notificationIndex]['message'] =
                  'You are now connected with $senderName';
              notifications[notificationIndex]['isRead'] = true;
              notifications[notificationIndex]['showViewProfile'] = true;
            }
            unreadCount = unreadCount > 0 ? unreadCount - 1 : 0;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Connection accepted! Click "View Profile" to see their details.',
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          // For reject, remove the notification
          setState(() {
            notifications.removeWhere((n) => n['id'] == notificationId);
            unreadCount = unreadCount > 0 ? unreadCount - 1 : 0;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Connection rejected'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } else if (response['alreadyProcessed'] == true) {
        // Connection already processed - handle gracefully
        print('ℹ️ Connection already ${response['status']}');

        if (response['status'] == 'accepted') {
          // Update notification to show View Profile button
          setState(() {
            final notificationIndex = notifications.indexWhere(
              (n) => n['id'] == notificationId,
            );
            if (notificationIndex != -1) {
              notifications[notificationIndex]['type'] = 'connection_accepted';
              notifications[notificationIndex]['title'] = 'Already Connected';
              notifications[notificationIndex]['message'] =
                  'You are already connected with $senderName';
              notifications[notificationIndex]['isRead'] = true;
              notifications[notificationIndex]['showViewProfile'] = true;
            }
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('You are already connected with this member'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } else {
          // Already declined - just remove it
          setState(() {
            notifications.removeWhere((n) => n['id'] == notificationId);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('This connection request was already processed'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to respond');
      }
    } catch (e) {
      print('❌ Error handling connection response: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Remove from processing set
      setState(() {
        processingNotifications.remove(notificationId);
      });
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

            // Action buttons for connection requests
            if (type == 'connection_request' &&
                notification['connectionId'] != null) ...[
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          processingNotifications.contains(notification['id'])
                          ? null
                          : () => _handleConnectionResponse(
                              connectionId: notification['connectionId'],
                              action: 'accept',
                              notificationId: notification['id'],
                              senderId: notification['senderId'] ?? '',
                              senderName: sender['name'] ?? 'Member',
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4285F4),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child:
                          processingNotifications.contains(notification['id'])
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Connect',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          processingNotifications.contains(notification['id'])
                          ? null
                          : () => _handleConnectionResponse(
                              connectionId: notification['connectionId'],
                              action: 'decline',
                              notificationId: notification['id'],
                              senderId: notification['senderId'] ?? '',
                              senderName: sender['name'] ?? 'Member',
                            ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEA4335),
                        side: const BorderSide(
                          color: Color(0xFFEA4335),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // View Profile button for accepted connections
            if ((type == 'connection_accepted' &&
                    notification['showViewProfile'] == true) ||
                (type == 'connection_accepted' &&
                    notification['senderId'] != null)) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final memberId = notification['senderId'] ?? '';
                    print(
                      '🔍 Navigating to full dashboard for member: $memberId',
                    );

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MemberDashboardScreen(memberId: memberId),
                      ),
                    );
                  },
                  icon: const Icon(Icons.dashboard_outlined, size: 18),
                  label: const Text(
                    'View Dashboard',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34A853),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

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
                    color: badgeColor.withValues(alpha: 0.15),
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
