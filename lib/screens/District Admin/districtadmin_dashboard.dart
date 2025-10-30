import 'package:flutter/material.dart';
import 'package:activ/services/api_service.dart';
import 'package:activ/services/auth_service.dart';
import 'package:activ/services/application_service.dart';
import 'districtadmin_settings.dart';
import 'districtadmin_approval_page.dart';
import 'districtadmin_members_page.dart';
import 'dart:developer' as developer;

class DistrictAdminDashboardApp extends StatelessWidget {
  const DistrictAdminDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'District Admin Dashboard',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const DistrictAdminDashboard(),
    );
  }
}

class DistrictAdminDashboard extends StatefulWidget {
  final String? adminId;

  const DistrictAdminDashboard({super.key, this.adminId});

  @override
  State<DistrictAdminDashboard> createState() =>
      _DistrictAdminDashboardPageState();
}

class _DistrictAdminDashboardPageState extends State<DistrictAdminDashboard> {
  int _tab = 0;

  List<dynamic> _pendingApplications = [];
  bool _isLoading = true;
  String? _districtAdminId;
  late ApplicationService _applicationService;
  final Map<String, int> _stats = {
    'total': 0,
    'pending': 0,
    'approved': 0,
    'rejected': 0,
  };

  @override
  void initState() {
    super.initState();
    // Initialize ApplicationService with baseUrl
    _applicationService = ApplicationService(ApiService.baseUrl);
    _initializeAdminData();
  }

  Future<void> _initializeAdminData() async {
    try {
      // Use passed adminId if available, otherwise get from AuthService
      if (widget.adminId != null && widget.adminId!.isNotEmpty) {
        setState(() {
          _districtAdminId = widget.adminId!;
        });
        await _fetchPendingApplications();
      } else {
        final user = await AuthService.getUserData();
        if (user != null) {
          setState(() {
            _districtAdminId = (user['adminId'] ?? user['_id'] ?? '')
                .toString();
          });
          await _fetchPendingApplications();
        }
      }
    } catch (e) {
      developer.log(
        'Error initializing admin data: $e',
        name: 'DistrictAdminDashboard',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPendingApplications() async {
    if (_districtAdminId == null) return;

    try {
      // Fetch pending applications
      final applications = await ApiService.getDistrictAdminApplications(
        _districtAdminId!,
      );

      // Fetch statistics from backend
      final stats = await _applicationService.getDistrictStats(
        _districtAdminId!,
      );

      if (applications.isNotEmpty || stats.isNotEmpty) {
        setState(() {
          _pendingApplications = applications;
          // Update stats with real data from backend
          _stats['pending'] = stats['pending'] ?? 0;
          _stats['approved'] = stats['approved'] ?? 0;
          _stats['rejected'] = stats['rejected'] ?? 0;
          _stats['total'] = stats['total'] ?? 0;
        });
      }
    } catch (e) {
      developer.log(
        'Error fetching applications and stats: $e',
        name: 'DistrictAdminDashboard',
      );
    }
  }

  Future<void> _handleApplicationAction(
    String applicationId,
    String action, {
    String? reason,
  }) async {
    try {
      final success = await ApiService.reviewDistrictApplication(
        applicationId,
        action,
        reason: reason,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Application ${action}d successfully'),
            backgroundColor: action == 'approve' ? Colors.green : Colors.red,
          ),
        );
        await _fetchPendingApplications();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error ${action}ing application: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        return RefreshIndicator(onRefresh: _fetchPendingApplications, child: _dashboard());
      case 1:
        return DistrictAdminApprovalPage(
          apiBaseUrl: ApiService.baseUrl,
          districtAdminId: _districtAdminId ?? '',
          districtName: 'Salem District', // You can make this dynamic
        );
      case 2:
        return DistrictAdminMembersPage(
          apiBaseUrl: ApiService.baseUrl,
          districtAdminId: _districtAdminId ?? '',
          districtName: 'Salem District', // You can make this dynamic
        );
      case 3:
        return const DistrictAdminSettingsPage();
      default:
        return _dashboard();
    }
  }

  Widget _dashboard() {
    return SingleChildScrollView(
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
                  subtitle: 'district level',
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
          if (_pendingApplications.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Applications',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ..._pendingApplications
                .take(3)
                .map(
                  (app) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    child: _userCard(app),
                  ),
                ),
          ],
          const SizedBox(height: 100),
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
                      'District Admin Dashboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage District Level',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              _iconButton(Icons.filter_list),
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
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _pill('District Administration'),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF3B82F6,
                    ).withAlpha((0.1 * 255).toInt()),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF3B82F6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app['fullName'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        app['email'] ?? 'N/A',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showUserDetailsDropdown(app),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFF3B82F6,
                      ).withAlpha((0.1 * 255).toInt()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.expand_more,
                      color: Color(0xFF3B82F6),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Phone: ${app['phone'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Block: ${app['block'] ?? 'N/A'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleApplicationAction(
                      app['id'].toString(),
                      'approve',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Approve',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showRejectDialog(app['id'].toString()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5C5C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showUserDetailsDropdown(dynamic app) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UserDetailsDropdown(
        app: app,
        onApprove: () =>
            _handleApplicationAction(app['id'].toString(), 'approve'),
        onReject: () => _showRejectDialog(app['id'].toString()),
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

// UserDetailsDropdown widget - copied from Block Admin with District-specific adaptations
class UserDetailsDropdown extends StatelessWidget {
  final dynamic app;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const UserDetailsDropdown({
    super.key,
    required this.app,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    // Helper functions
    String s(dynamic value) => value?.toString() ?? 'N/A';
    String b(bool? value) =>
        value == true ? 'Yes' : (value == false ? 'No' : 'N/A');
    String listToString(List<dynamic>? list) {
      if (list == null || list.isEmpty) return 'N/A';
      return list.join(', ');
    }

    // Extract data sections
    final personalInfo = app['personalInfo'] ?? {};
    final businessInfo = app['businessInfo'] ?? {};
    final financialInfo = app['financialInfo'] ?? {};
    final declaration = app['declaration'] ?? {};

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
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

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal & Demographic Details
                  _buildSectionHeader('Personal & Demographic Details'),
                  _buildDetailCard([
                    _buildDetailRow('Full Name', s(app['fullName'])),
                    _buildDetailRow('Email', s(app['email'])),
                    _buildDetailRow('Phone', s(app['phone'])),
                    _buildDetailRow('State', s(app['state'])),
                    _buildDetailRow('District', s(app['district'])),
                    _buildDetailRow('Block', s(app['block'])),
                    _buildDetailRow('Gender', s(personalInfo['gender'])),
                    _buildDetailRow(
                      'Date of Birth',
                      s(_formatDate(personalInfo['dateOfBirth'])),
                    ),
                    _buildDetailRow('Category', s(personalInfo['category'])),
                    _buildDetailRow('Religion', s(personalInfo['religion'])),
                    _buildDetailRow(
                      'Marital Status',
                      s(personalInfo['maritalStatus']),
                    ),
                    _buildDetailRow('Education', s(personalInfo['education'])),
                    _buildDetailRow(
                      'Occupation',
                      s(personalInfo['occupation']),
                    ),
                  ]),

                  const SizedBox(height: 16),

                  // Business Information
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
                            _buildDetailRow(
                              'Business Name',
                              s(businessInfo['businessName']),
                            ),
                            _buildDetailRow(
                              'Business Type',
                              s(businessInfo['businessType']),
                            ),
                            _buildDetailRow(
                              'Business Address',
                              s(businessInfo['businessAddress']),
                            ),
                            _buildDetailRow(
                              'Years in Business',
                              s(businessInfo['yearsInBusiness']),
                            ),
                            _buildDetailRow(
                              'Number of Employees',
                              s(businessInfo['numberOfEmployees']),
                            ),
                            _buildDetailRow(
                              'Business Registration',
                              s(businessInfo['businessRegistration']),
                            ),
                            _buildDetailRow(
                              'Registration Number',
                              s(businessInfo['registrationNumber']),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Financial & Compliance
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
                            _buildDetailRow(
                              'PAN Number',
                              s(financialInfo['panNumber']),
                            ),
                            _buildDetailRow(
                              'Aadhaar Number',
                              s(financialInfo['aadhaarNumber']),
                            ),
                            _buildDetailRow(
                              'GST Number',
                              s(financialInfo['gstNumber']),
                            ),
                            _buildDetailRow(
                              'Udyam Number',
                              s(financialInfo['udyamNumber']),
                            ),
                            _buildDetailRow(
                              'Filed ITR',
                              b(financialInfo['filedITR'] as bool?),
                            ),
                            _buildDetailRow(
                              'ITR Years',
                              s(financialInfo['itrYears']),
                            ),
                            _buildDetailRow(
                              'Turnover Range',
                              s(financialInfo['turnoverRange']),
                            ),
                            _buildDetailRow(
                              'FY 2021',
                              s(financialInfo['fy2021']),
                            ),
                            _buildDetailRow(
                              'FY 2020',
                              s(financialInfo['fy2020']),
                            ),
                            _buildDetailRow(
                              'FY 2019',
                              s(financialInfo['fy2019']),
                            ),
                            _buildDetailRow(
                              'Govt Scheme Benefit',
                              b(financialInfo['govtSchemeBenefit'] as bool?),
                            ),
                            _buildDetailRow(
                              'Scheme 1',
                              s(financialInfo['scheme1']),
                            ),
                            _buildDetailRow(
                              'Scheme 2',
                              s(financialInfo['scheme2']),
                            ),
                            _buildDetailRow(
                              'Scheme 3',
                              s(financialInfo['scheme3']),
                            ),
                            _buildDetailRow(
                              'IFSC Code',
                              s(financialInfo['ifscCode']),
                            ),
                            _buildDetailRow(
                              'Bank Branch',
                              s(financialInfo['bankBranch']),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Declaration
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
                            _buildDetailRow(
                              'Sister Concerns',
                              s(declaration['sisterConcerns']),
                            ),
                            _buildDetailRow(
                              'Company Names',
                              listToString(
                                (declaration['companyNames'] as List?)
                                    ?.cast<dynamic>(),
                              ),
                            ),
                            _buildDetailRow(
                              'Show One Field Per Name',
                              b(declaration['showOneFieldPerName'] as bool?),
                            ),
                            _buildDetailRow(
                              'Agree To Declaration',
                              b(declaration['agreeToDeclaration'] as bool?),
                            ),
                            _buildDetailRow(
                              'Profile Completed',
                              b(declaration['profileCompleted'] as bool?),
                            ),
                            _buildDetailRow(
                              'Submission Date',
                              s(_formatDate(declaration['submissionDate'])),
                            ),
                            _buildDetailRow('Status', s(declaration['status'])),
                            _buildDetailRow(
                              'Review Notes',
                              s(declaration['reviewNotes']),
                            ),
                            _buildDetailRow(
                              'Reviewed By',
                              s(declaration['reviewedBy']),
                            ),
                            _buildDetailRow(
                              'Reviewed At',
                              s(_formatDate(declaration['reviewedAt'])),
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

          // Action buttons
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
      // Handle DateTime directly
      if (date is DateTime) {
        final d = date;
        return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      }

      // Handle numeric timestamps (ms or sec)
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

      // Handle strings in various common formats
      if (date is String) {
        final raw = date.trim();
        if (raw.isEmpty) return null;

        // If already in dd/MM/yyyy, return as-is
        final ddmmyyyySlash = RegExp(r'^\d{2}/\d{2}/\d{4}$');
        if (ddmmyyyySlash.hasMatch(raw)) return raw;

        // Convert dd-MM-yyyy to dd/MM/yyyy
        final ddmmyyyyDash = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$');
        final dashMatch = ddmmyyyyDash.firstMatch(raw);
        if (dashMatch != null) {
          final d = dashMatch.group(1)!;
          final m = dashMatch.group(2)!;
          final y = dashMatch.group(3)!;
          return '$d/$m/$y';
        }

        // Parse ISO-like formats (e.g., yyyy-MM-dd or ISO timestamps)
        try {
          final parsed = DateTime.parse(raw);
          return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
        } catch (_) {
          // Fallback: return the original string if parsing fails
          return raw;
        }
      }

      // Fallback for unexpected types
      return null;
    } catch (_) {
      return null;
    }
  }
}
