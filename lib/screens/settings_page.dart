import 'package:flutter/material.dart';
import '../services/application_service.dart';
import '../services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Mock classes for Provider pattern - these would typically be in separate files
class AppConfig {
  final String apiBaseUrl =
      'http://localhost:3000/api'; // Replace with your actual API base URL
}

class AuthProvider {
  String? token;
  AdminData? currentAdmin;

  AuthProvider() {
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');

    // Load admin data from AuthService
    final userData = await AuthService.getUserData();
    if (userData != null) {
      currentAdmin = AdminData(
        adminId: userData['_id'] ?? '',
        email: userData['email'] ?? '',
        role: userData['role'] ?? '',
        meta: AdminMeta(
          state: userData['state'] ?? '',
          district: userData['district'] ?? '',
          block: userData['block'] ?? '',
        ),
        active: userData['active'] ?? true,
      );
    }
  }
}

class AdminData {
  final String adminId;
  final String email;
  final String role;
  final AdminMeta meta;
  final bool active;

  AdminData({
    required this.adminId,
    required this.email,
    required this.role,
    required this.meta,
    required this.active,
  });
}

class AdminMeta {
  final String state;
  final String district;
  final String block;

  AdminMeta({required this.state, required this.district, required this.block});
}

class SettingsPage extends StatefulWidget {
  // New constructor parameters for direct instantiation
  final String? apiBaseUrl;
  final String? token;
  final String? blockAdminId;
  final String? blockName;
  final String? blockEmail;
  final bool? isActive;

  const SettingsPage({
    super.key,
    this.apiBaseUrl,
    this.token,
    this.blockAdminId,
    this.blockName,
    this.blockEmail,
    this.isActive,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  Map<String, int> _stats = {};
  bool _loading = true;
  late final ApplicationService _svc;
  // ignore: unused_field
  late final ApplicationService svc;
  // ignore: unused_field
  late final String adminId;
  // ignore: unused_field
  late final String blockName;
  // ignore: unused_field
  late final String email;
  // ignore: unused_field
  bool active = true;
  // ignore: unused_field
  Map<String, int>? stats;

  final AppConfig _appConfig = AppConfig();
  final AuthProvider _authProvider = AuthProvider();

  @override
  void initState() {
    super.initState();

    // Use new parameters if available, otherwise fall back to existing logic
    if (widget.apiBaseUrl != null && widget.token != null) {
      _svc = ApplicationService(widget.apiBaseUrl!, token: widget.token!);
      _load();
    } else {
      // Existing initialization logic
      _initializeData();
    }
  }

  // New simplified load method
  Future<void> _load() async {
    if (widget.blockAdminId != null) {
      final data = await _svc.getBlockStats(widget.blockAdminId!);
      if (!mounted) return;
      setState(() {
        _stats = data;
        _loading = false;
      });
    }
  }

  Future<void> _initializeData() async {
    await _authProvider._loadAuthData();

    if (_authProvider.currentAdmin != null) {
      final admin = _authProvider.currentAdmin!;
      adminId = admin.adminId;
      email = admin.email;
      blockName = admin.meta.block;
      active = admin.active;

      svc = ApplicationService(
        _appConfig.apiBaseUrl,
        token: _authProvider.token,
      );

      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_authProvider.currentAdmin == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final title = '$blockName Block Admin';
    final blockArea = '$blockName Block';

    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF5FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(radius: 28, child: Icon(Icons.person)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          blockArea,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Active Status'),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? const Color(0xFFDFF7E3)
                                    : const Color(0xFFFFE4E4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                active ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  color: active
                                      ? const Color(0xFF1F8B4C)
                                      : const Color(0xFFB42318),
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
            ),

            const SizedBox(height: 16),
            
            // Add stats cards to use _statsCard method and _stats values
            _statsCard('Total Applications', _stats['total'] ?? 0, Colors.blue),
            _statsCard('Pending Approvals', _stats['pending'] ?? 0, Colors.orange),
            _statsCard('Approved', _stats['approved'] ?? 0, Colors.green),
            _statsCard('Rejected', _stats['rejected'] ?? 0, Colors.red),
            
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Account',
              items: const ['Profile Information', 'Notifications'],
            ),

            const SizedBox(height: 16),
            _adminStats(stats),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<String> items}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          for (final label in items)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(label),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
        ],
      ),
    );
  }

  Widget _adminStats(Map<String, int>? s) {
    final total = s?['total'] ?? 0;
    final pending = s?['pending'] ?? 0;
    final approved = s?['approved'] ?? 0;
    final rejected = s?['rejected'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _row('Total Applications:', total, const Color(0xFF2563EB)),
          _row('Pending Approvals:', pending, const Color(0xFFF59E0B)),
          _row('Approved:', approved, const Color(0xFF16A34A)),
          _row('Rejected:', rejected, const Color(0xFFDC2626)),
        ],
      ),
    );
  }

  Widget _row(String label, int value, Color color) => ListTile(
    dense: true,
    contentPadding: EdgeInsets.zero,
    leading: const SizedBox(width: 4),
    title: Text(label),
    trailing: Text(
      '$value',
      style: TextStyle(fontWeight: FontWeight.w600, color: color),
    ),
  );

  // New _statsCard method from provided code
  Widget _statsCard(String title, int value, Color color) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(13),
          blurRadius: 10,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16)),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}
