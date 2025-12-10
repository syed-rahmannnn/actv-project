import 'package:flutter/material.dart';
import 'package:activ/services/auth_service.dart';
import 'package:activ/services/api_service.dart';
import '../Member Dashboard/my_profile_screen.dart';
import '../../utils/snackbar_utils.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<String> _userNameFuture;

  @override
  void initState() {
    super.initState();
    _userNameFuture = _loadUserName();
  }

  // removed unused _isTruthy helper

  Future<String> _loadUserName() async {
    try {
      final localUser = await AuthService.getUserData();
      final registrationForm =
          localUser?['registrationForm'] as Map<String, dynamic>?;
      final localName = registrationForm?['fullName'] ?? localUser?['fullName'];

      final email = localUser?['email'] ?? localUser?['member']?['email'];
      if (email is String && email.trim().isNotEmpty) {
        final res = await ApiService.getMemberByEmail(email);
        if (res['success'] == true) {
          final member = Map<String, dynamic>.from(res['data'] as Map);
          final backendName = member['fullName'];
          if (backendName is String && backendName.trim().isNotEmpty) {
            return backendName;
          }
        }
      }

      return (localName is String && localName.trim().isNotEmpty)
          ? localName
          : '';
    } catch (_) {
      final localUser = await AuthService.getUserData();
      final registrationForm =
          localUser?['registrationForm'] as Map<String, dynamic>?;
      final fallbackName =
          registrationForm?['fullName'] ?? localUser?['fullName'];
      return (fallbackName is String && fallbackName.trim().isNotEmpty)
          ? fallbackName
          : '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header
              const Text(
                'Account',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 40),

              // Profile Picture
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(shape: BoxShape.circle),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/profile.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // User Name
              FutureBuilder<String>(
                future: _userNameFuture,
                builder: (context, snapshot) {
                  final name = snapshot.data ?? '';
                  return Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),

              // Menu Items
              Expanded(
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.person_outline,
                      title: 'My Profile',
                      onTap: () async {
                        // Get user data for member name display
                        final userData = await AuthService.getUserData();

                        print('=== PROFILE SCREEN DEBUG ===');
                        print(
                          'Navigating to MyProfileScreen with dynamic data fetch...',
                        );

                        final memberName =
                            userData?['fullName'] ??
                            userData?['member']?['fullName'] ??
                            userData?['registrationForm']?['fullName'] ??
                            'Member';

                        print('Member name: $memberName');

                        if (mounted) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MyProfileScreen(memberName: memberName),
                            ),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),

                    _buildDisabledMenuItem(
                      icon: Icons.payment_outlined,
                      title: 'Payment History',
                    ),
                    const SizedBox(height: 20),

                    _buildDisabledMenuItem(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Certificates',
                    ),

                    const Spacer(),

                    // Logout Button
                    _buildLogoutButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey[600], size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledMenuItem({
    required IconData icon,
    required String title,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600], size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400], size: 24),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
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

        if (shouldLogout == true) {
          await AuthService.logout();
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (Route<dynamic> route) => false,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Logged out successfully'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Colors.red, size: 20),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
