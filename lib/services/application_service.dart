import 'dart:convert';
import 'package:http/http.dart' as http;

class ApplicationService {
  final String baseUrl;
  final String? token;
  final Map<String, String>? extraHeaders;

  ApplicationService(this.baseUrl, {this.token, Map<String, String>? headers})
    : extraHeaders = headers;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null && token!.isNotEmpty) 'Authorization': 'Bearer $token',
    ...?extraHeaders,
  };

  // ---------- USER SUBMISSION ----------
  Future<Map<String, dynamic>> submitApplication({
    required String userId,
    required String fullName,
    required String email,
    required String phone,
    required String state,
    required String district,
    required String block,
    required Map<String, dynamic> formData,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/applications/submit'),
      headers: _headers,
      body: jsonEncode({
        'userId': userId,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'state': state.trim(),
        'district': district.trim(),
        'block': block.trim(),
        'formData': formData,
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ---------- INBOXES ----------
  Future<List<dynamic>> getBlockInbox(String blockAdminId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/applications/block/$blockAdminId'),
      headers: _headers,
    );
    final data = jsonDecode(res.body);

    // Handle error responses
    if (res.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to fetch block inbox');
    }

    return (data['applications'] ?? []) as List<dynamic>;
  }

  Future<List<dynamic>> getDistrictInbox(String districtAdminId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/applications/district/$districtAdminId'),
      headers: _headers,
    );
    final data = jsonDecode(res.body);

    // Handle error responses
    if (res.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to fetch district inbox');
    }

    return (data['applications'] ?? []) as List<dynamic>;
  }

  Future<List<dynamic>> getStateInbox(String stateAdminId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/applications/state/$stateAdminId'),
      headers: _headers,
    );
    final data = jsonDecode(res.body);

    // Handle error responses
    if (res.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to fetch state inbox');
    }

    return (data['applications'] ?? []) as List<dynamic>;
  }

  // ---------- REVIEWS ----------
  Future<Map<String, dynamic>> blockReview({
    required String appId,
    required String adminId,
    required String action, // 'approve' | 'reject'
    String? reason,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/applications/block-review/$appId'),
      headers: _headers,
      body: jsonEncode({
        'adminId': adminId,
        'action': action,
        'reason': reason,
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;

    // Handle error responses
    if (res.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to process block review');
    }

    return data;
  }

  Future<Map<String, dynamic>> districtReview({
    required String appId,
    required String adminId,
    required String action, // 'approve' | 'reject'
    String? reason,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/applications/district-review/$appId'),
      headers: _headers,
      body: jsonEncode({
        'adminId': adminId,
        'action': action,
        'reason': reason,
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;

    // Handle error responses
    if (res.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to process district review');
    }

    return data;
  }

  Future<Map<String, dynamic>> stateReview({
    required String appId,
    required String adminId,
    required String action, // 'approve' | 'reject'
    String? reason,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/applications/state-review/$appId'),
      headers: _headers,
      body: jsonEncode({
        'adminId': adminId,
        'action': action,
        'reason': reason,
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;

    // Handle error responses
    if (res.statusCode != 200) {
      throw Exception(data['message'] ?? 'Failed to process state review');
    }

    return data;
  }

  // ---------- STATS ----------
  Future<int> _getCount({
    required String adminId,
    required String role, // 'block' | 'district' | 'state'
    required String status, // 'Approved' | 'Rejected'
  }) async {
    try {
      final res = await http.get(
        Uri.parse(
          '$baseUrl/applications/by-admin/$adminId?role=$role&status=$status',
        ),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        return (jsonDecode(res.body)['count'] ?? 0) as int;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, int>> getBlockStats(String blockAdminId) async {
    final pending = await getBlockInbox(blockAdminId);
    final approved = await _getCount(
      adminId: blockAdminId,
      role: 'block',
      status: 'Approved',
    );
    final rejected = await _getCount(
      adminId: blockAdminId,
      role: 'block',
      status: 'Rejected',
    );
    return {
      'pending': pending.length,
      'approved': approved,
      'rejected': rejected,
      'total': pending.length + approved + rejected,
    };
  }

  Future<Map<String, int>> getDistrictStats(String districtAdminId) async {
    final pending = await getDistrictInbox(districtAdminId);
    final approved = await _getCount(
      adminId: districtAdminId,
      role: 'district',
      status: 'Approved',
    );
    final rejected = await _getCount(
      adminId: districtAdminId,
      role: 'district',
      status: 'Rejected',
    );
    return {
      'pending': pending.length,
      'approved': approved,
      'rejected': rejected,
      'total': pending.length + approved + rejected,
    };
  }

  Future<Map<String, int>> getStateStats(String stateAdminId) async {
    final pending = await getStateInbox(stateAdminId);
    final approved = await _getCount(
      adminId: stateAdminId,
      role: 'state',
      status: 'Approved',
    );
    final rejected = await _getCount(
      adminId: stateAdminId,
      role: 'state',
      status: 'Rejected',
    );
    return {
      'pending': pending.length,
      'approved': approved,
      'rejected': rejected,
      'total': pending.length + approved + rejected,
    };
  }

  // ---------- USER/APPLICATIONS ----------
  Future<Map<String, dynamic>> userApplications(String userId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/applications/user/$userId'),
      headers: _headers,
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getApplicationDetails(String appId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/applications/$appId'),
      headers: _headers,
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
