import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// -------------------------------
/// Simple service used by dashboard
/// -------------------------------
class ApplicationService {
  final String baseUrl;
  final Map<String, String> headers;

  ApplicationService({required this.baseUrl, required String token})
    : headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  Future<List<dynamic>> getBlockInbox(String blockAdminId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/applications/block/$blockAdminId'),
      headers: headers,
    );
    final data = jsonDecode(res.body);
    return (data['applications'] ?? []) as List<dynamic>;
  }

  /// Optional helper endpoints for counts (if your backend provides them).
  /// If they don't exist, we simply return 0 for those counts.
  Future<int> _getCountByStatus({
    required String blockAdminId,
    required String status, // 'Approved' | 'Rejected'
  }) async {
    try {
      final url =
          '$baseUrl/applications/by-admin/$blockAdminId?role=block&status=$status';
      final res = await http.get(Uri.parse(url), headers: headers);
      if (res.statusCode == 200) {
        final body = jsonDecode(res.body);
        return (body['count'] ?? 0) as int;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<Map<String, int>> getBlockStats(String blockAdminId) async {
    final pending = await getBlockInbox(blockAdminId);
    final approved = await _getCountByStatus(
      blockAdminId: blockAdminId,
      status: 'Approved',
    );
    final rejected = await _getCountByStatus(
      blockAdminId: blockAdminId,
      status: 'Rejected',
    );
    return {
      'pending': pending.length,
      'approved': approved,
      'rejected': rejected,
      'total': pending.length + approved + rejected,
    };
  }

  Future<Map<String, dynamic>> blockReview({
    required String appId,
    required String adminId,
    required String action, // 'approve' | 'reject'
    String? reason,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/applications/block-review/$appId'),
      headers: headers,
      body: jsonEncode({
        'adminId': adminId, // API now accepts either MongoDB _id or admin code
        'action': action,
        'reason': reason,
      }),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}

/// ------------------------------------------------------
/// Block Admin Dashboard (self-contained, no providers)
/// ------------------------------------------------------
class BlockAdminDashboard extends StatefulWidget {
  final String apiBaseUrl;
  final String? authToken;
  final String? token; // Alternative parameter name for compatibility
  final String blockAdminId;
  final String blockName; // e.g., "Erode"
  final String? adminEmail; // e.g., "blockadmin@activ.com"
  final String? blockEmail; // Alternative parameter name for compatibility

  const BlockAdminDashboard({
    super.key,
    required this.apiBaseUrl,
    this.authToken,
    this.token,
    required this.blockAdminId,
    required this.blockName,
    this.adminEmail,
    this.blockEmail,
  }) : assert(
         authToken != null || token != null,
         'Either authToken or token must be provided',
       ),
       assert(
         adminEmail != null || blockEmail != null,
         'Either adminEmail or blockEmail must be provided',
       );

  @override
  State<BlockAdminDashboard> createState() => _BlockAdminDashboardState();
}

class _BlockAdminDashboardState extends State<BlockAdminDashboard> {
  late final ApplicationService _svc;

  bool _isLoading = true;
  int _selectedIndex = 0;

  Map<String, int> _stats = {
    'total': 0,
    'pending': 0,
    'approved': 0,
    'rejected': 0,
  };
  List<dynamic> _pendingApplications = [];

  @override
  void initState() {
    super.initState();
    _svc = ApplicationService(
      baseUrl: widget.apiBaseUrl,
      token: widget.authToken ?? widget.token!,
    );
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    // Fetch counts and pending list in parallel
    final results = await Future.wait([
      _svc.getBlockStats(widget.blockAdminId),
      _svc.getBlockInbox(widget.blockAdminId),
    ]);

    if (!mounted) return;
    setState(() {
      _stats = results[0] as Map<String, int>;
      _pendingApplications = results[1] as List<dynamic>;
      _isLoading = false;
    });
  }

  // Alternative simplified method name for compatibility
  // ignore: unused_element
  Future<void> _loadData() async {
    await _loadDashboardData();
  }

  // Alternative simplified method name for compatibility
  // ignore: unused_element
  Future<void> _review(String id, String action, {String? reason}) async {
    await _handleApplicationAction(appId: id, action: action, reason: reason);
  }

  Future<void> _handleApplicationAction({
    required String appId,
    required String action, // 'approve' | 'reject'
    String? reason,
  }) async {
    setState(() => _isLoading = true);
    final res = await _svc.blockReview(
      appId: appId,
      adminId: widget.blockAdminId,
      action: action,
      reason: reason,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(res['message']?.toString() ?? 'Action complete')),
    );

    // Refresh list and counts
    await _loadDashboardData();
  }

  // Alternative simplified method name for compatibility
  // ignore: unused_element
  Future<void> _rejectDialog(String id) async {
    await _showRejectDialog(id);
  }

  Future<void> _showRejectDialog(String appId) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reject Application'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Reason (optional)'),
            maxLines: 2,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _handleApplicationAction(
        appId: appId,
        action: 'reject',
        reason: controller.text.trim().isEmpty ? null : controller.text.trim(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: _buildDashboardView(),
            ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        selectedItemColor: const Color(0xFF1E88FF),
        unselectedItemColor: const Color(0xFF6B7280),
        backgroundColor: Colors.white,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_outlined),
            activeIcon: Icon(Icons.verified),
            label: 'Approvals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            activeIcon: Icon(Icons.group),
            label: 'Members',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _cardsRow({required Widget left, required Widget right}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 16),
        Expanded(child: right),
      ],
    );
  }

  Widget _statCard({
  required String title,
  required int value,
  required String subtitle,
  required Color bg,
  Widget? icon,
  Color? valueColor,
  Color? badgeColor,
  String? badgeText,
}) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
            if (icon != null) icon,
            if (badgeText != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(badgeText,
                    style: const TextStyle(fontSize: 12, color: Colors.white)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: valueColor ?? const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(subtitle,
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12)),
      ],
    ),
  );
}
Widget _buildStatGrid() {
  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Members',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                      ),
                      const Icon(Icons.info_outline, size: 16, color: Color(0xFF6B7280)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_stats['total'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'block level',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F5FF),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pending',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'pending',
                          style: TextStyle(fontSize: 10, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_stats['pending'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Awaiting approval',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECF9F0),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Approved',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.check_circle, size: 16, color: Color(0xFF16A34A)),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF16A34A),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'approved',
                              style: TextStyle(fontSize: 10, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_stats['approved'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Successfully approved',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEF0),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Rejected',
                        style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.cancel, size: 16, color: Color(0xFFFF5C5C)),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF5C5C),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'rejected',
                              style: TextStyle(fontSize: 10, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_stats['rejected'] ?? 0}',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF5C5C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Request denied',
                    style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

  Widget _memberCard({
    required String name,
    required String email,
    required String role,
    required String gender,
    required String block,
    required String phone,
    required String status,
    required VoidCallback onApprove,
    required VoidCallback onReject,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 13),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 22, child: Icon(Icons.person)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF3A78D2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(email, style: const TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text(
            'Role: $role, Gender: $gender',
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 2),
          Text('$block Block', style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 6),
          Text(phone, style: const TextStyle(color: Colors.green)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Approve'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onReject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Reject'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  Widget _buildPendingList() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E88FF),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Text(
                "Pending (${_pendingApplications.length})",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      const SizedBox(height: 12),
      ..._pendingApplications.map((app) {
        final name = (app['fullName'] ?? '').toString();
        final email = (app['email'] ?? '').toString();
        final role = (app['formData']?['role'] ?? 'Member').toString();
        final gender = (app['formData']?['gender'] ?? '—').toString();
        final block = (app['block'] ?? '—').toString();
        final phone = (app['phone'] ?? '—').toString();
        final id = (app['_id'] ?? '').toString();

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFFDEEAF9),
                      child: Icon(Icons.person, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE6F5FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'pending',
                                  style: TextStyle(
                                    color: Color(0xFF0366A6),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(email,
                              style: const TextStyle(color: Color(0xFF6B7280))),
                          const SizedBox(height: 6),
                          Text(
                              "Role: $role, Gender: $gender",
                              style: const TextStyle(color: Color(0xFF6B7280))),
                          const SizedBox(height: 6),
                          Text(block,
                              style: const TextStyle(color: Color(0xFF6B7280))),
                          const SizedBox(height: 8),
                          Text(phone,
                              style: const TextStyle(
                                  color: Color(0xFF16A34A),
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _handleApplicationAction(
                        appId: id,
                        action: 'approve',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      ),
                      child: const Text('Approve'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _showRejectDialog(id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5C5C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                      ),
                      child: const Text('Reject'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ],
  );
}
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Block Admin Dashboard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10345A),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Manage Block Level',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                ),
                child: const Text('Block',
                    style: TextStyle(fontWeight: FontWeight.w500, color: Colors.white)),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.filter_list, color: Color(0xFF10345A)),
              ),
              Stack(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Icon(
                      Icons.notifications_none,
                      color: Color(0xFF10345A),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E88FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '4',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 7),
              const CircleAvatar(
                radius: 18,
                backgroundColor: Color(0xFF1E88FF),
                child: Text(
                  'A',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

Widget _buildDashboardView() {
  return SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildStatGrid(),
          const SizedBox(height: 18),
          _buildPendingList(),
          const SizedBox(height: 80),
        ],
      ),
    ),
  );
}
}