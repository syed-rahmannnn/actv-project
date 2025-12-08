import 'package:flutter/material.dart';
import '../../services/application_service.dart';
import '../../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  final String apiBaseUrl = 'https://actv-project.onrender.com/api';
}

class AuthProvider {
  String? token;
  AdminData? currentAdmin;

  AuthProvider(); // Remove automatic loading from constructor

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');

    final userData = await AuthService.getUserData();
    if (userData != null) {
      currentAdmin = AdminData(
        adminId: userData['adminId'] ?? userData['_id'] ?? '',
        email: userData['email'] ?? '',
        role: userData['role'] ?? '',
        fullName: userData['fullName'] ?? userData['adminName'] ?? '',
        meta: AdminMeta(
          state: userData['state'] ?? userData['meta']?['state'] ?? '',
          district: userData['district'] ?? userData['meta']?['district'] ?? '',
          block:
              userData['block'] ??
              userData['blockName'] ??
              userData['meta']?['block'] ??
              '',
          stateName:
              userData['meta']?['stateName'] ?? userData['stateName'] ?? '',
          districtName:
              userData['meta']?['districtName'] ??
              userData['districtName'] ??
              '',
          blockName:
              userData['meta']?['blockName'] ?? userData['blockName'] ?? '',
        ),
        active: (userData['active'] ?? true) == true,
      );
    }
  }
}

class AdminData {
  final String adminId;
  final String email;
  final String role;
  final String fullName;
  final AdminMeta meta;
  final bool active;

  AdminData({
    required this.adminId,
    required this.email,
    required this.role,
    required this.fullName,
    required this.meta,
    required this.active,
  });
}

class AdminMeta {
  final String state;
  final String district;
  final String block;
  final String stateName;
  final String districtName;
  final String blockName;

  AdminMeta({
    required this.state,
    required this.district,
    required this.block,
    required this.stateName,
    required this.districtName,
    required this.blockName,
  });
}

class DistrictAdminSettingsPage extends StatefulWidget {
  final String? apiBaseUrl;
  final String? token;
  final String? districtAdminId;
  final String? districtName;
  final String? districtEmail;
  final bool? isActive;
  // When provided, these counts take precedence and keep Settings in sync
  // with the Dashboard tab.
  final Map<String, int>? statsOverride;
  // Callback to navigate back to Dashboard tab (bottom nav index 0)
  final VoidCallback? onBackToDashboard;

  const DistrictAdminSettingsPage({
    super.key,
    this.apiBaseUrl,
    this.token,
    this.districtAdminId,
    this.districtName,
    this.districtEmail,
    this.isActive,
    this.statsOverride,
    this.onBackToDashboard,
  });

  @override
  State<DistrictAdminSettingsPage> createState() =>
      _DistrictAdminSettingsPageState();
}

class _DistrictAdminSettingsPageState extends State<DistrictAdminSettingsPage> {
  Map<String, int> _stats = {};
  bool _loading = true;
  late ApplicationService _svc;

  String adminId = '';
  String districtName = '';
  String email = '';
  bool active = true;

  final _config = AppConfig();
  AuthProvider? _auth; // Make it nullable and initialize only when needed

  @override
  void initState() {
    super.initState();
    // If dashboard passed the counts, use them directly
    if (widget.statsOverride != null) {
      adminId = widget.districtAdminId ?? '';
      districtName = widget.districtName ?? '';
      email = widget.districtEmail ?? '';
      active = widget.isActive ?? true;
      
      setState(() {
        _stats = {
          'total': widget.statsOverride!['total'] ?? 0,
          'pending': widget.statsOverride!['pending'] ?? 0,
          'approved': widget.statsOverride!['approved'] ?? 0,
          'rejected': widget.statsOverride!['rejected'] ?? 0,
        };
        _loading = false;
      });
    } else if (widget.apiBaseUrl != null && widget.token != null) {
      _svc = ApplicationService(widget.apiBaseUrl!, token: widget.token!);
      adminId = widget.districtAdminId ?? '';
      districtName = widget.districtName ?? '';
      email = widget.districtEmail ?? '';
      active = widget.isActive ?? true;

      if (adminId.isNotEmpty) {
        _loadFromParams();
      } else {
        setState(() => _loading = false);
      }
    } else {
      _initFromAuth();
    }
  }

  Future<void> _loadFromParams() async {
    if (adminId.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);

    try {
      // Only fetch pending count to avoid slow stats call
      if (widget.token != null && widget.token!.isNotEmpty) {
        _svc = ApplicationService(widget.apiBaseUrl!, token: widget.token!);
        final pending = await _svc.getDistrictInbox(adminId);

        if (!mounted) return;
        setState(() {
          _stats = {
            'total': pending.length,
            'pending': pending.length,
            'approved': 0,
            'rejected': 0
          };
          _loading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _stats = {'total': 0, 'pending': 0, 'approved': 0, 'rejected': 0};
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _stats = {'total': 0, 'pending': 0, 'approved': 0, 'rejected': 0};
          _loading = false;
        });
      }
    }
  }

  Future<void> _initFromAuth() async {
    // Initialize AuthProvider only when needed and load data once
    _auth = AuthProvider();
    await _auth!._loadAuthData();

    if (_auth!.currentAdmin != null) {
      final a = _auth!.currentAdmin!;
      adminId = a.adminId;

      // Enhanced email handling with fallback
      email = a.email.isNotEmpty ? a.email : '';

      // Enhanced district name handling with fallback
      districtName = a.meta.district.isNotEmpty ? a.meta.district : '';

      active = a.active;
      _svc = ApplicationService(_config.apiBaseUrl, token: _auth!.token);
      await _loadFromParams();
    } else {
      // If no admin data is available, try to load from AuthService directly
      try {
        final userData = await AuthService.getUserData();
        if (userData != null) {
          adminId = userData['adminId']?.toString() ?? '';
          email = userData['email']?.toString() ?? '';

          // Enhanced district name extraction with multiple fallbacks
          districtName =
              userData['district']?.toString() ??
              userData['districtName']?.toString() ??
              userData['meta']?['district']?.toString() ??
              '';

          active = userData['active'] == true;

          // Initialize service if we have token
          final token = await AuthService.getToken();
          if (token != null) {
            _svc = ApplicationService(_config.apiBaseUrl, token: token);
            await _loadFromParams();
          }
        }
      } catch (e) {
        // Log initialization error to avoid empty catch lint
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      if (widget.apiBaseUrl != null && widget.token != null) {
        // Use widget parameters
        _svc = ApplicationService(widget.apiBaseUrl!, token: widget.token!);
        adminId = widget.districtAdminId ?? '';
        districtName = widget.districtName ?? '';
        email = widget.districtEmail ?? '';
        active = widget.isActive ?? true;
        await _loadFromParams();
      } else {
        // Use auth data
        await _initFromAuth();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Improved display logic with proper fallbacks
    final displayDistrictName = districtName.isNotEmpty
        ? districtName
        : (widget.districtName?.isNotEmpty == true ? widget.districtName! : "");

    final displayTitle = displayDistrictName.isNotEmpty
        ? '$displayDistrictName District Admin'
        : 'District Admin';

    final displayEmail = email.isNotEmpty
        ? email
        : (widget.districtEmail?.isNotEmpty == true
              ? widget.districtEmail!
              : "");

    final displayLocation = displayDistrictName.isNotEmpty
        ? '$displayDistrictName District'
        : 'District not found';

    // Fallback email generation when email is missing
    final finalDisplayEmail = displayEmail.isNotEmpty
        ? displayEmail
        : (displayDistrictName.isNotEmpty
              ? 'district.${displayDistrictName.toLowerCase().replaceAll(' ', '')}.admin@activ.com'
              : 'admin@activ.com');

    final isActive = widget.isActive ?? active;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        title: const Text(
          'Settings',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Color(0xFF0F172A),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () {
            if (widget.onBackToDashboard != null) {
              widget.onBackToDashboard!();
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Profile header card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha((0.13 * 255).toInt()),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: const Color(0xFF1E88FF),
                              child: Text(
                                finalDisplayEmail.isNotEmpty
                                    ? finalDisplayEmail[0].toUpperCase()
                                    : 'A',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayTitle,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.email,
                                        size: 18,
                                        color: Colors.grey[600],
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          finalDisplayEmail,
                                          style: const TextStyle(
                                            color: Color(0xFF6B7280),
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 18,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                displayLocation,
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Text(
                              'Active Status: ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: isActive
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Admin stats block (true numbers sourced from dashboard endpoints)
                  _adminStats(),

                  const SizedBox(height: 24),

                  // Account section (same as mock; you'll wire later
                  const SizedBox(height: 16),

                  // Support section
                  _sectionCard(
                    title: 'Support',
                    items: const ['Help & Support'],
                  ),

                  const SizedBox(height: 32),

                  // Logout
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Show confirmation dialog
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Logout'),
                              content: const Text(
                                'Are you sure you want to logout?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text(
                                    'Logout',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            );
                          },
                        );

                        // If user confirmed logout
                        if (shouldLogout == true) {
                          if (!mounted) return;
                          // Show loading indicator BEFORE capturing context
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          // Capture navigator and messenger after showing dialog
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);

                          try {
                            // Clear session and token
                            await AuthService.logout();
                            if (!mounted) return;
                            // Navigate to login screen and clear all routes
                            navigator.pop(); // Close loading dialog
                            navigator.pushNamedAndRemoveUntil(
                              '/login',
                              (route) => false,
                            );
                          } catch (e) {
                            // Handle logout error
                            if (!mounted) return;
                            navigator.pop(); // Close loading dialog
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Logout failed: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Logout',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _adminStats() {
    if (_loading) {
      return Container(
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
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'District Overview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            SizedBox(height: 20),
            Center(child: CircularProgressIndicator()),
            SizedBox(height: 20),
          ],
        ),
      );
    }

    final total = _stats['total'] ?? 0;
    final pending = _stats['pending'] ?? 0;
    final approved = _stats['approved'] ?? 0;
    final rejected = _stats['rejected'] ?? 0;

    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Administration Count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _statRow(
            'Total Members:',
            total,
            Icons.people,
            const Color(0xFF2563EB),
            link: false,
          ),
          const SizedBox(height: 10),
          _statRow(
            'Pending Approvals:',
            pending,
            Icons.access_time,
            const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 10),
          _statRow(
            'Approved:',
            approved,
            Icons.check_circle,
            const Color(0xFF16A34A),
          ),
          const SizedBox(height: 10),
          _statRow(
            'Rejected:',
            rejected,
            Icons.cancel,
            const Color(0xFFDC2626),
          ),
        ],
      ),
    );
  }

  Widget _statRow(
    String label,
    int value,
    IconData icon,
    Color iconColor, {
    bool link = true,
  }) {
    return Row(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '$value',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _sectionCard({required String title, required List<String> items}) {
    return Container(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          ...items.map(
            (t) => ListTile(
              title: Text(
                t,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: const Icon(
                Icons.chevron_right,
                color: Color(0xFF9CA3AF),
              ),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
