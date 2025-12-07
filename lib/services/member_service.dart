import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../utils/cache_manager.dart';

class MemberService {
  static final _cache = FastCacheManager();
  // Backend URL Configuration
  // Using machine's local WiFi IP for device connectivity
  static const String baseUrl = 'http://10.42.208.174:3000/api';

  // Get current user's identifier (email) from secure storage
  static Future<String?> _getCurrentUserIdentifier() async {
    try {
      final userData = await AuthService.getUserData();

      if (userData == null) {
        print('⚠️ No user data found in secure storage');
        return null;
      }

      // Try to get email from various possible locations in userData
      final email =
          userData['email'] ??
          userData['member']?['email'] ??
          userData['registrationForm']?['email'];

      if (email == null || (email as String).isEmpty) {
        print(
          '⚠️ No email found in user data. Keys available: ${userData.keys.toList()}',
        );
        return null;
      }

      print('✅ Retrieved user email from session: $email');
      return email;
    } catch (e) {
      print('❌ Error retrieving user identifier: $e');
      return null;
    }
  }

  // Fetch member details dynamically using current user's session
  static Future<Map<String, dynamic>?> getMemberDetails([
    String? emailOverride,
  ]) async {
    try {
      // Get identifier from session (unless explicitly overridden for testing)
      final email = emailOverride ?? await _getCurrentUserIdentifier();

      if (email == null || email.isEmpty) {
        print('❌ Cannot fetch member details: No user identifier found');
        print('💡 User must login again to establish session');
        return null;
      }

      final encodedEmail = Uri.encodeComponent(email);
      final cacheKey = 'member_details_$email';
      
      // Try cache first
      final cached = _cache.get<Map<String, dynamic>>(cacheKey);
      if (cached != null) {
        print('✅ Loaded member details from cache (${cached['data']?['personal_and_demographic_details']?['full_name'] ?? 'Member'})');
        return cached;
      }
      
      print('\n🔄 Fetching member details from API...');
      print('📧 User email from session: $email');
      print('🌐 API URL: $baseUrl/members/$encodedEmail/details');

      // ✅ OPTIMIZED: Single attempt with shorter timeout for faster failure
      try {
        final response = await http
            .get(
              Uri.parse('$baseUrl/members/$encodedEmail/details'),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(
              const Duration(seconds: 3), // Reduced from 5s
              onTimeout: () {
                print('⏱️ Request timeout (3s)');
                throw TimeoutException('Request timed out after 3 seconds');
              },
            );

        print('📡 Response status: ${response.statusCode}');

        if (response.statusCode == 200) {
          print('✅ Member details fetched successfully from API');
          final data = json.decode(response.body);
          // Cache for 5 minutes (increased for better performance)
          _cache.set(cacheKey, data);
          return data;
        } else if (response.statusCode == 404) {
          print('❌ Member not found in database');
            return {
            'success': false,
            'message':
                'No member profile found. Please complete your registration.',
          };
        } else {
          print('❌ Error fetching member details: ${response.statusCode}');
          return null;
        }
      } on TimeoutException catch (e) {
        print('⏱️ Timeout: $e');
        print('❌ Request failed due to timeout');
        return {
          'success': false,
          'message': 'Connection timeout. Please check your network and try again.',
        };
      } catch (e) {
        print('❌ Network/other error: $e');
        return {
          'success': false,
          'message': 'Network error. Please check your connection.',
        };
      }
    } catch (e) {
      print('❌ Exception fetching member details: $e');
      print('Stack trace: ${StackTrace.current}');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  // Update member details dynamically using current user's session
  static Future<bool> updateMemberDetails(
    Map<String, dynamic> details, [
    String? emailOverride,
  ]) async {
    try {
      // Get identifier from session (unless explicitly overridden)
      final email = emailOverride ?? await _getCurrentUserIdentifier();

      if (email == null || email.isEmpty) {
        print('❌ Cannot update member details: No user identifier found');
        return false;
      }

      final encodedEmail = Uri.encodeComponent(email);
      print('\n🔄 Updating member details dynamically...');
      print('📧 User email from session: $email');

      final response = await http.put(
        Uri.parse('$baseUrl/members/$encodedEmail/details'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(details),
      );

      if (response.statusCode == 200) {
        print('✅ Member details updated successfully');
        // Clear cache so next fetch gets fresh data
        _cache.clearByPrefix('member_details_');
        return true;
      } else {
        print('❌ Failed to update member details: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Exception updating member details: $e');
      return false;
    }
  }

  // Fetch dashboard status for current user
  static Future<Map<String, dynamic>?> getDashboardStatus() async {
    try {
      // Get user data to extract member ID
      final userData = await AuthService.getUserData();
      if (userData == null) {
        print('⚠️ No user data found for dashboard status');
        return null;
      }

      // Extract member ID (same logic as application_status_service.dart)
      final memberId =
          userData['_id'] ?? userData['member']?['_id'] ?? userData['id'];

      if (memberId == null || (memberId as String).isEmpty) {
        print('⚠️ No member ID found in user data');
        return null;
      }

      print('🔄 Fetching dashboard status for member: $memberId');

      final response = await http
          .get(Uri.parse('$baseUrl/members/$memberId/status'))
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('✅ Dashboard status fetched successfully');
          print('📊 Profile completion: ${data['data']['profileCompletion']}%');
          print('📋 Application status: ${data['data']['applicationStatus']}');
          return data['data'];
        }
      }

      print('❌ Failed to fetch dashboard status: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ Exception fetching dashboard status: $e');
      return null;
    }
  }
}
