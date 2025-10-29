import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'blockadmin_settings.dart';
import 'package:activ/services/api_service.dart';

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
    if (data is Map<String, dynamic>) {
      final applications = data['applications'];
      if (applications is List) {
        return applications
            .map((app) => app is Map ? Map<String, dynamic>.from(app) : app)
            .toList();
      }
    }
    return [];
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
  late final ApplicationService _svc;
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
    _svc = ApplicationService(
      baseUrl: widget.apiBaseUrl,
      token: widget.authToken ?? widget.token!,
    );
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await Future.wait([
      _svc.getBlockStats(widget.blockAdminId),
      _svc.getBlockInbox(widget.blockAdminId),
    ]);
    if (!mounted) return;
    setState(() {
      _stats = res[0] as Map<String, int>;
      _pending = res[1] as List<dynamic>;
      _isLoading = false;
    });
  }

  Future<void> _act(String appId, String action, {String? reason}) async {
    setState(() => _isLoading = true);
    final r = await _svc.blockReview(
      appId: appId,
      adminId: widget.blockAdminId,
      action: action,
      reason: reason,
    ); // approved/rejected path is validated server-side. :contentReference[oaicite:4]{index=4}
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(r['message']?.toString() ?? 'Done')));
    await _load();
  }

  Future<void> _rejectDialog(String appId) async {
    final c = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Application'),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(labelText: 'Reason (optional)'),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _act(
        appId,
        'reject',
        reason: c.text.trim().isEmpty ? null : c.text.trim(),
      );
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FF),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _page(_tab),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
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

  Widget _page(int i) {
    switch (i) {
      case 0:
        return RefreshIndicator(onRefresh: _load, child: _dashboard());
      case 3:
        return BlockAdminSettingsPage(
          apiBaseUrl: widget.apiBaseUrl,
          token: widget.authToken ?? widget.token!,
          blockAdminId: widget.blockAdminId,
          blockName: widget.blockName,
          blockEmail: widget.adminEmail ?? widget.blockEmail!,
          isActive: true,
        );
      default:
        // Placeholders to match your tab structure (you can wire later).
        return const Center(child: Text('Coming soon'));
    }
  }

  Widget _dashboard() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _topBar(),
        _heroHeader(),
        const SizedBox(height: 16),

        // Stat cards (2x2)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _statCard(
                title: 'Total Members',
                value: _stats['total'] ?? 0,
                subtitle: 'block level',
                icon: Icons.person_outline,
              ),
              _statCard(
                title: 'Pending',
                value: _stats['pending'] ?? 0,
                subtitle: 'Awaiting approval',
                icon: Icons.access_time,
                chipText: 'pending',
                chipColor: const Color(0xFF1E88FF),
              ),
              _statCard(
                title: 'Approved',
                value: _stats['approved'] ?? 0,
                subtitle: 'Successfully approved',
                icon: Icons.check_circle,
                chipText: 'approved',
                chipColor: const Color(0xFF16A34A),
              ),
              _statCard(
                title: 'Rejected',
                value: _stats['rejected'] ?? 0,
                subtitle: 'Request denied',
                icon: Icons.cancel,
                chipText: 'rejected',
                chipColor: const Color(0xFFFF5C5C),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Pending header chip
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _pill('Pending (${_stats['pending'] ?? 0})'),
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
          _iconButton(Icons.filter_alt_outlined),
          const SizedBox(width: 8),
          Stack(
            children: [
              _iconButton(Icons.notifications_none_outlined),
              Positioned(right: 8, top: 6, child: _notifDot('4')),
            ],
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF1E88FF),
            child: Text('A', style: TextStyle(color: Colors.white)),
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
        child: _pill(widget.blockName),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required int value,
    required String subtitle,
    required IconData icon,
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
              Icon(icon, color: const Color(0xFF6B7280)),
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
    final id = app['_id']?.toString() ?? '';
    final fullName = app['fullName']?.toString() ?? 'Member';
    final email = app['email']?.toString() ?? '';
    final phone = app['phone']?.toString() ?? '';
    final block = app['block']?.toString() ?? widget.blockName;
    final form = app['formData'] != null
        ? Map<String, dynamic>.from(app['formData'])
        : <String, dynamic>{};
    final role = (form['role'] ?? 'Member').toString();
    final gender = (form['gender'] ?? '').toString();

    return GestureDetector(
      onTap: () async {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        try {
          // Fetch full member profile
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
                if (profileRes['success'] == true &&
                    profileRes['data'] != null) {
                  // Close loading dialog
                  if (mounted) Navigator.pop(context);

                  if (mounted) {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (ctx) => UserDetailsDropdown(
                        memberProfile: Map<String, dynamic>.from(
                          profileRes['data'],
                        ),
                        onApprove: () => _act(id, 'approve'),
                        onReject: () => _rejectDialog(id),
                      ),
                    );
                  }
                  return;
                }
              }
            }
          }

          // Fallback: close loading and show modal with basic data
          if (mounted) Navigator.pop(context);
          if (mounted) {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => UserDetailsDropdown(
                app: Map<String, dynamic>.from(app),
                onApprove: () => _act(id, 'approve'),
                onReject: () => _rejectDialog(id),
              ),
            );
          }
        } catch (e) {
          // Close loading dialog and show error
          if (mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading profile: $e')),
            );
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
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
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFFE5E7EB),
                  child: Icon(Icons.person, color: Color(0xFF6B7280)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Role: $role, Gender: ${gender.isEmpty ? '—' : gender}',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$block Block',
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        phone,
                        style: const TextStyle(
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF1E88FF,
                    ).withAlpha((0.15 * 255).toInt()),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'pending',
                    style: TextStyle(
                      color: Color(0xFF1E88FF),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _act(id, 'approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Approve',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _rejectDialog(id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5C5C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(fontWeight: FontWeight.w700),
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

  Widget _iconButton(IconData icon) => Container(
    width: 38,
    height: 38,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha((0.06 * 255).toInt()),
          blurRadius: 10,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Icon(icon, color: const Color(0xFF0F172A)),
  );

  Widget _notifDot(String n) => Container(
    width: 16,
    height: 16,
    decoration: BoxDecoration(
      color: const Color(0xFF1E88FF),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(color: Colors.white, width: 2),
    ),
    alignment: Alignment.center,
    child: Text(
      n,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 9,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

/// UserDetailsDropdown widget that shows detailed user information in a modal bottom sheet
class UserDetailsDropdown extends StatelessWidget {
  final Map<String, dynamic>? app;
  final Map<String, dynamic>? memberProfile;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const UserDetailsDropdown({
    super.key,
    this.app,
    this.memberProfile,
    required this.onApprove,
    required this.onReject,
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
      // Fall back to the old app structure
      profileData = app ?? {};
      member = profileData;
      final form = profileData['formData'] != null
          ? Map<String, dynamic>.from(profileData['formData'])
          : <String, dynamic>{};
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

    String s(dynamic v) =>
        (v == null || (v is String && v.isEmpty)) ? '—' : v.toString();
    String b(bool? v) => v == null ? '—' : (v ? 'Yes' : 'No');
    String listToString(List<dynamic>? v) =>
        (v == null || v.isEmpty) ? '—' : v.join(', ');

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
                  // Personal & Demographic Details
                  _buildSectionHeader('Personal & Demographic Details'),
                  _buildDetailCard([
                    _buildDetailRow('Name', s(member['fullName'])),
                    _buildDetailRow('Email', s(member['email'])),
                    _buildDetailRow('Phone', s(member['phone'])),
                    _buildDetailRow(
                      'Date of Birth',
                      s(_formatDate(member['dateOfBirth'])),
                    ),
                    _buildDetailRow('State', s(member['state'])),
                    _buildDetailRow('District', s(member['district'])),
                    _buildDetailRow('Block', s(member['block'])),
                    _buildDetailRow('City', s(member['city'])),
                    _buildDetailRow('Street Name', s(member['streetName'])),
                    _buildDetailRow(
                      'Educational Qualification',
                      s(member['educationalQualification']),
                    ),
                    _buildDetailRow('Religion', s(member['religion'])),
                    _buildDetailRow(
                      'Social Category',
                      s(member['socialCategory']),
                    ),
                    _buildDetailRow(
                      'Aadhaar Number',
                      s(member['aadhaarNumber']),
                    ),
                    _buildDetailRow('Gender', s(member['gender'])),
                    _buildDetailRow('Role', s(member['role'])),
                  ]),

                  const SizedBox(height: 16),

                  // Business Information
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
                            _buildDetailRow(
                              'Doing Business',
                              b(businessInfo['doingBusiness'] as bool?),
                            ),
                            _buildDetailRow(
                              'Organization Name',
                              s(businessInfo['organizationName']),
                            ),
                            _buildDetailRow(
                              'Constitution Type',
                              s(businessInfo['constitutionType']),
                            ),
                            _buildDetailRow(
                              'Business Type',
                              s(businessInfo['businessType']),
                            ),
                            _buildDetailRow(
                              'Business Activities',
                              s(businessInfo['businessActivities']),
                            ),
                            _buildDetailRow(
                              'Business Commencement Year',
                              s(businessInfo['businessCommencementYear']),
                            ),
                            _buildDetailRow(
                              'Number of Employees',
                              s(businessInfo['numberOfEmployees']),
                            ),
                            _buildDetailRow(
                              'Member of Other Chamber',
                              b(businessInfo['memberOfOtherChamber'] as bool?),
                            ),
                            if (businessInfo['memberOfOtherChamber'] == true)
                              _buildDetailRow(
                                'Other Chamber Name',
                                s(businessInfo['otherChamber']),
                              ),
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
                            _buildDetailRow(
                              'PAN Number',
                              s(financialInfo['panNumber']),
                            ),
                            _buildDetailRow(
                              'GST Number',
                              s(financialInfo['gstNumber']),
                            ),
                            _buildDetailRow(
                              'Udyam Number',
                              s(financialInfo['udyamNumber']),
                            ),
                            _buildDetailRow(
                              'Filed ITR',
                              b(financialInfo['filedITR'] as bool?),
                            ),
                            _buildDetailRow(
                              'ITR Years',
                              s(financialInfo['itrYears']),
                            ),
                            _buildDetailRow(
                              'Turnover Range',
                              s(financialInfo['turnoverRange']),
                            ),
                            _buildDetailRow(
                              'FY 2021',
                              s(financialInfo['fy2021']),
                            ),
                            _buildDetailRow(
                              'FY 2020',
                              s(financialInfo['fy2020']),
                            ),
                            _buildDetailRow(
                              'FY 2019',
                              s(financialInfo['fy2019']),
                            ),
                            _buildDetailRow(
                              'Govt Scheme Benefit',
                              b(financialInfo['govtSchemeBenefit'] as bool?),
                            ),
                            _buildDetailRow(
                              'Scheme 1',
                              s(financialInfo['scheme1']),
                            ),
                            _buildDetailRow(
                              'Scheme 2',
                              s(financialInfo['scheme2']),
                            ),
                            _buildDetailRow(
                              'Scheme 3',
                              s(financialInfo['scheme3']),
                            ),
                            _buildDetailRow(
                              'IFSC Code',
                              s(financialInfo['ifscCode']),
                            ),
                            _buildDetailRow(
                              'Bank Branch',
                              s(financialInfo['bankBranch']),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Declaration
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
                            _buildDetailRow(
                              'Sister Concerns',
                              s(declaration['sisterConcerns']),
                            ),
                            _buildDetailRow(
                              'Company Names',
                              listToString(
                                (declaration['companyNames'] as List?)
                                    ?.cast<dynamic>(),
                              ),
                            ),
                            _buildDetailRow(
                              'Show One Field Per Name',
                              b(declaration['showOneFieldPerName'] as bool?),
                            ),
                            _buildDetailRow(
                              'Agree To Declaration',
                              b(declaration['agreeToDeclaration'] as bool?),
                            ),
                            _buildDetailRow(
                              'Profile Completed',
                              b(declaration['profileCompleted'] as bool?),
                            ),
                            _buildDetailRow(
                              'Submission Date',
                              s(_formatDate(declaration['submissionDate'])),
                            ),
                            _buildDetailRow('Status', s(declaration['status'])),
                            _buildDetailRow(
                              'Review Notes',
                              s(declaration['reviewNotes']),
                            ),
                            _buildDetailRow(
                              'Reviewed By',
                              s(declaration['reviewedBy']),
                            ),
                            _buildDetailRow(
                              'Reviewed At',
                              s(_formatDate(declaration['reviewedAt'])),
                            ),
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

          // Action buttons
          Container(
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
          ),
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
