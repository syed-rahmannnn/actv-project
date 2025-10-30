import 'package:flutter/material.dart';
import '../../services/application_service.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  final String apiBaseUrl = 'https://actv-project.onrender.com/api';
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

    final userData = await AuthService.getUserData();
    if (userData != null) {
      currentAdmin = AdminData(
        adminId: userData['adminId'] ?? userData['_id'] ?? '',
        email: userData['email'] ?? '',
        role: userData['role'] ?? '',
        fullName: userData['fullName'] ?? '',
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

class BlockAdminSettingsPage extends StatefulWidget {
  final String? apiBaseUrl;
  final String? token;
  final String? blockAdminId;
  final String? blockName;
  final String? blockEmail;
  final bool? isActive;

  const BlockAdminSettingsPage({
    super.key,
    this.apiBaseUrl,
    this.token,
    this.blockAdminId,
    this.blockName,
    this.blockEmail,
    this.isActive,
  });

  @override
  State<BlockAdminSettingsPage> createState() => _BlockAdminSettingsPageState();
}

class _BlockAdminSettingsPageState extends State<BlockAdminSettingsPage> {
  Map<String, int> _stats = {};
  bool _loading = true;
  late ApplicationService _svc;

  String adminId = '';
  String adminName = '';
  String adminEmail = '';
  String adminRole = '';
  String locationName = '';
  String overviewTitle = '';
  bool active = true;

  final _config = AppConfig();
  final _auth = AuthProvider();

  @override
  void initState() {
    super.initState();
    // Always call this, regardless of where adminId comes from
    _initAdminData();
  }

  // Helper to guarantee fetching from backend
  Future<void> _initAdminData() async {
    setState(() => _loading = true);
    try {
      // hydrate auth to get latest token and admin
      await _auth._loadAuthData();

      final token = widget.token ?? _auth.token ?? await AuthService.getToken();
      if (token == null || token.isEmpty) throw Exception('Missing auth token');
      _svc = ApplicationService(_config.apiBaseUrl, token: token);

      // Pull BOTH ids from user data
      final user = await AuthService.getUserData();
      final blockAdminDocId =
          widget
              .blockAdminId // if pushed in
              ??
          user?['_id']
              ?.toString() // Mongo _id for API calls
              ??
          '';
      final publicAdminCode =
          user?['adminId']
              ?.toString() // e.g., BA29022001 (display only)
              ??
          '';

      if (blockAdminDocId.isEmpty) throw Exception('Missing block admin _id');

      // Quick verification log
      debugPrint(
        'SETTINGS -> calling with _id=' +
            blockAdminDocId +
            ', publicCode=' +
            publicAdminCode,
      );

      // Use the new ApiService.fetchBlockAdmin method
      // Try with _id first, then fallback to adminId if needed
      Map<String, dynamic>? profile = await ApiService.fetchBlockAdmin(
        blockAdminDocId,
      );
      if (profile == null && publicAdminCode.isNotEmpty) {
        profile = await ApiService.fetchBlockAdmin(publicAdminCode);
      }
      final stats = await _svc.getBlockStats(blockAdminDocId);

      // Debug: Print the profile data to understand its structure
      debugPrint('SETTINGS -> Profile data: $profile');
      debugPrint('SETTINGS -> Profile meta: ${profile?['meta']}');

      // 4) map to UI safely - using same logic as approval page
      if (!mounted) return;
      setState(() {
        // Extract admin details similar to approval page logic
        if (profile != null) {
          adminName = profile['fullName']?.toString() ?? 'Block Admin';
          adminEmail = profile['email']?.toString() ?? '';
          adminRole = profile['role']?.toString() ?? 'block';
          active = profile['active'] == true;

          // Extract block name using same logic as approval page
          locationName =
              profile['meta']?['blockName']?.toString() ??
              profile['meta']?['block']?.toString() ??
              widget.blockName ??
              '';

          // Debug: Print extracted values
          debugPrint('SETTINGS -> Extracted adminName: $adminName');
          debugPrint('SETTINGS -> Extracted adminEmail: $adminEmail');
          debugPrint('SETTINGS -> Extracted locationName: $locationName');
        } else {
          // Fallback values if profile is null or not a Map
          adminName = 'Block Admin';
          adminEmail = '';
          locationName = widget.blockName ?? '';
          debugPrint('SETTINGS -> Using fallback values');
        }

        // Keep the public code if you show it anywhere
        adminId = publicAdminCode;

        overviewTitle = 'Block Overview';
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      debugPrint('BlockAdminSettings bootstrap failed: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    await _initAdminData();
  }

  @override
  Widget build(BuildContext context) {
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
                  // Profile Card
                  _buildProfileCard(),

                  const SizedBox(height: 24),

                  // Admin Overview Stats
                  _buildOverviewStats(),

                  const SizedBox(height: 24),

                  // Support Section (Account panel removed as requested)
                  _buildSupportSection(),

                  const SizedBox(height: 32),

                  // Logout Button
                  _buildLogoutButton(),

                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF1E88FF),
            child: Text(
              adminName.isNotEmpty ? adminName[0].toUpperCase() : 'A',
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
                  adminName.isNotEmpty ? adminName : 'Block Admin',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.email, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        adminEmail.isNotEmpty ? adminEmail : 'admin@activ.com',
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        locationName.isNotEmpty ? locationName : 'Block Admin',
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
                      'Active Status:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF374151),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        active ? 'Active' : 'Inactive',
                        style: TextStyle(
                          color: active
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
        ],
      ),
    );
  }

  Widget _buildOverviewStats() {
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
          Text(
            overviewTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildStatRow(
            'Total Members:',
            total,
            Icons.person_outline,
            const Color(0xFF0F172A),
          ),
          const SizedBox(height: 10),
          _buildStatRow(
            'Pending Approvals:',
            pending,
            Icons.access_time,
            const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 10),
          _buildStatRow(
            'Approved:',
            approved,
            Icons.check_circle,
            const Color(0xFF16A34A),
          ),
          const SizedBox(height: 10),
          _buildStatRow(
            'Rejected:',
            rejected,
            Icons.cancel,
            const Color(0xFFDC2626),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6B7280), size: 20),
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
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
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Support',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          ListTile(
            title: const Text(
              'Help & Support',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
            onTap: () {
              // Handle help & support navigation
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                const Center(child: CircularProgressIndicator()),
          );

          try {
            // Clear session and token
            await AuthService.logout();
            if (!context.mounted) return;
            // Navigate to login screen and clear all routes
            Navigator.of(context).pop(); // Close loading dialog
            Navigator.of(
              context,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          } catch (e) {
            // Handle logout error
            if (!context.mounted) return;
            Navigator.of(context).pop(); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Logout failed: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
