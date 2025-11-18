import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Sample notifications data
  final List<Map<String, dynamic>> notifications = [
    {
      'type': 'approval',
      'title': 'New Approval Request',
      'message': 'Aditi Sharma has submitted a new membership application for review',
      'time': '30m ago',
      'badge': 'Block',
      'badgeColor': Color(0xFFFFA726),
      'isUnread': true,
      'icon': Icons.notifications_outlined,
    },
    {
      'type': 'approved',
      'title': 'Application Approved',
      'message': 'Rajesh Kumar\'s membership application has been approved by the district admin',
      'time': '2h ago',
      'badge': 'District',
      'badgeColor': Color(0xFF66BB6A),
      'isUnread': true,
      'icon': Icons.check_circle_outline,
    },
    {
      'type': 'alert',
      'title': 'System Alert',
      'message': 'Server maintenance scheduled for tonight at 11:00 PM. Expected downtime: 2 hours',
      'time': '4h ago',
      'badge': 'State',
      'badgeColor': Color(0xFF9C27B0),
      'isUnread': false,
      'icon': Icons.error_outline,
      'isAlert': true,
    },
    {
      'type': 'status',
      'title': 'Status Update',
      'message': 'Monthly membership report is now available for download in the reports section',
      'time': '1d ago',
      'badge': 'Block',
      'badgeColor': Color(0xFFFFA726),
      'isUnread': false,
      'icon': Icons.update,
    },
    {
      'type': 'status',
      'title': 'Status Update',
      'message': 'Monthly membership report is now available for download in the reports section',
      'time': '1d ago',
      'badge': 'Block',
      'badgeColor': Color(0xFFFFA726),
      'isUnread': false,
      'icon': Icons.update,
    },
  ];

  int get unreadCount => notifications.where((n) => n['isUnread'] == true).length;

  void markAllAsRead() {
    setState(() {
      for (var notification in notifications) {
        notification['isUnread'] = false;
      }
    });
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
                  TextButton(
                    onPressed: markAllAsRead,
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
            
            // Notifications List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  return _buildNotificationCard(notifications[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isAlert = notification['isAlert'] == true;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
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
              if (isAlert)
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFEA4335),
                  size: 20,
                )
              else if (notification['type'] == 'status')
                const Icon(
                  Icons.access_time,
                  color: Color(0xFF5F6368),
                  size: 20,
                ),
              
              if (isAlert || notification['type'] == 'status')
                const SizedBox(width: 8),
              
              // Title
              Expanded(
                child: Text(
                  notification['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isAlert ? const Color(0xFFEA4335) : const Color(0xFF202124),
                  ),
                ),
              ),
              
              // Unread indicator
              if (notification['isUnread'] == true)
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
            notification['message'],
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF5F6368),
              height: 1.4,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Time and Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                notification['time'],
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
                  color: (notification['badgeColor'] as Color).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  notification['badge'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: notification['badgeColor'],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
