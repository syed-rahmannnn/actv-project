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
    List<Widget> details = [];

    // Helper function to check if value is valid
    bool hasValue(dynamic value) {
      if (value == null) return false;
      final str = value.toString().trim();
      return str.isNotEmpty && str.toLowerCase() != 'n/a' && str != 'null';
    }

    // Only add fields that have actual data
    if (hasValue(personal['full_name'])) {
      details.add(
        _buildDetailRow('Full Name', personal['full_name'].toString()),
      );
    }
    if (hasValue(personal['date_of_birth'])) {
      details.add(
        _buildDetailRow('Date of Birth', personal['date_of_birth'].toString()),
      );
    }
    if (hasValue(personal['gender'])) {
      details.add(_buildDetailRow('Gender', personal['gender'].toString()));
    }
    if (hasValue(personal['email'])) {
      details.add(_buildDetailRow('Email', personal['email'].toString()));
    }
    if (hasValue(personal['phone'])) {
      details.add(_buildDetailRow('Phone', personal['phone'].toString()));
    }
    if (hasValue(personal['address'])) {
      details.add(_buildDetailRow('Address', personal['address'].toString()));
    }
    if (hasValue(personal['state'])) {
      details.add(_buildDetailRow('State', personal['state'].toString()));
    }
    if (hasValue(personal['district'])) {
      details.add(_buildDetailRow('District', personal['district'].toString()));
    }
    if (hasValue(personal['block'])) {
      details.add(_buildDetailRow('Block', personal['block'].toString()));
    }
    if (hasValue(personal['pincode'])) {
      details.add(_buildDetailRow('Pincode', personal['pincode'].toString()));
    }
    if (hasValue(personal['category'])) {
      details.add(_buildDetailRow('Category', personal['category'].toString()));
    }
    if (hasValue(personal['marital_status'])) {
      details.add(
        _buildDetailRow(
          'Marital Status',
          personal['marital_status'].toString(),
        ),
      );
    }
    if (hasValue(personal['education'])) {
      details.add(
        _buildDetailRow('Education', personal['education'].toString()),
      );
    }
    if (hasValue(personal['occupation'])) {
      details.add(
        _buildDetailRow('Occupation', personal['occupation'].toString()),
      );
    }

    return details;
  }

  List<Widget> _buildBusinessDetails() {
    final business = _memberData['business_information'] ?? {};
    List<Widget> details = [];

    // Helper function to check if value is valid
    bool hasValue(dynamic value) {
      if (value == null) return false;
      final str = value.toString().trim();
      return str.isNotEmpty && str.toLowerCase() != 'n/a' && str != 'null';
    }

    // Show Doing Business status
    if (business['doing_business'] != null) {
      details.add(
        _buildDetailRow(
          'Doing Business',
          business['doing_business'] == true ? 'Yes' : 'No',
        ),
      );
    }

    // Only add fields that have actual data
    if (hasValue(business['organization_name'])) {
      details.add(
        _buildDetailRow(
          'Organization Name',
          business['organization_name'].toString(),
        ),
      );
    }
    if (hasValue(business['constitution_type'])) {
      details.add(
        _buildDetailRow(
          'Constitution Type',
          business['constitution_type'].toString(),
        ),
      );
    }
    if (hasValue(business['business_type'])) {
      details.add(
        _buildDetailRow('Business Type', business['business_type'].toString()),
      );
    }
    if (hasValue(business['activities'])) {
      details.add(
        _buildDetailRow('Activities', business['activities'].toString()),
      );
    }
    if (hasValue(business['commencement_year'])) {
      details.add(
        _buildDetailRow(
          'Commencement Year',
          business['commencement_year'].toString(),
        ),
      );
    }
    if (hasValue(business['number_of_employees'])) {
      details.add(
        _buildDetailRow(
          'Number of Employees',
          business['number_of_employees'].toString(),
        ),
      );
    }
    if (business['member_of_other_chamber'] != null) {
      details.add(
        _buildDetailRow(
          'Member of Other Chamber',
          business['member_of_other_chamber'] == true ? 'Yes' : 'No',
        ),
      );
    }
    if (hasValue(business['other_chamber'])) {
      details.add(
        _buildDetailRow(
          'Other Chamber Details',
          business['other_chamber'].toString(),
        ),
      );
    }

    // Handle govt registrations if it's a list and has data
    if (business['govt_registrations'] is List &&
        (business['govt_registrations'] as List).isNotEmpty) {
      final registrations = (business['govt_registrations'] as List)
          .where((item) => item != null && item.toString().trim().isNotEmpty)
          .join(', ');
      if (registrations.isNotEmpty) {
        details.add(_buildDetailRow('Govt Registrations', registrations));
      }
    }

    return details;
  }

  List<Widget> _buildFinancialDetails() {
    final financial = _memberData['financial_information'] ?? {};
    List<Widget> details = [];

    // Helper function to check if value is valid
    bool hasValue(dynamic value) {
      if (value == null) return false;
      final str = value.toString().trim();
      return str.isNotEmpty && str.toLowerCase() != 'n/a' && str != 'null';
    }

    // Only add fields that have actual data
    if (hasValue(financial['pan_number'])) {
      details.add(
        _buildDetailRow('PAN Number', financial['pan_number'].toString()),
      );
    }
    if (hasValue(financial['gst_number'])) {
      details.add(
        _buildDetailRow('GST Number', financial['gst_number'].toString()),
      );
    }
    if (hasValue(financial['udyam_number'])) {
      details.add(
        _buildDetailRow('Udyam Number', financial['udyam_number'].toString()),
      );
    }
    if (financial['filed_itr'] != null) {
      details.add(
        _buildDetailRow(
          'Filed ITR',
          financial['filed_itr'] == true ? 'Yes' : 'No',
        ),
      );
    }
    if (hasValue(financial['itr_years'])) {
      details.add(
        _buildDetailRow('ITR Years', financial['itr_years'].toString()),
      );
    }
    if (hasValue(financial['turnover_range'])) {
      details.add(
        _buildDetailRow(
          'Turnover Range',
          financial['turnover_range'].toString(),
        ),
      );
    }
    if (hasValue(financial['fy_2021'])) {
      details.add(_buildDetailRow('FY 2021', financial['fy_2021'].toString()));
    }
    if (hasValue(financial['fy_2020'])) {
      details.add(_buildDetailRow('FY 2020', financial['fy_2020'].toString()));
    }
    if (hasValue(financial['fy_2019'])) {
      details.add(_buildDetailRow('FY 2019', financial['fy_2019'].toString()));
    }
    if (financial['govt_scheme_benefit'] != null) {
      details.add(
        _buildDetailRow(
          'Govt Scheme Benefit',
          financial['govt_scheme_benefit'] == true ? 'Yes' : 'No',
        ),
      );
    }
    if (hasValue(financial['scheme_1'])) {
      details.add(
        _buildDetailRow('Scheme 1', financial['scheme_1'].toString()),
      );
    }
    if (hasValue(financial['scheme_2'])) {
      details.add(
        _buildDetailRow('Scheme 2', financial['scheme_2'].toString()),
      );
    }
    if (hasValue(financial['scheme_3'])) {
      details.add(
        _buildDetailRow('Scheme 3', financial['scheme_3'].toString()),
      );
    }

    return details;
  }

  List<Widget> _buildDeclarationDetails() {
    final declaration = _memberData['declaration'] ?? {};
    List<Widget> details = [];

    // Helper function to check if value is valid
    bool hasValue(dynamic value) {
      if (value == null) return false;
      final str = value.toString().trim();
      return str.isNotEmpty && str.toLowerCase() != 'n/a' && str != 'null';
    }

    // Only add fields that have actual data
    if (declaration['agree_terms'] != null) {
      details.add(
        _buildDetailRow(
          'Agreed to Terms',
          declaration['agree_terms'] == true ? 'Yes' : 'No',
        ),
      );
    }
    if (hasValue(declaration['submitted_at'])) {
      details.add(
        _buildDetailRow('Submitted At', declaration['submitted_at'].toString()),
      );
    }

    return details;
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
                                // Demographic Details
                                _buildExpandableCard(
                                  title: 'Demographic Details',
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
