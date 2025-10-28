import 'package:flutter/material.dart';
import '../Member Profile/profile_screen.dart';
import 'browse_members_screen.dart';
import 'notification_screen.dart';
import '../Member Addtional Details/personal_details_form.dart';
import '../Application Status/application_submitted_screen.dart';

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const DashboardScreen({super.key, required this.userData});

  // Removed unused helper to satisfy analyzer

  @override
  Widget build(BuildContext context) {
    // Debug logs removed for security - no longer printing sensitive user data

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNavigation(context),

      // 🔹 Body starts
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔹 Full Blue Header
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFB3D4FF), Color(0xFFE6D8FF)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(
                        top: 50,
                        left: 20,
                        right: 20,
                      ),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundImage: AssetImage(
                              'assets/images/profile.png',
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome back , ${userData['fullName'] ?? userData['registrationForm']?['fullName'] ?? 'User'}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Text(
                                  'TechCorp Solution',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by location...',
                        hintStyle: const TextStyle(color: Colors.black54),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.black54,
                        ),
                        filled: true,
                        fillColor: Color.lerp(
                          const Color(0xFFE6D8FF),
                          Colors.white,
                          0.55,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Dynamic Card based on registration progress
            _buildProgressCard(context, userData),
          ],
        ),
      ),
    );
  }

  // 🔹 Bottom Navigation
  Widget _buildBottomNavigation(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBottomNavItem(
                icon: Icons.home,
                label: 'Home',
                isSelected: true,
                onTap: () {},
              ),
              _buildBottomNavItem(
                icon: Icons.group_outlined,
                label: 'Explore',
                isSelected: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BrowseMembersScreen(),
                    ),
                  );
                },
              ),
              _buildBottomNavItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                isSelected: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => NotificationScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blue : Colors.grey[600],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey[600],
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

// Add helpers inside DashboardScreen class
bool _isTruthy(dynamic v) {
  return v == true || v == 'true' || v == 1 || v == '1';
}

bool _isBasicRegistrationCompleted(Map<String, dynamic> data) {
  // Check if user has completed registration steps 1 and 2
  // This is indicated by having basic user data like fullName, email, state, district
  return data['fullName'] != null &&
      data['email'] != null &&
      data['state'] != null &&
      data['district'] != null;
}

bool _isFullProfileCompleted(Map<String, dynamic> data) {
  // Debug logging removed for security - no longer printing sensitive data
  final form = data['registrationForm'];

  if (form is Map<String, dynamic>) {
    final v = form['profileCompleted'];
    if (_isTruthy(v)) return true;
  }

  // Also check if profileCompleted is directly in the data
  final direct = data['profileCompleted'];
  if (_isTruthy(direct)) {
    return true;
  }

  // Check if member object has profileCompleted
  final member = data['member'];
  if (member is Map<String, dynamic> && _isTruthy(member['profileCompleted'])) {
    return true;
  }

  return false;
}

Widget _buildProgressCard(BuildContext context, Map<String, dynamic> userData) {
  if (_isFullProfileCompleted(userData)) {
    // Show Image 2 state - Profile Status card
    return _buildStatusCard(context, userData);
  } else if (_isBasicRegistrationCompleted(userData)) {
    // Show Image 1 state - Complete Profile card
    return _buildCompletionCard(context, userData);
  } else {
    // Fallback to completion card for incomplete registration
    return _buildCompletionCard(context, userData);
  }
}

Widget _buildCompletionCard(
  BuildContext context,
  Map<String, dynamic> userData,
) {
  final data = userData;
  return Card(
    elevation: 2,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete Your Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  '65% completed',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Unlock all features by completing your profile.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PersonalDetailsForm(userData: data),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: const Text(
                    'Complete Profile',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 72,
            width: 96,
            child: Image.asset('assets/images/Box1.png', fit: BoxFit.contain),
          ),
        ],
      ),
    ),
  );
}

Widget _buildStatusCard(BuildContext context, Map<String, dynamic> userData) {
  final data = userData;
  return Card(
    elevation: 2,
    margin: const EdgeInsets.symmetric(horizontal: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profile Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3CD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'In review',
                    style: TextStyle(color: Color(0xFF856404), fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your profile is under review. Tap to see status updates',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ApplicationSubmittedScreen(userData: data),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(120, 40),
                  ),
                  child: const Text('View Status'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 72,
            width: 96,
            child: Image.asset('assets/images/Box2.png', fit: BoxFit.contain),
          ),
        ],
      ),
    ),
  );
}
