import 'package:flutter/material.dart';
import 'stateadmin_settings.dart';
import 'stateadmin_approval_page.dart';
import 'stateadmin_members_page.dart';
import '../../services/application_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'dart:developer' as developer;

class StateAdminDashboard extends StatelessWidget {
  final String adminId;
  const StateAdminDashboard({super.key, required this.adminId});

  @override
  Widget build(BuildContext context) {
    return const StateAdminDashboardPage();
  }
}

class StateAdminDashboardPage extends StatefulWidget {
  const StateAdminDashboardPage({super.key});

  @override
  State<StateAdminDashboardPage> createState() =>
      _StateAdminDashboardPageState();
}

class _StateAdminDashboardPageState extends State<StateAdminDashboardPage> {
  int _tab = 0;
  bool _isLoading = false;
  final Map<String, int> _stats = {
    'pending': 0,
    'approved': 0,
    'rejected': 0,
    'total': 0,
  };

  final List<dynamic> _pending = [];
  String? _stateAdminId;
  String _stateName = '';
  late ApplicationService _applicationService;

  @override
  void initState() {
    super.initState();
    _applicationService = ApplicationService(ApiService.baseUrl);
    _initAdminAndData();
  }

  Future<void> _initAdminAndData() async {
    setState(() => _isLoading = true);
    try {
      final me = await AuthService.getUserData();
      _stateAdminId = (me?['adminId'] ?? me?['_id'] ?? '').toString();
      _stateName = (me?['stateName'] ?? 'State').toString();
      await _fetchPendingApplications();
      await _fetchStats();
    } catch (e) {
      developer.log(
        'Error initializing state admin: $e',
        name: 'StateAdminDashboard',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchPendingApplications() async {
    try {
      final stateId = (_stateAdminId ?? '').trim();
      if (stateId.isEmpty) return;
      final apps = await _applicationService.getStateApplications(
        stateAdminId: stateId,
      );
      final pendingApps = apps.where((app) {
        final status = (app['status'] ?? app['applicationStatus'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        return status == 'pending-state' || status.contains('pending-state');
      }).toList();
      setState(() {
        _pending.clear();
        _pending.addAll(pendingApps);
      });
    } catch (e) {
      developer.log(
        'Error fetching pending apps: $e',
        name: 'StateAdminDashboard',
      );
    }
  }

  Future<void> _fetchStats() async {
    try {
      final stateId = (_stateAdminId ?? '').trim();
      if (stateId.isEmpty) return;
      final stats = await _applicationService.getStateStats(stateId);
      setState(() {
        _stats['pending'] = stats['pending'] ?? 0;
        _stats['approved'] = stats['approved'] ?? 0;
        _stats['rejected'] = stats['rejected'] ?? 0;
        _stats['total'] = stats['total'] ?? 0;
      });
    } catch (e) {
      developer.log('Error fetching stats: $e', name: 'StateAdminDashboard');
    }
  }

  Future<void> _handleApplicationAction(
    String applicationId,
    String action, {
    String? reason,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    try {
      final res = await _applicationService.stateReview(
        appId: applicationId,
        adminId: _stateAdminId ?? '',
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
      await _fetchPendingApplications();
      await _fetchStats();
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Error ${action}ing application: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleApprove(Map<String, dynamic> app) async {
    final applicationId = app['_id']?.toString() ?? '';
    if (applicationId.isEmpty) return;
    await _handleApplicationAction(applicationId, 'approve');
    await _fetchStats();
  }

  Future<void> _handleReject(Map<String, dynamic> app) async {
    final applicationId = app['_id']?.toString() ?? '';
    if (applicationId.isEmpty) return;
    _showRejectDialog(applicationId);
  }

  void _showRejectDialog(String applicationId) {
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
                _handleApplicationAction(
                  applicationId,
                  'reject',
                  reason: reasonController.text,
                );
                _fetchStats();
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Navigate to login screen
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      },
      child: Scaffold(
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
      ),
    );
  }

  Widget _page(int i) {
    switch (i) {
      case 0:
        return RefreshIndicator(
          onRefresh: _fetchPendingApplications,
          child: _dashboard(),
        );
      case 1:
        return StateAdminApprovalPage(
          apiBaseUrl: ApiService.baseUrl,
          stateAdminId: _stateAdminId ?? '',
          stateName: _stateName.isNotEmpty ? _stateName : 'State',
          onRefreshRequested: () async {
            await _fetchPendingApplications();
            await _fetchStats();
          },
          onNavigateToSettings: () {
            setState(() => _tab = 3);
          },
        );
      case 2:
        return StateAdminMembersPage(
          apiBaseUrl: ApiService.baseUrl,
          stateAdminId: _stateAdminId ?? '',
          stateName: _stateName.isNotEmpty ? _stateName : 'State',
          onNavigateToSettings: () {
            setState(() => _tab = 3);
          },
        );
      case 3:
        return StateAdminSettingsPage(
          apiBaseUrl: ApiService.baseUrl,
          stateAdminId: _stateAdminId ?? '',
          stateName: _stateName,
          statsOverride: _stats,
          onBackToDashboard: () {
            setState(() => _tab = 0);
          },
        );
      default:
        return _dashboard();
    }
  }

  Widget _dashboard() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          _topBar(),
          const SizedBox(height: 12),
          _heroHeader(),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _statCard(
                  title: 'Total Members',
                  value: '${_stats['total']}',
                  subtitle: 'state level',
                  icon: Icons.people,
                  chipText: 'All',
                  chipColor: const Color(0xFF3B82F6),
                ),
                _statCard(
                  title: 'Pending',
                  value: '${_stats['pending']}',
                  subtitle: 'Awaiting approval',
                  icon: Icons.access_time,
                  chipText: 'Pending',
                  chipColor: const Color(0xFFF59E0B),
                ),
                _statCard(
                  title: 'Approved',
                  value: '${_stats['approved']}',
                  subtitle: 'applications',
                  icon: Icons.check_circle,
                  chipText: 'Approved',
                  chipColor: const Color(0xFF10B981),
                ),
                _statCard(
                  title: 'Rejected',
                  value: '${_stats['rejected']}',
                  subtitle: 'applications',
                  icon: Icons.cancel,
                  chipText: 'Rejected',
                  chipColor: const Color(0xFFEF4444),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _pill('Pending (${_stats['pending'] ?? 0})'),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: _pending.map((app) => _userCard(app)).toList(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _topBar() {
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
                      'State Admin Dashboard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage State Level',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _tab = 3; // Navigate to Settings tab
                  });
                },
                child: Container(
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
                  child: const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _pill('State Administration'),
      ),
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required String chipText,
    required Color chipColor,
  }) {
    return Container(
      width: (MediaQuery.of(context).size.width - 52) / 2,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 10,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: chipColor, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: chipColor.withAlpha((0.1 * 255).toInt()),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    chipText,
                    style: TextStyle(
                      color: chipColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
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
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _userCard(dynamic app) {
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

    final status = (app['status'] ?? app['applicationStatus'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    developer.log('STATE CARD status=$status, id=${app['_id']}');

    final fullName = (app['fullName'] ?? app['name'] ?? 'Unknown').toString();
    final phone = (app['phone'] ?? 'N/A').toString();
    final block = (app['block'] ?? 'N/A').toString();
    final email = (app['email'] ?? 'N/A').toString();
    final Map<String, dynamic>? personalInfo =
        app['personalInfo'] as Map<String, dynamic>?;
    final gender =
        (app['gender'] ??
                (personalInfo != null ? personalInfo['gender'] : null) ??
                'NA')
            .toString();
    final appliedDate = fmtDate(app['districtApprovedAt'] ?? app['createdAt']);

    return InkWell(
      onTap: () => _openProfileSheet(app),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.06 * 255).toInt()),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF59E0B)),
                  ),
                  child: const Text(
                    'Pending',
                    style: TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
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
            if (status.contains('pending')) ...[
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  developer.log('SHOW BUTTONS for ${app['_id']}');
                  return const SizedBox.shrink();
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleApprove(app),
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleReject(app),
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
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF3B82F6).withAlpha((0.1 * 255).toInt()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF3B82F6).withAlpha((0.2 * 255).toInt()),
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF3B82F6),
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.1 * 255).toInt()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(icon, color: const Color(0xFF6B7280), size: 20),
    );
  }

  Widget _notifDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Color(0xFFFF5C5C),
        shape: BoxShape.circle,
      ),
    );
  }
}

// UserDetailsDropdown widget - shows detailed user information in a modal bottom sheet
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
      profileData = memberProfile!;
      member = profileData['member'] ?? {};
      businessInfo = profileData['businessInfo'] ?? {};
      financialInfo = profileData['financialInfo'] ?? {};
      declaration = profileData['declaration'] ?? {};
    } else {
      profileData = app ?? {};
      final form = profileData['formData'] != null
          ? Map<String, dynamic>.from(profileData['formData'])
          : <String, dynamic>{};

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

    String s(dynamic value) =>
        (value == null || (value is String && value.isEmpty))
        ? '—'
        : value.toString();
    String b(bool? value) => value == null ? '—' : (value ? 'Yes' : 'No');
    String listToString(List<dynamic>? list) {
      if (list == null || list.isEmpty) return '—';
      return list.join(', ');
    }

    bool hasValue(dynamic value) {
      if (value == null) return false;
      if (value is String) return value.trim().isNotEmpty;
      if (value is List) return value.isNotEmpty;
      if (value is Map) return value.isNotEmpty;
      return true;
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Application Details',
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
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Demographic Details'),
                  _buildDetailCard([
                    _buildDetailRow('Full Name', s(member['fullName'])),
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
                              if (businessInfo['doingBusiness'] != null)
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
                              if (hasValue(
                                businessInfo['businessCommencementYear'],
                              ))
                                _buildDetailRow(
                                  'Business Commencement Year',
                                  s(businessInfo['businessCommencementYear']),
                                ),
                              if (hasValue(businessInfo['numberOfEmployees']))
                                _buildDetailRow(
                                  'Number of Employees',
                                  s(businessInfo['numberOfEmployees']),
                                ),
                              if (businessInfo['memberOfOtherChamber'] != null)
                                _buildDetailRow(
                                  'Member of Other Chamber',
                                  b(
                                    businessInfo['memberOfOtherChamber']
                                        as bool?,
                                  ),
                                ),
                              if (businessInfo['memberOfOtherChamber'] ==
                                      true &&
                                  hasValue(businessInfo['otherChamber']))
                                _buildDetailRow(
                                  'Other Chamber Name',
                                  s(businessInfo['otherChamber']),
                                ),
                              if (hasValue(
                                businessInfo['registeredWithGovtOrganization'],
                              ))
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
                              if (financialInfo['filedITR'] != null)
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
                              if (financialInfo['govtSchemeBenefit'] != null)
                                _buildDetailRow(
                                  'Govt Scheme Benefit',
                                  b(
                                    financialInfo['govtSchemeBenefit'] as bool?,
                                  ),
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
                              if (declaration['showOneFieldPerName'] != null)
                                _buildDetailRow(
                                  'Show One Field Per Name',
                                  b(
                                    declaration['showOneFieldPerName'] as bool?,
                                  ),
                                ),
                              if (declaration['agreeToDeclaration'] != null)
                                _buildDetailRow(
                                  'Agree To Declaration',
                                  b(declaration['agreeToDeclaration'] as bool?),
                                ),
                              if (declaration['profileCompleted'] != null)
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
                                _buildDetailRow(
                                  'Status',
                                  s(declaration['status']),
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
          if (showActions)
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
      if (date is DateTime) {
        final d = date;
        return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      }

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

      if (date is String) {
        final raw = date.trim();
        if (raw.isEmpty) return null;

        final ddmmyyyySlash = RegExp(r'^\d{2}/\d{2}/\d{4}$');
        if (ddmmyyyySlash.hasMatch(raw)) return raw;

        final ddmmyyyyDash = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$');
        final dashMatch = ddmmyyyyDash.firstMatch(raw);
        if (dashMatch != null) {
          final d = dashMatch.group(1)!;
          final m = dashMatch.group(2)!;
          final y = dashMatch.group(3)!;
          return '$d/$m/$y';
        }

        try {
          final parsed = DateTime.parse(raw);
          return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
        } catch (_) {
          return raw;
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }
}
