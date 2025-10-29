import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/status.dart';
import '../models/block_stats.dart';
import '../models/user_application.dart';

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

  // ---------- TYPED: APPLICATIONS & STATS ----------
  Future<List<UserApplication>> getBlockApplications({required String blockId}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/applications/block/$blockId'),
      headers: _headers,
    );
    final data = jsonDecode(res.body);

    if (res.statusCode != 200) {
      throw Exception((data is Map && data['message'] != null)
          ? data['message']
          : 'Failed to fetch block applications');
    }

    final list = (data is Map<String, dynamic>)
        ? (data['applications'] ?? [])
        : (data as List<dynamic>);

    return list
        .cast<Map<String, dynamic>>()
        .map((j) => UserApplication.fromJson(j))
        .toList();
  }

  Future<BlockStats> getBlockStatsModel({required String blockId}) async {
    // Try a dedicated stats endpoint if available.
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/block-admin/$blockId/stats'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        if (body is Map<String, dynamic>) {
          final total = (body['total'] ?? 0) as int;
          final pending = (body['pending'] ?? 0) as int;
          final approved = (body['approved'] ?? 0) as int;
          final rejected = (body['rejected'] ?? 0) as int;
          return BlockStats(
            total: total,
            pending: pending,
            approved: approved,
            rejected: rejected,
          );
        }
      }
    } catch (_) {
      // fall through to compute from lists
    }

    // Fallback: compute stats from applications list
    final list = await getBlockApplications(blockId: blockId);
    final total = list.length;
    final approved = list.where((u) => u.status == MemberStatus.approved).length;
    final rejected = list.where((u) => u.status == MemberStatus.rejected).length;
    final pending = list.where((u) => u.status == MemberStatus.pending).length;

    return BlockStats(
      total: total,
      pending: pending,
      approved: approved,
      rejected: rejected,
    );
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
