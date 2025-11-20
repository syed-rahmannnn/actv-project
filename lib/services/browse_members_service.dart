import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class BrowseMembersService {
  // Using WiFi IP address
  static const String baseUrl = 'http://10.201.103.174:3000/api/browse-members';

  // Fetch all approved members with payment completed (excluding current user)
  static Future<Map<String, dynamic>> getApprovedMembers({
    String? state,
    String? district,
    String? block,
    String? search,
    int page = 1,
    int limit = 10,
    String? excludeUserId,
  }) async {
    try {
      final queryParams = {'page': page.toString(), 'limit': limit.toString()};

      if (state != null && state.isNotEmpty) queryParams['state'] = state;
      if (district != null && district.isNotEmpty)
        queryParams['district'] = district;
      if (block != null && block.isNotEmpty) queryParams['block'] = block;
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (excludeUserId != null && excludeUserId.isNotEmpty)
        queryParams['exclude_user_id'] = excludeUserId;

      final uri = Uri.parse(baseUrl).replace(queryParameters: queryParams);

      print('\n🌐 === FETCHING APPROVED & PAID MEMBERS ===');
      print('📍 API URL: $uri');
      print(
        '🔍 Filters: ${queryParams.entries.where((e) => !['page', 'limit'].contains(e.key)).map((e) => '${e.key}=${e.value}').join(', ')}',
      );

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              print('⏱️ Request timed out after 10 seconds');
              print('🔍 Possible issues:');
              print('   - Mobile device not on same WiFi network (10.201.x.x)');
              print('   - Backend server not running on 10.201.103.174:3000');
              print('   - Firewall blocking connection');
              throw Exception(
                'Connection timeout - Check network connectivity',
              );
            },
          );

      print('📡 Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final memberCount = data['data']?.length ?? 0;

        print('✅ Successfully fetched $memberCount members');

        if (memberCount == 0) {
          print('⚠️  No members found with criteria:');
          print('   ✓ Approved by state admin (approvedBy != null)');
          print('   ✓ Payment completed (membershipStatus = "active")');
          print('   ✓ Profile completed (profileCompleted = true)');
        } else {
          print('📊 Members found: $memberCount');
          print('   All members have:');
          print('   ✓ Approval status: approved_by_state_admin');
          print('   ✓ Payment status: completed');
        }

        return data;
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        return {
          'success': false,
          'message': 'Server returned error: ${response.statusCode}',
          'data': [],
        };
      }
    } on http.ClientException catch (e) {
      print('❌ Network error - Cannot reach server: $e');
      print('🔧 Troubleshooting steps:');
      print('   1. Ensure mobile device is on WiFi network 10.201.x.x');
      print(
        '   2. Check backend server is running: http://10.201.103.174:3000',
      );
      print(
        '   3. Try accessing http://10.201.103.174:3000/api/browse-members in browser',
      );
      return {
        'success': false,
        'message': 'Cannot reach server. Check network connection.',
        'data': [],
      };
    } catch (e) {
      print('❌ Exception in getApprovedMembers: $e');
      return {
        'success': false,
        'message': 'Network error: ${e.toString()}',
        'data': [],
      };
    }
  }

  // Send connection request
  static Future<Map<String, dynamic>> sendConnectionRequest({
    required String senderId,
    required String recipientId,
    String? message,
  }) async {
    try {
      print('🤝 Sending connection request from $senderId to $recipientId');

      final response = await http
          .post(
            Uri.parse('$baseUrl/connect'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'senderId': senderId,
              'recipientId': recipientId,
              'message': message ?? 'Wants to connect with you',
            }),
          )
          .timeout(const Duration(seconds: 30));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Connection request sent successfully');
      } else {
        print('⚠️ Connection request response: ${data['message']}');
      }

      return data;
    } catch (e) {
      print('❌ Exception in sendConnectionRequest: $e');
      return {
        'success': false,
        'message': 'Failed to send connection request: $e',
      };
    }
  }

  // Check connection status between two users
  static Future<Map<String, dynamic>> getConnectionStatus({
    required String senderId,
    required String recipientId,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/connection-status/$senderId/$recipientId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'data': {'hasConnection': false, 'status': null},
        };
      }
    } catch (e) {
      print('❌ Exception in getConnectionStatus: $e');
      return {
        'success': false,
        'data': {'hasConnection': false, 'status': null},
      };
    }
  }

  // Check connection status by connection ID
  static Future<Map<String, dynamic>> getConnectionStatusById(
    String connectionId,
  ) async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/connection/$connectionId/status'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'data': {'status': null},
        };
      }
    } catch (e) {
      print('❌ Exception in getConnectionStatusById: $e');
      return {
        'success': false,
        'data': {'status': null},
      };
    }
  }

  // Respond to connection request (accept/decline)
  static Future<Map<String, dynamic>> respondToConnection({
    required String connectionId,
    required String action, // 'accept' or 'decline'
  }) async {
    try {
      print('💬 Responding to connection $connectionId: $action');

      final response = await http
          .put(
            Uri.parse('$baseUrl/connection/$connectionId/respond'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'action': action}),
          )
          .timeout(const Duration(seconds: 30));

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        print('✅ Connection $action successful');
        return data;
      } else if (response.statusCode == 409 || response.statusCode == 400) {
        // Connection already processed - check if message indicates this
        final message = data['message'] ?? '';
        if (message.contains('already')) {
          print(
            'ℹ️ Connection already processed: ${data['status'] ?? message}',
          );
          return {
            'success': false,
            'alreadyProcessed': true,
            'status': data['status'] ?? 'accepted',
            'message': data['message'],
          };
        }
        // Other 400 errors
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to respond to connection',
        };
      } else {
        print('❌ Error ${response.statusCode}: ${data['message']}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to respond to connection',
        };
      }
    } catch (e) {
      print('❌ Exception in respondToConnection: $e');
      return {
        'success': false,
        'message': 'Failed to respond to connection: $e',
      };
    }
  }

  // Get member by ID
  static Future<Map<String, dynamic>> getMemberById(String memberId) async {
    try {
      print('👤 Fetching member details for: $memberId');
      print('🌐 API URL: $baseUrl/member/$memberId');

      final response = await http
          .get(
            Uri.parse('$baseUrl/member/$memberId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('⏱️ Request timed out after 30 seconds');
              throw Exception(
                'Connection timeout - Check network connectivity',
              );
            },
          );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Member details fetched successfully');
        if (data['data'] != null) {
          print('📋 Member name: ${data['data']['fullName']}');
        }
        return data;
      } else if (response.statusCode == 404) {
        print('❌ Member not found with ID: $memberId');
        return {'success': false, 'message': 'Member not found'};
      } else {
        print('❌ Error ${response.statusCode}: ${response.body}');
        final errorData = json.decode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Failed to fetch member details',
        };
      }
    } on http.ClientException catch (e) {
      print('❌ Network error - Cannot reach server: $e');
      return {
        'success': false,
        'message': 'Cannot reach server. Check network connection.',
      };
    } catch (e) {
      print('❌ Exception in getMemberById: $e');
      return {
        'success': false,
        'message': 'Failed to fetch member details: $e',
      };
    }
  }

  // Get notifications for a member
  static Future<Map<String, dynamic>> getNotifications({
    required String memberId,
    int page = 1,
    int limit = 20,
    bool unreadOnly = false,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'unreadOnly': unreadOnly.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/notifications/$memberId',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('🔔 Fetched ${data['data']?.length ?? 0} notifications');
        return data;
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch notifications',
          'data': [],
        };
      }
    } catch (e) {
      print('❌ Exception in getNotifications: $e');
      return {'success': false, 'message': 'Network error: $e', 'data': []};
    }
  }

  // Mark notification as read
  static Future<Map<String, dynamic>> markNotificationAsRead(
    String notificationId,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/notifications/$notificationId/read'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 30));

      return json.decode(response.body);
    } catch (e) {
      print('❌ Exception in markNotificationAsRead: $e');
      return {
        'success': false,
        'message': 'Failed to mark notification as read',
      };
    }
  }

  // Get current user ID
  static Future<String?> getCurrentUserId() async {
    try {
      final userData = await AuthService.getUserData();
      return userData?['id'] ?? userData?['memberId'];
    } catch (e) {
      print('❌ Error getting current user ID: $e');
      return null;
    }
  }
}
