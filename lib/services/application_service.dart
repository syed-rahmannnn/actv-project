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
    print('ApplicationService: getBlockInbox called with adminId: $blockAdminId');
    final url = '$baseUrl/applications/block/$blockAdminId';
    print('ApplicationService: Making request to: $url');
    print('ApplicationService: Headers: $_headers');
    
    final res = await http.get(
      Uri.parse(url),
      headers: _headers,
    );
    
    print('ApplicationService: getBlockInbox response status: ${res.statusCode}');
    print('ApplicationService: getBlockInbox response body: ${res.body}');
    
    final data = jsonDecode(res.body);
    print('ApplicationService: Parsed data: $data');
    print('ApplicationService: Data type: ${data.runtimeType}');

    // Handle error responses
    if (res.statusCode != 200) {
      print('ApplicationService: Error response in getBlockInbox');
      // For error responses, data might be an object with message
      if (data is Map<String, dynamic>) {
        throw Exception(data['message'] ?? 'Failed to fetch block inbox');
      } else {
        throw Exception('Failed to fetch block inbox');
      }
    }

    // The backend returns applications directly as an array, not wrapped in an object
    if (data is List<dynamic>) {
      print('ApplicationService: Applications list length: ${data.length}');
      return data;
    } else {
      print('ApplicationService: Unexpected response format, returning empty list');
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
      final url = '$baseUrl/applications/by-admin/$adminId?role=$role&status=$status';
      print('ApplicationService: Making API call to: $url');
      print('ApplicationService: Headers: $_headers');
      print('ApplicationService: AdminId: $adminId, Role: $role, Status: $status');
      
      final res = await http.get(
        Uri.parse(url),
        headers: _headers,
      );
      
      print('ApplicationService: Response status code: ${res.statusCode}');
      print('ApplicationService: Response body: ${res.body}');
      
      if (res.statusCode == 200) {
        final responseData = jsonDecode(res.body);
        print('ApplicationService: Parsed response data: $responseData');
        print('ApplicationService: Response data type: ${responseData.runtimeType}');
        
        if (responseData is Map<String, dynamic>) {
          final count = responseData['count'];
          print('ApplicationService: Count value: $count, Type: ${count.runtimeType}');
          return (count ?? 0) as int;
        } else {
          print('ApplicationService: Response is not a Map, returning 0');
          return 0;
        }
      } else {
        print('ApplicationService: Non-200 status code, returning 0');
        return 0;
      }
    } catch (e) {
      print('ApplicationService: Exception in _getCount: $e');
      return 0;
    }
  }

  Future<Map<String, int>> getBlockStats(String blockAdminId) async {
    print('ApplicationService: getBlockStats called with adminId: $blockAdminId');
    print('ApplicationService: Base URL: $baseUrl');
    print('ApplicationService: Token available: ${token != null && token!.isNotEmpty}');
    
    try {
      print('ApplicationService: Fetching all applications...');
      final allApplications = await getBlockInbox(blockAdminId);
      print('ApplicationService: All applications count: ${allApplications.length}');
      
      // Filter pending applications (same logic as Dashboard)
      final pendingApps = allApplications.where((app) {
        final status = (app['status'] ?? '').toString().toLowerCase();
        return status == 'pending-block' || status == 'submitted' || status == 'pending';
      }).toList();
      print('ApplicationService: Pending applications count: ${pendingApps.length}');
      
      print('ApplicationService: Fetching approved count...');
      final approved = await _getCount(
        adminId: blockAdminId,
        role: 'block',
        status: 'Approved',
      );
      print('ApplicationService: Approved count: $approved');
      
      print('ApplicationService: Fetching rejected count...');
      final rejected = await _getCount(
        adminId: blockAdminId,
        role: 'block',
        status: 'Rejected',
      );
      print('ApplicationService: Rejected count: $rejected');
      
      final stats = {
        'pending': pendingApps.length,
        'approved': approved,
        'rejected': rejected,
        'total': pendingApps.length + approved + rejected,
      };
      
      print('ApplicationService: Final stats: $stats');
      return stats;
    } catch (e) {
      print('ApplicationService: Exception in getBlockStats: $e');
      print('ApplicationService: Stack trace: ${StackTrace.current}');
      rethrow;
    }
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
      throw Exception('Failed to fetch district admin details: ${res.statusCode}');
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
