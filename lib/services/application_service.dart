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
      final allApplications = await getBlockInbox(blockAdminId);

      // Filter pending applications (same logic as Dashboard)
      final pendingApps = allApplications.where((app) {
        final status = (app['status'] ?? '').toString().toLowerCase();
        return status == 'pending-block' ||
            status == 'submitted' ||
            status == 'pending';
      }).toList();

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

      final stats = {
        'pending': pendingApps.length,
        'approved': approved,
        'rejected': rejected,
        'total': pendingApps.length + approved + rejected,
      };
      return stats;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, int>> getDistrictStats(String districtAdminId) async {
    // Fetch all applications and derive counts to ensure accuracy
    final all = await getDistrictApplications(districtAdminId: districtAdminId);

    // Pending at district stage
    final pendingCount = all.where((app) {
      final status = (app['status'] ?? app['applicationStatus'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      return status.contains('pending-district');
    }).length;

    // Approved by district (includes Pending-State and Approved per backend route)
    final approved = await _getCount(
      adminId: districtAdminId,
      role: 'district',
      status: 'Approved',
    );

    // Rejected (any stage) assigned to this district admin
    // Align with approvals page which shows all 'Rejected' regardless of reviewer
    final rejected = all.where((app) {
      final status = (app['status'] ?? app['applicationStatus'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      return status == 'rejected' || status.contains('rejected');
    }).length;

    return {
      'pending': pendingCount,
      'approved': approved,
      'rejected': rejected,
      'total': pendingCount + approved + rejected,
    };
  }

  Future<Map<String, int>> getStateStats(String stateAdminId) async {
    // Fetch all applications and derive counts to ensure accuracy
    final all = await getStateApplications(stateAdminId: stateAdminId);

    // Pending at state stage
    final pendingCount = all.where((app) {
      final status = (app['status'] ?? app['applicationStatus'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      return status == 'pending-state' || status.contains('pending-state');
    }).length;

    // Approved by state
    final approved = await _getCount(
      adminId: stateAdminId,
      role: 'state',
      status: 'Approved',
    );

    // Rejected (any stage) assigned to this state admin
    final rejected = all.where((app) {
      final status = (app['status'] ?? app['applicationStatus'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      return status == 'rejected' || status.contains('rejected');
    }).length;

    return {
      'pending': pendingCount,
      'approved': approved,
      'rejected': rejected,
      'total': pendingCount + approved + rejected,
    };
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
