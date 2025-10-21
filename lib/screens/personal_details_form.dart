import 'package:flutter/material.dart';
import 'package:activ/services/api_service.dart';
import 'business_information_form.dart';

class PersonalDetailsForm extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PersonalDetailsForm({
    super.key,
    required this.userData,
  });

  @override
  State<PersonalDetailsForm> createState() => _PersonalDetailsFormState();
}

class _PersonalDetailsFormState extends State<PersonalDetailsForm> {
  Future<Map<String, dynamic>?> _loadMemberFromBackend() async {
    try {
      // Get email from userData instead of Firebase
      final email = widget.userData['email'] ?? widget.userData['member']?['email'];
      if (email == null) return widget.userData;
      
      // Get member details from backend
      final res = await ApiService.getMemberByEmail(email);
      if (res['success'] == true) {
        final member = Map<String, dynamic>.from(res['data'] as Map);
        
        return {
          'email': email,
          'memberId': member['_id'],
          'registrationForm': {
            'fullName': member['fullName'],
            'block': member['block'],
            'state': member['state'],
            'district': member['district'],
            'phoneNumber': member['phoneNumber'],
            'dateOfBirth': member['dateOfBirth'],
            'city': member['city'],
            // Include demographic fields from memberdetails (source of truth)
            'aadhaarNumber': member['aadhaarNumber'] ?? '',
            'streetName': member['streetName'] ?? '',
            'educationalQualification': member['educationalQualification'] ?? '',
            'religion': member['religion'] ?? '',
            'socialCategory': member['socialCategory'] ?? '',
          }
        };
      }
      return widget.userData;
    } catch (e) {
      debugPrint('Error loading member from backend: $e');
      return widget.userData;
    }
  }
  final _aadhaarController = TextEditingController();
  final _streetNameController = TextEditingController();
  final _educationController = TextEditingController();
  final _religionController = TextEditingController();
  String? _selectedSocialCategory;

  final List<String> _socialCategories = [
    'General',
    'OBC',
    'SC',
    'ST',
    'EWS',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    // Pre-fill with existing user data if available
    final registrationForm = widget.userData['registrationForm'];
    if (registrationForm != null) {
      _aadhaarController.text = registrationForm['aadhaarNumber'] ?? '';
      _streetNameController.text = registrationForm['streetName'] ?? '';
      _educationController.text = registrationForm['educationalQualification'] ?? '';
      _religionController.text = registrationForm['religion'] ?? '';
      _selectedSocialCategory = registrationForm['socialCategory'];
    }
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    _streetNameController.dispose();
    _educationController.dispose();
    _religionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FF),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                color: Colors.blue,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: const Center(
                  child: Text(
                    'ACTIV',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Title and Progress
                    const Text(
                      'Additional Details Form',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Member Registration',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Progress Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        bool isActive = index == 0;
                        return Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isActive ? Colors.blue : Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive ? Colors.white : Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            if (index < 3)
                              Container(
                                width: 40,
                                height: 2,
                                color: Colors.grey[300],
                              ),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Step 1 of 4',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Personal Details Section
    _buildSectionCard(
      'Personal details',
      [
        FutureBuilder<Map<String, dynamic>?>(
          future: _loadMemberFromBackend(),
          builder: (context, snapshot) {
            final data = snapshot.data;
            final form = (data?['registrationForm'] as Map<String, dynamic>?) ?? {};
            String s(dynamic v) => (v == null || (v is String && v.isEmpty)) ? '—' : v.toString();
            String fmtDate(dynamic v) {
              if (v == null) return '—';
              final raw = v.toString();
              final base = raw.contains('T') ? raw.split('T').first : raw;
              // Convert YYYY-MM-DD or YYYY/MM/DD -> DD-MM-YYYY
              if (base.contains('-')) {
                final parts = base.split('-');
                if (parts.length == 3 && parts[0].length == 4) {
                  return '${parts[2].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[0]}';
                }
                return base; // likely already DD-MM-YYYY
              }
              if (base.contains('/')) {
                final parts = base.split('/');
                if (parts.length == 3 && parts[0].length == 4) {
                  return '${parts[2].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[0]}';
                }
                if (parts.length == 3 && parts[2].length == 4) {
                  return '${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[2]}';
                }
              }
              return base;
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReadOnlyField('Name', s(form['fullName'])),
                _buildReadOnlyField('Block', s(form['block'])),
                _buildReadOnlyField('state', s(form['state'])),
                _buildReadOnlyField('District', s(form['district'])),
                _buildReadOnlyField('City', s(form['city'])),
                _buildReadOnlyField('Phone Number', s(form['phoneNumber'])),
                _buildReadOnlyField('Email ID', s(data?['email'])),
                _buildReadOnlyField('Date of Birth', fmtDate(form['dateOfBirth'])),
              ],
            );
          },
        ),
      ],
    ),
                    const SizedBox(height: 20),
                    
                    // Personal & Demographic Details Section
                    _buildSectionCard(
                      'Page 1 - Personal & Demographic Details',
                      [
                        _buildTextField('Aadhaar No. (Personal Identity No.)', _aadhaarController, 'Enter Aadhaar number'),
                        _buildTextField('Street Name', _streetNameController, 'Enter street name'),
                        _buildTextField('Educational Qualification', _educationController, 'Enter educational qualification'),
                        _buildTextField('Religion', _religionController, 'Enter religion'),
                        _buildDropdownField('Social Category', _selectedSocialCategory, _socialCategories, 'Select category'),
                      ],
                    ),
                    const SizedBox(height: 30),
                    
                    // Next Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _proceedToNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Next >',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String placeholder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: placeholder,
            filled: true,
            fillColor: Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropdownField(String label, String? selectedValue, List<String> options, String placeholder) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              hint: Text(
                placeholder,
                style: TextStyle(color: Colors.grey[600]),
              ),
              isExpanded: true,
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSocialCategory = newValue;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _proceedToNext() async {
    // Validate required fields
    if (_aadhaarController.text.isEmpty ||
        _streetNameController.text.isEmpty ||
        _educationController.text.isEmpty ||
        _religionController.text.isEmpty ||
        _selectedSocialCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Get member ID from backend data
      final backendData = await _loadMemberFromBackend();
      final memberId = backendData?['memberId'];
      
      if (memberId == null) {
        throw Exception('Member ID not found');
      }

      // Normalize date to DD-MM-YYYY
      String normalizeDate(dynamic v) {
        if (v == null) return '';
        final raw = v.toString();
        final base = raw.contains('T') ? raw.split('T').first : raw;
        if (base.contains('-')) {
          final parts = base.split('-');
          if (parts.length == 3 && parts[0].length == 4) {
            return '${parts[2].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[0]}';
          }
          return base; // already DD-MM-YYYY
        }
        if (base.contains('/')) {
          final parts = base.split('/');
          if (parts.length == 3 && parts[0].length == 4) {
            return '${parts[2].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[0]}';
          }
          if (parts.length == 3 && parts[2].length == 4) {
            return '${parts[0].padLeft(2, '0')}-${parts[1].padLeft(2, '0')}-${parts[2]}';
          }
        }
        return base;
      }

      // Compose updates for memberdetails including personal basics
      final memberData = await _loadMemberFromBackend();
      final form = (memberData?['registrationForm'] as Map<String, dynamic>?) ?? {};
      final updates = {
        'aadhaarNumber': _aadhaarController.text,
        'streetName': _streetNameController.text,
        'educationalQualification': _educationController.text,
        'religion': _religionController.text,
        'socialCategory': _selectedSocialCategory,
        if (form['fullName'] != null) 'fullName': form['fullName'],
        if (memberData?['email'] != null) 'email': memberData!['email'],
        if (form['phoneNumber'] != null) 'phoneNumber': form['phoneNumber'],
        if (form['city'] != null) 'city': form['city'],
        if (form['state'] != null) 'state': form['state'],
        if (form['district'] != null) 'district': form['district'],
        if (form['block'] != null) 'block': form['block'],
        if (form['dateOfBirth'] != null) 'dateOfBirth': normalizeDate(form['dateOfBirth']),
      };

      // Save demographics to memberdetails collection via updateMember
      final result = await ApiService().updateMember(memberId, updates);
      
      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);

      if (result['ok'] == true) {
        // Save form data to userData for navigation
        final updatedUserData = Map<String, dynamic>.from(widget.userData);
        if (updatedUserData['registrationForm'] == null) {
          updatedUserData['registrationForm'] = {};
        }
        
        updatedUserData['registrationForm']['aadhaarNumber'] = _aadhaarController.text;
        updatedUserData['registrationForm']['streetName'] = _streetNameController.text;
        updatedUserData['registrationForm']['educationalQualification'] = _educationController.text;
        updatedUserData['registrationForm']['religion'] = _religionController.text;
        updatedUserData['registrationForm']['socialCategory'] = _selectedSocialCategory;
        updatedUserData['memberId'] = memberId;

        // Navigate to next step
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BusinessInformationForm(userData: updatedUserData),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save data: ${result['body']?['message'] ?? result['status'] ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}



