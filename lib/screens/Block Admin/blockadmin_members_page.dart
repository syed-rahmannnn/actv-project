import 'package:flutter/material.dart';
import '../../services/api_service.dart';
// Reuse the same dropdown you already created inside the dashboard file
import 'blockadmin_dashboard.dart' show UserDetailsDropdown;

class BlockAdminMembersPage extends StatefulWidget {
  final String apiBaseUrl;
  final String blockAdminId;
  final String blockName;
  final String? token;

  const BlockAdminMembersPage({
    super.key,
    required this.apiBaseUrl,
    required this.blockAdminId,
    required this.blockName,
    this.token,
  });

  @override
  State<BlockAdminMembersPage> createState() => _BlockAdminMembersPageState();
}

class _BlockAdminMembersPageState extends State<BlockAdminMembersPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _all = [];
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final apps = await ApiService.getBlockAdminApplications(
        widget.blockAdminId,
      );
      _all = List<Map<String, dynamic>>.from(apps);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load members: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ---- status partitions (use normalized status from backend) ----
  bool _isPending(Map a) {
    final status = (a['status'] ?? '').toString().trim().toLowerCase();
    return status.isEmpty ||
        status == 'pending' ||
        status == 'submitted' ||
        status == 'pending-block';
  }

  bool _isApproved(Map a) {
    final status = (a['status'] ?? '').toString().trim().toLowerCase();
    return status == 'approved';
  }

  bool _isRejected(Map a) {
    final status = (a['status'] ?? '').toString().trim().toLowerCase();
    return status == 'rejected';
  }

  List<Map<String, dynamic>> get _filtered {
    final list = [..._all];
    // Optional: stable grouping Pending -> Approved -> Rejected (matches your mock sequence)
    list.sort((a, b) {
      int rank(Map x) => _isPending(x)
          ? 0
          : _isApproved(x)
          ? 1
          : 2;
      final r = rank(a).compareTo(rank(b));
      if (r != 0) return r;
      return (a['fullName'] ?? '').toString().compareTo(
        (b['fullName'] ?? '').toString(),
      );
    });

    if (_query.isEmpty) return list;

    bool match(Map m) {
      final name = (m['fullName'] ?? '').toString().toLowerCase();
      final email = (m['email'] ?? '').toString().toLowerCase();
      final phone = (m['phone'] ?? '').toString().toLowerCase();
      return name.contains(_query) ||
          email.contains(_query) ||
          phone.contains(_query);
    }

    return list.where(match).toList();
  }

  int get _total => _all.length;
  int get _approvedCount => _all.where(_isApproved).length;
  int get _pendingCount => _all.where(_isPending).length;

  Future<void> _approve(String appId) async {
    try {
      final ok = await ApiService.reviewBlockApplication(
        appId,
        'approve',
        adminId: widget.blockAdminId,
      );
      if (ok) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Approved')));
        }
        await _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Approve failed: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _reject(String appId) async {
    final reasonCtrl = TextEditingController();
    final go = await showDialog<bool>(
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
    if (go == true) {
      try {
        final ok = await ApiService.reviewBlockApplication(
          appId,
          'reject',
          adminId: widget.blockAdminId,
          reason: reasonCtrl.text.trim().isEmpty
              ? null
              : reasonCtrl.text.trim(),
        );
        if (ok) {
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Rejected')));
          }
          await _load();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Reject failed: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _openDetails(Map<String, dynamic> app) async {
    // Same dropdown flow used on your dashboard/approvals pages
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
                    showActions: false,
                    onApprove: () => _approve(app['_id'].toString()),
                    onReject: () => _reject(app['_id'].toString()),
                  ),
                );
              }
              return;
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
            showActions: false,
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

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
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
                    _countsLine(),
                    const SizedBox(height: 8),
                    _searchBar(),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: _filtered.map(_memberCard).toList(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          const Text(
            'Members',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFF1E88FF),
            child: Text('A', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _countsLine() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Text(
        '$_total members · $_approvedCount approved · $_pendingCount pending',
        style: const TextStyle(color: Color(0xFF6B7280)),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.06 * 255).toInt()),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.search, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search members...',
                  border: InputBorder.none,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _memberCard(Map<String, dynamic> app) {
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

    final fullName = (app['fullName'] ?? 'Member').toString();
    final email = (app['email'] ?? '').toString();
    final phone = (app['phone'] ?? '').toString();
    final block = (app['block'] ?? widget.blockName).toString();
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
    final dynamic rawGender =
        app['gender'] ??
        form['gender'] ??
        personalInfo?['gender'] ??
        personalDetails?['gender'];
    final String gender = normalizeGender(rawGender);

    // Normalize and style status pill like approvals/dashboard
    final bool approved = _isApproved(app);
    final bool rejected = _isRejected(app);
    final bool pending = _isPending(app);

    // Normalize to tri-state for chip display
    final String statusText = approved
        ? 'Approved'
        : (rejected ? 'Rejected' : 'Pending');

    return GestureDetector(
      onTap: () => _openDetails(app),
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
            // Top row: avatar, name + phone, status pill at right (match approvals page)
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: pending
                        ? const Color(0xFFFEF3C7)
                        : (approved
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEE2E2)),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: pending
                          ? const Color(0xFFF59E0B)
                          : (approved
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFFF5C5C)),
                    ),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: pending
                          ? const Color(0xFFF59E0B)
                          : (approved
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFFF5C5C)),
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
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.person,
                      size: 16,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Gender: $gender',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Status description only (no colored text), match approvals page
            if (!pending)
              Text(
                approved ? _getApprovalText(app) : _getRejectionText(app),
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }

  String _getApprovalText(Map<String, dynamic> app) {
    // Match the approval page text: prefer meta-driven location labels
    final reviewedBy = app['reviewedBy'];
    if (reviewedBy != null && reviewedBy is Map<String, dynamic>) {
      // Block admin
      final blockAdmin = reviewedBy['blockAdmin'];
      if (blockAdmin != null && blockAdmin is Map<String, dynamic>) {
        final blockName =
            blockAdmin['meta']?['blockName']?.toString() ?? widget.blockName;
        return 'Approved by $blockName Block Admin';
      }

      // District admin
      final districtAdmin = reviewedBy['districtAdmin'];
      if (districtAdmin != null && districtAdmin is Map<String, dynamic>) {
        final districtName =
            districtAdmin['meta']?['districtName']?.toString() ?? 'District';
        return 'Approved by $districtName District Admin';
      }

      // State admin
      final stateAdmin = reviewedBy['stateAdmin'];
      if (stateAdmin != null && stateAdmin is Map<String, dynamic>) {
        final stateName =
            stateAdmin['meta']?['stateName']?.toString() ?? 'State';
        return 'Approved by $stateName State Admin';
      }
    }

    // Fallback
    return 'Approved by ${widget.blockName} Block Admin';
  }

  String _getRejectionText(Map<String, dynamic> app) {
    // Match the approval page text
    final reviewedBy = app['reviewedBy'];
    if (reviewedBy != null && reviewedBy is Map<String, dynamic>) {
      final blockAdmin = reviewedBy['blockAdmin'];
      if (blockAdmin != null && blockAdmin is Map<String, dynamic>) {
        final blockName =
            blockAdmin['meta']?['blockName']?.toString() ?? widget.blockName;
        return 'Rejected by $blockName Block Admin';
      }
    }

    // Fallback
    return 'Rejected by ${widget.blockName} Block Admin';
  }
}
