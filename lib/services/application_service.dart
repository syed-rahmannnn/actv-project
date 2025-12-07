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
    final url = '$baseUrl/applications/block/$blockAdminId';

    final res = await http.get(Uri.parse(url), headers: _headers);

    final data = jsonDecode(res.body);

    // Handle error responses
    if (res.statusCode != 200) {
      // For error responses, data might be an object with message
      if (data is Map<String, dynamic>) {
        throw Exception(data['message'] ?? 'Failed to fetch block inbox');
      } else {
        throw Exception('Failed to fetch block inbox');
      }
    }

    // The backend returns applications directly as an array, not wrapped in an object
    if (data is List<dynamic>) {
      return data;
    } else {
      return [];
    }
  }

  Future<List<dynamic>> getBlockApplicationsByStatus({
    required String blockAdminId,
    required String status, // Approved | Rejected
  }) async {
    final url =
        '$baseUrl/applications/list-by-admin/$blockAdminId?role=block&status=$status';
    final res = await http.get(Uri.parse(url), headers: _headers);

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch $status applications');
    }

    final data = jsonDecode(res.body);
    if (data is List<dynamic>) {
      return data
          .map((app) => app is Map ? Map<String, dynamic>.from(app) : app)
          .toList();
    } else {
      return [];
    }
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

  Future<List<dynamic>> getDistrictApplicationsByStatus({
    required String districtAdminId,
    required String status, // Approved | Rejected
  }) async {
    final url =
        '$baseUrl/applications/list-by-admin/$districtAdminId?role=district&status=$status';
    final res = await http.get(Uri.parse(url), headers: _headers);

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch $status applications');
    }

    final data = jsonDecode(res.body);
    if (data is List<dynamic>) {
      return data
          .map((app) => app is Map ? Map<String, dynamic>.from(app) : app)
          .toList();
    } else {
      return [];
    }
  }

  Future<Map<String, int>> getDistrictStats(String districtAdminId) async {
    try {
      final pending = await getDistrictInbox(districtAdminId);
      final approvedList = await getDistrictApplicationsByStatus(
        districtAdminId: districtAdminId,
        status: 'Approved',
      );
      final rejectedList = await getDistrictApplicationsByStatus(
        districtAdminId: districtAdminId,
        status: 'Rejected',
      );
      return {
        'pending': pending.length,
        'approved': approvedList.length,
        'rejected': rejectedList.length,
        'total': pending.length + approvedList.length + rejectedList.length,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch ALL applications for a district admin.
  /// Uses `/applications/district/:districtAdminId` which now returns all statuses.
  Future<List<Map<String, dynamic>>> getDistrictApplications({
    required String districtAdminId,
    String status = 'all', // retained for compatibility; currently ignored
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/applications/district/$districtAdminId'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['applications'] is List) {
          return List<Map<String, dynamic>>.from(data['applications'] as List);
        }
        if (data is List) {
          return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      }
    } catch (e) {
      // Fallback to the known pending-only inbox if direct route fails
      final inbox = await getDistrictInbox(districtAdminId);
      return inbox.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    // HTTP error fallback
    final inbox = await getDistrictInbox(districtAdminId);
    return inbox.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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

  Future<List<dynamic>> getStateApplicationsByStatus({
    required String stateAdminId,
    required String status, // Approved | Rejected
  }) async {
    final url =
        '$baseUrl/applications/list-by-admin/$stateAdminId?role=state&status=$status';
    final res = await http.get(Uri.parse(url), headers: _headers);

    if (res.statusCode != 200) {
      throw Exception('Failed to fetch $status applications');
    }

    final data = jsonDecode(res.body);
    if (data is List<dynamic>) {
      return data
          .map((app) => app is Map ? Map<String, dynamic>.from(app) : app)
          .toList();
    } else {
      return [];
    }
  }

  Future<Map<String, int>> getStateStats(String stateAdminId) async {
    try {
      final pending = await getStateInbox(stateAdminId);
      final approvedList = await getStateApplicationsByStatus(
        stateAdminId: stateAdminId,
        status: 'Approved',
      );
      final rejectedList = await getStateApplicationsByStatus(
        stateAdminId: stateAdminId,
        status: 'Rejected',
      );
      return {
        'pending': pending.length,
        'approved': approvedList.length,
        'rejected': rejectedList.length,
        'total': pending.length + approvedList.length + rejectedList.length,
      };
    } catch (e) {
      rethrow;
    }
  }

  /// Fetch ALL applications for a state admin.
  /// Uses `/applications/state/:stateAdminId` which will return all statuses
  /// after backend update. Falls back to pending-only inbox if necessary.
  Future<List<Map<String, dynamic>>> getStateApplications({
    required String stateAdminId,
    String status = 'all', // retained for compatibility; currently ignored
  }) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/applications/state/$stateAdminId'),
        headers: _headers,
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is Map && data['applications'] is List) {
          return List<Map<String, dynamic>>.from(data['applications'] as List);
        }
        if (data is List) {
          return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      }
    } catch (e) {
      final inbox = await getStateInbox(stateAdminId);
      return inbox.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }

    final inbox = await getStateInbox(stateAdminId);
    return inbox.map((e) => Map<String, dynamic>.from(e as Map)).toList();
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
      final url =
          '$baseUrl/applications/by-admin/$adminId?role=$role&status=$status';

      final res = await http.get(Uri.parse(url), headers: _headers);

      if (res.statusCode == 200) {
        final responseData = jsonDecode(res.body);

        if (responseData is Map<String, dynamic>) {
          final count = responseData['count'];
          return (count ?? 0) as int;
        } else {
          return 0;
        }
      } else {
        return 0;
      }
    } catch (e) {
      return 0;
    }
  }

  Future<Map<String, int>> getBlockStats(String blockAdminId) async {
    try {
      // Fetch all lists to get real counts from backend
      final pending = await getBlockInbox(blockAdminId);

      final approvedList = await getBlockApplicationsByStatus(
        blockAdminId: blockAdminId,
        status: 'Approved',
      );

      final rejectedList = await getBlockApplicationsByStatus(
        blockAdminId: blockAdminId,
        status: 'Rejected',
      );

      return {
        'pending': pending.length,
        'approved': approvedList.length,
        'rejected': rejectedList.length,
        'total': pending.length + approvedList.length + rejectedList.length,
      };
    } catch (e) {
      rethrow;
    }
  }

  // ---------- ADMIN DETAILS ----------
  Future<Map<String, dynamic>> getBlockAdminDetails(String adminId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin/block/$adminId'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch block admin details: ${res.statusCode}');
    }
  }

  Future<Map<String, dynamic>> getDistrictAdminDetails(String adminId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin/district/$adminId'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception(
        'Failed to fetch district admin details: ${res.statusCode}',
      );
    }
  }

  Future<Map<String, dynamic>> getStateAdminDetails(String adminId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/admin/state/$adminId'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to fetch state admin details: ${res.statusCode}');
    }
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
