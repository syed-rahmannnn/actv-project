import 'package:flutter/material.dart';
import 'package:activ/services/auth_service.dart';
import 'package:activ/screens/profile_detail_screen.dart';
import 'package:activ/services/api_service.dart';

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

  bool _isTruthy(dynamic v) {
    return v == true || v == 'true' || v == 1 || v == '1';
  }

  Future<String> _loadUserName() async {
    try {
      final localUser = await AuthService.getUserData();
      if (localUser == null) return 'Tamilarasan';

      final registrationForm = localUser['registrationForm'] as Map<String, dynamic>?;
      final email = localUser['email'] ?? localUser['member']?['email'];
      final localName = registrationForm?['fullName'] ?? localUser['fullName'];

      if (email != null && registrationForm != null && _isTruthy(registrationForm['profileCompleted'])) {
        final res = await ApiService.getMemberByEmail(email);
        if (res['success'] == true) {
          final member = Map<String, dynamic>.from(res['data'] as Map);
          final backendName = member['fullName'];
          if (backendName is String && backendName.trim().isNotEmpty) {
            return backendName;
          }
        }
      }

      return (localName is String && localName.trim().isNotEmpty) ? localName : 'Tamilarasan';
    } catch (_) {
      final localUser = await AuthService.getUserData();
      final registrationForm = localUser?['registrationForm'] as Map<String, dynamic>?;
      final fallbackName = registrationForm?['fullName'] ?? localUser?['fullName'];
      return (fallbackName is String && fallbackName.trim().isNotEmpty) ? fallbackName : 'Tamilarasan';
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
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
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
                  final name = snapshot.data ?? 'Tamilarasan';
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileDetailScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    _buildMenuItem(
                      icon: Icons.payment_outlined,
                      title: 'Payment History',
                      onTap: () {
                        // Navigate to payment history
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Payment History clicked')),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    
                    _buildMenuItem(
                      icon: Icons.workspace_premium_outlined,
                      title: 'Certificates',
                      onTap: () {
                        // Navigate to certificates
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Certificates clicked')),
                        );
                      },
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
            Icon(
              icon,
              color: Colors.grey[600],
              size: 24,
            ),
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
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
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
            Icon(
              Icons.logout,
              color: Colors.red,
              size: 20,
            ),
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