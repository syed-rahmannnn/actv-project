import 'dart:convert';
import 'package:http/http.dart' as http;

class DashboardService {
  static const String baseUrl = 'http://10.42.208.174:3000/api';

  /// Fetch dashboard statistics for a company
  static Future<Map<String, dynamic>> getCompanyStats(String companyId) async {
    try {
      print('📊 Fetching stats for company: $companyId');

      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/stats/$companyId'),
      );

      print('📡 Stats response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ Stats fetched successfully');
          return data['data'];
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch stats');
        }
      } else {
        throw Exception('Failed to fetch stats: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching stats: $e');
      rethrow;
    }
  }

  /// Fetch recent activities for a company
  static Future<List<Map<String, dynamic>>> getRecentActivities(
    String companyId, {
    int limit = 10,
  }) async {
    try {
      print('📋 Fetching activities for company: $companyId');

      final response = await http.get(
        Uri.parse('$baseUrl/dashboard/activities/$companyId?limit=$limit'),
      );

      print('📡 Activities response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ Found ${data['data'].length} activities');
          return List<Map<String, dynamic>>.from(data['data']);
        } else {
          throw Exception(data['message'] ?? 'Failed to fetch activities');
        }
      } else {
        throw Exception('Failed to fetch activities: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching activities: $e');
      rethrow;
    }
  }

  /// Log a new activity
  static Future<void> logActivity({
    required String memberId,
    required String companyId,
    required String activityType,
    String? entityType,
    String? entityId,
    String? entityName,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('📝 Logging activity: $activityType');

      final response = await http.post(
        Uri.parse('$baseUrl/dashboard/activities'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'memberId': memberId,
          'companyId': companyId,
          'activityType': activityType,
          'entityType': entityType,
          'entityId': entityId,
          'entityName': entityName,
          'description': description,
          'metadata': metadata,
        }),
      );

      print('📡 Log activity response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ Activity logged successfully');
        } else {
          throw Exception(data['message'] ?? 'Failed to log activity');
        }
      } else {
        throw Exception('Failed to log activity: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error logging activity: $e');
      // Don't rethrow - activity logging should not break the main flow
    }
  }
}
