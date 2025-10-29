import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/member_status.dart';
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

class _BlockAdminMembersPageState extends State<BlockAdminMembersPage> 
    with AutomaticKeepAliveClientMixin {
  bool _loading = true;
  List<Map<String, dynamic>> _all = [];
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  bool get wantKeepAlive => true;

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

  // ---- status partitions ----
  bool _isPending(Map a) {
    final status = a['status']?.toString();
    return isPendingStatus(status);
  }

  bool _isApproved(Map a) {
    final status = a['status']?.toString();
    return isApprovedStatus(status);
  }

  bool _isRejected(Map a) {
    final status = a['status']?.toString();
    return isRejectedStatus(status);
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
  int get _rejectedCount => _all.where(_isRejected).length;
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Approved & forwarded to District')),
          );
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
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
          _iconButton(Icons.filter_alt_outlined),
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

  Widget _countsLine() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Text(
        '$_total members · $_approvedCount approved · $_rejectedCount rejected · $_pendingCount pending',
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
    final fullName = (app['fullName'] ?? 'Member').toString();
    final email = (app['email'] ?? '').toString();
    final phone = (app['phone'] ?? '').toString();
    final block = (app['block'] ?? widget.blockName).toString();
    final form = app['formData'] != null
        ? Map<String, dynamic>.from(app['formData'])
        : <String, dynamic>{};
    final gender = (form['gender'] ?? '').toString();
    final title = (form['jobTitle'] ?? form['role'] ?? '').toString();

    // Use consistent status handling
    final status = app['status']?.toString();
    final statusText = getStatusDisplayText(status);
    final statusColor = getStatusColor(status);

    final approved = isApprovedStatus(status);
    final rejected = isRejectedStatus(status);

    return GestureDetector(
      onTap: () => _openDetails(app),
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
            // header row with avatar + name + status chip
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: Color(0xFFE5E7EB),
                  child: Icon(Icons.person, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withAlpha(
                                (0.15 * 255).toInt(),
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // lines: email, title, location+gender, phone
                      _infoRow(Icons.mail_outline, email),
                      if (title.isNotEmpty) _infoRow(Icons.access_time, title),
                      _infoRow(
                        Icons.location_on_outlined,
                        [
                          if (gender.isNotEmpty) gender,
                          if (gender.isNotEmpty) ', ',
                          block,
                        ].join(),
                      ),
                      _infoRow(Icons.call_outlined, phone),
                      const SizedBox(height: 6),
                      if (approved)
                        const Text(
                          'Approved by: Block Admin',
                          style: TextStyle(
                            color: Color(0xFF16A34A),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      if (rejected)
                        const Text(
                          'Rejected by: Block Admin',
                          style: TextStyle(
                            color: Color(0xFFFF5C5C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Color(0xFF374151), fontSize: 14),
          ),
        ),
      ],
    ),
  );

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
}
