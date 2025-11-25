import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'browse_members_screen.dart';
import 'notifications_screen.dart';
import '../../services/member_service.dart';
import '../../services/browse_members_service.dart';

class MemberDashboardScreen extends StatefulWidget {
  final String?
  memberId; // Optional memberId - if null, shows logged-in user's dashboard

  const MemberDashboardScreen({super.key, this.memberId});

  @override
  State<MemberDashboardScreen> createState() => _MemberDashboardScreenState();
}

class _MemberDashboardScreenState extends State<MemberDashboardScreen> {
  String memberName = 'Member';
  String companyName = 'Your Company';
  String membershipType = 'Lifetime';
  String memberSince = '2024';
  String memberEmail = 'Loading...';
  String? displayMemberId; // Store the actual MongoDB _id
  bool isActive = true;
  bool isLoading = true;
  bool isViewingOtherMember = false;

  @override
  void initState() {
    super.initState();
    isViewingOtherMember = widget.memberId != null;
    _loadMemberData();
  }

  Future<void> _loadMemberData() async {
    print('🚀 === MEMBER DASHBOARD: Loading data ===');
    print('📋 MemberId parameter: ${widget.memberId}');
    print('👤 Viewing other member: $isViewingOtherMember');

    try {
      Map<String, dynamic>? response;

      if (widget.memberId != null) {
        // Load specific member's data using BrowseMembersService
        print('🔍 Fetching data for member: ${widget.memberId}');
        response = await BrowseMembersService.getMemberById(widget.memberId!);
        print('📦 Specific member API Response: $response');
      } else {
        // Load logged-in user's data using MemberService
        print('👤 Fetching logged-in user data');
        response = await MemberService.getMemberDetails();
        print('📦 Logged-in user API Response: $response');
      }

      if (response != null && response['success'] == true) {
        // Handle different response structures
        final data = response['data'] ?? response['member'];

        if (data != null) {
          print('🔍 Full data structure: $data');
          final personalDetails = data['personal_and_demographic_details'];
          final businessInfo = data['business_information'];

          print('👤 Personal Details: $personalDetails');
          print('🏢 Business Info: $businessInfo');

          setState(() {
            memberName = personalDetails?['full_name'] ?? 'Member';
            // Use organization name if provided, otherwise show empty string
            companyName = businessInfo?['organization_name'] ?? '';
            memberEmail = personalDetails?['email'] ?? 'N/A';
            displayMemberId = data['_id']; // Store MongoDB _id
            memberSince =
                personalDetails?['date_of_birth']?.split('-')[2] ?? '2024';
            isLoading = false;
          });

          print(
            '✅ Data loaded: $memberName from $companyName (ID: $displayMemberId)',
          );
        } else {
          print('⚠️ No data found in response');
          setState(() => isLoading = false);
        }
      } else {
        print('⚠️ Response unsuccessful or null');
        setState(() => isLoading = false);
      }
    } catch (e) {
      print('❌ Error loading dashboard data: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF5B3A8F), // Deep purple at top
              Color(0xFF3D2563), // Darker purple at bottom
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Section - Purple Background
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Profile Header
                    Row(
                      children: [
                        // Profile Image
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const CircleAvatar(
                            radius: 35,
                            backgroundImage: AssetImage(
                              'assets/images/profile.png',
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Name and Company
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isViewingOtherMember
                                    ? memberName
                                    : 'Welcome back, $memberName',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                companyName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Search Bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by location...',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: Colors.grey[600]),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // White Content Section (Scrollable)
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Membership Card
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFB388FF), // Light purple
                                Color(0xFFFF6EC7), // Pink
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Lifetime Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      membershipType,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  // Active Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00C853),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Text(
                                      'Active',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  // Crown Icon
                                  const Icon(
                                    Icons.emoji_events,
                                    color: Color(0xFFFFC107),
                                    size: 28,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Member Since
                              const Text(
                                'Member since',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                memberSince,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Member Email
                              Text(
                                'Email: $memberEmail',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Official Documents Section
                        const Text(
                          'Official Documents',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF202124),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Access and download essential documents\nrelated to your account',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5F6368),
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Download Membership Certificate
                        _buildDownloadButton(
                          icon: Icons.workspace_premium,
                          text: 'Download Membership Certificate',
                          backgroundColor: const Color(0xFFE3F2FD),
                          iconColor: const Color(0xFF1976D2),
                          onTap: () {
                            // TODO: Implement certificate download
                          },
                        ),

                        const SizedBox(height: 12),

                        // Download Tax Exemption Certificate
                        _buildDownloadButton(
                          icon: Icons.receipt_long,
                          text: 'Download Tax Exemption Certificate',
                          backgroundColor: const Color(0xFFE8F5E9),
                          iconColor: const Color(0xFF2E7D32),
                          onTap: () {
                            // TODO: Implement certificate download
                          },
                        ),

                        const SizedBox(height: 32),

                        // Quick Actions Grid
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          children: [
                            _buildQuickActionCard(
                              icon: Icons.person_outline,
                              title: 'Profile',
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE3F2FD), Color(0xFFC5E1FF)],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AccountScreen(
                                      memberName: memberName,
                                      companyName: companyName,
                                      memberId: isViewingOtherMember ? displayMemberId : null, // Pass displayMemberId when viewing other member
                                    ),
                                  ),
                                );
                              },
                            ),
                            _buildQuickActionCard(
                              icon: Icons.calendar_month_outlined,
                              title: 'Events',
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE3F2FD), Color(0xFFC5E1FF)],
                              ),
                              onTap: () {
                                // TODO: Navigate to events
                              },
                            ),
                            _buildQuickActionCard(
                              icon: Icons.headset_mic_outlined,
                              title: 'Support',
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE3F2FD), Color(0xFFC5E1FF)],
                              ),
                              onTap: () {
                                // TODO: Navigate to support
                              },
                            ),
                            _buildQuickActionCard(
                              icon: Icons.settings_outlined,
                              title: 'Settings',
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE3F2FD), Color(0xFFC5E1FF)],
                              ),
                              onTap: () {
                                // TODO: Navigate to settings
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context),
    );
  }

  Widget _buildDownloadButton({
    required IconData icon,
    required String text,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF202124),
                ),
              ),
            ),
            Icon(Icons.download_outlined, color: iconColor, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: const Color(0xFF1565C0)),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF202124),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
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
                icon: Icons.home,
                label: 'Home',
                isSelected: true,
                onTap: () {},
              ),
              _buildNavItem(
                icon: Icons.explore_outlined,
                label: 'Explore',
                isSelected: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BrowseMembersScreen(),
                    ),
                  );
                },
              ),
              _buildNavItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                isSelected: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsScreen(),
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
          Icon(icon, color: isSelected ? Colors.black : Colors.grey, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
