import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class ApiService {
  // Replace with your Render domain (include https)
  // Make base URL configurable for device runs via --dart-define
  static final String baseUrl = _resolveBaseUrl();

  static String _resolveBaseUrl() {
    // Full override if provided
    const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (apiBaseUrl.isNotEmpty) return apiBaseUrl;

    // In release mode, ALWAYS use production backend
    if (!kDebugMode) {
      return 'https://actv-project.onrender.com/api';
    }

    // For debug mode, check if we should force production
    const forceProduction = String.fromEnvironment(
      'FORCE_PRODUCTION',
      defaultValue: 'false',
    );
    if (forceProduction.toLowerCase() == 'true') {
      return 'https://actv-project.onrender.com/api';
    }

    // Only use local development server if explicitly enabled
    const useLocalDev = String.fromEnvironment(
      'USE_LOCAL_DEV',
      defaultValue: 'false',
    );
    if (useLocalDev.toLowerCase() == 'true') {
      const devHost = String.fromEnvironment(
        'DEV_HOST',
        defaultValue: '192.168.29.130',
      );
      const apiPort = String.fromEnvironment('API_PORT', defaultValue: '3000');
      const apiScheme = String.fromEnvironment(
        'API_SCHEME',
        defaultValue: 'http',
      );
      return '$apiScheme://$devHost:$apiPort/api';
    }

    // Default to production for all other cases (including physical devices in debug mode)
    return 'https://actv-project.onrender.com/api';
  }

  String? _token;

  // Helper to get headers, include token if present
  Map<String, String> _headers({bool json = true, bool auth = false}) {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json';
      headers['Accept'] = 'application/json';
    }
    if (auth && _token != null) headers['Authorization'] = 'Bearer $_token';
    return headers;
  }

  // Static helper to get headers with token from AuthService
  static Future<Map<String, String>> _staticHeaders({bool json = true}) async {
    final headers = <String, String>{};
    if (json) {
      headers['Content-Type'] = 'application/json';
      headers['Accept'] = 'application/json';
    }

    // Get token from AuthService for static methods
    final token = await AuthService.getToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  void setToken(String token) {
    _token = token;
    // Token management logging kept for debugging auth issues (no sensitive data exposed)
    developer.log(
      'ApiService: token set length=${token.length}',
      name: 'ApiService',
    );
  }

  void clearToken() {
    _token = null;
    developer.log('ApiService: token cleared', name: 'ApiService');
  }

  // Safe json decode
  dynamic jsonDecodeSafe(String input) {
    try {
      return input.isNotEmpty ? jsonDecode(input) : null;
    } catch (e) {
      // Error logging kept for debugging JSON parsing issues (no sensitive data exposed)
      developer.log('jsonDecodeSafe error: $e', name: 'ApiService');
      return input;
    }
  }

  // Register user with proper backend route
  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/auth/register'); // auth.js register route
    // Logging removed for security - no longer exposing sensitive registration data

    final resp = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(payload),
    );
    // Response logging removed for security

    final body = jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      // backend returns data.token and data.member
      final token = body['data']?['token'] ?? body['token'];
      if (token != null) setToken(token as String);
      return {'ok': true, 'body': body, 'token': token};
    } else {
      return {'ok': false, 'body': body, 'error': 'Registration failed'};
    }
  }

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final payload = {'email': email.trim(), 'password': password};
    // Logging removed for security - no longer exposing login credentials

    http.Response resp;
    try {
      resp = await http
          .post(url, headers: _headers(), body: jsonEncode(payload))
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      developer.log('login request error: $e', name: 'ApiService');
      return {'ok': false, 'body': null, 'error': 'Network error or timeout'};
    }
    // Response logging removed for security

    final body = jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final token = body['data']?['token'] ?? body['token'];
      if (token != null) setToken(token as String);
      return {'ok': true, 'body': body, 'token': token};
    } else {
      return {'ok': false, 'body': body, 'error': 'Login failed'};
    }
  }

  // Admin login
  Future<Map<String, dynamic>> loginAdmin(
    String email,
    String password,
    String role,
  ) async {
    final url = Uri.parse('$baseUrl/admin/login');
    final payload = {'email': email.trim(), 'password': password, 'role': role};
    // Logging removed for security - no longer exposing admin login credentials

    http.Response resp;
    try {
      resp = await http
          .post(url, headers: _headers(), body: jsonEncode(payload))
          .timeout(const Duration(seconds: 12));
    } catch (e) {
      developer.log('loginAdmin request error: $e', name: 'ApiService');
      return {
        'ok': false,
        'body': null,
        'error': 'Admin login timeout or network error',
      };
    }
    // Response logging removed for security

    final body = jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final token = body['token'];
      if (token != null) setToken(token as String);
      // Use MongoDB _id if available, otherwise fall back to adminId
      final mongoId = body['id'];
      final adminId = mongoId ?? body['adminId'];
      return {
        'ok': true,
        'body': body,
        'token': token,
        'role': body['role'],
        'adminId': adminId,
        'mongoId':
            mongoId, // Include MongoDB _id separately for backward compatibility
      };
    } else {
      return {'ok': false, 'body': body, 'error': 'Admin login failed'};
    }
  }

  // Update member profile
  Future<Map<String, dynamic>> updateMember(
    String memberId,
    Map<String, dynamic> updates,
  ) async {
    final url = Uri.parse('$baseUrl/members/$memberId');
    // Logging removed for security - no longer exposing member update data

    final resp = await http.put(
      url,
      headers: _headers(auth: true),
      body: jsonEncode(updates),
    );
    // Response logging removed for security

    final body = jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'ok': true, 'body': body};
    } else {
      return {'ok': false, 'body': body, 'error': 'Update failed'};
    }
  }

  // Get member profile
  Future<Map<String, dynamic>> getMember() async {
    final url = Uri.parse('$baseUrl/members/profile');
    // Logging removed for security

    final resp = await http.get(url, headers: _headers(auth: true));
    // Response logging removed for security

    final body = jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'ok': true, 'body': body};
    } else {
      return {'ok': false, 'body': body, 'error': 'Failed to get member'};
    }
  }

  // Get member by ID
  Future<Map<String, dynamic>> getMemberById(String memberId) async {
    final url = Uri.parse('$baseUrl/members/$memberId');
    // Logging removed for security - no longer exposing member lookup data
    developer.log('ApiService: getMemberById called', name: 'ApiService');

    final resp = await http.get(url, headers: _headers(auth: true));
    // Response logging removed for security

    final body = jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'ok': true, 'body': body};
    } else {
      return {'ok': false, 'body': body, 'error': 'Failed to get member'};
    }
  }

  // Get all members
  Future<Map<String, dynamic>> getAllMembers() async {
    final url = Uri.parse('$baseUrl/members');
    // Logging removed for security

    final resp = await http.get(url, headers: _headers(auth: true));
    // Response logging removed for security

    final body = jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'ok': true, 'body': body};
    } else {
      return {'ok': false, 'body': body, 'error': 'Failed to get members'};
    }
  }

  // Get member dashboard data
  Future<Map<String, dynamic>> getMemberDashboard() async {
    final url = Uri.parse('$baseUrl/members/dashboard');
    // Logging removed for security

    final resp = await http.get(url, headers: _headers(auth: true));
    // Response logging removed for security

    final body = jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'ok': true, 'body': body};
    } else {
      return {'ok': false, 'body': body, 'error': 'Failed to get dashboard'};
    }
  }

  // Submit business information
  Future<Map<String, dynamic>> submitBusinessInfo(
    Map<String, dynamic> payload,
  ) async {
    final url = Uri.parse('$baseUrl/members/business-info');
    // Logging removed for security - no longer exposing business data

    final resp = await http.post(
      url,
      headers: _headers(auth: true),
      body: jsonEncode(payload),
    );
    // Response logging removed for security

    final body = jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'ok': true, 'body': body};
    } else {
      return {
        'ok': false,
        'body': body,
        'error': 'Business info submission failed',
      };
    }
  }

  // Submit financial information
  Future<Map<String, dynamic>> submitFinancialInfo(
    Map<String, dynamic> payload,
  ) async {
    final url = Uri.parse('$baseUrl/members/financial-info');
    // Logging removed for security - no longer exposing financial data

    final resp = await http.post(
      url,
      headers: _headers(auth: true),
      body: jsonEncode(payload),
    );
    // Response logging removed for security

    final body = jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'ok': true, 'body': body};
    } else {
      return {
        'ok': false,
        'body': body,
        'error': 'Financial info submission failed',
      };
    }
  }

  // Submit declaration
  Future<Map<String, dynamic>> submitDeclaration(
    Map<String, dynamic> payload,
  ) async {
    final url = Uri.parse('$baseUrl/members/declaration');
    // Logging removed for security - no longer exposing declaration data

    final resp = await http.post(
      url,
      headers: _headers(auth: true),
      body: jsonEncode(payload),
    );
    // Response logging removed for security

    final body = jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'ok': true, 'body': body};
    } else {
      return {
        'ok': false,
        'body': body,
        'error': 'Declaration submission failed',
      };
    }
  }

  // Static method to get member by email (used by multiple screens)
  static Future<Map<String, dynamic>> getMemberByEmail(String email) async {
    final url = Uri.parse('$baseUrl/auth/member-by-email/$email');
    // Logging removed for security - no longer exposing member lookup data
    developer.log('ApiService: getMemberByEmail called', name: 'ApiService');

    final resp = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    // Response logging removed for security

    final body = _jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      // Backend returns {success: true, data: {member: {...}}}
      // Extract the member data for compatibility
      final memberData = body['data']?['member'];
      return {'success': true, 'data': memberData};
    } else {
      return {
        'success': false,
        'error': body['message'] ?? 'Failed to get member by email',
      };
    }
  }

  // Static method to get complete member profile (used by profile detail screen)
  static Future<Map<String, dynamic>> getMemberProfile(String memberId) async {
    final url = Uri.parse('$baseUrl/profile/$memberId');
    // Logging removed for security - no longer exposing profile lookup data
    developer.log('ApiService: getMemberProfile called', name: 'ApiService');

    final resp = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    // Response logging removed for security

    final body = _jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'success': true, 'data': body['data']};
    } else {
      return {
        'success': false,
        'error': body['message'] ?? 'Failed to get member profile',
      };
    }
  }

  // Static method to get all members (used by browse members screen)
  static Future<Map<String, dynamic>> getMembers({
    int page = 1,
    int limit = 10,
  }) async {
    final url = Uri.parse('$baseUrl/members?page=$page&limit=$limit');
    // Logging removed for security - no longer exposing member lookup data
    developer.log('ApiService: getMembers called', name: 'ApiService');

    final resp = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    // Response logging removed for security

    final body = _jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'success': true, 'data': body['data']};
    } else {
      return {
        'success': false,
        'error': body['message'] ?? 'Failed to get members',
      };
    }
  }

  // Static method to save declaration (used by declaration form)
  static Future<Map<String, dynamic>> saveDeclaration(
    String memberId,
    Map<String, dynamic> payload,
  ) async {
    final url = Uri.parse('$baseUrl/profile/declaration');
    // Logging removed for security - no longer exposing declaration data
    developer.log('ApiService: saveDeclaration called', name: 'ApiService');

    final requestPayload = {'memberId': memberId, ...payload};
    final resp = await http.post(
      url,
      headers: await _staticHeaders(),
      body: jsonEncode(requestPayload),
    );
    // Response logging removed for security

    final body = _jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'success': true, 'data': body['data']};
    } else {
      return {
        'success': false,
        'error': body['message'] ?? 'Failed to save declaration',
      };
    }
  }

  // Static method to submit application for approval workflow
  static Future<Map<String, dynamic>> submitApplication(
    Map<String, dynamic> payload,
  ) async {
    final url = Uri.parse('$baseUrl/applications/submit');
    developer.log('ApiService: submitApplication called', name: 'ApiService');

    final resp = await http.post(
      url,
      headers: await _staticHeaders(),
      body: jsonEncode(payload),
    );

    final body = _jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'success': true, 'data': body};
    } else {
      return {
        'success': false,
        'error': body['message'] ?? 'Failed to submit application',
      };
    }
  }

  // Static method to save business info (used by business information form)
  static Future<Map<String, dynamic>> saveBusinessInfo(
    String memberId,
    Map<String, dynamic> payload,
  ) async {
    final url = Uri.parse('$baseUrl/profile/business-info');
    // Logging removed for security - no longer exposing business data
    developer.log('ApiService: saveBusinessInfo called', name: 'ApiService');

    final requestPayload = {'memberId': memberId, ...payload};
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestPayload),
    );
    // Response logging removed for security

    final body = _jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'success': true, 'data': body['data']};
    } else {
      return {
        'success': false,
        'error': body['message'] ?? 'Failed to save business info',
      };
    }
  }

  // Static method to save financial info (used by financial compliance form)
  static Future<Map<String, dynamic>> saveFinancialInfo(
    String memberId,
    Map<String, dynamic> payload,
  ) async {
    final url = Uri.parse('$baseUrl/profile/financial-info');
    // Logging removed for security - no longer exposing financial data
    developer.log('ApiService: saveFinancialInfo called', name: 'ApiService');

    final requestPayload = {'memberId': memberId, ...payload};
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestPayload),
    );
    // Response logging removed for security

    final body = _jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'success': true, 'data': body['data']};
    } else {
      return {
        'success': false,
        'error': body['message'] ?? 'Failed to save financial info',
      };
    }
  }

  // Static helper for JSON decoding (used by static method)
  static dynamic _jsonDecodeSafe(String input) {
    try {
      return input.isNotEmpty ? jsonDecode(input) : null;
    } catch (e) {
      developer.log('_jsonDecodeSafe error: $e', name: 'ApiService');
      return input;
    }
  }

  // ---- Helper methods for fallback routing ----
  static Uri _u(String p) => Uri.parse('$baseUrl$p');

  static Future<http.Response> _getWithFallback(String pathAfterBase) async {
    // Try /api/applications first, then /applications
    final r1 = await http.get(_u('/api/applications$pathAfterBase'));
    if (r1.statusCode != 404) return r1;
    final r2 = await http.get(_u('/applications$pathAfterBase'));
    return r2;
  }

  static Future<http.Response> _postWithFallback(
    String pathAfterBase,
    Map body,
  ) async {
    final h = {'Content-Type': 'application/json'};
    final r1 = await http.post(
      _u('/api/applications$pathAfterBase'),
      headers: h,
      body: jsonEncode(body),
    );
    if (r1.statusCode != 404) return r1;
    final r2 = await http.post(
      _u('/applications$pathAfterBase'),
      headers: h,
      body: jsonEncode(body),
    );
    return r2;
  }

  static Exception _err(http.Response r) =>
      Exception('HTTP ${r.statusCode}: ${r.body.isEmpty ? "No body" : r.body}');

  // Get applications for block admin
  static Future<List<dynamic>> getBlockAdminApplications(
    String blockAdminId,
  ) async {
    // Prefer direct route under baseUrl to avoid double-/api prefix issues
    final url = Uri.parse('$baseUrl/applications/block/$blockAdminId');
    http.Response res;
    try {
      res = await http.get(url, headers: await _staticHeaders());
    } catch (e) {
      // Fallback: try legacy paths if direct route fails at network layer
      res = await _getWithFallback('/block/$blockAdminId');
    }

    if (res.statusCode == 200) {
      final data = _jsonDecodeSafe(res.body);
      // Support both array and wrapped `{ applications: [...] }` shapes
      if (data is List) return data;
      if (data is Map) {
        final apps = data['applications'];
        if (apps is List) return apps;
      }
      return [];
    }
    throw _err(res);
  }

  // Review block application (approve/reject)
  static Future<bool> reviewBlockApplication(
    String appId,
    String action, {
    String? reason,
    required String adminId,
  }) async {
    final body = {
      'action': action,
      'adminId': adminId,
      if (reason != null) 'reason': reason,
    };
    final res = await _postWithFallback('/block-review/$appId', body);
    if (res.statusCode == 200) return true;
    throw _err(res);
  }

  // Get applications for district admin
  static Future<List<Map<String, dynamic>>> getDistrictAdminApplications(
    String districtAdminId,
  ) async {
    final url = Uri.parse(
      '$baseUrl/api/applications/district/$districtAdminId',
    );
    developer.log(
      'ApiService: getDistrictAdminApplications called for admin: $districtAdminId',
      name: 'ApiService',
    );

    try {
      final resp = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      final body = _jsonDecodeSafe(resp.body);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (body is List) {
          return List<Map<String, dynamic>>.from(body);
        } else {
          return [];
        }
      } else {
        throw Exception(body['message'] ?? 'Failed to fetch applications');
      }
    } catch (e) {
      developer.log(
        'getDistrictAdminApplications error: $e',
        name: 'ApiService',
      );
      throw Exception('Network error: $e');
    }
  }

  // Review district application (approve/reject)
  static Future<bool> reviewDistrictApplication(
    String applicationId,
    String action, {
    String? reason,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/applications/district-review/$applicationId',
    );
    developer.log(
      'ApiService: reviewDistrictApplication called - action: $action',
      name: 'ApiService',
    );

    try {
      final payload = {'action': action, if (reason != null) 'reason': reason};

      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      final body = _jsonDecodeSafe(resp.body);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return body['success'] == true;
      } else {
        throw Exception(body['message'] ?? 'Failed to review application');
      }
    } catch (e) {
      developer.log('reviewDistrictApplication error: $e', name: 'ApiService');
      throw Exception('Network error: $e');
    }
  }
}
