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
        );
      case 2:
        return StateAdminMembersPage(
          apiBaseUrl: ApiService.baseUrl,
          stateAdminId: _stateAdminId ?? '',
          stateName: _stateName.isNotEmpty ? _stateName : 'State',
        );
      case 3:
        return StateAdminSettingsPage(
          apiBaseUrl: ApiService.baseUrl,
          stateAdminId: _stateAdminId ?? '',
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
              Stack(
                children: [
                  _iconButton(Icons.notifications_outlined),
                  Positioned(right: 8, top: 8, child: _notifDot()),
                ],
              ),
              const SizedBox(width: 12),
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

    return Container(
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
              const Icon(Icons.location_on, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Text(
                'Block: $block',
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
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
                style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
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
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.person, size: 16, color: Color(0xFF6B7280)),
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
    );
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
