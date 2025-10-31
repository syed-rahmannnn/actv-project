import 'package:flutter/material.dart';
import '../../services/api_service.dart'; // uses your existing static helpers
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
    final status = (a['status'] ?? '').toString().toLowerCase();
    // Only treat exact 'pending-block' and 'submitted' as pending
    return status == 'pending-block' || status == 'submitted';
  }).toList();

  List<Map<String, dynamic>> get _approved => _all.where((a) {
    final status = (a['status'] ?? '').toString();
    return status == 'Approved' ||
        status == 'Pending-District' ||
        status == 'Pending-State';
  }).toList();

  List<Map<String, dynamic>> get _rejected => _all.where((a) {
    final status = (a['status'] ?? '').toString();
    return status == 'Rejected' || status.toLowerCase().contains('rejected');
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
      // Show loading indicator
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
              content: Text('✅ Approved & forwarded to District'),
              backgroundColor: Color(0xFF16A34A),
            ),
          );
        }
        // Refresh the data to update UI state
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Approve failed: $e'),
            backgroundColor: Color(0xFFFF5C5C),
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
              backgroundColor: Color(0xFFFF5C5C),
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        // Show loading indicator
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
          reason: reasonCtrl.text.trim().isEmpty
              ? null
              : reasonCtrl.text.trim(),
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
          // Refresh the data to update UI state
          await _load();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Reject failed: $e'),
              backgroundColor: Color(0xFFFF5C5C),
            ),
          );
        }
      }
    }
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
          Stack(
            alignment: Alignment.topRight,
            children: [
              _iconButton(Icons.notifications_none_rounded),
              if (_pending.isNotEmpty)
                Positioned(right: 0, top: 0, child: _notifDot(_pending.length.toString())),
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            chip('Pending ($pendingCount)', _tab == ApprovalCategory.pending, () {
              setState(() => _tab = ApprovalCategory.pending);
            }),
            const SizedBox(width: 8),
            chip('Approved ($approvedCount)', _tab == ApprovalCategory.approved, () {
              setState(() => _tab = ApprovalCategory.approved);
            }),
            const SizedBox(width: 8),
            chip('Rejected ($rejectedCount)', _tab == ApprovalCategory.rejected, () {
              setState(() => _tab = ApprovalCategory.rejected);
            }),
            const SizedBox(width: 8),
            chip('All ($allCount)', _tab == ApprovalCategory.all, () {
              setState(() => _tab = ApprovalCategory.all);
            }),
          ],
        ),
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
    final rejectionReason = app['rejectionReason']?.toString() ?? '';

    final form = app['formData'] != null
        ? Map<String, dynamic>.from(app['formData'])
        : <String, dynamic>{};
    final role = (form['role'] ?? 'Member').toString();
    final gender = (form['gender'] ?? '').toString();

    // Improved status detection logic
    final statusLower = status.toLowerCase();
    final isApproved = statusLower.contains('approved') || 
                      statusLower.contains('pending-district') ||
                      status == 'Approved' ||
                      status == 'Pending-District';
    final isRejected = statusLower.contains('rejected') || 
                      status == 'Rejected';
    final isPending = !isApproved && !isRejected && (
                     statusLower.contains('pending-block') ||
                     statusLower.contains('pending') ||
                     statusLower == 'submitted' ||
                     statusLower == 'pending');

    Color chipColor;
    String chipText;
    if (isApproved) {
      chipColor = const Color(0xFF16A34A);
      chipText = 'Approved';
    } else if (isRejected) {
      chipColor = const Color(0xFFFF5C5C);
      chipText = 'Rejected';
    } else {
      chipColor = const Color(0xFF1E88FF);
      chipText = 'Pending';
    }

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
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Role: $role, Gender: ${gender.isEmpty ? '—' : gender}',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                    color: chipColor.withAlpha((0.15 * 255).toInt()),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    chipText,
                    style: TextStyle(
                      color: chipColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Show buttons only for pending status, otherwise show status badge and reason
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status description only (no duplicate badge)
                  Text(
                    isApproved
                        ? _getApprovalText(app)
                        : _getRejectionText(app),
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                  // Show rejection reason if available
                  if (isRejected && rejectionReason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Reason: $rejectionReason',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
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

  String _getApprovalText(Map<String, dynamic> app) {
    // Get reviewedBy information from the backend
    final reviewedBy = app['reviewedBy'];
    if (reviewedBy != null && reviewedBy is Map<String, dynamic>) {
      // Check for block admin approval
      final blockAdmin = reviewedBy['blockAdmin'];
      if (blockAdmin != null && blockAdmin is Map<String, dynamic>) {
        final adminName = blockAdmin['fullName']?.toString() ?? 'Block Admin';
        final blockName = blockAdmin['meta']?['blockName']?.toString() ?? widget.blockName;
        return 'Approved by $adminName, $blockName Admin';
      }
      
      // Check for district admin approval
      final districtAdmin = reviewedBy['districtAdmin'];
      if (districtAdmin != null && districtAdmin is Map<String, dynamic>) {
        final adminName = districtAdmin['fullName']?.toString() ?? 'District Admin';
        final districtName = districtAdmin['meta']?['districtName']?.toString() ?? 'District';
        return 'Approved by $adminName, $districtName Admin';
      }
      
      // Check for state admin approval
      final stateAdmin = reviewedBy['stateAdmin'];
      if (stateAdmin != null && stateAdmin is Map<String, dynamic>) {
        final adminName = stateAdmin['fullName']?.toString() ?? 'State Admin';
        final stateName = stateAdmin['meta']?['stateName']?.toString() ?? 'State';
        return 'Approved by $adminName, $stateName Admin';
      }
    }
    
    // Fallback to generic text if approval info is not available
    return 'Approved by ${widget.blockName}';
  }

  String _getRejectionText(Map<String, dynamic> app) {
    // Get reviewedBy information from the backend
    final reviewedBy = app['reviewedBy'];
    if (reviewedBy != null && reviewedBy is Map<String, dynamic>) {
      // Check for block admin rejection
      final blockAdmin = reviewedBy['blockAdmin'];
      if (blockAdmin != null && blockAdmin is Map<String, dynamic>) {
        final adminName = blockAdmin['fullName']?.toString() ?? 'Block Admin';
        final blockName = blockAdmin['meta']?['blockName']?.toString() ?? widget.blockName;
        return 'Rejected by $adminName, $blockName Admin';
      }
      
      // Check for district admin rejection
      final districtAdmin = reviewedBy['districtAdmin'];
      if (districtAdmin != null && districtAdmin is Map<String, dynamic>) {
        final adminName = districtAdmin['fullName']?.toString() ?? 'District Admin';
        final districtName = districtAdmin['meta']?['districtName']?.toString() ?? 'District';
        return 'Rejected by $adminName, $districtName Admin';
      }
      
      // Check for state admin rejection
      final stateAdmin = reviewedBy['stateAdmin'];
      if (stateAdmin != null && stateAdmin is Map<String, dynamic>) {
        final adminName = stateAdmin['fullName']?.toString() ?? 'State Admin';
        final stateName = stateAdmin['meta']?['stateName']?.toString() ?? 'State';
        return 'Rejected by $adminName, $stateName Admin';
      }
    }
    
    // Fallback to generic text if rejection info is not available
    return 'Rejected by ${widget.blockName}';
  }
}
