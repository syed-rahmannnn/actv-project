import 'package:flutter/material.dart';
import '../../services/member_service.dart';
import '../../services/browse_members_service.dart';

class MyProfileScreen extends StatefulWidget {
  final String memberName;
  final String profileImageUrl;
  final String?
  memberId; // Add memberId - if provided, fetch that member's data

  const MyProfileScreen({
    super.key,
    required this.memberName,
    this.profileImageUrl = 'assets/images/profile.png',
    this.memberId, // Optional memberId
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
    print('📛 Member Name from widget: ${widget.memberName}');
    print('🆔 Member ID from widget: ${widget.memberId}');
    print('🔍 Has memberId? ${widget.memberId != null}');
    print('🔄 Fetching data...');

    try {
      Map<String, dynamic>? data;

      if (widget.memberId != null && widget.memberId!.isNotEmpty) {
        // Fetch specific member's data
        print('✅ Fetching SPECIFIC member data for ID: ${widget.memberId}');
        data = await BrowseMembersService.getMemberById(widget.memberId!);
        print(
          '📦 Response from BrowseMembersService: Success=${data['success']}',
        );
      } else {
        // Fetch logged-in user's data
        print('👤 No memberId provided - Fetching LOGGED-IN user data');
        data = await MemberService.getMemberDetails();
        print('📦 Response from MemberService: Success=${data?['success']}');
      }

      print('📊 Full API Response: $data');

      if (data != null && data['success'] == true) {
        final memberData = data['data'];
        if (memberData != null) {
          setState(() {
            _memberData = memberData;
            _isLoading = false;
          });
          print('✅ Member data loaded successfully');
          print(
            '📊 Business Info Keys: ${memberData['business_information']?.keys.toList()}',
          );
          print('📊 Business Data: ${memberData['business_information']}');
          print(
            '📊 Financial Info Keys: ${memberData['financial_information']?.keys.toList()}',
          );
          print('📊 Financial Data: ${memberData['financial_information']}');
          print(
            '📊 Declaration Keys: ${memberData['declaration']?.keys.toList()}',
          );
          print('📊 Declaration Data: ${memberData['declaration']}');
        } else {
          setState(() => _isLoading = false);
          print('❌ No member data in response');
        }
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
        (business['organization_name']?.toString() ?? '').isEmpty
            ? ''
            : business['organization_name'].toString(),
      ),
      _buildDetailRow(
        'Constitution Type',
        (business['constitution_type']?.toString() ?? '').isEmpty
            ? ''
            : business['constitution_type'].toString(),
      ),
      _buildDetailRow(
        'Business Type',
        (business['business_type']?.toString() ?? '').isEmpty
            ? ''
            : business['business_type'].toString(),
      ),
      _buildDetailRow(
        'Activities',
        (business['activities']?.toString() ?? '').isEmpty
            ? ''
            : business['activities'].toString(),
      ),
      _buildDetailRow(
        'Commencement Year',
        (business['commencement_year']?.toString() ?? '').isEmpty
            ? ''
            : business['commencement_year'].toString(),
      ),
      _buildDetailRow(
        'Number of Employees',
        (business['number_of_employees']?.toString() ?? '').isEmpty
            ? ''
            : business['number_of_employees'].toString(),
      ),
      _buildDetailRow(
        'Member of Other Chamber',
        business['member_of_other_chamber'] == true ? 'Yes' : 'No',
      ),
      _buildDetailRow(
        'Other Chamber Details',
        (business['other_chamber']?.toString() ?? '').isEmpty
            ? ''
            : business['other_chamber'].toString(),
      ),
      _buildDetailRow(
        'Govt Registrations',
        (business['govt_registrations'] as List?)?.join(', ') ?? '',
      ),
    ];
  }

  List<Widget> _buildFinancialDetails() {
    final financial = _memberData['financial_information'] ?? {};
    return [
      _buildDetailRow(
        'PAN Number',
        (financial['pan_number']?.toString() ?? '').isEmpty
            ? ''
            : financial['pan_number'].toString(),
      ),
      _buildDetailRow(
        'GST Number',
        (financial['gst_number']?.toString() ?? '').isEmpty
            ? ''
            : financial['gst_number'].toString(),
      ),
      _buildDetailRow(
        'Udyam Number',
        (financial['udyam_number']?.toString() ?? '').isEmpty
            ? ''
            : financial['udyam_number'].toString(),
      ),
      _buildDetailRow(
        'Filed ITR',
        financial['filed_itr'] == true ? 'Yes' : 'No',
      ),
      _buildDetailRow(
        'ITR Years',
        (financial['itr_years']?.toString() ?? '').isEmpty
            ? ''
            : financial['itr_years'].toString(),
      ),
      _buildDetailRow(
        'Turnover Range',
        (financial['turnover_range']?.toString() ?? '').isEmpty
            ? ''
            : financial['turnover_range'].toString(),
      ),
      _buildDetailRow(
        'FY 2021',
        (financial['fy_2021']?.toString() ?? '').isEmpty
            ? ''
            : financial['fy_2021'].toString(),
      ),
      _buildDetailRow(
        'FY 2020',
        (financial['fy_2020']?.toString() ?? '').isEmpty
            ? ''
            : financial['fy_2020'].toString(),
      ),
      _buildDetailRow(
        'FY 2019',
        (financial['fy_2019']?.toString() ?? '').isEmpty
            ? ''
            : financial['fy_2019'].toString(),
      ),
      _buildDetailRow(
        'Govt Scheme Benefit',
        financial['govt_scheme_benefit'] == true ? 'Yes' : 'No',
      ),
      _buildDetailRow(
        'Scheme 1',
        (financial['scheme_1']?.toString() ?? '').isEmpty
            ? ''
            : financial['scheme_1'].toString(),
      ),
      _buildDetailRow(
        'Scheme 2',
        (financial['scheme_2']?.toString() ?? '').isEmpty
            ? ''
            : financial['scheme_2'].toString(),
      ),
      _buildDetailRow(
        'Scheme 3',
        (financial['scheme_3']?.toString() ?? '').isEmpty
            ? ''
            : financial['scheme_3'].toString(),
      ),
    ];
  }

  List<Widget> _buildDeclarationDetails() {
    final declaration = _memberData['declaration'] ?? {};
    return [
      _buildDetailRow(
        'Agreed to Terms',
        declaration['agree_terms'] == true ? 'Yes' : 'No',
      ),
      _buildDetailRow(
        'Submitted At',
        declaration['submitted_at']?.toString() ?? 'N/A',
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
    // Show "Not Provided" for empty strings, "N/A" for null or "N/A"
    final displayValue = value.isEmpty ? 'Not Provided' : value;

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
              displayValue,
              style: TextStyle(
                fontSize: 14,
                color: displayValue == 'Not Provided' || displayValue == 'N/A'
                    ? Colors.grey[500]
                    : const Color(0xFF202124),
                fontWeight: FontWeight.w500,
                fontStyle:
                    displayValue == 'Not Provided' || displayValue == 'N/A'
                    ? FontStyle.italic
                    : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
