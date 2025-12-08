import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'blockadmin_settings.dart';
import 'blockadmin_approval_page.dart';
import 'blockadmin_members_page.dart';
import '../../services/api_service.dart';

/// Lightweight service embedded here so your existing constructor
/// parameters keep working. Calls the same endpoints you already expose:
/// - GET /applications/block/:blockAdminId  -> Pending list
/// - GET /applications/by-admin/:id?role=block&status=Approved/Rejected -> counts
/// - POST /applications/block-review/:appId -> approve/reject
/// These are already implemented in your API (see server routes).
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

    // Handle error responses
    if (res.statusCode != 200) {
      if (data is Map<String, dynamic>) {
        throw Exception(data['message'] ?? 'Failed to fetch block inbox');
      } else {
        throw Exception('Failed to fetch block inbox');
      }
    }

    // The backend returns applications directly as an array, not wrapped in an object
    if (data is List<dynamic>) {
      return data
          .map((app) => app is Map ? Map<String, dynamic>.from(app) : app)
          .toList();
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
    final res = await http.get(Uri.parse(url), headers: headers);

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

  Future<int> _getCountByStatus({
    required String blockAdminId,
    required String status, // Approved | Rejected
  }) async {
    final url =
        '$baseUrl/applications/by-admin/$blockAdminId?role=block&status=$status';
    final res = await http.get(Uri.parse(url), headers: headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return (body['count'] ?? 0) as int;
    }
    return 0;
  }

  Future<Map<String, int>> getBlockStats(String blockAdminId) async {
    final pending = await getBlockInbox(
      blockAdminId,
    ); // Pending-Block list (server route). :contentReference[oaicite:0]{index=0}
    final approved = await _getCountByStatus(
      blockAdminId: blockAdminId,
      status:
          'Approved', // server aggregates by reviewedBy + status. :contentReference[oaicite:1]{index=1}
    );
    final rejected = await _getCountByStatus(
      blockAdminId: blockAdminId,
      status:
          'Rejected', // same stats route. :contentReference[oaicite:2]{index=2}
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
        'adminId':
            adminId, // supports ObjectId or admin code per backend. :contentReference[oaicite:3]{index=3}
        'action': action,
        'reason': reason,
      }),
    );
    final data = jsonDecode(res.body);
    return data is Map<String, dynamic>
        ? data
        : Map<String, dynamic>.from(data as Map);
  }
}

/// ------------------------------------------------------
/// Block Admin Dashboard — EXACT UI of your mock
/// ------------------------------------------------------
class BlockAdminDashboard extends StatefulWidget {
  final String apiBaseUrl;
  final String? authToken;
  final String? token; // compatibility
  final String blockAdminId;
  final String blockName; // e.g., "Sriperumbudur"
  final String? adminEmail; // e.g., "blockadmin@activ.com"
  final String? blockEmail; // compatibility

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
  bool _isLoading = true;
  int _tab = 0;

  Map<String, int> _stats = {
    'total': 0,
    'pending': 0,
    'approved': 0,
    'rejected': 0,
  };
  List<dynamic> _pending = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final token = widget.authToken ?? widget.token;
      if (token == null) {
        throw Exception('No authentication token available');
      }

      final svc = ApplicationService(baseUrl: widget.apiBaseUrl, token: token);

      // Fetch stats using the service that calls proper backend endpoints
      final stats = await svc.getBlockStats(widget.blockAdminId);

      // Fetch pending applications list
      final pendingApps = await svc.getBlockInbox(widget.blockAdminId);

      if (!mounted) return;
      setState(() {
        _stats = stats;
        _pending = pendingApps;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading data: $e')));
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Navigate to login screen
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F6FF),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _page(_tab),
        bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _tab,
        onTap: (i) {
          // If navigating back to dashboard (tab 0) from any other tab, refresh the data
          if (i == 0 && _tab != 0) {
            _load();
          }
          setState(() {
            _tab = i;
          });
        },
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
      ),
    );
  }

  Widget _page(int i) {
    switch (i) {
      case 0:
        return RefreshIndicator(onRefresh: _load, child: _dashboard());
      case 1: // Approvals tab
        return BlockAdminApprovalPage(
          apiBaseUrl: widget.apiBaseUrl,
          blockAdminId: widget.blockAdminId,
          blockName: widget.blockName,
          token: widget.authToken ?? widget.token,
          initialCategory: ApprovalCategory.pending,
          onNavigateToSettings: () {
            setState(() => _tab = 3);
          },
        );
      case 2: // Members
        return BlockAdminMembersPage(
          apiBaseUrl: widget.apiBaseUrl,
          blockAdminId: widget.blockAdminId,
          blockName: widget.blockName,
          token: widget.authToken ?? widget.token,
          onNavigateToSettings: () {
            setState(() => _tab = 3);
          },
        );
      case 3:
        return BlockAdminSettingsPage(
          apiBaseUrl: widget.apiBaseUrl,
          token: widget.authToken ?? widget.token!,
          blockAdminId: widget.blockAdminId,
          blockName: widget.blockName,
          blockEmail: widget.adminEmail ?? widget.blockEmail!,
          isActive: true,
          statsOverride: _stats,
          onBackToDashboard: () {
            // Navigate back to Dashboard tab (index 0)
            setState(() => _tab = 0);
          },
        );
      default:
        return const SizedBox();
    }
  }

  Widget _dashboard() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _topBar(),
        const SizedBox(height: 12),
        _heroHeader(),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _statCard(
                title: 'Total Members',
                value: _stats['total'] ?? 0,
                subtitle: 'Block level',
                icon: Icons.people,
                iconColor: const Color(0xFF3B82F6),
                chipText: 'All',
                chipColor: const Color(0xFF3B82F6),
              ),
              _statCard(
                title: 'Pending',
                value: _stats['pending'] ?? 0,
                subtitle: 'Awaiting approval',
                icon: Icons.access_time,
                iconColor: const Color(0xFFF59E0B),
                chipText: 'Pending',
                chipColor: const Color(0xFFF59E0B),
              ),
              _statCard(
                title: 'Approved',
                value: _stats['approved'] ?? 0,
                subtitle: 'Successfully approved',
                icon: Icons.check_circle,
                iconColor: const Color(0xFF10B981),
                chipText: 'approved',
                chipColor: const Color(0xFF10B981),
              ),
              _statCard(
                title: 'Rejected',
                value: _stats['rejected'] ?? 0,
                subtitle: 'Request denied',
                icon: Icons.cancel,
                iconColor: const Color(0xFFEF4444),
                chipText: 'Rejected',
                chipColor: const Color(0xFFEF4444),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Pending header chip
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: _pill('Pending (${_stats['pending'] ?? 0})'),
          ),
        ),

        const SizedBox(height: 8),

        // Pending list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: _pending.map((app) => _userCard(app)).toList(),
          ),
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.only(top: 54, left: 16, right: 16, bottom: 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF1F6FF), Color(0xFFE9F0FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Block Admin Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Manage Block Level',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              setState(() {
                _tab = 3; // Navigate to Settings tab
              });
            },
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF1E88FF),
              child: Text('A', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _pill("Block Administration"),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required int value,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    String? chipText,
    Color? chipColor,
  }) {
    return Container(
      width: (MediaQuery.of(context).size.width - 16 * 2 - 16) / 2,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.06 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor ?? const Color(0xFF6B7280)),
              const Spacer(),
              if (chipText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (chipColor ?? const Color(0xFF1E88FF)).withAlpha(
                      (0.15 * 255).toInt(),
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    chipText,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: chipColor ?? const Color(0xFF1E88FF),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }

  Widget _userCard(dynamic app) {
    // Helper to format dates like DD/MM/YYYY with safe fallback
    String fmtDate(dynamic value) {
      if (value == null) return 'N/A';
      try {
        final s = value.toString();
        final dt = DateTime.parse(s);
        final dd = dt.day.toString().padLeft(2, '0');
        final mm = dt.month.toString().padLeft(2, '0');
        final yyyy = dt.year.toString();
        return '$dd/$mm/$yyyy';
      } catch (_) {
        return 'N/A';
      }
    }

    final id = app['_id']?.toString() ?? '';
    final fullName = app['fullName']?.toString() ?? 'Member';
    final email = app['email']?.toString() ?? '';
    final phone = app['phone']?.toString() ?? '';
    final status = app['status']?.toString() ?? '';
    final block = app['block']?.toString() ?? widget.blockName;
    final appliedDate = fmtDate(app['createdAt'] ?? app['submittedAt']);

    final form = app['formData'] != null
        ? Map<String, dynamic>.from(app['formData'])
        : <String, dynamic>{};
    // Gender can be at root level or nested. Normalize common variants.
    String normalizeGender(dynamic g) {
      if (g == null) return 'NA';
      final v = g.toString().trim();
      if (v.isEmpty) return 'NA';
      final lc = v.toLowerCase();
      if (lc == 'm' || lc == 'male' || lc.startsWith('male')) {
        return 'Male';
      }
      if (lc == 'f' || lc == 'female' || lc.startsWith('female')) {
        return 'Female';
      }
      if (lc == 'o' || lc == 'other' || lc.startsWith('other')) {
        return 'Other';
      }
      return v;
    }

    final Map<String, dynamic>? personalInfo =
        form['personalInfo'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(form['personalInfo'])
        : null;
    final Map<String, dynamic>? personalDetails =
        form['personalDetails'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(form['personalDetails'])
        : null;
    // Simple tri-state status from backend (already normalized)
    final normalizedStatus = status.trim().toLowerCase();
    final bool displayAsPending =
        normalizedStatus.isEmpty ||
        normalizedStatus == 'pending' ||
        normalizedStatus == 'submitted';
    final String statusLabel = displayAsPending
        ? 'Pending'
        : (normalizedStatus == 'approved'
              ? 'Approved'
              : (normalizedStatus == 'rejected' ? 'Rejected' : status));

    return GestureDetector(
      onTap: () => _openProfileSheet(app),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.06 * 255).toInt()),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: avatar, name + phone, status pill at right
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFFE5E7EB),
                  child: Icon(Icons.person, color: Color(0xFF6B7280)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phone: $phone',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                // Status pill styled like approval page
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: displayAsPending
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: displayAsPending
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF16A34A),
                    ),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: displayAsPending
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF16A34A),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Block (left) and Applied on date (right)
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Text(
                  'Block: $block',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Text(
                  'Applied: $appliedDate',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Second line: Email (left) and Gender (right)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.email, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Email: $email',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF374151),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Approve/Reject buttons (pending only)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approve(id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Approve',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _reject(id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5C5C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleApprove(dynamic app) {
    final appId = app['_id']?.toString();
    if (appId != null) {
      _approve(appId);
    }
  }

  void _handleReject(dynamic app) {
    final appId = app['_id']?.toString();
    if (appId != null) {
      _reject(appId);
    }
  }

  Future<void> _approve(String appId) async {
    try {
      // Show progress feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Approving...'),
              ],
            ),
            duration: Duration(seconds: 1),
          ),
        );
      }

      final ok = await ApiService.reviewBlockApplication(
        appId,
        'approve',
        adminId: widget.blockAdminId,
      );
      if (ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Approved'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
        }
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Approve failed: $e'),
            backgroundColor: const Color(0xFFFF5C5C),
          ),
        );
      }
    }
  }

  Future<void> _reject(String appId) async {
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Application'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Reason (optional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5C5C),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        final rejectionReason = reasonCtrl.text.trim();

        // Show progress feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Rejecting...'),
                ],
              ),
              duration: Duration(seconds: 1),
            ),
          );
        }

        final ok2 = await ApiService.reviewBlockApplication(
          appId,
          'reject',
          adminId: widget.blockAdminId,
          reason: rejectionReason.isEmpty ? null : rejectionReason,
        );
        if (ok2) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Application Rejected'),
                backgroundColor: Color(0xFFFF5C5C),
              ),
            );
          }
          await _load();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Reject failed: $e'),
              backgroundColor: const Color(0xFFFF5C5C),
            ),
          );
        }
      }
    }
  }

  void _openProfileSheet(Map<String, dynamic> app) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final email = app["email"] ?? app["memberEmail"];
      if (email != null) {
        final memberRes = await ApiService.getMemberByEmail(email);
        if (memberRes['success'] == true && memberRes['data'] != null) {
          final memberId =
              memberRes['data']['id'] ??
              memberRes['data']['memberId'] ??
              memberRes['data']['_id'];
          if (memberId != null) {
            final profileRes = await ApiService.getMemberProfile(
              memberId.toString(),
            );
            if (mounted) Navigator.pop(context);
            if (profileRes['success'] == true && profileRes['data'] != null) {
              if (mounted) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => UserDetailsDropdown(
                    memberProfile: Map<String, dynamic>.from(
                      profileRes['data'],
                    ),
                    showActions: true,
                    onApprove: () {
                      Navigator.pop(context);
                      _handleApprove(app);
                    },
                    onReject: () {
                      Navigator.pop(context);
                      _handleReject(app);
                    },
                  ),
                );
                return;
              }
            }
          }
        }
      }
      if (mounted) Navigator.pop(context);
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => UserDetailsDropdown(
            app: Map<String, dynamic>.from(app),
            showActions: true,
            onApprove: () {
              Navigator.pop(context);
              _handleApprove(app);
            },
            onReject: () {
              Navigator.pop(context);
              _handleReject(app);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1E88FF).withAlpha((0.12 * 255).toInt()),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1E88FF),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// UserDetailsDropdown widget that shows detailed user information in a modal bottom sheet
class UserDetailsDropdown extends StatelessWidget {
  final Map<String, dynamic>? app;
  final Map<String, dynamic>? memberProfile;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final bool showActions;

  const UserDetailsDropdown({
    super.key,
    this.app,
    this.memberProfile,
    required this.onApprove,
    required this.onReject,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    // Use memberProfile if available, otherwise fall back to app data
    final Map<String, dynamic> profileData;
    final Map<String, dynamic> member;
    final Map<String, dynamic> businessInfo;
    final Map<String, dynamic> financialInfo;
    final Map<String, dynamic> declaration;

    if (memberProfile != null) {
      // Use the full profile structure like profile_detail_screen.dart
      profileData = memberProfile!;
      member = profileData['member'] ?? {};
      businessInfo = profileData['businessInfo'] ?? {};
      financialInfo = profileData['financialInfo'] ?? {};
      declaration = profileData['declaration'] ?? {};
    } else {
      // Parse application data with enhanced formData from backend
      profileData = app ?? {};
      final form = profileData['formData'] != null
          ? Map<String, dynamic>.from(profileData['formData'])
          : <String, dynamic>{};
      
      // Member/Demographic data - check both formData root and top-level fields
      member = {
        'fullName': form['fullName'] ?? profileData['fullName'],
        'email': form['email'] ?? profileData['email'],
        'phoneNumber': form['phoneNumber'] ?? profileData['phone'],
        'phone': form['phoneNumber'] ?? profileData['phone'],
        'dateOfBirth': form['dateOfBirth'],
        'state': form['state'] ?? profileData['state'],
        'district': form['district'] ?? profileData['district'],
        'block': form['block'] ?? profileData['block'],
        'city': form['city'],
        'streetName': form['streetName'],
        'educationalQualification': form['educationalQualification'],
        'religion': form['religion'],
        'socialCategory': form['socialCategory'],
        'aadhaarNumber': form['aadhaarNumber'],
        'gender': form['gender'],
      };
      
      businessInfo = form['businessInfo'] != null
          ? Map<String, dynamic>.from(form['businessInfo'])
          : <String, dynamic>{};
      financialInfo = form['financialInfo'] != null
          ? Map<String, dynamic>.from(form['financialInfo'])
          : <String, dynamic>{};
      declaration = form['declaration'] != null
          ? Map<String, dynamic>.from(form['declaration'])
          : <String, dynamic>{};
    }

    // Helper functions
    String s(dynamic value) =>
        (value == null || (value is String && value.isEmpty))
        ? '—'
        : value.toString();
    String b(bool? value) => value == null ? '—' : (value ? 'Yes' : 'No');
    String listToString(List<dynamic>? list) {
      if (list == null || list.isEmpty) return '—';
      return list.join(', ');
    }
    
    // Helper to check if a value is not empty
    bool hasValue(dynamic value) {
      if (value == null) return false;
      if (value is String) return value.trim().isNotEmpty;
      if (value is List) return value.isNotEmpty;
      if (value is Map) return value.isNotEmpty;
      return true; // For numbers, bools, etc
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Member Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Demographic Details
                  _buildSectionHeader('Demographic Details'),
                  _buildDetailCard([
                    _buildDetailRow('Name', s(member['fullName'])),
                    _buildDetailRow('Email', s(member['email'])),
                    _buildDetailRow(
                      'Phone',
                      s(member['phone'] ?? member['phoneNumber']),
                    ),
                    if (hasValue(member['dateOfBirth']))
                      _buildDetailRow(
                        'Date of Birth',
                        s(_formatDate(member['dateOfBirth'])),
                      ),
                    _buildDetailRow('State', s(member['state'])),
                    _buildDetailRow('District', s(member['district'])),
                    _buildDetailRow('Block', s(member['block'])),
                    if (hasValue(member['city']))
                      _buildDetailRow('City', s(member['city'])),
                    if (hasValue(member['streetName']))
                      _buildDetailRow('Street Name', s(member['streetName'])),
                    if (hasValue(member['educationalQualification']))
                      _buildDetailRow(
                        'Educational Qualification',
                        s(member['educationalQualification']),
                      ),
                    if (hasValue(member['religion']))
                      _buildDetailRow('Religion', s(member['religion'])),
                    if (hasValue(member['socialCategory']))
                      _buildDetailRow(
                        'Social Category',
                        s(member['socialCategory']),
                      ),
                    if (hasValue(member['aadhaarNumber']))
                      _buildDetailRow(
                        'Aadhaar Number',
                        s(member['aadhaarNumber']),
                      ),
                    if (hasValue(member['gender']))
                      _buildDetailRow('Gender', s(member['gender'])),
                  ]),

                  const SizedBox(height: 16),

                  // Business Information
                  if (hasValue(businessInfo))
                    ExpansionTile(
                      title: const Text(
                        'Business Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              if (hasValue(businessInfo['doingBusiness']))
                                _buildDetailRow(
                                  'Doing Business',
                                  b(businessInfo['doingBusiness'] as bool?),
                                ),
                              if (hasValue(businessInfo['organizationName']))
                                _buildDetailRow(
                                  'Organization Name',
                                  s(businessInfo['organizationName']),
                                ),
                              if (hasValue(businessInfo['constitutionType']))
                                _buildDetailRow(
                                  'Constitution Type',
                                  s(businessInfo['constitutionType']),
                                ),
                              if (hasValue(businessInfo['businessType']))
                                _buildDetailRow(
                                  'Business Type',
                                  s(businessInfo['businessType']),
                                ),
                              if (hasValue(businessInfo['businessActivities']))
                                _buildDetailRow(
                                  'Business Activities',
                                  s(businessInfo['businessActivities']),
                                ),
                              if (hasValue(businessInfo['businessCommencementYear']))
                                _buildDetailRow(
                                  'Business Commencement Year',
                                  s(businessInfo['businessCommencementYear']),
                                ),
                              if (hasValue(businessInfo['numberOfEmployees']))
                                _buildDetailRow(
                                  'Number of Employees',
                                  s(businessInfo['numberOfEmployees']),
                                ),
                              if (hasValue(businessInfo['memberOfOtherChamber']))
                                _buildDetailRow(
                                  'Member of Other Chamber',
                                  b(businessInfo['memberOfOtherChamber'] as bool?),
                                ),
                              if (businessInfo['memberOfOtherChamber'] == true &&
                                  hasValue(businessInfo['otherChamber']))
                                _buildDetailRow(
                                  'Other Chamber Name',
                                  s(businessInfo['otherChamber']),
                                ),
                              if (hasValue(businessInfo['registeredWithGovtOrganization']))
                                _buildDetailRow(
                                  'Registered with Govt Organizations',
                                  listToString(
                                    (businessInfo['registeredWithGovtOrganization']
                                            as List?)
                                        ?.cast<dynamic>(),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  // Financial & Compliance
                  if (hasValue(financialInfo))
                    ExpansionTile(
                      title: const Text(
                        'Financial & Compliance',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              if (hasValue(financialInfo['panNumber']))
                                _buildDetailRow(
                                  'PAN Number',
                                  s(financialInfo['panNumber']),
                                ),
                              if (hasValue(financialInfo['gstNumber']))
                                _buildDetailRow(
                                  'GST Number',
                                  s(financialInfo['gstNumber']),
                                ),
                              if (hasValue(financialInfo['udyamNumber']))
                                _buildDetailRow(
                                  'Udyam Number',
                                  s(financialInfo['udyamNumber']),
                                ),
                              if (hasValue(financialInfo['filedITR']))
                                _buildDetailRow(
                                  'Filed ITR',
                                  b(financialInfo['filedITR'] as bool?),
                                ),
                              if (hasValue(financialInfo['itrYears']))
                                _buildDetailRow(
                                  'ITR Years',
                                  s(financialInfo['itrYears']),
                                ),
                              if (hasValue(financialInfo['turnoverRange']))
                                _buildDetailRow(
                                  'Turnover Range',
                                  s(financialInfo['turnoverRange']),
                                ),
                              if (hasValue(financialInfo['fy2021']))
                                _buildDetailRow(
                                  'FY 2021',
                                  s(financialInfo['fy2021']),
                                ),
                              if (hasValue(financialInfo['fy2020']))
                                _buildDetailRow(
                                  'FY 2020',
                                  s(financialInfo['fy2020']),
                                ),
                              if (hasValue(financialInfo['fy2019']))
                                _buildDetailRow(
                                  'FY 2019',
                                  s(financialInfo['fy2019']),
                                ),
                              if (hasValue(financialInfo['govtSchemeBenefit']))
                                _buildDetailRow(
                                  'Govt Scheme Benefit',
                                  b(financialInfo['govtSchemeBenefit'] as bool?),
                                ),
                              if (hasValue(financialInfo['scheme1']))
                                _buildDetailRow(
                                  'Scheme 1',
                                  s(financialInfo['scheme1']),
                                ),
                              if (hasValue(financialInfo['scheme2']))
                                _buildDetailRow(
                                  'Scheme 2',
                                  s(financialInfo['scheme2']),
                                ),
                              if (hasValue(financialInfo['scheme3']))
                                _buildDetailRow(
                                  'Scheme 3',
                                  s(financialInfo['scheme3']),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),

                  // Declaration
                  if (hasValue(declaration))
                    ExpansionTile(
                      title: const Text(
                        'Declaration',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              if (hasValue(declaration['sisterConcerns']))
                                _buildDetailRow(
                                  'Sister Concerns',
                                  s(declaration['sisterConcerns']),
                                ),
                              if (hasValue(declaration['companyNames']))
                                _buildDetailRow(
                                  'Company Names',
                                  listToString(
                                    (declaration['companyNames'] as List?)
                                        ?.cast<dynamic>(),
                                  ),
                                ),
                              if (hasValue(declaration['showOneFieldPerName']))
                                _buildDetailRow(
                                  'Show One Field Per Name',
                                  b(declaration['showOneFieldPerName'] as bool?),
                                ),
                              if (hasValue(declaration['agreeToDeclaration']))
                                _buildDetailRow(
                                  'Agree To Declaration',
                                  b(declaration['agreeToDeclaration'] as bool?),
                                ),
                              if (hasValue(declaration['profileCompleted']))
                                _buildDetailRow(
                                  'Profile Completed',
                                  b(declaration['profileCompleted'] as bool?),
                                ),
                              if (hasValue(declaration['submissionDate']))
                                _buildDetailRow(
                                  'Submission Date',
                                  s(_formatDate(declaration['submissionDate'])),
                                ),
                              if (hasValue(declaration['status']))
                                _buildDetailRow('Status', s(declaration['status'])),
                              // Removed admin review audit fields from UI for admin pages
                            ],
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Action buttons (conditionally shown)
          showActions
              ? Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.1 * 255).toInt()),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onApprove();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Approve',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            onReject();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF5C5C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Reject',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _buildDetailCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha((0.1 * 255).toInt()),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String? _formatDate(dynamic date) {
    if (date == null) return null;

    try {
      // Handle DateTime directly
      if (date is DateTime) {
        final d = date;
        return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      }

      // Handle numeric timestamps (ms or sec)
      if (date is num) {
        final millis = date > 1000000000000
            ? date.toInt()
            : (date.toInt() * 1000);
        final d = DateTime.fromMillisecondsSinceEpoch(
          millis,
          isUtc: true,
        ).toLocal();
        return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      }

      // Handle strings in various common formats
      if (date is String) {
        final raw = date.trim();
        if (raw.isEmpty) return null;

        // If already in dd/MM/yyyy, return as-is
        final ddmmyyyySlash = RegExp(r'^\d{2}/\d{2}/\d{4}$');
        if (ddmmyyyySlash.hasMatch(raw)) return raw;

        // Convert dd-MM-yyyy to dd/MM/yyyy
        final ddmmyyyyDash = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$');
        final dashMatch = ddmmyyyyDash.firstMatch(raw);
        if (dashMatch != null) {
          final d = dashMatch.group(1)!;
          final m = dashMatch.group(2)!;
          final y = dashMatch.group(3)!;
          return '$d/$m/$y';
        }

        // Parse ISO-like formats (e.g., yyyy-MM-dd or ISO timestamps)
        try {
          final parsed = DateTime.parse(raw);
          return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
        } catch (_) {
          // Fallback: return the original string if parsing fails
          return raw;
        }
      }

      // Fallback for unexpected types
      return null;
    } catch (_) {
      return null;
    }
  }
}
