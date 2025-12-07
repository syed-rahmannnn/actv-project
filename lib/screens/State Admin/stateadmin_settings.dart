import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/application_service.dart';
import '../../services/auth_service.dart';

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

class StateAdminSettingsPage extends StatefulWidget {
  final String? apiBaseUrl;
  final String? token;
  final String? stateAdminId;
  final String? stateName;
  final String? stateEmail;
  final bool? isActive;

  const StateAdminSettingsPage({
    super.key,
    this.apiBaseUrl,
    this.token,
    this.stateAdminId,
    this.stateName,
    this.stateEmail,
    this.isActive,
  });

  @override
  State<StateAdminSettingsPage> createState() => _StateAdminSettingsPageState();
}

class _StateAdminSettingsPageState extends State<StateAdminSettingsPage> {
  Map<String, int> _stats = {};
  bool _loading = true;
  late ApplicationService _svc;

  String adminId = '';
  String stateName = '';
  String email = '';
  bool active = true;

  final _config = AppConfig();
  AuthProvider? _auth; // Make it nullable and initialize only when needed

  @override
  void initState() {
    super.initState();
    if (widget.apiBaseUrl != null && widget.token != null) {
      _svc = ApplicationService(widget.apiBaseUrl!, token: widget.token!);
      adminId = widget.stateAdminId ?? '';
      stateName = widget.stateName ?? '';
      email = widget.stateEmail ?? '';
      active = widget.isActive ?? true;
      _loadFromParams();
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
      // True numbers via the same endpoint pattern as dashboard
      final data = await _svc.getStateStats(adminId);
      if (!mounted) return;
      setState(() {
        _stats = data;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _initFromAuth() async {
    // Initialize AuthProvider only when needed and load data once
    _auth = AuthProvider();
    await _auth!._loadAuthData();

    if (_auth!.currentAdmin != null) {
      final a = _auth!.currentAdmin!;
      adminId = a.adminId;

      email = a.email.isNotEmpty ? a.email : '';

      // Prefer meta.state (code) then meta.stateName (readable), or blank
      stateName = a.meta.state.isNotEmpty
          ? a.meta.state
          : (a.meta.stateName.isNotEmpty ? a.meta.stateName : '');

      active = a.active;
      _svc = ApplicationService(_config.apiBaseUrl, token: _auth!.token);
      await _loadFromParams();
    } else {
      try {
        final userData = await AuthService.getUserData();
        if (userData != null) {
          adminId = userData['adminId']?.toString() ?? '';
          email = userData['email']?.toString() ?? '';

          stateName =
              userData['state']?.toString() ??
              userData['stateName']?.toString() ??
              userData['meta']?['state']?.toString() ??
              userData['meta']?['stateName']?.toString() ??
              '';

          active = userData['active'] == true;

          final token = await AuthService.getToken();
          if (token != null) {
            _svc = ApplicationService(_config.apiBaseUrl, token: token);
            await _loadFromParams();
          }
        }
      } catch (e) {
        // swallow init error
      }
      setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      if (widget.apiBaseUrl != null && widget.token != null) {
        _svc = ApplicationService(widget.apiBaseUrl!, token: widget.token!);
        adminId = widget.stateAdminId ?? '';
        stateName = widget.stateName ?? '';
        email = widget.stateEmail ?? '';
        active = widget.isActive ?? true;
        await _loadFromParams();
      } else {
        await _initFromAuth();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Compute display values with fallbacks to mirror District UI
    final displayStateName = stateName.isNotEmpty
        ? stateName
        : (widget.stateName?.isNotEmpty == true ? widget.stateName! : "");

    final displayTitle = displayStateName.isNotEmpty
        ? '$displayStateName State Admin'
        : 'State Admin';

    final displayEmail = email.isNotEmpty
        ? email
        : (widget.stateEmail?.isNotEmpty == true ? widget.stateEmail! : "");

    final displayLocation = displayStateName.isNotEmpty
        ? '$displayStateName State'
        : 'State not found';

    final finalDisplayEmail = displayEmail.isNotEmpty
        ? displayEmail
        : (displayStateName.isNotEmpty
              ? 'state.${displayStateName.toLowerCase().replaceAll(' ', '')}.admin@activ.com'
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
          onPressed: () => Navigator.of(context).pop(),
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

                  // Account section (same as mock; you'll wire later)
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
                          // Capture navigator and messenger before async gaps
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          // Show loading indicator
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

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
              'State Overview',
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
