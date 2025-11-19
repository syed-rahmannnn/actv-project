import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String baseUrl = 'http://10.201.103.174:3000/api/notifications';

  /// Fetch notifications for a user
  static Future<Map<String, dynamic>> getNotifications({
    required String userId,
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      print('🔔 === FETCHING NOTIFICATIONS ===');
      print('User ID: $userId');
      print('Page: $page, Limit: $limit, Unread Only: $unreadOnly');

      final uri = Uri.parse('$baseUrl/$userId').replace(
        queryParameters: {
          'page': page.toString(),
          'limit': limit.toString(),
          'unreadOnly': unreadOnly.toString(),
        },
      );

      print('📍 API URL: $uri');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Successfully fetched ${data['data'].length} notifications');
        print('📊 Unread count: ${data['pagination']['unreadCount']}');
        return data;
      } else {
        print('❌ Failed to fetch notifications: ${response.statusCode}');
        throw Exception('Failed to fetch notifications: ${response.body}');
      }
    } catch (error) {
      print('❌ Error fetching notifications: $error');
      rethrow;
    }
  }

  /// Mark a notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      print('✅ Marking notification as read: $notificationId');

      final response = await http.put(
        Uri.parse('$baseUrl/$notificationId/read'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        print('✅ Notification marked as read');
        return true;
      } else {
        print('❌ Failed to mark notification as read: ${response.statusCode}');
        return false;
      }
    } catch (error) {
      print('❌ Error marking notification as read: $error');
      return false;
    }
  }

  /// Mark all notifications as read for a user
  static Future<bool> markAllAsRead(String userId) async {
    try {
      print('✅ Marking all notifications as read for user: $userId');

      final response = await http.put(
        Uri.parse('$baseUrl/$userId/read-all'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(
          '✅ Marked ${data['data']['modifiedCount']} notifications as read',
        );
        return true;
      } else {
        print(
          '❌ Failed to mark all notifications as read: ${response.statusCode}',
        );
        return false;
      }
    } catch (error) {
      print('❌ Error marking all notifications as read: $error');
      return false;
    }
  }
}
