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
        'adminId': adminId,
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
    // NOTE: _selectedIndex is kept only if you show a BottomNavigationBar.
    // If you don't need it, you can remove it.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Block Admin Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadDashboardData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _cardsRow(
                    left: _statCard(
                      title: 'Total Members',
                      value: _stats['total'] ?? 0,
                      subtitle: 'block level',
                    ),
                    right: _statCard(
                      title: 'Pending',
                      value: _stats['pending'] ?? 0,
                      subtitle: 'Awaiting approval',
                      tint: Colors.lightBlue.shade50,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _cardsRow(
                    left: _statCard(
                      title: 'Approved',
                      value: _stats['approved'] ?? 0,
                      subtitle: 'Successfully approved',
                      tint: Colors.green.shade50,
                      withCheck: true,
                    ),
                    right: _statCard(
                      title: 'Rejected',
                      value: _stats['rejected'] ?? 0,
                      subtitle: 'Rejected Members',
                      tint: Colors.red.shade50,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_pendingApplications.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      alignment: Alignment.center,
                      child: const Text('No pending applications'),
                    )
                  else
                    ..._pendingApplications.map((app) {
                      final name = (app['fullName'] ?? '').toString();
                      final email = (app['email'] ?? '').toString();
                      final role = (app['formData']?['role'] ?? 'Member')
                          .toString();
                      final gender = (app['formData']?['gender'] ?? '—')
                          .toString();
                      final block = (app['block'] ?? '—').toString();
                      final phone = (app['phone'] ?? '—').toString();
                      final id = (app['_id'] ?? '').toString();

                      return _memberCard(
                        name: name.isEmpty ? '—' : name,
                        email: email.isEmpty ? '—' : email,
                        role: role,
                        gender: gender,
                        block: block,
                        phone: phone,
                        status: 'pending',
                        onApprove: () => _handleApplicationAction(
                          appId: id,
                          action: 'approve',
                        ),
                        onReject: () => _showRejectDialog(id),
                      );
                    }),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_outlined),
            label: 'Approvals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group_outlined),
            label: 'Members',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            label: 'Settings',
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              UserAccountsDrawerHeader(
                accountName: Text('${widget.blockName} Block Admin'),
                accountEmail: Text(widget.adminEmail ?? widget.blockEmail!),
                currentAccountPicture: const CircleAvatar(
                  child: Icon(Icons.person),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.home_outlined),
                title: const Text('Dashboard'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
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
    String? subtitle,
    Color? tint,
    bool withCheck = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tint ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Text(
            title,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (withCheck) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_circle, color: Colors.green, size: 22),
              ],
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.black45),
            ),
          ],
        ],
      ),
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

  // Helper method from provided code for compatibility
  // ignore: unused_element
  Widget _statsRow(String title, int value, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    ),
  );
}
