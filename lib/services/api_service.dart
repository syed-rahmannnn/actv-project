import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;

class ApiService {
  // Replace with your Render domain (include https)
  static const String baseUrl =
      'https://actv-project.onrender.com/api'; // Render domain

  String? _token;

  // Helper to get headers, include token if present
  Map<String, String> _headers({bool json = true, bool auth = false}) {
    final headers = <String, String>{};
    if (json) headers['Content-Type'] = 'application/json';
    if (auth && _token != null) headers['Authorization'] = 'Bearer $_token';
    return headers;
  }

  void setToken(String token) {
    _token = token;
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
      developer.log('jsonDecodeSafe error: $e', name: 'ApiService');
      return input;
    }
  }

  // Register user with proper backend route
  Future<Map<String, dynamic>> register(Map<String, dynamic> payload) async {
    final url = Uri.parse('$baseUrl/auth/register'); // auth.js register route
    developer.log('POST $url', name: 'ApiService');
    developer.log('payload: ${jsonEncode(payload)}', name: 'ApiService');

    final resp = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(payload),
    );
    developer.log('status: ${resp.statusCode}', name: 'ApiService');
    developer.log('body: ${resp.body}', name: 'ApiService');

    // Decode and normalize body to a Map to avoid String index errors on Lists
    final dynamic decoded = jsonDecodeSafe(resp.body);
    final Map<String, dynamic> body = decoded is Map<String, dynamic>
        ? decoded
        : decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : <String, dynamic>{};

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      // backend returns data.token and data.member
      final dynamic data = body['data'];
      final String? token = data is Map && data['token'] is String
          ? data['token'] as String
          : body['token'] is String
              ? body['token'] as String
              : null;
      if (token != null) setToken(token);
      return {'ok': true, 'body': body, 'token': token};
    } else {
      return {'ok': false, 'status': resp.statusCode, 'body': body};
    }
  }

  // Login user
  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final payload = {'email': email.trim(), 'password': password};
    developer.log('POST $url', name: 'ApiService');
    developer.log('payload: ${jsonEncode(payload)}', name: 'ApiService');

    final resp = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(payload),
    );
    developer.log('status: ${resp.statusCode}', name: 'ApiService');
    developer.log('body: ${resp.body}', name: 'ApiService');

    final body = jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final token = body['data']?['token'] ?? body['token'];
      if (token != null) setToken(token as String);
      return {'ok': true, 'body': body, 'token': token};
    } else {
      return {'ok': false, 'status': resp.statusCode, 'body': body};
    }
  }

  // Generic put for updating member by id (example)
  Future<Map<String, dynamic>> updateMember(
    String id,
    Map<String, dynamic> updates,
  ) async {
    final url = Uri.parse('$baseUrl/members/$id');
    developer.log('PUT $url (auth: ${_token != null})', name: 'ApiService');
    developer.log('updates: ${jsonEncode(updates)}', name: 'ApiService');

    final resp = await http.put(
      url,
      headers: _headers(auth: true),
      body: jsonEncode(updates),
    );
    developer.log('status: ${resp.statusCode}', name: 'ApiService');
    developer.log('body: ${resp.body}', name: 'ApiService');
    final body = jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'ok': true, 'body': body};
    } else {
      return {'ok': false, 'status': resp.statusCode, 'body': body};
    }
  }

  // Get all members (for browse members screen)
  static Future<Map<String, dynamic>> getMembers({
    int page = 1,
    int limit = 10,
  }) async {
    final url = Uri.parse('$baseUrl/members?page=$page&limit=$limit');
    developer.log('GET $url', name: 'ApiService');

    final resp = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    developer.log('status: ${resp.statusCode}', name: 'ApiService');
    developer.log('body: ${resp.body}', name: 'ApiService');

    // Create a temporary instance to use jsonDecodeSafe
    final apiService = ApiService();
    final body = apiService.jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'success': true, 'data': body['data']['members']};
    } else {
      return {'success': false, 'status': resp.statusCode, 'body': body};
    }
  }

  // Get member by Firebase UID (using email from Firebase user)
  static Future<Map<String, dynamic>> getMemberByFirebaseUid(
    String firebaseUid,
  ) async {
    // Since the backend doesn't store Firebase UID, we'll use the email from Firebase Auth
    // This method should be called with the user's email, not UID
    // For now, return an error indicating this needs to be updated
    developer.log(
      'getMemberByFirebaseUid called with UID: $firebaseUid',
      name: 'ApiService',
    );
    return {
      'success': false,
      'message':
          'getMemberByFirebaseUid needs to be updated to use email instead of UID',
    };
  }

  // Get member by email (alternative to getMemberByFirebaseUid)
  static Future<Map<String, dynamic>> getMemberByEmail(String email) async {
    final url = Uri.parse(
      '$baseUrl/members/by-email?email=${Uri.encodeComponent(email)}',
    );
    developer.log('GET $url', name: 'ApiService');

    final resp = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    developer.log('status: ${resp.statusCode}', name: 'ApiService');
    developer.log('body: ${resp.body}', name: 'ApiService');

    // Create a temporary instance to use jsonDecodeSafe
    final apiService = ApiService();
    final body = apiService.jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'success': true, 'data': body['data']};
    } else {
      return {'success': false, 'status': resp.statusCode, 'body': body};
    }
  }

  // Get business information by member ID
  static Future<Map<String, dynamic>> getBusinessInfo(String memberId) async {
    final url = Uri.parse('$baseUrl/profile/business-info/$memberId');
    developer.log('GET $url', name: 'ApiService');

    final resp = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    developer.log('status: ${resp.statusCode}', name: 'ApiService');
    developer.log('body: ${resp.body}', name: 'ApiService');

    // Create a temporary instance to use jsonDecodeSafe
    final apiService = ApiService();
    final body = apiService.jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'success': true, 'data': body['data']};
    } else {
      return {'success': false, 'status': resp.statusCode, 'body': body};
    }
  }

  // Get complete profile by member ID
  static Future<Map<String, dynamic>> getMemberProfile(String memberId) async {
    final url = Uri.parse('$baseUrl/profile/$memberId');
    developer.log('GET $url', name: 'ApiService');

    final resp = await http.get(
      url,
      headers: {'Content-Type': 'application/json'},
    );
    developer.log('status: ${resp.statusCode}', name: 'ApiService');
    developer.log('body: ${resp.body}', name: 'ApiService');

    final apiService = ApiService();
    final body = apiService.jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'success': true, 'data': body['data']};
    } else {
      return {'success': false, 'status': resp.statusCode, 'body': body};
    }
  }

  // Save business information
  static Future<Map<String, dynamic>> saveBusinessInfo(
    String memberId,
    Map<String, dynamic> businessData,
  ) async {
    final url = Uri.parse('$baseUrl/profile/business-info');
    final payload = {'memberId': memberId, ...businessData};
    developer.log('POST $url', name: 'ApiService');
    developer.log('payload: ${jsonEncode(payload)}', name: 'ApiService');

    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    developer.log('status: ${resp.statusCode}', name: 'ApiService');
    developer.log('body: ${resp.body}', name: 'ApiService');

    // Create a temporary instance to use jsonDecodeSafe
    final apiService = ApiService();
    final body = apiService.jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'success': true, 'data': body['data']};
    } else {
      return {'success': false, 'status': resp.statusCode, 'body': body};
    }
  }

  // Save financial & compliance information
  static Future<Map<String, dynamic>> saveFinancialInfo(
    String memberId,
    Map<String, dynamic> financialData,
  ) async {
    final url = Uri.parse('$baseUrl/profile/financial-info');
    final payload = {'memberId': memberId, ...financialData};
    developer.log('POST $url', name: 'ApiService');
    developer.log('payload: ${jsonEncode(payload)}', name: 'ApiService');

    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    developer.log('status: ${resp.statusCode}', name: 'ApiService');
    developer.log('body: ${resp.body}', name: 'ApiService');

    final apiService = ApiService();
    final body = apiService.jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'success': true, 'data': body['data']};
    } else {
      return {'success': false, 'status': resp.statusCode, 'body': body};
    }
  }

  // Save declaration information
  static Future<Map<String, dynamic>> saveDeclaration(
    String memberId,
    Map<String, dynamic> declarationData,
  ) async {
    final url = Uri.parse('$baseUrl/profile/declaration');
    final payload = {'memberId': memberId, ...declarationData};
    developer.log('POST $url', name: 'ApiService');
    developer.log('payload: ${jsonEncode(payload)}', name: 'ApiService');

    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    developer.log('status: ${resp.statusCode}', name: 'ApiService');
    developer.log('body: ${resp.body}', name: 'ApiService');

    final apiService = ApiService();
    final body = apiService.jsonDecodeSafe(resp.body);
    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      return {'success': true, 'data': body['data']};
    } else {
      return {'success': false, 'status': resp.statusCode, 'body': body};
    }
  }
}
