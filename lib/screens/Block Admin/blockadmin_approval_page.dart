import 'package:flutter/material.dart';
import '../../services/api_service.dart'; // uses your existing static helpers
import '../../utils/member_status.dart';
import 'blockadmin_dashboard.dart'
    show UserDetailsDropdown; // reuse the same dropdown

enum ApprovalCategory { pending, approved, rejected, all }

class BlockAdminApprovalPage extends StatefulWidget {
  final String apiBaseUrl;
  final String blockAdminId;
  final String blockName;
  final String? token; // if you need it later
  final ApprovalCategory initialCategory;

  const BlockAdminApprovalPage({
    super.key,
    required this.apiBaseUrl,
    required this.blockAdminId,
    required this.blockName,
    this.token,
    this.initialCategory = ApprovalCategory.pending,
  });

  @override
  State<BlockAdminApprovalPage> createState() => _BlockAdminApprovalPageState();
}

class _BlockAdminApprovalPageState extends State<BlockAdminApprovalPage> {
  bool _loading = true;
  ApprovalCategory _tab = ApprovalCategory.pending;

  // Raw list for this block admin (we’ll segment by status)
  List<Map<String, dynamic>> _all = [];

  @override
  void initState() {
    super.initState();
    _tab = widget.initialCategory;
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // This endpoint already exists in your code and returns applications for block admin.
      // (It’s used in your project as: ApiService.getBlockAdminApplications) :contentReference[oaicite:0]{index=0}
      final apps = await ApiService.getBlockAdminApplications(
        widget.blockAdminId,
      );
      _all = List<Map<String, dynamic>>.from(apps);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load approvals: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Helpers
  List<Map<String, dynamic>> get _pending => _all.where((a) {
    final status = a['status']?.toString();
    return isPendingStatus(status);
  }).toList();

  List<Map<String, dynamic>> get _approved => _all.where((a) {
    final status = a['status']?.toString();
    return isApprovedStatus(status);
  }).toList();

  List<Map<String, dynamic>> get _rejected => _all.where((a) {
    final status = a['status']?.toString();
    return isRejectedStatus(status);
  }).toList();

  List<Map<String, dynamic>> get _listForTab {
    switch (_tab) {
      case ApprovalCategory.pending:
        return _pending;
      case ApprovalCategory.approved:
        return _approved;
      case ApprovalCategory.rejected:
        return _rejected;
      case ApprovalCategory.all:
        return _all;
    }
  }

  Future<void> _approve(String appId) async {
    try {
      // You’re already reviewing at block on dashboard via block-review (forwarding to District on success). :contentReference[oaicite:1]{index=1}
      final ok = await ApiService.reviewBlockApplication(
        appId,
        'approve',
        adminId: widget.blockAdminId,
      ); // POST /api/applications/block-review/:id :contentReference[oaicite:2]{index=2}
      if (ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Approved & forwarded to District')),
          );
        }
        // Update local state instead of full reload
        _updateLocalStatus(appId, MemberStatus.approved);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Approve failed: $e')));
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
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        final ok2 = await ApiService.reviewBlockApplication(
          appId,
          'reject',
          adminId: widget.blockAdminId,
          reason: reasonCtrl.text.trim().isEmpty
              ? null
              : reasonCtrl.text.trim(),
        ); // same backend review call :contentReference[oaicite:3]{index=3}
        if (ok2) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Rejected')));
          }
          // Update local state instead of full reload
          _updateLocalStatus(appId, MemberStatus.rejected);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Reject failed: $e')));
        }
      }
    }
  }

  // Helper method to update local state after approve/reject
  void _updateLocalStatus(String appId, String newStatus) {
    setState(() {
      final index = _all.indexWhere((app) => app['_id'] == appId);
      if (index != -1) {
        _all[index]['status'] = newStatus;
      }
    });
  }

  void _openProfileSheet(Map<String, dynamic> app) async {
    // Same behavior as dashboard user card: try full profile by email, else fallback. :contentReference[oaicite:4]{index=4}
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
                    onApprove: () => _approve(app['_id'].toString()),
                    onReject: () => _reject(app['_id'].toString()),
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
            onApprove: () => _approve(app['_id'].toString()),
            onReject: () => _reject(app['_id'].toString()),
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

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final pendingCount = _pending.length;
    final approvedCount = _approved.length;
    final rejectedCount = _rejected.length;
    final allCount = _all.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FF),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _topBar(),
                    const SizedBox(height: 8),
                    _subtitle(),
                    const SizedBox(height: 12),
                    _tabs(
                      pendingCount: pendingCount,
                      approvedCount: approvedCount,
                      rejectedCount: rejectedCount,
                      allCount: allCount,
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: _listForTab.map(_memberCard).toList(),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          const Text(
            'Approvals',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          // icons mimic your mock
          _iconButton(Icons.filter_alt_outlined),
          const SizedBox(width: 10),
          Stack(
            alignment: Alignment.topRight,
            children: [
              _iconButton(Icons.notifications_none_rounded),
              Positioned(right: 0, top: 0, child: _notifDot('4')),
            ],
          ),
          const SizedBox(width: 10),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF1E88FF),
            child: Text('A', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _subtitle() => const Padding(
    padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
    child: Text(
      'Manage member requests',
      style: TextStyle(color: Color(0xFF6B7280)),
    ),
  );

  Widget _tabs({
    required int pendingCount,
    required int approvedCount,
    required int rejectedCount,
    required int allCount,
  }) {
    Widget chip(String label, bool active, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: active ? Colors.white : const Color(0xFFEAF2FF),
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.06 * 255).toInt()),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: active ? const Color(0xFF0F172A) : const Color(0xFF6B7280),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          chip('Pending', _tab == ApprovalCategory.pending, () {
            setState(() => _tab = ApprovalCategory.pending);
          }),
          const SizedBox(width: 8),
          chip('Approved', _tab == ApprovalCategory.approved, () {
            setState(() => _tab = ApprovalCategory.approved);
          }),
          const SizedBox(width: 8),
          chip('Rejected', _tab == ApprovalCategory.rejected, () {
            setState(() => _tab = ApprovalCategory.rejected);
          }),
          const SizedBox(width: 8),
          chip('All ($allCount)', _tab == ApprovalCategory.all, () {
            setState(() => _tab = ApprovalCategory.all);
          }),
        ],
      ),
    );
  }

  Widget _memberCard(Map<String, dynamic> app) {
    final id = app['_id']?.toString() ?? '';
    final fullName = app['fullName']?.toString() ?? 'Member';
    final email = app['email']?.toString() ?? '';
    final phone = app['phone']?.toString() ?? '';
    final status = app['status']?.toString() ?? '';
    final block = app['block']?.toString() ?? widget.blockName;

    final form = app['formData'] != null
        ? Map<String, dynamic>.from(app['formData'])
        : <String, dynamic>{};
    final role = (form['role'] ?? 'Member').toString();
    final gender = (form['gender'] ?? '').toString();

    // Use consistent status checking
    final isPending = isPendingStatus(status);
    final isApproved = isApprovedStatus(status);

    // Use consistent status display
    final statusText = getStatusDisplayText(status);
    final statusColor = getStatusColor(status);

    return GestureDetector(
      onTap: () => _openProfileSheet(
        app,
      ), // same dropdown behavior as dashboard :contentReference[oaicite:5]{index=5}
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
                    color: statusColor.withAlpha((0.15 * 255).toInt()),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (isPending)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approve(id),
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
                      onPressed: () => _reject(id),
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
              )
            else
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  isApproved
                      ? 'Approved by Block Admin'
                      : 'Rejected by Block Admin',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // small reusables (match your dashboard look)
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
