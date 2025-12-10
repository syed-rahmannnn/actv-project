import 'package:flutter/material.dart';
import '../Member Profile/profile_screen.dart';
import 'browse_members_screen.dart';
import 'notification_screen.dart';
import '../Member Addtional Details/personal_details_form.dart';
import '../Application Status/application_status_screen.dart';
import '../Bussiness account/business_profile_screen.dart';
import '../Bussiness account/businessaccount _dashboard_screen.dart';
import '../../services/member_service.dart';
import '../../services/api_service.dart';
import '../../services/business_profile_service.dart';
import '../../services/company_service.dart';
import '../../models/business_profile_model.dart';
import '../../models/company_model.dart';

class DashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const DashboardScreen({super.key, required this.userData});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String displayName = 'Member';
  String companyName = 'Your Company';
  String mobileNumber = '';
  bool isLoading = true;
  int profileCompletionPercentage = 0;
  int filledFieldsCount = 0;
  int totalFieldsCount = 0;
  String? profileImageUrl;

  // Business account state
  bool hasBusinessAccount = false;
  String? businessId;
  String? accountStatus;

  // Dashboard status state (for dynamic card display)
  int _profileCompletion = 0;
  bool _hasPendingApplication = false;
  bool _hasBusinessProfile = false; // true after business details submitted
  bool _hasApplication = false; // true after application created
  String _applicationStatus = 'NONE'; // NONE, PENDING, Pending-Block, etc.
  bool _isDashboardLoading = true;

  bool _hasLoadedOnce = false;

  @override
  void initState() {
    super.initState();
    _loadMemberData();
    _loadDashboard(); // Load dashboard status on init
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload business account and dashboard status when returning to this screen
    if (_hasLoadedOnce) {
      print('🔄 Dashboard became active again, reloading data...');
      _loadBusinessAccount();
      _loadDashboard(); // Refresh dashboard status when returning
    } else {
      _hasLoadedOnce = true;
    }
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

    // ✅ OPTIMIZATION: Use login data immediately for instant UI
    final initialName =
        widget.userData['fullName'] ??
        widget.userData['member']?['fullName'] ??
        'Member';

    final initialCompany =
        widget.userData['companyName'] ??
        widget.userData['organizationName'] ??
        'Your Company';

    print('📝 Initial name: $initialName');

    // ✅ OPTIMIZATION: Show UI immediately with login data
    setState(() {
      displayName = initialName;
      companyName = initialCompany;
      isLoading = false; // Stop loading immediately!
    });

    print('✅ Dashboard UI shown instantly with login data');

    // ✅ OPTIMIZATION: Fetch all API data in parallel (non-blocking)
    final memberId =
        widget.userData['_id'] ??
        widget.userData['id'] ??
        widget.userData['member']?['_id'];

    // Run all fetches in parallel without blocking UI
    Future.wait([
      MemberService.getMemberDetails()
          .then((data) {
            if (data != null && data['success'] == true && mounted) {
              final memberData = data['data'];
              final personalDetails =
                  memberData['personal_and_demographic_details'];
              final businessInfo = memberData['business_information'];

              setState(() {
                displayName = personalDetails?['full_name'] ?? displayName;
                companyName = businessInfo?['organization_name'] ?? companyName;
                mobileNumber =
                    personalDetails?['mobile_number']?.toString() ?? '';
              });
              print('✅ Dashboard data updated from API');
            }
          })
          .catchError((e) {
            print('⚠️ Error loading member details: $e');
          }),

      _loadProfileCompletion().catchError((e) {
        print('⚠️ Error loading profile completion: $e');
      }),

      if (memberId != null)
        _loadBusinessAccount().catchError((e) {
          print('⚠️ Error loading business account: $e');
        }),
    ]);
  }

  // Load dashboard status from API
  Future<void> _loadDashboard() async {
    try {
      print('🔄 Loading dashboard status...');
      final status = await MemberService.getDashboardStatus();

      if (status != null && mounted) {
        setState(() {
          _profileCompletion = status['profileCompletion'] ?? 0;
          _hasPendingApplication = status['hasPendingApplication'] ?? false;
          _hasBusinessProfile = status['hasBusinessProfile'] ?? false;
          _hasApplication = status['hasApplication'] ?? false;
          _applicationStatus = status['applicationStatus'] ?? 'NONE';
          _isDashboardLoading = false;
        });

        print('✅ Dashboard status loaded:');
        print('   - Profile completion: $_profileCompletion%');
        print('   - Has business profile: $_hasBusinessProfile');
        print('   - Has application: $_hasApplication');
        print('   - Application status: $_applicationStatus');
      } else {
        if (mounted) {
          setState(() {
            _isDashboardLoading = false;
          });
        }
        print('⚠️ Could not load dashboard status');
      }
    } catch (e) {
      print('❌ Error loading dashboard status: $e');
      if (mounted) {
        setState(() {
          _isDashboardLoading = false;
        });
      }
    }
  }

  Future<void> _loadBusinessAccount() async {
    try {
      final memberId =
          widget.userData['_id'] ??
          widget.userData['id'] ??
          widget.userData['member']?['_id'];

      if (memberId == null) {
        print('⚠️ No member ID found, cannot fetch business account');
        return;
      }

      print('🏢 Fetching business account for member: $memberId');

      // ✅ CRITICAL: Clear caches before fetching to ensure fresh data
      // This fixes the issue where newly created accounts show stale "no account" data
      await BusinessProfileService.clearCache(memberId.toString());
      await CompanyService.clearCache(memberId.toString());

      // Fetch BOTH business profile AND companies in parallel
      final results = await Future.wait([
        BusinessProfileService.getBusinessProfile(memberId.toString()),
        CompanyService.getCompanies(memberId.toString()),
      ]);

      if (!mounted) return; // Don't update state if widget is disposed

      final profile = results[0] as BusinessProfile?;
      final companies = results[1] as List<Company>;

      // Business account is valid only if BOTH profile AND companies exist
      if (profile != null && companies.isNotEmpty) {
        setState(() {
          hasBusinessAccount = true;
          businessId = profile.businessId;
          accountStatus = profile.status;
          companyName = companies[0].name; // Use first company name
        });

        print('✅ Business account found:');
        print('   - Company: ${companies[0].name}');
        print('   - Total Companies: ${companies.length}');
        print('   - Business ID: ${profile.businessId}');
        print('   - Status: ${profile.status}');
      } else {
        setState(() {
          hasBusinessAccount = false;
          businessId = null;
          accountStatus = null;
        });

        if (profile == null) {
          print('ℹ️ No business profile found for this member');
        } else if (companies.isEmpty) {
          print(
            '⚠️ Business profile exists but no companies found - data mismatch!',
          );
        }
      }
    } catch (e) {
      print('❌ Error loading business account: $e');
      if (!mounted) return; // Don't update state if widget is disposed

      setState(() {
        hasBusinessAccount = false;
        businessId = null;
        accountStatus = null;
      });
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
          : RefreshIndicator(
              onRefresh: () async {
                await _loadMemberData();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
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
                                        if (mobileNumber.isNotEmpty)
                                          Text(
                                            mobileNumber,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Colors.black54,
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
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // 🔹 Dynamic Card based on application status (fetched from backend)
                    _isDashboardLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildTopCard(context),

                    const SizedBox(height: 16),

                    // 🔹 Business Account Card (always shown)
                    _buildBusinessAccountCard(context, widget.userData),
                  ],
                ),
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
    // Conditional title and description
    final String cardTitle = hasBusinessAccount
        ? 'Your Business Account'
        : 'Create Your Business Account';

    final String cardDescription = hasBusinessAccount
        ? 'View and manage your business profile and settings'
        : 'Set up your business account to unlock team features and payments';

    final String buttonText = hasBusinessAccount
        ? 'View Account'
        : 'Create Account';

    final String badgeText = hasBusinessAccount
        ? accountStatus == 'approved'
              ? 'Active'
              : 'Pending'
        : 'Start setup';

    final Color badgeColor = hasBusinessAccount
        ? accountStatus == 'approved'
              ? const Color(0xFFD4EDDA) // Green for active
              : const Color(0xFFFFF3CD) // Yellow for pending
        : const Color(0xFFFFF3CD);

    final Color badgeTextColor = hasBusinessAccount
        ? accountStatus == 'approved'
              ? const Color(0xFF155724) // Dark green
              : const Color(0xFF856404) // Dark yellow
        : const Color(0xFF856404);

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cardTitle,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeTextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    cardDescription,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      print(
                        '🔵 BUSINESS BUTTON CLICKED - hasAccount: $hasBusinessAccount',
                      );

                      if (hasBusinessAccount && businessId != null) {
                        // Navigate to Business Dashboard
                        print('   → Navigating to BusinessDashboardScreen');
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BusinessDashboardScreen(userData: userData),
                          ),
                        );
                        // Reload business account after returning
                        print('🔄 Returned from dashboard, reloading data...');
                        await _loadBusinessAccount();
                      } else {
                        // Navigate to Business Profile onboarding
                        print('   → Navigating to BusinessProfileScreen');
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                BusinessProfileScreen(userData: userData),
                          ),
                        );
                        // ✅ Account was created! The user is now in BusinessDashboard
                        // When they come back here, reload business account status
                        print(
                          '🔄 User returned to member dashboard, reloading business account status...',
                        );
                        // Wait a bit for any pending operations
                        await Future.delayed(const Duration(milliseconds: 500));
                        await _loadBusinessAccount();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D6EFD),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.network(
                'https://img.icons8.com/fluency/96/business.png',
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 70,
                    height: 70,
                    child: Icon(
                      Icons.business,
                      size: 50,
                      color: Color(0xFF0D6EFD),
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

  // 🔹 Build Profile Card - shows "Complete Profile" OR "View Status" based on application status
  Widget _buildProfileCard(BuildContext context) {
    // This method is replaced by _buildTopCard - kept for backward compatibility
    return _buildTopCard(context);
  }

  // 🔹 Build Top Card - Shows ONLY ONE card at a time
  Widget _buildTopCard(BuildContext context) {
    // Rule: ONLY check hasApplication flag from backend
    // This ensures we show correct card based on actual database state

    print(
      '🔍 _buildTopCard: _hasApplication = $_hasApplication, _applicationStatus = $_applicationStatus',
    );

    if (_hasApplication) {
      // Application exists in database - show "Your Application Status" card
      print('✅ Showing Application Status card');
      return _buildApplicationStatusCard(context);
    } else {
      // No application in database - show "Complete Profile" card
      print('✅ Showing Complete Profile card');
      return _buildCompleteProfileCard(context);
    }
  }

  // 🔹 Build Application Status Card
  Widget _buildApplicationStatusCard(BuildContext context) {
    // Determine status label and color
    String statusLabel;
    Color statusColor;
    Color statusBgColor;

    switch (_applicationStatus) {
      case 'PENDING':
        statusLabel = 'Pending';
        statusColor = const Color(0xFF856404);
        statusBgColor = const Color(0xFFFFF3CD);
        break;
      case 'Pending-Block':
        statusLabel = 'Block Review';
        statusColor = const Color(0xFF856404);
        statusBgColor = const Color(0xFFFFF3CD);
        break;
      case 'Pending-District':
        statusLabel = 'District Review';
        statusColor = const Color(0xFF856404);
        statusBgColor = const Color(0xFFFFF3CD);
        break;
      case 'Pending-State':
        statusLabel = 'State Review';
        statusColor = const Color(0xFF856404);
        statusBgColor = const Color(0xFFFFF3CD);
        break;
      case 'Approved':
        statusLabel = 'Approved';
        statusColor = const Color(0xFF155724);
        statusBgColor = const Color(0xFFD4EDDA);
        break;
      case 'Rejected':
        statusLabel = 'Rejected';
        statusColor = const Color(0xFF721C24);
        statusBgColor = const Color(0xFFF8D7DA);
        break;
      default:
        statusLabel = 'In Review';
        statusColor = const Color(0xFF856404);
        statusBgColor = const Color(0xFFFFF3CD);
    }

    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your Application Status',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your application is under review. Tap to see status updates.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      // Navigate to Application Status screen
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ApplicationStatusScreen(),
                        ),
                      );
                      // Refresh dashboard when returning
                      _loadDashboard();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'View Status',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.pending_actions,
                size: 70,
                color: Color(0xFFFFA726),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Build Complete Profile Card (for users without application)
  Widget _buildCompleteProfileCard(BuildContext context) {
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
                    'Complete your profile to submit your membership application.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      print('🟢 COMPLETE PROFILE BUTTON CLICKED');
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PersonalDetailsForm(userData: widget.userData),
                        ),
                      );
                      // Refresh dashboard when returning
                      if (result == true && mounted) {
                        _loadDashboard();
                        _loadProfileCompletion();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Complete Profile',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                'https://img.icons8.com/fluency/96/briefcase.png',
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.business_center,
                    size: 60,
                    color: Color(0xFF00BCD4),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOldProfileCard(BuildContext context) {
    if (_applicationStatus == 'NONE') {
      // No application submitted - show "Complete Your Profile"
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
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_profileCompletion% completed',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
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
                                PersonalDetailsForm(userData: widget.userData),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Complete Profile',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.search, size: 60, color: Color(0xFF00BCD4)),
            ],
          ),
        ),
      );
    } else {
      // Application exists - show "Your Application Status"
      // Determine status label and color
      String statusLabel;
      Color statusColor;
      Color statusBgColor;

      switch (_applicationStatus) {
        case 'PENDING':
          statusLabel = 'Pending';
          statusColor = const Color(0xFF856404);
          statusBgColor = const Color(0xFFFFF3CD);
          break;
        case 'Pending-Block':
          statusLabel = 'Block Review';
          statusColor = const Color(0xFF856404);
          statusBgColor = const Color(0xFFFFF3CD);
          break;
        case 'Pending-District':
          statusLabel = 'District Review';
          statusColor = const Color(0xFF856404);
          statusBgColor = const Color(0xFFFFF3CD);
          break;
        case 'Pending-State':
          statusLabel = 'State Review';
          statusColor = const Color(0xFF856404);
          statusBgColor = const Color(0xFFFFF3CD);
          break;
        case 'Approved':
          statusLabel = 'Approved';
          statusColor = const Color(0xFF155724);
          statusBgColor = const Color(0xFFD4EDDA);
          break;
        case 'Rejected':
          statusLabel = 'Rejected';
          statusColor = const Color(0xFF721C24);
          statusBgColor = const Color(0xFFF8D7DA);
          break;
        default:
          statusLabel = 'In Review';
          statusColor = const Color(0xFF856404);
          statusBgColor = const Color(0xFFFFF3CD);
      }

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
                      'Your Application Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(color: statusColor, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Your application is under review. Tap to see status updates.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        // Navigate to Application Status screen
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ApplicationStatusScreen(),
                          ),
                        );
                        // Refresh dashboard when returning
                        _loadDashboard();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'View Status',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.pending_actions,
                size: 60,
                color: Color(0xFFFFA726),
              ),
            ],
          ),
        ),
      );
    }
  }
}
