import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/application_service.dart';
import 'districtadmin_dashboard.dart' show UserDetailsDropdown;

enum ApprovalCategory { pending, approved, rejected, all }

class DistrictAdminApprovalPage extends StatefulWidget {
  // Make inputs optional and resolve sensible defaults at runtime.
  final String? apiBaseUrl;
  final String? districtAdminId;
  final String? districtName;
  final String? token;
  final ApprovalCategory initialCategory;
  final VoidCallback? onRefreshRequested;

  const DistrictAdminApprovalPage({
    super.key,
    this.apiBaseUrl,
    this.districtAdminId,
    this.districtName,
    this.token,
    this.initialCategory = ApprovalCategory.pending,
    this.onRefreshRequested,
  });

  @override
  State<DistrictAdminApprovalPage> createState() =>
      _DistrictAdminApprovalPageState();
}

class _DistrictAdminApprovalPageState extends State<DistrictAdminApprovalPage> {
  bool _loading = true;
  ApprovalCategory _tab = ApprovalCategory.pending;

  List<Map<String, dynamic>> _pending = [];
  List<Map<String, dynamic>> _approved = [];
  List<Map<String, dynamic>> _rejected = [];
  late ApplicationService _svc;
  String? _inFlightId;
  final DateFormat _fmt = DateFormat('dd/MM/yyyy');
  // Resolved context
  String? _resolvedDistrictAdminId;
  String _resolvedDistrictName = '';

  @override
  void initState() {
    super.initState();
    _tab = widget.initialCategory;
    _svc = ApplicationService(widget.apiBaseUrl ?? ApiService.baseUrl);
    debugPrint('[DA_APPROVAL] init for districtId=${widget.districtAdminId}');
    _resolveContextAndLoad();
  }

  Future<void> _resolveContextAndLoad() async {
    // If critical inputs are missing, try to resolve from logged-in user
    if ((widget.districtAdminId == null || widget.districtAdminId!.isEmpty) ||
        (widget.districtName == null || widget.districtName!.isEmpty)) {
      try {
        final user = await AuthService.getUserData();
        _resolvedDistrictAdminId = (user?['adminId'] ?? user?['_id'] ?? '')
            .toString();
        _resolvedDistrictName = (user?['districtName'] ?? 'District')
            .toString();
      } catch (_) {
        // Leave as null/empty; _load will still guard.
      }
    }
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      debugPrint('DA[_load]: called');
      final districtId = (widget.districtAdminId?.isNotEmpty == true)
          ? widget.districtAdminId!
          : (_resolvedDistrictAdminId ?? '');

      if (districtId.isEmpty) {
        throw Exception('Missing district admin id');
      }

      // Fetch ALL applications using the new endpoint
      final allApps = await ApiService.getDistrictAdminAllApplications(
        districtId,
      );

      // Filter by status
      final allAppsList = List<Map<String, dynamic>>.from(allApps);

      final pending = allAppsList.where((app) {
        final status = (app['status'] ?? '').toString().toLowerCase();
        return status == 'pending-district' || status == 'pending';
      }).toList();

      final approved = allAppsList.where((app) {
        final status = (app['status'] ?? '').toString().toLowerCase();
        return status == 'approved' || status == 'pending-state';
      }).toList();

      final rejected = allAppsList.where((app) {
        final status = (app['status'] ?? '').toString().toLowerCase();
        return status == 'rejected';
      }).toList();

      setState(() {
        _pending = pending;
        _approved = approved;
        _rejected = rejected;
      });

      debugPrint(
        '[DA_API] response 200 pending=${_pending.length} approved=${_approved.length} rejected=${_rejected.length}',
      );
    } catch (e) {
      debugPrint('[DA_API] error 500 ${e.toString()}');
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
    debugPrint('DA[handleAction]: action=$action on appId=$appId');
    if (mounted) setState(() => _inFlightId = appId);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final res = await _svc.districtReview(
        appId: appId,
        adminId: (widget.districtAdminId?.isNotEmpty == true)
            ? widget.districtAdminId!
            : (_resolvedDistrictAdminId ?? ''),
        action: action,
        reason: reason,
      );
      debugPrint('DA[handleAction]: apiResponse=$res');
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
            app['status'] = 'Pending-State';
            _approved.insert(0, app);
          } else {
            app['status'] = 'Rejected';
            _rejected.insert(0, app);
          }
        });
        // Notify parent dashboard to refresh its stats
        widget.onRefreshRequested?.call();
      } else {
        debugPrint(
          'DA[handleAction]: appId not found in pending; will refetch',
        );
        await _load();
        widget.onRefreshRequested?.call();
      }
    } catch (e) {
      debugPrint('DA[handleAction]: error=${e.toString()}');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Error ${action}ing application: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _inFlightId = null);
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
                  hintText: 'Enter rejection reason...',
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
                _reject(appId, reason: reasonController.text);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );
  }

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
                    _buildHeader(),

                    const SizedBox(height: 12),
                    _buildTabBar(),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: () {
                          final items = _filtered
                              .map(_buildApplicationCard)
                              .toList();
                          debugPrint(
                            'DA[buildApplications]: displaying ${items.length} cards',
                          );
                          return items;
                        }(),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
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
                      'District Approvals',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage ${(widget.districtName?.isNotEmpty == true ? widget.districtName! : (_resolvedDistrictName.isNotEmpty ? _resolvedDistrictName : 'District'))} Applications',
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
            chip(
              'Pending ($pendingCount)',
              _tab == ApprovalCategory.pending,
              () {
                setState(() => _tab = ApprovalCategory.pending);
                debugPrint(
                  'DA[filter]: tab=pending resultCount=${_filtered.length}',
                );
              },
            ),
            const SizedBox(width: 8),
            chip(
              'Approved ($approvedCount)',
              _tab == ApprovalCategory.approved,
              () {
                setState(() => _tab = ApprovalCategory.approved);
                debugPrint(
                  'DA[filter]: tab=approved resultCount=${_filtered.length}',
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
                  'DA[filter]: tab=rejected resultCount=${_filtered.length}',
                );
              },
            ),
            const SizedBox(width: 8),
            chip('All ($allCount)', _tab == ApprovalCategory.all, () {
              setState(() => _tab = ApprovalCategory.all);
              debugPrint('DA[filter]: tab=all resultCount=${_filtered.length}');
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> app) {
    // Debug: Print entire app object to see structure
    debugPrint('[DA_CARD_BUILD] Building card for app: ${app['_id']}');
    debugPrint('[DA_CARD_KEYS] App keys: ${app.keys.toList()}');

    final status = app['status'] ?? '';
    final isPending = status.toString().toLowerCase().contains(
      'pending-district',
    );
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

    // Debug logging to see what data we have
    debugPrint(
      '[DA_GENDER_DEBUG] App ${app['_id']}: rawGender=$rawGender, '
      'app.gender=${app['gender']}, form.gender=${form['gender']}, '
      'personalInfo.gender=${personalInfo?['gender']}, '
      'personalDetails.gender=${personalDetails?['gender']}, '
      'appPersonalDetails.gender=${appPersonalDetails?['gender']}, '
      'formData keys=${app['formData']?.keys.toList()}, '
      'personalDetails keys=${personalDetails?.keys.toList()}, '
      'app keys=${app.keys.toList()}',
    );

    final String gender = normalizeGender(rawGender);
    debugPrint(
      '[DA_GENDER_DEBUG] App ${app['_id']}: normalized gender=$gender',
    );

    final appliedAt = app['blockApprovedAt'] ?? app['createdAt'];
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
              // Second line: Email (left) and Gender (right)
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
              // Entire card is tappable; removed inner GestureDetector
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
      case 'Pending-District':
        return const Color(0xFFF59E0B);
      case 'Pending-State':
        return const Color(0xFF10B981);
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
      case 'Pending-District':
        return 'Pending';
      case 'Pending-State':
        return 'Approved';
      case 'Rejected':
        return 'Rejected';
      default:
        return status;
    }
  }
}
