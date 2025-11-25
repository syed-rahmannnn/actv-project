import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'auth_service.dart';

class MemberService {
  // Backend URL Configuration
  // Using machine's local WiFi IP for device connectivity
  static const String baseUrl = 'http://10.201.103.174:3000/api';

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
      print('\n🔄 Fetching member details dynamically...');
      print('📧 User email from session: $email');
      print('🌐 API URL: $baseUrl/members/$encodedEmail/details');

      // Try with longer timeout and retry logic
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          print('🔄 Attempt $attempt of 3...');

          final response = await http
              .get(
                Uri.parse('$baseUrl/members/$encodedEmail/details'),
                headers: {'Content-Type': 'application/json'},
              )
              .timeout(
                const Duration(seconds: 30),
                onTimeout: () {
                  print('⏱️ Request timeout on attempt $attempt');
                  throw TimeoutException('Request timed out after 30 seconds');
                },
              );

          print('📡 Response status: ${response.statusCode}');
          print('📦 Response body: ${response.body}');

          if (response.statusCode == 200) {
            print('✅ Member details fetched successfully');
            return json.decode(response.body);
          } else if (response.statusCode == 404) {
            print('❌ Member not found in database');
            return {
              'success': false,
              'message':
                  'No member profile found. Please complete your registration.',
            };
          } else {
            print('❌ Error fetching member details: ${response.statusCode}');
            print('Response body: ${response.body}');

            // Don't retry on 4xx errors (client errors)
            if (response.statusCode >= 400 && response.statusCode < 500) {
              return null;
            }

            // Retry on 5xx errors
            if (attempt < 3) {
              print('⏳ Waiting 2 seconds before retry...');
              await Future.delayed(const Duration(seconds: 2));
              continue;
            }
            return null;
          }
        } on TimeoutException catch (e) {
          print('⏱️ Timeout on attempt $attempt: $e');
          if (attempt < 3) {
            print('⏳ Waiting 2 seconds before retry...');
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
          print('❌ All retry attempts failed due to timeout');
          print('💡 Possible issues:');
          print('   1. Backend server not running');
          print('   2. Network connectivity issues');
          print('   3. Emulator network configuration');
          return {
            'success': false,
            'message':
                'Connection timeout. Please check your network and try again.',
          };
        } catch (e) {
          print('❌ Network/other error on attempt $attempt: $e');
          if (attempt < 3) {
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
          return {
            'success': false,
            'message': 'Network error. Please check your connection.',
          };
        }
      }

      return null;
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
}
