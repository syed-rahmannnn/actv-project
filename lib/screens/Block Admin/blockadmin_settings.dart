import 'package:flutter/material.dart';
import '../../services/application_service.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
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
        ),
        active: (userData['active'] ?? true) == true,
      );
    } else {}
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

  AdminMeta({
    required this.state,
    required this.district,
    required this.block,
    required this.stateName,
    required this.districtName,
  });
}

class BlockAdminSettingsPage extends StatefulWidget {
  final String? apiBaseUrl;
  final String? token;
  final String? blockAdminId;
  final String? blockName;
  final String? blockEmail;
  final bool? isActive;
  // When provided, these counts take precedence and keep Settings in sync
  // with the Dashboard tab.
  final Map<String, int>? statsOverride;

  const BlockAdminSettingsPage({
    super.key,
    this.apiBaseUrl,
    this.token,
    this.blockAdminId,
    this.blockName,
    this.blockEmail,
    this.isActive,
    this.statsOverride,
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
    // If dashboard passed the counts, use them directly
    if (widget.statsOverride != null) {
      _stats = {
        'total': widget.statsOverride!['total'] ?? 0,
        'pending': widget.statsOverride!['pending'] ?? 0,
        'approved': widget.statsOverride!['approved'] ?? 0,
        'rejected': widget.statsOverride!['rejected'] ?? 0,
      };
      _loading = false;
    } else if (widget.apiBaseUrl != null && widget.token != null) {
      _svc = ApplicationService(widget.apiBaseUrl!, token: widget.token!);
      adminId = widget.blockAdminId ?? '';
      adminEmail = widget.blockEmail ?? '';
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
      // Use the service to fetch stats properly
      if (widget.token != null && widget.token!.isNotEmpty) {
        _svc = ApplicationService(widget.apiBaseUrl!, token: widget.token!);
        final stats = await _svc.getBlockStats(adminId);

        if (!mounted) return;
        setState(() {
          _stats = stats;
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
    try {
      await _auth._loadAuthData();

      if (_auth.currentAdmin != null) {
        final admin = _auth.currentAdmin!;

        adminId = admin.adminId;
        adminEmail = admin.email;
        adminRole = admin.role;
        active = admin.active;

        // Validate critical data
        if (adminId.isEmpty) {}
        if (adminRole.isEmpty) {}
        if (adminEmail.isEmpty) {}

        // Set admin name and location based on role
        switch (adminRole.toLowerCase()) {
          case 'block':
            adminName = admin.meta.districtName.isNotEmpty
                ? '${admin.meta.districtName} District Admin'
                : 'District Admin';
            locationName = admin.meta.districtName.isNotEmpty
                ? admin.meta.districtName
                : 'District not found';
            overviewTitle = 'Block Overview';
            break;
          case 'district':
            adminName = admin.meta.districtName.isNotEmpty
                ? '${admin.meta.districtName} District Admin'
                : 'District Admin';
            locationName = admin.meta.districtName.isNotEmpty
                ? '${admin.meta.districtName} District'
                : 'District not found';
            overviewTitle = 'District Overview';
            break;
          case 'state':
            adminName = admin.meta.stateName.isNotEmpty
                ? '${admin.meta.stateName} State Admin'
                : 'State Admin';
            locationName = admin.meta.stateName.isNotEmpty
                ? '${admin.meta.stateName} State'
                : 'State not found';
            overviewTitle = 'State Overview';
            break;
          default:
            adminName = admin.fullName.isNotEmpty ? admin.fullName : 'Admin';
            locationName = 'Location not found';
            overviewTitle = 'Admin Overview';
        }

        _svc = ApplicationService(_config.apiBaseUrl, token: _auth.token);

        // Fetch fresh admin details from backend
        await fetchAndSetAdminDetails();
        await _loadStats();
      } else {
        // Fallback to AuthService directly
        try {
          final userData = await AuthService.getUserData();

          if (userData != null) {
            adminId = userData['adminId']?.toString() ?? '';
            adminEmail = userData['email']?.toString() ?? '';
            adminRole = userData['role']?.toString() ?? '';
            active = userData['active'] == true;

            // Validate critical data from AuthService
            if (adminId.isEmpty) {}
            if (adminRole.isEmpty) {}

            // Set names based on role with fallbacks
            switch (adminRole.toLowerCase()) {
              case 'block':
                final districtName =
                    userData['districtName']?.toString() ??
                    userData['district']?.toString() ??
                    userData['meta']?['districtName']?.toString() ??
                    '';
                adminName = districtName.isNotEmpty
                    ? '$districtName District Admin'
                    : 'District Admin';
                locationName = districtName.isNotEmpty
                    ? districtName
                    : 'District not found';
                overviewTitle = 'Block Overview';
                break;
              case 'district':
                final districtName =
                    userData['districtName']?.toString() ??
                    userData['meta']?['districtName']?.toString() ??
                    '';
                adminName = districtName.isNotEmpty
                    ? '$districtName District Admin'
                    : 'District Admin';
                locationName = districtName.isNotEmpty
                    ? '$districtName District'
                    : 'District not found';
                overviewTitle = 'District Overview';
                break;
              case 'state':
                final stateName =
                    userData['stateName']?.toString() ??
                    userData['meta']?['stateName']?.toString() ??
                    '';
                adminName = stateName.isNotEmpty
                    ? '$stateName State Admin'
                    : 'State Admin';
                locationName = stateName.isNotEmpty
                    ? '$stateName State'
                    : 'State not found';
                overviewTitle = 'State Overview';
                break;
              default:
                adminName = userData['fullName']?.toString() ?? 'Admin';
                locationName = 'Location not found';
                overviewTitle = 'Admin Overview';
            }

            final token = await AuthService.getToken();

            if (token != null) {
              _svc = ApplicationService(_config.apiBaseUrl, token: token);

              // Fetch fresh admin details from backend
              await fetchAndSetAdminDetails();
              await _loadStats();
            } else {
              setState(() => _loading = false);
            }
          } else {
            setState(() => _loading = false);
          }
        } catch (e) {
          setState(() => _loading = false);
        }
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> fetchAndSetAdminDetails() async {
    if (adminId.isEmpty) return;

    try {
      Map<String, dynamic> data;

      // Fetch admin details based on role
      switch (adminRole.toLowerCase()) {
        case 'blockadmin':
        case 'block':
          data = await _svc.getBlockAdminDetails(adminId);
          break;
        case 'districtadmin':
        case 'district':
          data = await _svc.getDistrictAdminDetails(adminId);
          break;
        case 'stateadmin':
        case 'state':
          data = await _svc.getStateAdminDetails(adminId);
          break;
        default:
          // Fallback: try block admin first
          try {
            data = await _svc.getBlockAdminDetails(adminId);
          } catch (_) {
            // If block admin fails, try district admin
            try {
              data = await _svc.getDistrictAdminDetails(adminId);
            } catch (_) {
              // If district admin fails, try state admin
              data = await _svc.getStateAdminDetails(adminId);
            }
          }
      }

      setState(() {
        adminName = data['fullName'] ?? 'Admin';
        adminEmail = data['email'] ?? '';
        active = data['active'] ?? true;

        // Set location name based on available meta data
        final meta = data['meta'] ?? {};
        if (meta['districtName'] != null &&
            meta['districtName'].toString().isNotEmpty) {
          locationName = '${meta['districtName']}';
          adminName = adminName.isEmpty
              ? '${meta['districtName']} District Admin'
              : adminName;
          overviewTitle = 'District Overview';
        } else if (meta['blockName'] != null &&
            meta['blockName'].toString().isNotEmpty) {
          locationName = '${meta['blockName']} Block';
          adminName = adminName.isEmpty
              ? '${meta['blockName']} Block Admin'
              : adminName;
          overviewTitle = 'Block Overview';
        } else if (meta['stateName'] != null &&
            meta['stateName'].toString().isNotEmpty) {
          locationName = '${meta['stateName']} State';
          adminName = adminName.isEmpty
              ? '${meta['stateName']} State Admin'
              : adminName;
          overviewTitle = 'State Overview';
        } else {
          locationName = 'Location not found';
          overviewTitle = 'Admin Overview';
        }
      });
    } catch (e) {
      // Handle error silently or show a message
    }
  }

  Future<void> _loadStats() async {
    // Defensive check: Ensure adminId is not empty
    if (adminId.isEmpty) {
      setState(() => _loading = false);
      return;
    }

    // Service is expected to be initialized before loading stats

    setState(() => _loading = true);

    try {
      Map<String, int> stats = {};

      // Prefer dashboard-provided counts if available
      if (widget.statsOverride != null) {
        stats = {
          'total': widget.statsOverride!['total'] ?? 0,
          'pending': widget.statsOverride!['pending'] ?? 0,
          'approved': widget.statsOverride!['approved'] ?? 0,
          'rejected': widget.statsOverride!['rejected'] ?? 0,
        };
      } else {
        // Fetch stats using the service that calls proper backend endpoints
        if (_auth.token != null && _auth.token!.isNotEmpty) {
          final svc = ApplicationService(
            _config.apiBaseUrl,
            token: _auth.token!,
          );
          stats = await svc.getBlockStats(adminId);
        } else {
          stats = {'total': 0, 'pending': 0, 'approved': 0, 'rejected': 0};
        }
      }

      // Validate stats structure
      if (stats.isEmpty) {
      } else {}

      if (!mounted) {
        return;
      }

      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);

    try {
      if (widget.apiBaseUrl != null && widget.token != null) {
        // Initialize service with widget parameters
        _svc = ApplicationService(widget.apiBaseUrl!, token: widget.token!);
        adminId = widget.blockAdminId ?? '';
        adminEmail = widget.blockEmail ?? '';
        active = widget.isActive ?? true;

        await _loadFromParams();
      } else {
        await _initFromAuth();
      }
    } catch (e) {
      // Log refresh error for visibility (avoids empty catches)
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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
          : FutureBuilder<Map<String, dynamic>?>(
              future: AuthService.getUserData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasData && snapshot.data != null) {
                  final userData = snapshot.data!;

                  // Update local variables with fresh data
                  adminEmail =
                      userData['email']?.toString() ?? 'No email found';
                  adminName = userData['fullName']?.toString() ?? 'Admin';

                  // Extract district name for location icon
                  final districtName =
                      userData['districtName']?.toString() ??
                      userData['district']?.toString() ??
                      userData['meta']?['districtName']?.toString() ??
                      userData['meta']?['district']?.toString() ??
                      'Ariyalur'; // Known district name as fallback

                  locationName =
                      districtName; // Keep this for backward compatibility
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // Profile Card
                      _buildProfileCard(
                        freshAdminName: adminName,
                        freshAdminEmail: adminEmail,
                      ),

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
                );
              },
            ),
    );
  }

  Widget _buildProfileCard({
    String? freshAdminName,
    String? freshAdminEmail,
    String? freshDistrictName,
  }) {
    // Use fresh data if provided, otherwise fall back to class variables
    final displayAdminName = freshAdminName ?? adminName;
    final displayAdminEmail = freshAdminEmail ?? adminEmail;
    final displayDistrictName = freshDistrictName ?? locationName;

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
                  displayAdminName.isNotEmpty
                      ? displayAdminName[0].toUpperCase()
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
                      displayAdminName.isNotEmpty ? displayAdminName : 'Admin',
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
                            displayAdminEmail.isNotEmpty
                                ? displayAdminEmail
                                : 'No email found',
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
              Icon(Icons.location_on, size: 18, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  displayDistrictName.isNotEmpty
                      ? '$displayDistrictName District'
                      : 'Location not available',
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
    );
  }

  Widget _buildOverviewStats() {
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
      child: _loading
          ? const Column(
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading stats...'),
              ],
            )
          : Column(
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
                const SizedBox(height: 16),
                // Section heading for stats
                const Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    'Administration Count',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildStatRow(
                  'Total Members:',
                  _stats['total'] ?? 0,
                  Icons.people,
                  const Color(0xFF2563EB),
                ),
                const SizedBox(height: 10),
                _buildStatRow(
                  'Pending Approvals:',
                  _stats['pending'] ?? 0,
                  Icons.access_time,
                  const Color(0xFFF59E0B),
                ),
                const SizedBox(height: 10),
                _buildStatRow(
                  'Approved:',
                  _stats['approved'] ?? 0,
                  Icons.check_circle,
                  const Color(0xFF16A34A),
                ),
                const SizedBox(height: 10),
                _buildStatRow(
                  'Rejected:',
                  _stats['rejected'] ?? 0,
                  Icons.cancel,
                  const Color(0xFFDC2626),
                ),
              ],
            ),
    );
  }

  // Helper to compute tri-state counts identically to Approvals/Dashboard
  Map<String, int> _deriveStatsFromList(List<dynamic> all) {
    final pending = all.where((app) {
      final s = (app['status'] ?? '').toString().toLowerCase();
      return s == 'pending' ||
          s == 'submitted' ||
          s == 'pending-block' ||
          s.isEmpty;
    }).length;
    final approved = all.where((app) {
      final s = (app['status'] ?? '').toString().toLowerCase();
      return s == 'approved';
    }).length;
    final rejected = all.where((app) {
      final s = (app['status'] ?? '').toString().toLowerCase();
      return s == 'rejected';
    }).length;
    return {
      'total': all.length,
      'pending': pending,
      'approved': approved,
      'rejected': rejected,
    };
  }

  Widget _buildStatRow(String label, int value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
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
          // Show confirmation dialog
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
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
              builder: (context) =>
                  const Center(child: CircularProgressIndicator()),
            );

            try {
              // Clear session and token
              await AuthService.logout();
              if (!mounted) return;
              // Navigate to login screen and clear all routes
              navigator.pop(); // Close loading dialog
              navigator.pushNamedAndRemoveUntil('/login', (route) => false);
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
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
