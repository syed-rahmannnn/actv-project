import 'package:flutter/material.dart';
import '../Member Profile/profile_screen.dart';
import 'browse_members_screen.dart';
import 'notification_screen.dart';
import '../Member Addtional Details/personal_details_form.dart';
import '../Application Status/application_status_screen.dart';
import '../Bussiness account/business_profile_screen.dart';
import '../../services/member_service.dart';
import '../../services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DashboardScreen({super.key, required this.userData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String displayName = 'Member';
  String companyName = 'Your Company';
  bool isLoading = true;
  int profileCompletionPercentage = 0;
  int filledFieldsCount = 0;
  int totalFieldsCount = 0;
  String? profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadMemberData();
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'M';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  Future<void> _loadMemberData() async {
    print('\n🚀 === DASHBOARD _loadMemberData CALLED ===');
    print('📦 widget.userData: ${widget.userData}');
    print('🔑 userData keys: ${widget.userData.keys.toList()}');

    // First, try to get name from userData passed from login
    final initialName =
        widget.userData['fullName'] ??
        widget.userData['member']?['fullName'] ??
        'Member';

    print('📝 Initial name extracted: $initialName');

    setState(() {
      displayName = initialName;
    });

    print('=== DASHBOARD SCREEN INIT ===');
    print('Initial name from userData: $displayName');
    print('🌐 About to call MemberService.getMemberDetails()...');

    // Then fetch fresh data from API
    try {
      final data = await MemberService.getMemberDetails();

      print('📡 API Response received: ${data != null}');
      print('📊 Full API response: $data');

      if (data != null && data['success'] == true) {
        final memberData = data['data'];
        final personalDetails = memberData['personal_and_demographic_details'];
        final businessInfo = memberData['business_information'];

        print('👤 Personal details: $personalDetails');
        print('🏢 Business info: $businessInfo');
        print('📛 Extracted full_name: ${personalDetails?['full_name']}');
        print(
          '🏭 Extracted organization_name: ${businessInfo?['organization_name']}',
        );

        setState(() {
          displayName = personalDetails?['full_name'] ?? displayName;
          companyName = businessInfo?['organization_name'] ?? 'Your Company';
          isLoading = false;
        });

        print('✅ Dashboard data loaded from API');
        print('✅ Final display name: $displayName');
        print('✅ Final company name: $companyName');

        // Fetch profile completion percentage
        _loadProfileCompletion();
      } else {
        setState(() => isLoading = false);
        print('⚠️ Could not fetch fresh data, using login data');
        print('⚠️ API response was: $data');
      }
    } catch (e, stackTrace) {
      setState(() => isLoading = false);
      print('❌ Error loading dashboard data: $e');
      print('❌ Stack trace: $stackTrace');
    }
  }

  Future<void> _loadProfileCompletion() async {
    try {
      final memberId =
          widget.userData['_id'] ??
          widget.userData['id'] ??
          widget.userData['member']?['_id'];

      if (memberId != null) {
        final result = await ApiService.getProfileCompletion(memberId);
        if (result['success'] == true && mounted) {
          setState(() {
            profileCompletionPercentage = result['percentage'] ?? 0;
            filledFieldsCount = result['filledFields'] ?? 0;
            totalFieldsCount = result['totalFields'] ?? 0;
          });
          print('✅ Profile completion: $profileCompletionPercentage%');
        }
      }
    } catch (e) {
      print('❌ Error loading profile completion: $e');
    }
  }

  // Removed unused helper to satisfy analyzer

  @override
  Widget build(BuildContext context) {
    // Debug: Print userData to see what's available
    print('=== DASHBOARD SCREEN BUILD ===');
    print('UserData received: ${widget.userData}');
    print('UserData keys: ${widget.userData.keys.toList()}');
    print('Current display name: $displayName');
    print('Current company name: $companyName');

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomNavigation(context),

      // 🔹 Body starts
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                                CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Colors.blue.shade700,
                                  child: Text(
                                    _getInitials(displayName),
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome back, $displayName',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        companyName,
                                        style: const TextStyle(
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
                  _buildProgressCard(context, widget.userData),

                  const SizedBox(height: 16),

                  // 🔹 Create Business Account Card
                  _buildBusinessAccountCard(context, widget.userData),
                ],
              ),
            ),
    );
  }

  // 🔹 Build Profile Completion Card
  Widget _buildCompletionCard(
    BuildContext context,
    Map<String, dynamic> userData,
  ) {
    // Use backend-fetched percentage, fallback to calculation if not available
    final completionPercentage = profileCompletionPercentage > 0
        ? profileCompletionPercentage
        : _calculateProfileCompletion(userData);

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
                  Text(
                    '$completionPercentage% completed',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Unlock all features by completing your profile.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      print(
                        '🟢 COMPLETE PROFILE BUTTON CLICKED - Navigating to PersonalDetailsForm',
                      );
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PersonalDetailsForm(userData: userData),
                        ),
                      );
                      // Refresh profile completion when returning
                      if (result == true && mounted) {
                        _loadProfileCompletion();
                      }
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                'https://img.icons8.com/fluency/96/search.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Build Business Account Card
  Widget _buildBusinessAccountCard(
    BuildContext context,
    Map<String, dynamic> userData,
  ) {
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
                    'Create Your Business Account',
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
                      'Start setup',
                      style: TextStyle(
                        color: Color(0xFF856404),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set up your business account to unlock team features and payments',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () {
                      print(
                        '🔵 CREATE ACCOUNT BUTTON CLICKED - Navigating to BusinessProfileScreen',
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              BusinessProfileScreen(userData: userData),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                'https://img.icons8.com/fluency/96/business.png',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: Icon(
                      Icons.business,
                      size: 40,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ),
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
                      builder: (context) => const BrowseMembersScreen(),
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
                      builder: (context) => const NotificationScreen(),
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

  // Add helpers inside State class
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
    if (member is Map<String, dynamic> &&
        _isTruthy(member['profileCompleted'])) {
      return true;
    }

    return false;
  }

  int _calculateProfileCompletion(Map<String, dynamic> data) {
    int totalFields = 0;
    int filledFields = 0;

    // Basic registration fields (from step 1 & 2)
    final basicFields = [
      data['fullName'] ?? data['member']?['fullName'],
      data['email'] ?? data['member']?['email'],
      data['phoneNumber'] ?? data['member']?['phoneNumber'],
      data['state'] ?? data['member']?['state'],
      data['district'] ?? data['member']?['district'],
      data['block'] ?? data['member']?['block'],
      data['city'] ?? data['member']?['city'],
    ];

    for (var field in basicFields) {
      totalFields++;
      if (field != null && field.toString().trim().isNotEmpty) {
        filledFields++;
      }
    }

    // Profile completion fields (from additional details form)
    final profileFields = [
      data['aadhaarNumber'],
      data['streetName'],
      data['educationalQualification'],
      data['religion'],
      data['socialCategory'],
      // Business info
      data['businessName'],
      data['businessType'],
      data['businessCategory'],
      // Financial info
      data['bankName'],
      data['accountNumber'],
      data['ifscCode'],
    ];

    for (var field in profileFields) {
      totalFields++;
      if (field != null && field.toString().trim().isNotEmpty) {
        filledFields++;
      }
    }

    if (totalFields == 0) return 0;
    return ((filledFields / totalFields) * 100).round();
  }

  Widget _buildProgressCard(
    BuildContext context,
    Map<String, dynamic> userData,
  ) {
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

  Widget _buildStatusCard(BuildContext context, Map<String, dynamic> userData) {
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
                          builder: (context) => const ApplicationStatusScreen(),
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
}
