import 'package:flutter/material.dart';

class AccountScreen extends StatelessWidget {
  final String memberName;
  final String companyName;
  final String profileImageUrl;

  const AccountScreen({
    super.key,
    required this.memberName,
    required this.companyName,
    this.profileImageUrl = 'assets/images/profile.png',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              color: Colors.white,
              child: const Center(
                child: Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF202124),
                  ),
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    
                    // Profile Picture
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 58,
                        backgroundImage: AssetImage(profileImageUrl),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Name
                    Text(
                      memberName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF202124),
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Company Name
                    Text(
                      companyName,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF5F6368),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Menu Items Container
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildMenuItem(
                            icon: Icons.person_outline,
                            title: 'My Profile',
                            onTap: () {
                              // TODO: Navigate to profile details
                            },
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.payment_outlined,
                            title: 'Payment History',
                            onTap: () {
                              // TODO: Navigate to payment history
                            },
                          ),
                          _buildDivider(),
                          _buildMenuItem(
                            icon: Icons.workspace_premium_outlined,
                            title: 'Certificates',
                            onTap: () {
                              // TODO: Navigate to certificates
                            },
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Bottom Navigation Bar
            _buildBottomNavBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool showDivider = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF202124),
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF202124),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF5F6368),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      color: const Color(0xFFE8EAED),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                label: 'Home',
                isSelected: false,
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              _buildNavItem(
                icon: Icons.people_outline,
                label: 'Explore',
                isSelected: false,
                onTap: () {
                  // TODO: Navigate to explore
                },
              ),
              _buildNavItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                isSelected: false,
                onTap: () {
                  // TODO: Navigate to notifications
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.black : const Color(0xFF5F6368),
            size: 28,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.black : const Color(0xFF5F6368),
            ),
          ),
        ],
      ),
    );
  }
}
