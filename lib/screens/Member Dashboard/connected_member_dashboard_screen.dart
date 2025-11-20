import 'package:flutter/material.dart';
import '../../services/browse_members_service.dart';

class ConnectedMemberDashboardScreen extends StatefulWidget {
  final String memberId;
  final String memberName;

  const ConnectedMemberDashboardScreen({
    super.key,
    required this.memberId,
    required this.memberName,
  });

  @override
  State<ConnectedMemberDashboardScreen> createState() =>
      _ConnectedMemberDashboardScreenState();
}

class _ConnectedMemberDashboardScreenState
    extends State<ConnectedMemberDashboardScreen> {
  Map<String, dynamic>? memberData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadMemberDashboard();
  }

  Future<void> _loadMemberDashboard() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      print('🔍 Loading dashboard for member: ${widget.memberId}');

      final response = await BrowseMembersService.getMemberById(
        widget.memberId,
      );

      if (response['success'] == true && response['data'] != null) {
        print('✅ Member dashboard data loaded');
        setState(() {
          memberData = response['data'];
          isLoading = false;
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to load dashboard');
      }
    } catch (e) {
      print('❌ Error loading member dashboard: $e');
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF6A4C93), // Purple background like home
      body: SafeArea(
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : error != null
            ? _buildErrorView()
            : _buildDashboard(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'Failed to load dashboard',
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _loadMemberDashboard,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard() {
    final name = memberData!['personal_and_demographic_details']?['full_name'] ?? widget.memberName;
    final organization = memberData!['business_information']?['organization_name'] ?? '';

    return Column(
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 20),
              // Profile Picture
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6A4C93),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Welcome back, $name',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (organization.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  organization,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ],
          ),
        ),

        // Main Content
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
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 12),
                        Text(
                          'Search by location...',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Tax Exemption Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.description,
                            color: Color(0xFF4CAF50),
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Download Tax Exemption\nCertificate',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF202124),
                            ),
                          ),
                        ),
                        const Icon(Icons.download, color: Color(0xFF4CAF50)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Dashboard Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildDashboardCard(
                        icon: Icons.person_outline,
                        label: 'Profile',
                        color: const Color(0xFF2196F3),
                        onTap: () {
                          // Show profile details
                          _showProfileDetails();
                        },
                      ),
                      _buildDashboardCard(
                        icon: Icons.calendar_today,
                        label: 'Events',
                        color: const Color(0xFF2196F3),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Events feature coming soon'),
                            ),
                          );
                        },
                      ),
                      _buildDashboardCard(
                        icon: Icons.headset_mic,
                        label: 'Support',
                        color: const Color(0xFF2196F3),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Support feature coming soon'),
                            ),
                          );
                        },
                      ),
                      _buildDashboardCard(
                        icon: Icons.settings,
                        label: 'Settings',
                        color: const Color(0xFF2196F3),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Settings feature coming soon'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDashboardCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF202124),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileDetails() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: controller,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildProfileSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Profile Header
        Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF4285F4).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  memberData!['fullName']?.substring(0, 1).toUpperCase() ?? 'M',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4285F4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    memberData!['fullName'] ?? 'Member',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34A853).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Connected',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF34A853),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Personal Details
        _buildDetailSection(
          title: 'Personal Details',
          icon: Icons.person_outline,
          children: [
            _buildDetailRow('Full Name', memberData!['personal_and_demographic_details']?['full_name'] ?? 'N/A'),
            _buildDetailRow('Email', memberData!['personal_and_demographic_details']?['email'] ?? 'N/A'),
            _buildDetailRow('Phone', memberData!['personal_and_demographic_details']?['phone'] ?? 'N/A'),
            _buildDetailRow('Date of Birth', memberData!['personal_and_demographic_details']?['date_of_birth'] ?? 'N/A'),
            _buildDetailRow('Gender', memberData!['personal_and_demographic_details']?['gender'] ?? 'N/A'),
          ],
        ),
        const SizedBox(height: 20),

        // Location
        _buildDetailSection(
          title: 'Location',
          icon: Icons.location_on_outlined,
          children: [
            _buildDetailRow('State', memberData!['personal_and_demographic_details']?['state'] ?? 'N/A'),
            _buildDetailRow('District', memberData!['personal_and_demographic_details']?['district'] ?? 'N/A'),
            _buildDetailRow('Block', memberData!['personal_and_demographic_details']?['block'] ?? 'N/A'),
            if (memberData!['personal_and_demographic_details']?['city'] != null)
              _buildDetailRow('City', memberData!['personal_and_demographic_details']['city']),
          ],
        ),
        const SizedBox(height: 20),

        // Business Info
        if (memberData!['business_information'] != null)
          _buildDetailSection(
            title: 'Business Information',
            icon: Icons.business_outlined,
            children: [
              _buildDetailRow(
                'Organization',
                memberData!['business_information']['organization_name'] ?? 'N/A',
              ),
              if (memberData!['business_information']['business_type'] != null &&
                  memberData!['business_information']['business_type'].toString().isNotEmpty)
                _buildDetailRow(
                  'Business Type',
                  memberData!['business_information']['business_type'],
                ),
              if (memberData!['business_information']['commencement_year'] != null &&
                  memberData!['business_information']['commencement_year'].toString().isNotEmpty)
                _buildDetailRow(
                  'Since',
                  memberData!['business_information']['commencement_year'].toString(),
                ),
            ],
          ),
      ],
    );
  }

  Widget _buildDetailSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF4285F4), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF202124),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5F6368),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, color: Color(0xFF202124)),
            ),
          ),
        ],
      ),
    );
  }
}
