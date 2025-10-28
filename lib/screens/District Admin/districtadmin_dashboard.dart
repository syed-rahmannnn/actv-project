import 'package:flutter/material.dart';
import '../Block Admin/blockadmin_settings.dart';
import 'dart:developer' as developer;
import '../../services/api_service.dart';
import '../../services/auth_service.dart';

void main() => runApp(const DistrictAdminDashboardApp());

class DistrictAdminDashboardApp extends StatelessWidget {
  const DistrictAdminDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'District Admin Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color(0xFFEAF6FF),
      ),
      home: const DistrictAdminDashboard(adminId: ''),
    );
  }
}

class DistrictAdminDashboard extends StatelessWidget {
  final String adminId;

  const DistrictAdminDashboard({super.key, required this.adminId});

  @override
  Widget build(BuildContext context) {
    return DistrictAdminDashboardPage(adminId: adminId);
  }
}

class DistrictAdminDashboardPage extends StatefulWidget {
  final String adminId;

  const DistrictAdminDashboardPage({super.key, required this.adminId});

  @override
  State<DistrictAdminDashboardPage> createState() =>
      _DistrictAdminDashboardPageState();
}

class _DistrictAdminDashboardPageState
    extends State<DistrictAdminDashboardPage> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _pendingApplications = [];
  bool _isLoading = false;
  String? _districtAdminId;

  @override
  void initState() {
    super.initState();
    _initializeAdminData();
  }

  Future<void> _initializeAdminData() async {
    _districtAdminId = widget.adminId.isNotEmpty
        ? widget.adminId
        : await AuthService.getAdminId();
    if (_districtAdminId != null) {
      await _fetchPendingApplications();
    }
  }

  Future<void> _fetchPendingApplications() async {
    if (_districtAdminId == null) return;

    setState(() => _isLoading = true);
    try {
      final applications = await ApiService.getDistrictAdminApplications(
        _districtAdminId!,
      );
      setState(() {
        _pendingApplications = applications;
        // Update the pending count in cards
        _cards[1]['count'] = applications.length;
      });
    } catch (e) {
      developer.log(
        'Error fetching applications: $e',
        name: 'DistrictAdminDashboard',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading applications: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleApplicationAction(
    String applicationId,
    String action, {
    String? reason,
  }) async {
    try {
      await ApiService.reviewDistrictApplication(
        applicationId,
        action,
        reason: reason,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application ${action}d successfully'),
            backgroundColor: action == 'approve' ? Colors.green : Colors.red,
          ),
        );
      }

      // Refresh the applications list
      await _fetchPendingApplications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showRejectDialog(String applicationId) {
    final TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (reasonController.text.trim().isNotEmpty) {
                Navigator.pop(context);
                _handleApplicationAction(
                  applicationId,
                  'reject',
                  reason: reasonController.text.trim(),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  final List<Map<String, dynamic>> _cards = [
    {
      'label': 'Total Members',
      'count': 12,
      'subtitle': 'district level',
      'color': Colors.white,
    },
    {
      'label': 'Pending',
      'count': 0,
      'subtitle': 'Awaiting approval',
      'color': Color(0xFFD9F2FF),
    },
    {
      'label': 'Approved',
      'count': 6,
      'subtitle': 'Successfully approved',
      'color': Color(0xFFECF9F0),
    },
    {
      'label': 'Rejected',
      'count': 6,
      'subtitle': 'Rejected Members',
      'color': Color(0xFFFFEEF0),
    },
  ];

  void _onBottomNavTap(int idx) => setState(() => _selectedIndex = idx);

  Widget _buildTabContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardView();
      case 1:
        return _buildApprovalsView();
      case 2:
        return const SafeArea(
          child: Center(
            child: Text('Members tab', style: TextStyle(fontSize: 16)),
          ),
        );
      case 3:
        return const BlockAdminSettingsPage();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildApprovalsView() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pending Applications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10345A),
                  ),
                ),
                IconButton(
                  onPressed: _fetchPendingApplications,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _pendingApplications.isEmpty
                  ? const Center(
                      child: Text(
                        'No pending applications',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _pendingApplications.length,
                      itemBuilder: (context, index) {
                        final application = _pendingApplications[index];
                        return _buildApplicationCard(application);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardView() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildStatGrid(),
            const SizedBox(height: 18),
            if (_pendingApplications.isNotEmpty) ...[
              const Text(
                'Recent Pending Applications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10345A),
                ),
              ),
              const SizedBox(height: 12),
              ..._buildPendingCards(),
            ],
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildTabContent(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'District Admin Dashboard',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF10345A),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Manage District Level',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
          ],
        ),
        Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_none,
                    color: Color(0xFF10345A),
                  ),
                ),
                if (_pendingApplications.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF1E88FF),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_pendingApplications.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF1E88FF),
              child: Text(
                'A',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _StatCard(data: _cards[0])),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(data: _cards[1])),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _StatCard(data: _cards[2])),
            const SizedBox(width: 10),
            Expanded(child: _StatCard(data: _cards[3])),
          ],
        ),
      ],
    );
  }

  List<Widget> _buildPendingCards() {
    // Show only first 3 applications in dashboard view
    final displayApplications = _pendingApplications.take(3).toList();

    return displayApplications
        .map(
          (application) => Padding(
            padding: const EdgeInsets.only(bottom: 14.0),
            child: _buildApplicationCard(application),
          ),
        )
        .toList();
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 22,
                backgroundColor: Color(0xFFDEEAF9),
                child: Icon(Icons.person, color: Colors.grey),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          application['fullName'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F5FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            application['status'] ?? 'pending',
                            style: const TextStyle(
                              color: Color(0xFF0366A6),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      application['email'] ?? '',
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${application['state'] ?? ''}, ${application['district'] ?? ''}, ${application['block'] ?? ''}',
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Submitted: ${_formatDate(application['createdAt'])}',
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      application['phone'] ?? '',
                      style: const TextStyle(
                        color: Color(0xFF16A34A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: () =>
                    _handleApplicationAction(application['_id'], 'approve'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                ),
                child: const Text('Approve'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => _showRejectDialog(application['_id']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5C5C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 12,
                  ),
                ),
                child: const Text('Reject'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onBottomNavTap,
      selectedItemColor: const Color(0xFF1E88FF),
      unselectedItemColor: const Color(0xFF94A3B8),
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_filled),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.check_circle_outline),
          label: 'Approvals',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people_outline),
          label: 'Members',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'Settings',
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: data['color'] ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                data['label'],
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
              if (data['label'] == 'Approved')
                const Icon(Icons.check_circle, color: Color(0xFF16A34A))
              else if (data['label'] == 'Pending')
                const Icon(Icons.schedule, color: Color(0xFF0EA5E9))
              else
                const SizedBox.shrink(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${data['count']}',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data['subtitle'],
            style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
