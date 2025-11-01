import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/application_service.dart';
import '../District Admin/districtadmin_dashboard.dart'
    show UserDetailsDropdown;

enum ApprovalCategory { pending, approved, rejected, all }

// Persist state admin approvals/rejections across navigation within app session
class _StateApprovalMemory {
  static final Map<String, Map<String, dynamic>> acted = {};
}

class StateAdminApprovalPage extends StatefulWidget {
  final String? apiBaseUrl;
  final String? stateAdminId;
  final String? stateName;
  final String? token;
  final ApprovalCategory initialCategory;
  final VoidCallback? onRefreshRequested;

  const StateAdminApprovalPage({
    super.key,
    this.apiBaseUrl,
    this.stateAdminId,
    this.stateName,
    this.token,
    this.initialCategory = ApprovalCategory.pending,
    this.onRefreshRequested,
  });

  @override
  State<StateAdminApprovalPage> createState() => _StateAdminApprovalPageState();
}

class _StateAdminApprovalPageState extends State<StateAdminApprovalPage> {
  bool _loading = true;
  ApprovalCategory _tab = ApprovalCategory.pending;

  List<Map<String, dynamic>> _all = [];
  late ApplicationService _svc;
  String? _inFlightId;
  final DateFormat _fmt = DateFormat('dd/MM/yyyy');
  String? _resolvedStateAdminId;
  String _resolvedStateName = '';

  // --- Debug helpers ---
  String _normStatus(Map<String, dynamic> a) {
    final sRaw = (a['status'] ?? a['applicationStatus'] ?? '')
        .toString()
        .trim();
    final sLower = sRaw.toLowerCase();
    if (sLower.contains('pending-state')) return 'pending-state';
    if (sRaw == 'Approved') return 'approved';
    if (sLower.contains('rejected')) return 'rejected';
    return sRaw.isEmpty ? 'unknown' : sLower;
  }

  Map<String, int> _bucketCounts(List<Map<String, dynamic>> list) {
    final buckets = <String, int>{
      'pending-state': 0,
      'approved': 0,
      'rejected': 0,
      'unknown': 0,
    };
    for (final a in list) {
      final b = _normStatus(a);
      buckets[b] = (buckets[b] ?? 0) + 1;
    }
    return buckets;
  }

  void _logSummary(String where, {List<Map<String, dynamic>>? list}) {
    final src = list ?? _all;
    final buckets = _bucketCounts(src);
    final ids = src.take(10).map((a) => a['_id']?.toString() ?? '').toList();
    debugPrint(
      '[StateAdminApproval] $where: total=${src.length} buckets=$buckets ids(sample)=$ids',
    );
  }

  @override
  void initState() {
    super.initState();
    _tab = widget.initialCategory;
    _svc = ApplicationService(
      widget.apiBaseUrl ?? ApiService.baseUrl,
      token: widget.token,
    );
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    debugPrint(
      '[StateAdminApproval] _load() start: tab=$_tab props: stateAdminId=${widget.stateAdminId} token=${widget.token != null} apiBaseUrl=${widget.apiBaseUrl}',
    );
    try {
      // Resolve admin context
      if (widget.stateAdminId?.isNotEmpty == true) {
        _resolvedStateAdminId = widget.stateAdminId;
      } else {
        final me = await AuthService.getUserData();
        _resolvedStateAdminId = (me?['adminId'] ?? me?['_id'] ?? '').toString();
        _resolvedStateName =
            me?['meta']?['stateName']?.toString() ??
            me?['stateName']?.toString() ??
            '';
      }

      debugPrint(
        '[StateAdminApproval] resolved adminId=$_resolvedStateAdminId stateName=${_resolvedStateName.isNotEmpty ? _resolvedStateName : widget.stateName}',
      );

      final stateId = (_resolvedStateAdminId ?? '').toString();
      if (stateId.isEmpty) {
        throw Exception('Missing state admin id');
      }

      // Fetch applications for state admin (backend may return pending-only)
      final apps = await _svc.getStateApplications(stateAdminId: stateId);
      final fetched = List<Map<String, dynamic>>.from(
        apps.map((e) => Map<String, dynamic>.from(e as Map)),
      );

      // Preserve locally approved/rejected items across reloads (backend often omits them)
      final preserve = _all.where((a) {
        final s = _normStatus(a);
        return s == 'approved' || s == 'rejected';
      }).toList();

      // Merge and dedupe by _id, favor fetched data for pending items
      final byId = <String, Map<String, dynamic>>{};
      for (final a in [...fetched, ...preserve]) {
        final id = (a['_id']?.toString() ?? '').trim();
        if (id.isEmpty) continue;
        // If both exist, prefer the one with a non-pending terminal status
        if (!byId.containsKey(id)) {
          byId[id] = a;
        } else {
          final existing = byId[id]!;
          final sNew = _normStatus(a);
          final sOld = _normStatus(existing);
          // Prefer approved/rejected over pending-state
          if (sOld == 'pending-state' &&
              (sNew == 'approved' || sNew == 'rejected')) {
            byId[id] = a;
          }
        }
      }
      // Merge with session cache (items approved/rejected earlier in this run)
      final cached = _StateApprovalMemory.acted.values.toList();
      for (final a in cached) {
        final id = (a['_id']?.toString() ?? '').trim();
        if (id.isEmpty) continue;
        final s = _normStatus(a);
        if (s == 'approved' || s == 'rejected') {
          if (!byId.containsKey(id)) {
            byId[id] = a;
          } else {
            final existing = byId[id]!;
            final sOld = _normStatus(existing);
            if (sOld == 'pending-state') byId[id] = a;
          }
        }
      }
      _all = byId.values.toList();
      _logSummary('after _load fetch');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading applications: $e')),
        );
        debugPrint('[StateAdminApproval] _load() error: $e');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      debugPrint('[StateAdminApproval] _load() done, loading=$_loading');
    }
  }

  List<Map<String, dynamic>> get _filtered {
    switch (_tab) {
      case ApprovalCategory.pending:
        return _all
            .where((app) => _normStatus(app) == 'pending-state')
            .toList();
      case ApprovalCategory.approved:
        return _all.where((app) => _normStatus(app) == 'approved').toList();
      case ApprovalCategory.rejected:
        return _all.where((app) => _normStatus(app) == 'rejected').toList();
      case ApprovalCategory.all:
        return _all.where((app) {
          final s = _normStatus(app);
          return s == 'pending-state' || s == 'approved' || s == 'rejected';
        }).toList();
    }
  }

  Future<void> _approve(String appId) async {
    debugPrint('[StateAdminApproval] approve tapped: $appId');
    await _handleAction(appId, 'approve');
  }

  Future<void> _reject(String appId, {String? reason}) async {
    debugPrint(
      '[StateAdminApproval] reject tapped: $appId reason=${reason ?? ''}',
    );
    await _handleAction(appId, 'reject', reason: reason);
  }

  Future<void> _handleAction(
    String appId,
    String action, {
    String? reason,
  }) async {
    if (mounted) setState(() => _inFlightId = appId);
    final beforeIdx = _all.indexWhere(
      (a) => (a['_id']?.toString() ?? '') == appId,
    );
    final beforeStatus = beforeIdx != -1
        ? _normStatus(_all[beforeIdx])
        : 'not-found';
    debugPrint(
      '[StateAdminApproval] action start: $action appId=$appId beforeStatus=$beforeStatus reason=${reason ?? ''}',
    );
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await _svc.stateReview(
        appId: appId,
        adminId: (widget.stateAdminId?.isNotEmpty == true)
            ? widget.stateAdminId!
            : (_resolvedStateAdminId ?? ''),
        action: action,
        reason: reason,
      );

      if (!mounted) return;
      final message = res['message']?.toString() ?? 'Application ${action}d';
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: action == 'approve' ? Colors.green : Colors.red,
        ),
      );

      final i = _all.indexWhere((a) => (a['_id']?.toString() ?? '') == appId);
      if (i != -1) {
        final updated = Map<String, dynamic>.from(_all[i]);
        updated['status'] = action == 'approve' ? 'Approved' : 'Rejected';
        setState(() {
          _all[i] = updated;
        });
        // Persist in session cache to survive navigation reloads
        _StateApprovalMemory.acted[appId] = updated;
        debugPrint(
          '[StateAdminApproval] local update: appId=$appId newStatus=${_normStatus(updated)}',
        );
        _logSummary('after local update');
        widget.onRefreshRequested?.call();
      } else {
        await _load();
        debugPrint(
          '[StateAdminApproval] app not found locally, refetched list',
        );
        // Also persist into cache using minimal data so it remains visible post-reload
        _StateApprovalMemory.acted[appId] = {
          '_id': appId,
          'status': action == 'approve' ? 'Approved' : 'Rejected',
        };
        widget.onRefreshRequested?.call();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error ${action}ing application: $e'),
            backgroundColor: Colors.red,
          ),
        );
        debugPrint(
          '[StateAdminApproval] action error: $action appId=$appId error=$e',
        );
      }
    } finally {
      if (mounted) setState(() => _inFlightId = null);
      debugPrint('[StateAdminApproval] action done: $action appId=$appId');
    }
  }

  void _showRejectDialog(String appId) {
    final TextEditingController reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Application'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Please provide a reason for rejection:'),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  hintText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                debugPrint(
                  '[StateAdminApproval] reject dialog submit: appId=$appId reason=${reasonController.text.trim()}',
                );
                _reject(appId, reason: reasonController.text.trim());
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _openProfileSheet(Map<String, dynamic> app) {
    final map = Map<String, dynamic>.from(app);
    final String appId = (map['_id'] ?? '').toString();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserDetailsDropdown(
        app: map,
        onApprove: () => _approve(appId),
        onReject: () => _showRejectDialog(appId),
        showActions: false,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending-State':
        return const Color(0xFF1E88FF);
      case 'Approved':
        return const Color(0xFF10B981);
      case 'Rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Pending-State':
        return 'Pending';
      case 'Approved':
        return 'Approved';
      case 'Rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint(
      '[StateAdminApproval] build() start: loading=$_loading tab=$_tab total=${_all.length}',
    );
    _logSummary('build start');
    return Scaffold(
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildTabBar(),
                const SizedBox(height: 18),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: () {
                      debugPrint(
                        '[StateAdminApproval] build list: tab=$_tab filteredCount=${_filtered.length}',
                      );
                      final items = _filtered;
                      if (items.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: const [SizedBox(height: 24)],
                        );
                      }
                      return ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: items.length,
                        itemBuilder: (context, index) =>
                            _buildApplicationCard(items[index]),
                      );
                    }(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1F6FF), Color(0xFFE9F0FF)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'State Approvals',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage ${(widget.stateName?.isNotEmpty == true ? widget.stateName! : (_resolvedStateName.isNotEmpty ? _resolvedStateName : 'State'))} Applications',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.1 * 255).toInt()),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    final pendingCount = _all
        .where((a) => _normStatus(a) == 'pending-state')
        .length;
    final approvedCount = _all
        .where((a) => _normStatus(a) == 'approved')
        .length;
    final rejectedCount = _all
        .where((a) => _normStatus(a) == 'rejected')
        .length;
    final allCount = pendingCount + approvedCount + rejectedCount;

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
              debugPrint(
                '[StateAdminApproval] tab switch → pending; filtered=${_filtered.length}',
              );
              _logSummary('tab pending filtered', list: _filtered);
            }),
            const SizedBox(width: 8),
            chip(
              'Approved ($approvedCount)',
              _tab == ApprovalCategory.approved,
              () {
                setState(() => _tab = ApprovalCategory.approved);
                debugPrint(
                  '[StateAdminApproval] tab switch → approved; filtered=${_filtered.length}',
                );
                _logSummary('tab approved filtered', list: _filtered);
              },
            ),
            const SizedBox(width: 8),
            chip(
              'Rejected ($rejectedCount)',
              _tab == ApprovalCategory.rejected,
              () {
                setState(() => _tab = ApprovalCategory.rejected);
                debugPrint(
                  '[StateAdminApproval] tab switch → rejected; filtered=${_filtered.length}',
                );
                _logSummary('tab rejected filtered', list: _filtered);
              },
            ),
            const SizedBox(width: 8),
            chip('All ($allCount)', _tab == ApprovalCategory.all, () {
              setState(() => _tab = ApprovalCategory.all);
              debugPrint(
                '[StateAdminApproval] tab switch → all; filtered=${_filtered.length}',
              );
              _logSummary('tab all filtered', list: _filtered);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> app) {
    final status = (app['status'] ?? app['applicationStatus'] ?? '').toString();
    final isPending = _normStatus(app) == 'pending-state';
    final id = app['_id']?.toString() ?? '';
    final fullName =
        (app['fullName'] ?? app['name'] ?? app['memberName'] ?? 'Unknown')
            .toString();
    final phone = (app['phone'] ?? 'N/A').toString();
    final email = (app['email'] ?? app['memberEmail'] ?? 'N/A').toString();
    final block = (app['block'] ?? 'N/A').toString();
    final Map<String, dynamic>? personalInfo =
        app['personalInfo'] as Map<String, dynamic>?;
    final gender =
        (app['gender'] ??
                (personalInfo != null ? personalInfo['gender'] : null) ??
                'NA')
            .toString();
    final appliedAt = app['districtApprovedAt'] ?? app['createdAt'];
    String appliedOnStr = 'N/A';
    try {
      if (appliedAt != null) {
        final dt = DateTime.parse(appliedAt.toString());
        appliedOnStr = _fmt.format(dt);
      }
    } catch (_) {}

    return InkWell(
      onTap: () => _openProfileSheet(app),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).toInt()),
              blurRadius: 14,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 26,
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
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Phone: $phone',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
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
                      color: _getStatusColor(
                        status,
                      ).withAlpha((0.1 * 255).toInt()),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusText(status),
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
                    'Applied: $appliedOnStr',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.email,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
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
              if (isPending) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _inFlightId == id
                            ? null
                            : () => _approve(id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _inFlightId == id
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _inFlightId == id
                            ? null
                            : () => _showRejectDialog(id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5C5C),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _inFlightId == id
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Reject'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
