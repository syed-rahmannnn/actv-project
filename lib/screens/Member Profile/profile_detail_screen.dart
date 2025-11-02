import 'package:flutter/material.dart';
import 'package:activ/services/auth_service.dart';
import 'package:activ/services/api_service.dart';

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  bool personalExpanded = true; // Start expanded
  bool businessExpanded = false;
  bool financialExpanded = false;
  bool declarationExpanded = false;

  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadMemberProfile();
  }

  Future<Map<String, dynamic>?> _loadMemberFromBackend() async {
    try {
      // Get user data from AuthService instead of Firebase
      final userData = await AuthService.getUserData();
      if (userData == null) return null;

      final email = userData['email'] ?? userData['member']?['email'];
      if (email == null || email.toString().trim().isEmpty) return userData;

      final res = await ApiService.getMemberByEmail(email);
      if (res['success'] == true && res['data'] != null) {
        // Normalize to structure similar to previous userData for minimal UI changes
        final member = Map<String, dynamic>.from(res['data'] as Map);
        return {
          'email': email,
          'fullName': member['fullName'],
          'phoneNumber': member['phoneNumber'],
          'dateOfBirth': member['dateOfBirth'],
          'registrationForm': {
            'fullName': member['fullName'],
            'phoneNumber': member['phoneNumber'],
            'dateOfBirth': member['dateOfBirth'],
            'state': member['state'],
            'district': member['district'],
            'block': member['block'],
            'city': member['city'],
          },
        };
      }
      return await AuthService.getUserData();
    } catch (_) {
      return await AuthService.getUserData();
    }
  }

  Future<Map<String, dynamic>?> _loadMemberProfile() async {
    try {
      final localUser = await AuthService.getUserData();
      if (localUser == null) return null;

      final email = localUser['email'] ?? localUser['member']?['email'];
      if (email == null || email.toString().trim().isEmpty) return null;

      final memberRes = await ApiService.getMemberByEmail(email);
      if (memberRes['success'] == true && memberRes['data'] != null) {
        final member = Map<String, dynamic>.from(memberRes['data'] as Map);
        final memberId = member['memberId'] ?? member['id'] ?? member['_id'];
        if (memberId == null) {
          return {'member': member};
        }
        final profileRes = await ApiService.getMemberProfile(
          memberId.toString(),
        );
        if (profileRes['success'] == true) {
          return Map<String, dynamic>.from(profileRes['data'] as Map);
        }
        return {'member': member};
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Picture and Name
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!, width: 2),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/profile.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // User Name
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _loadMemberFromBackend(),
                      builder: (context, snapshot) {
                        final userData = snapshot.data;
                        final registrationForm =
                            userData?['registrationForm']
                                as Map<String, dynamic>?;
                        final name =
                            (registrationForm?['fullName'] ??
                                    userData?['fullName'] ??
                                    '')
                                as String;
                        return Text(
                          name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Personal & Demographic Details Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Section Header
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          personalExpanded = !personalExpanded;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Personal Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Icon(
                              personalExpanded
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_right,
                              color: Colors.grey[600],
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Personal Details Content
                    if (personalExpanded) ...[
                      const Divider(height: 1, color: Colors.grey),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: FutureBuilder<Map<String, dynamic>?>(
                          future: _profileFuture,
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              final data = snapshot.data!;
                              final member =
                                  data['member'] as Map<String, dynamic>?;

                              String s(dynamic v) =>
                                  (v == null || (v is String && v.isEmpty))
                                  ? '—'
                                  : v.toString();

                              return Column(
                                children: [
                                  _buildDetailRow(
                                    'Name',
                                    s(member?['fullName']),
                                  ),
                                  _buildDetailRow(
                                    'Phone Number',
                                    s(member?['phoneNumber']),
                                  ),
                                  _buildDetailRow(
                                    'Email ID',
                                    s(member?['email']),
                                  ),
                                  _buildDetailRow(
                                    'Date of Birth',
                                    s(_formatDate(member?['dateOfBirth'])),
                                  ),
                                  _buildDetailRow('State', s(member?['state'])),
                                  _buildDetailRow(
                                    'District',
                                    s(member?['district']),
                                  ),
                                  _buildDetailRow('Block', s(member?['block'])),
                                  _buildDetailRow('City', s(member?['city'])),
                                  _buildDetailRow(
                                    'Street Name',
                                    s(member?['streetName']),
                                  ),
                                  _buildDetailRow(
                                    'Educational Qualification',
                                    s(member?['educationalQualification']),
                                  ),
                                  _buildDetailRow(
                                    'Religion',
                                    s(member?['religion']),
                                  ),
                                  _buildDetailRow(
                                    'Social Category',
                                    s(member?['socialCategory']),
                                  ),
                                  _buildDetailRow(
                                    'Aadhaar Number',
                                    s(member?['aadhaarNumber']),
                                  ),
                                ],
                              );
                            }

                            // Default data when no user data is available (matching the image)
                            return const Center(
                              child: Text(
                                'No profile data found',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Business Information
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          businessExpanded = !businessExpanded;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Business Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Icon(
                              businessExpanded
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_right,
                              color: Colors.grey[600],
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (businessExpanded) ...[
                      const Divider(height: 1, color: Colors.grey),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: FutureBuilder<Map<String, dynamic>?>(
                          future: _profileFuture,
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              final data = snapshot.data!;
                              final business =
                                  data['businessInfo'] as Map<String, dynamic>?;

                              String s(dynamic v) =>
                                  (v == null || (v is String && v.isEmpty))
                                  ? '—'
                                  : v.toString();
                              String b(bool? v) =>
                                  v == null ? '—' : (v ? 'Yes' : 'No');
                              String listToString(List<dynamic>? v) =>
                                  (v == null || v.isEmpty) ? '—' : v.join(', ');

                              if (business == null) {
                                return const Center(
                                  child: Text(
                                    'No business information found',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                );
                              }

                              return Column(
                                children: [
                                  _buildDetailRow(
                                    'Doing Business',
                                    b(business['doingBusiness'] as bool?),
                                  ),
                                  _buildDetailRow(
                                    'Name of the Organization',
                                    s(business['organizationName']),
                                  ),
                                  _buildDetailRow(
                                    'Constitution of the Company',
                                    s(business['constitutionType']),
                                  ),
                                  _buildDetailRow(
                                    'Type of Business',
                                    s(business['businessType']),
                                  ),
                                  _buildDetailRow(
                                    'Business Activities',
                                    s(business['businessActivities']),
                                  ),
                                  _buildDetailRow(
                                    'Business Commencement Year',
                                    s(business['businessCommencementYear']),
                                  ),
                                  _buildDetailRow(
                                    'Number of Employees',
                                    s(business['numberOfEmployees']),
                                  ),
                                  _buildDetailRow(
                                    'Member of any other Chamber/Association',
                                    b(
                                      business['memberOfOtherChamber'] as bool?,
                                    ),
                                  ),
                                  if (business['memberOfOtherChamber'] == true)
                                    _buildDetailRow(
                                      'Name of Chamber/Association',
                                      s(business['otherChamber']),
                                    ),
                                  _buildDetailRow(
                                    'Registered with Govt. Organisations',
                                    listToString(
                                      (business['registeredWithGovtOrganization']
                                              as List?)
                                          ?.cast<dynamic>(),
                                    ),
                                  ),
                                ],
                              );
                            }
                            return const Center(
                              child: Text(
                                'Loading...',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Financial & Compliance
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          financialExpanded = !financialExpanded;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Financial & Compliance',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Icon(
                              financialExpanded
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_right,
                              color: Colors.grey[600],
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (financialExpanded) ...[
                      const Divider(height: 1, color: Colors.grey),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: FutureBuilder<Map<String, dynamic>?>(
                          future: _profileFuture,
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              final data = snapshot.data!;
                              final financial =
                                  data['financialInfo']
                                      as Map<String, dynamic>?;

                              String s(dynamic v) =>
                                  (v == null || (v is String && v.isEmpty))
                                  ? '—'
                                  : v.toString();
                              String b(bool? v) =>
                                  v == null ? '—' : (v ? 'Yes' : 'No');

                              if (financial == null) {
                                return const Center(
                                  child: Text(
                                    'No financial information found',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                );
                              }

                              return Column(
                                children: [
                                  _buildDetailRow(
                                    'PAN Number',
                                    s(financial['panNumber']),
                                  ),
                                  _buildDetailRow(
                                    'GST Number',
                                    s(financial['gstNumber']),
                                  ),
                                  _buildDetailRow(
                                    'Udyam Number',
                                    s(financial['udyamNumber']),
                                  ),
                                  _buildDetailRow(
                                    'Filed ITR',
                                    b(financial['filedITR'] as bool?),
                                  ),
                                  _buildDetailRow(
                                    'ITR Years',
                                    s(financial['itrYears']),
                                  ),
                                  _buildDetailRow(
                                    'Turnover Range',
                                    s(financial['turnoverRange']),
                                  ),
                                  _buildDetailRow(
                                    'FY 2021',
                                    s(financial['fy2021']),
                                  ),
                                  _buildDetailRow(
                                    'FY 2020',
                                    s(financial['fy2020']),
                                  ),
                                  _buildDetailRow(
                                    'FY 2019',
                                    s(financial['fy2019']),
                                  ),
                                  _buildDetailRow(
                                    'Govt Scheme Benefit',
                                    b(financial['govtSchemeBenefit'] as bool?),
                                  ),
                                  _buildDetailRow(
                                    'Scheme 1',
                                    s(financial['scheme1']),
                                  ),
                                  _buildDetailRow(
                                    'Scheme 2',
                                    s(financial['scheme2']),
                                  ),
                                  _buildDetailRow(
                                    'Scheme 3',
                                    s(financial['scheme3']),
                                  ),
                                ],
                              );
                            }
                            return const Center(
                              child: Text(
                                'Loading...',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Declaration
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          declarationExpanded = !declarationExpanded;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Declaration',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Icon(
                              declarationExpanded
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_right,
                              color: Colors.grey[600],
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (declarationExpanded) ...[
                      const Divider(height: 1, color: Colors.grey),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: FutureBuilder<Map<String, dynamic>?>(
                          future: _profileFuture,
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              final data = snapshot.data!;
                              final declaration =
                                  data['declaration'] as Map<String, dynamic>?;

                              String s(dynamic v) =>
                                  (v == null || (v is String && v.isEmpty))
                                  ? '—'
                                  : v.toString();
                              String b(bool? v) =>
                                  v == null ? '—' : (v ? 'Yes' : 'No');
                              String listToString(List<dynamic>? v) =>
                                  (v == null || v.isEmpty) ? '—' : v.join(', ');

                              if (declaration == null) {
                                return const Center(
                                  child: Text(
                                    'No declaration found',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                );
                              }

                              return Column(
                                children: [
                                  _buildDetailRow(
                                    'Sister Concerns',
                                    s(declaration['sisterConcerns']),
                                  ),
                                  _buildDetailRow(
                                    'Company Names',
                                    listToString(
                                      (declaration['companyNames'] as List?)
                                          ?.cast<dynamic>(),
                                    ),
                                  ),
                                  _buildDetailRow(
                                    'Show One Field Per Name',
                                    b(
                                      declaration['showOneFieldPerName']
                                          as bool?,
                                    ),
                                  ),
                                  _buildDetailRow(
                                    'Agree To Declaration',
                                    b(
                                      declaration['agreeToDeclaration']
                                          as bool?,
                                    ),
                                  ),
                                  _buildDetailRow(
                                    'Profile Completed',
                                    b(declaration['profileCompleted'] as bool?),
                                  ),
                                  _buildDetailRow(
                                    'Submission Date',
                                    s(
                                      _formatDate(
                                        declaration['submissionDate'],
                                      ),
                                    ),
                                  ),
                                  _buildDetailRow(
                                    'Status',
                                    s(declaration['status']),
                                  ),
                                ],
                              );
                            }
                            return const Center(
                              child: Text(
                                'Loading...',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String? _formatDate(dynamic date) {
    if (date == null) return null;

    try {
      // Handle DateTime directly
      if (date is DateTime) {
        final d = date;
        return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      }

      // Handle numeric timestamps (ms or sec)
      if (date is num) {
        final millis = date > 1000000000000
            ? date.toInt()
            : (date.toInt() * 1000);
        final d = DateTime.fromMillisecondsSinceEpoch(
          millis,
          isUtc: true,
        ).toLocal();
        return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
      }

      // Handle strings in various common formats
      if (date is String) {
        final raw = date.trim();
        if (raw.isEmpty) return null;

        // If already in dd/MM/yyyy, return as-is
        final ddmmyyyySlash = RegExp(r'^\d{2}/\d{2}/\d{4}$');
        if (ddmmyyyySlash.hasMatch(raw)) return raw;

        // Convert dd-MM-yyyy to dd/MM/yyyy
        final ddmmyyyyDash = RegExp(r'^(\d{2})-(\d{2})-(\d{4})$');
        final dashMatch = ddmmyyyyDash.firstMatch(raw);
        if (dashMatch != null) {
          final d = dashMatch.group(1)!;
          final m = dashMatch.group(2)!;
          final y = dashMatch.group(3)!;
          return '$d/$m/$y';
        }

        // Parse ISO-like formats (e.g., yyyy-MM-dd or ISO timestamps)
        try {
          final parsed = DateTime.parse(raw);
          return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
        } catch (_) {
          // Fallback: return the original string if parsing fails
          return raw;
        }
      }

      // Fallback for unexpected types
      return null;
    } catch (_) {
      return null;
    }
  }
}
