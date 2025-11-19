import 'package:flutter/material.dart';
import '../../services/member_service.dart';

class MyProfileScreen extends StatefulWidget {
  final String memberName;
  final String profileImageUrl;

  const MyProfileScreen({
    super.key,
    required this.memberName,
    this.profileImageUrl = 'assets/images/profile.png',
  });

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  bool _isPersonalExpanded = false;
  bool _isBusinessExpanded = false;
  bool _isFinancialExpanded = false;
  bool _isDeclarationExpanded = false;
  bool _isLoading = true;

  Map<String, dynamic> _memberData = {};

  @override
  void initState() {
    super.initState();
    _fetchMemberDetails();
  }

  Future<void> _fetchMemberDetails() async {
    setState(() => _isLoading = true);

    print('=== MY PROFILE SCREEN DEBUG ===');
    print('Member Name: ${widget.memberName}');
    print('🔄 Fetching data dynamically from session...');

    try {
      // Fetch data dynamically - no email parameter needed!
      final data = await MemberService.getMemberDetails();
      print('API Response: $data');

      if (data != null && data['success'] == true) {
        setState(() {
          _memberData = data['data'];
          _isLoading = false;
        });
        print('✅ Member data loaded successfully');
      } else {
        setState(() => _isLoading = false);
        print('❌ Failed to load: data=$data');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                data?['message'] ??
                    'Unable to load profile. Please login again.',
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error loading member details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  List<Widget> _buildPersonalDetails() {
    final personal = _memberData['personal_and_demographic_details'] ?? {};
    return [
      _buildDetailRow('Full Name', personal['full_name'] ?? 'N/A'),
      _buildDetailRow('Date of Birth', personal['date_of_birth'] ?? 'N/A'),
      _buildDetailRow('Gender', personal['gender'] ?? 'N/A'),
      _buildDetailRow('Email', personal['email'] ?? 'N/A'),
      _buildDetailRow('Phone', personal['phone'] ?? 'N/A'),
      _buildDetailRow('Address', personal['address'] ?? 'N/A'),
      _buildDetailRow('State', personal['state'] ?? 'N/A'),
      _buildDetailRow('District', personal['district'] ?? 'N/A'),
      _buildDetailRow('Block', personal['block'] ?? 'N/A'),
      _buildDetailRow('Pincode', personal['pincode'] ?? 'N/A'),
      _buildDetailRow('Category', personal['category'] ?? 'N/A'),
      _buildDetailRow('Marital Status', personal['marital_status'] ?? 'N/A'),
      _buildDetailRow('Education', personal['education'] ?? 'N/A'),
      _buildDetailRow('Occupation', personal['occupation'] ?? 'N/A'),
    ];
  }

  List<Widget> _buildBusinessDetails() {
    final business = _memberData['business_information'] ?? {};
    return [
      _buildDetailRow(
        'Doing Business',
        business['doing_business'] == true ? 'Yes' : 'No',
      ),
      _buildDetailRow(
        'Organization Name',
        business['organization_name'] ?? 'N/A',
      ),
      _buildDetailRow(
        'Constitution Type',
        business['constitution_type'] ?? 'N/A',
      ),
      _buildDetailRow(
        'Business Types',
        (business['business_types'] as List?)?.join(', ') ?? 'N/A',
      ),
      _buildDetailRow('Activities', business['activities'] ?? 'N/A'),
      _buildDetailRow(
        'Commencement Year',
        business['commencement_year'] ?? 'N/A',
      ),
      _buildDetailRow(
        'Employee Count',
        business['employee_count']?.toString() ?? 'N/A',
      ),
      _buildDetailRow(
        'Chamber Membership',
        business['chamber_membership'] == true ? 'Yes' : 'No',
      ),
      _buildDetailRow('Chamber Details', business['chamber_details'] ?? 'N/A'),
      _buildDetailRow(
        'Govt Registrations',
        (business['govt_registrations'] as List?)?.join(', ') ?? 'N/A',
      ),
    ];
  }

  List<Widget> _buildFinancialDetails() {
    final financial = _memberData['financial_and_compliance'] ?? {};
    final turnover = financial['turnover_last_3_years'] ?? {};
    return [
      _buildDetailRow('PAN Number', financial['pan_number'] ?? 'N/A'),
      _buildDetailRow('GST Number', financial['gst_number'] ?? 'N/A'),
      _buildDetailRow('Udyam Number', financial['udyam_number'] ?? 'N/A'),
      _buildDetailRow(
        'IT Returns Filed',
        financial['it_returns_filed'] == true ? 'Yes' : 'No',
      ),
      _buildDetailRow('ITR Years', financial['itr_years']?.toString() ?? 'N/A'),
      _buildDetailRow('Turnover Range', financial['turnover_range'] ?? 'N/A'),
      _buildDetailRow('Turnover 2024-25', turnover['year_2024_25'] ?? 'N/A'),
      _buildDetailRow('Turnover 2023-24', turnover['year_2023_24'] ?? 'N/A'),
      _buildDetailRow('Turnover 2022-23', turnover['year_2022_23'] ?? 'N/A'),
      _buildDetailRow(
        'Govt Schemes Benefitted',
        financial['govt_schemes_benefitted'] == true ? 'Yes' : 'No',
      ),
      _buildDetailRow(
        'Govt Scheme List',
        (financial['govt_scheme_list'] as List?)?.join(', ') ?? 'N/A',
      ),
    ];
  }

  List<Widget> _buildDeclarationDetails() {
    final declaration = _memberData['declaration'] ?? {};
    return [
      _buildDetailRow(
        'Sister Concerns Count',
        declaration['sister_concerns_count']?.toString() ?? 'N/A',
      ),
      _buildDetailRow(
        'Company Names',
        (declaration['company_names'] as List?)?.join(', ') ?? 'N/A',
      ),
      _buildDetailRow(
        'Confirmation',
        declaration['confirmation'] == true ? 'Yes' : 'No',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              color: Colors.white,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.black,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Expanded(
                    child: Center(
                      child: const Text(
                        'My profile',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF202124),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance the back button
                ],
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 32),

                          // Profile Picture
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 47,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.black,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Name
                          Text(
                            _memberData['personal_and_demographic_details']?['full_name'] ??
                                widget.memberName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF202124),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Expandable Sections Container
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                // Personal & Demographic Details
                                _buildExpandableCard(
                                  title: 'Personal & Demographic Details',
                                  isExpanded: _isPersonalExpanded,
                                  onTap: () {
                                    setState(() {
                                      _isPersonalExpanded =
                                          !_isPersonalExpanded;
                                    });
                                  },
                                  children: _buildPersonalDetails(),
                                ),

                                const SizedBox(height: 16),

                                // Business Information
                                _buildExpandableCard(
                                  title: 'Business Information',
                                  isExpanded: _isBusinessExpanded,
                                  onTap: () {
                                    setState(() {
                                      _isBusinessExpanded =
                                          !_isBusinessExpanded;
                                    });
                                  },
                                  children: _buildBusinessDetails(),
                                ),

                                const SizedBox(height: 16),

                                // Financial & Compliance
                                _buildExpandableCard(
                                  title: 'Financial & Compliance',
                                  isExpanded: _isFinancialExpanded,
                                  onTap: () {
                                    setState(() {
                                      _isFinancialExpanded =
                                          !_isFinancialExpanded;
                                    });
                                  },
                                  children: _buildFinancialDetails(),
                                ),

                                const SizedBox(height: 16),

                                // Declaration
                                _buildExpandableCard(
                                  title: 'Declaration',
                                  isExpanded: _isDeclarationExpanded,
                                  onTap: () {
                                    setState(() {
                                      _isDeclarationExpanded =
                                          !_isDeclarationExpanded;
                                    });
                                  },
                                  children: _buildDeclarationDetails(),
                                ),

                                const SizedBox(height: 24),

                                // Logout Button
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE0E0E0),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Logout',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.red,
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios,
                                        color: Colors.red,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 32),
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
    );
  }

  Widget _buildExpandableCard({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required List<Widget> children,
  }) {
    return Container(
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
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF202124),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.black,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(children: children),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF202124),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
