import 'package:flutter/material.dart';
import '../../services/browse_members_service.dart';

class ViewMemberScreen extends StatefulWidget {
  final String memberId;
  final String memberName;

  const ViewMemberScreen({
    super.key,
    required this.memberId,
    required this.memberName,
  });

  @override
  State<ViewMemberScreen> createState() => _ViewMemberScreenState();
}

class _ViewMemberScreenState extends State<ViewMemberScreen> {
  Map<String, dynamic>? memberData;
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadMemberProfile();
  }

  Future<void> _loadMemberProfile() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      print('🔍 Loading member profile for ID: ${widget.memberId}');

      // Fetch member details from API
      final response = await BrowseMembersService.getMemberById(
        widget.memberId,
      );

      print('📦 API Response: $response');

      if (response['success'] == true && response['data'] != null) {
        print('✅ Member data loaded successfully');
        setState(() {
          memberData = response['data'];
          isLoading = false;
        });
      } else {
        final errorMsg = response['message'] ?? 'Failed to load member profile';
        print('❌ API returned error: $errorMsg');
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ Error loading member profile: $e');
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF202124)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.memberName,
          style: const TextStyle(
            color: Color(0xFF202124),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load profile',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadMemberProfile,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : memberData == null
          ? const Center(child: Text('No data available'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header Card
                  _buildProfileHeader(),
                  const SizedBox(height: 16),

                  // Personal Details
                  _buildSectionCard(
                    title: 'Personal Details',
                    icon: Icons.person_outline,
                    children: [
                      _buildDetailRow('Full Name', memberData!['personal_and_demographic_details']?['full_name'] ?? 'N/A'),
                      _buildDetailRow('Email', memberData!['personal_and_demographic_details']?['email'] ?? 'N/A'),
                      _buildDetailRow('Phone', memberData!['personal_and_demographic_details']?['phone'] ?? 'N/A'),
                      _buildDetailRow(
                        'Date of Birth',
                        memberData!['personal_and_demographic_details']?['date_of_birth'] ?? 'N/A',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Location Details
                  _buildSectionCard(
                    title: 'Location',
                    icon: Icons.location_on_outlined,
                    children: [
                      _buildDetailRow('State', memberData!['personal_and_demographic_details']?['state'] ?? 'N/A'),
                      _buildDetailRow('District', memberData!['personal_and_demographic_details']?['district'] ?? 'N/A'),
                      _buildDetailRow('Block', memberData!['personal_and_demographic_details']?['block'] ?? 'N/A'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Business Details (if available)
                  if (memberData!['business_information'] != null)
                    _buildSectionCard(
                      title: 'Business Information',
                      icon: Icons.business_outlined,
                      children: [
                        _buildDetailRow(
                          'Organization Name',
                          memberData!['business_information']?['organization_name'] ?? 'Not Provided',
                        ),
                        _buildDetailRow(
                          'Business Type',
                          memberData!['business_information']?['business_type'] ?? 'Not Provided',
                        ),
                        _buildDetailRow(
                          'Constitution Type',
                          memberData!['business_information']?['constitution_type'] ?? 'Not Provided',
                        ),
                        _buildDetailRow(
                          'Activities',
                          memberData!['business_information']?['activities'] ?? 'Not Provided',
                        ),
                        _buildDetailRow(
                          'Commencement Year',
                          memberData!['business_information']?['commencement_year'] ?? 'Not Provided',
                        ),
                      ],
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Profile Picture
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF4285F4).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (memberData!['personal_and_demographic_details']?['full_name'] ?? 'M').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4285F4),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Name and Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memberData!['personal_and_demographic_details']?['full_name'] ?? 'Member',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF202124),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
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
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
