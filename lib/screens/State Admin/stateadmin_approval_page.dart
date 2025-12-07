import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/application_service.dart';
import '../District Admin/districtadmin_dashboard.dart'
    show UserDetailsDropdown;

enum ApprovalCategory { pending, approved, rejected, all }

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

  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _approved = [];
  List<Map<String, dynamic>> _rejected = [];
  late ApplicationService _svc;
  String? _inFlightId;
  final DateFormat _fmt = DateFormat('dd/MM/yyyy');
  String? _resolvedStateAdminId;
  String _resolvedStateName = '';

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

      final stateId = (_resolvedStateAdminId ?? '').toString();
      if (stateId.isEmpty) {
        throw Exception('Missing state admin id');
      }

      // Fetch ALL applications using the new endpoint
      final allApps = await ApiService.getStateAdminAllApplications(stateId);

      // Filter by status
      final allAppsList = List<Map<String, dynamic>>.from(allApps);

      final pending = allAppsList.where((app) {
        final status = (app['status'] ?? '').toString().toLowerCase();
        return status == 'pending-state' || status == 'pending';
      }).toList();

      final approved = allAppsList.where((app) {
        final status = (app['status'] ?? '').toString().toLowerCase();
        return status == 'approved';
      }).toList();

      final rejected = allAppsList.where((app) {
        final status = (app['status'] ?? '').toString().toLowerCase();
        return status == 'rejected';
      }).toList();

      if (mounted) {
        setState(() {
          _pending = List<Map<String, dynamic>>.from(pending);
          _approved = List<Map<String, dynamic>>.from(approved);
          _rejected = List<Map<String, dynamic>>.from(rejected);
        });
      }

      debugPrint(
        '[SA_API] response 200 pending=${_pending.length} approved=${_approved.length} rejected=${_rejected.length}',
      );
    } catch (e) {
      debugPrint('[SA_API] error: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading applications: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    switch (_tab) {
      case ApprovalCategory.pending:
        return _pending;
      case ApprovalCategory.approved:
        return _approved;
      case ApprovalCategory.rejected:
        return _rejected;
      case ApprovalCategory.all:
        return [..._pending, ..._approved, ..._rejected];
    }
  }

  Future<void> _approve(String appId) async {
    await _handleAction(appId, 'approve');
  }

  Future<void> _reject(String appId, {String? reason}) async {
    await _handleAction(appId, 'reject', reason: reason);
  }

  Future<void> _handleAction(
    String appId,
    String action, {
    String? reason,
  }) async {
    if (mounted) setState(() => _inFlightId = appId);
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

      // Optimistic UI update: move application from pending to approved/rejected
      final pendingIndex = _pending.indexWhere(
        (a) => (a['_id']?.toString() ?? '') == appId,
      );
      if (pendingIndex != -1) {
        final app = Map<String, dynamic>.from(_pending[pendingIndex]);
        setState(() {
          _pending.removeAt(pendingIndex);
          if (action == 'approve') {
            app['status'] = 'Approved';
            _approved.insert(0, app);
          } else {
            app['status'] = 'Rejected';
            _rejected.insert(0, app);
          }
        });
        widget.onRefreshRequested?.call();
      } else {
        await _load();
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

  void _openProfileSheet(Map<String, dynamic> app) async {
    // Same behavior as block admin: try full profile by email, else fallback
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
                    onReject: () => _showRejectDialog(app['_id'].toString()),
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
            showActions: false,
            onApprove: () => _approve(app['_id'].toString()),
            onReject: () => _showRejectDialog(app['_id'].toString()),
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
    final totalCount = _pending.length + _approved.length + _rejected.length;
    debugPrint(
      '[StateAdminApproval] build() start: loading=$_loading tab=$_tab total=$totalCount',
    );
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
    final pendingCount = _pending.length;
    final approvedCount = _approved.length;
    final rejectedCount = _rejected.length;
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
              },
            ),
            const SizedBox(width: 8),
            chip('All ($allCount)', _tab == ApprovalCategory.all, () {
              setState(() => _tab = ApprovalCategory.all);
              debugPrint(
                '[StateAdminApproval] tab switch → all; filtered=${_filtered.length}',
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> app) {
    final status = (app['status'] ?? app['applicationStatus'] ?? '').toString();
    final isPending = status.toLowerCase().contains('pending-state');
    final id = app['_id']?.toString() ?? '';
    final fullName =
        (app['fullName'] ?? app['name'] ?? app['memberName'] ?? 'Unknown')
            .toString();
    final phone = (app['phone'] ?? 'N/A').toString();
    final email = (app['email'] ?? app['memberEmail'] ?? 'N/A').toString();
    final block = (app['block'] ?? 'N/A').toString();

    // Gender extraction logic matching Block Admin implementation
    final form = app['formData'] != null
        ? Map<String, dynamic>.from(app['formData'])
        : <String, dynamic>{};

    String normalizeGender(dynamic g) {
      if (g == null) return 'Not Specified';
      final v = g.toString().trim();
      if (v.isEmpty) return 'Not Specified';
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
      return v; // show as-is if unknown
    }

    final Map<String, dynamic>? personalInfo =
        form['personalInfo'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(form['personalInfo'])
        : null;
    final Map<String, dynamic>? personalDetails =
        form['personalDetails'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(form['personalDetails'])
        : null;

    // Also check if personalDetails exists directly in app (not in formData)
    final Map<String, dynamic>? appPersonalDetails =
        app['personalDetails'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(app['personalDetails'])
        : null;

    final dynamic rawGender =
        app['gender'] ??
        form['gender'] ??
        personalInfo?['gender'] ??
        personalDetails?['gender'] ??
        appPersonalDetails?['gender'];

    final String gender = normalizeGender(rawGender);

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
