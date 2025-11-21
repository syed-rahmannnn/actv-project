import 'dart:async';
import 'package:flutter/material.dart';
import 'package:activ/services/api_service.dart';
import 'business_information_form.dart';

class PersonalDetailsForm extends StatefulWidget {
  final Map<String, dynamic> userData;

  const PersonalDetailsForm({super.key, required this.userData});

  @override
  State<PersonalDetailsForm> createState() => _PersonalDetailsFormState();
}

class _PersonalDetailsFormState extends State<PersonalDetailsForm> {
  Future<Map<String, dynamic>?> _loadMemberFromBackend() async {
    try {
      // Get email from userData instead of Firebase
      final email =
          widget.userData['email'] ?? widget.userData['member']?['email'];
      if (email == null || email.toString().trim().isEmpty) {
        // Error loading member data - logging removed for security
        return widget.userData;
      }

      // Get member details from backend
      final res = await ApiService.getMemberByEmail(email);
      if (res['success'] == true && res['data'] != null) {
        final member = Map<String, dynamic>.from(res['data'] as Map);
        final memberId = member['memberId'] ?? member['id'] ?? member['_id'];

        if (memberId == null) {
          // Error loading member data - logging removed for security
          return widget.userData;
        }

        return {
          'email': email,
          'memberId': memberId,
          'registrationForm': {
            'fullName': member['fullName'] ?? '',
            'block': member['block'] ?? '',
            'state': member['state'] ?? '',
            'district': member['district'] ?? '',
            'phoneNumber': member['phoneNumber'] ?? '',
            'dateOfBirth': member['dateOfBirth'] ?? '',
            'city': member['city'] ?? '',
            // Include demographic fields from memberdetails (source of truth)
            'aadhaarNumber': member['aadhaarNumber'] ?? '',
            'streetName': member['streetName'] ?? '',
            'educationalQualification':
                member['educationalQualification'] ?? '',
            'religion': member['religion'] ?? '',
            'socialCategory': member['socialCategory'] ?? '',
          },
        };
      }
      return widget.userData;
    } catch (e) {
      // Error loading member data - logging removed for security
      return widget.userData;
    }
  }

  final _aadhaarController = TextEditingController();
  final _streetNameController = TextEditingController();
  final _educationController = TextEditingController();
  final _religionController = TextEditingController();

  // Personal details controllers
  final _nameController = TextEditingController();
  final _blockController = TextEditingController();
  final _stateController = TextEditingController();
  final _districtController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  String? _selectedSocialCategory;

  final List<String> _socialCategories = ['Christian SC', 'ST', 'Christian ST', 'Other'];

  // Auto-save debounce timer
  Timer? _debounceTimer;
  bool _isSaving = false;
  bool _hasAttemptedSave = false; // Track if we've tried to save at least once

  @override
  void initState() {
    super.initState();
    _populateFields();
    _setupAutoSaveListeners();
  }

  void _setupAutoSaveListeners() {
    // Add listeners to all controllers for auto-save
    final controllers = [
      _aadhaarController,
      _streetNameController,
      _educationController,
      _religionController,
      _nameController,
      _blockController,
      _stateController,
      _districtController,
      _cityController,
      _phoneController,
      _emailController,
    ];

    for (var controller in controllers) {
      controller.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Start new timer (auto-save after 2 seconds of inactivity)
    _debounceTimer = Timer(const Duration(seconds: 2), () {
      _autoSaveData();
    });
  }

  Future<void> _autoSaveData() async {
    if (_isSaving) return; // Prevent multiple simultaneous saves

    setState(() => _isSaving = true);

    try {
      // Try to get member ID from multiple sources
      String? memberId = widget.userData['memberId'] ??
          widget.userData['member']?['_id'] ??
          widget.userData['member']?['id'] ??
          widget.userData['_id'] ??
          widget.userData['id'];

      // If still no member ID, try loading from backend
      if (memberId == null) {
        final email = widget.userData['email'] ?? widget.userData['member']?['email'];
        if (email != null && email.toString().trim().isNotEmpty) {
          final res = await ApiService.getMemberByEmail(email);
          if (res['success'] == true && res['data'] != null) {
            final member = res['data'] as Map<String, dynamic>;
            memberId = member['memberId'] ?? member['id'] ?? member['_id'];
          }
        }
      }

      if (memberId == null) {
        // Silent fail - no error message to avoid annoying users
        // This happens when user accesses form directly without login/registration
        _hasAttemptedSave = true; // Mark that we attempted
        print('Auto-save skipped: Member ID not found');
        return;
      }

      _hasAttemptedSave = true; // Mark that we attempted to save

      // Prepare data
      final updateData = {
        'aadhaarNumber': _aadhaarController.text.trim(),
        'streetName': _streetNameController.text.trim(),
        'educationalQualification': _educationController.text.trim(),
        'religion': _religionController.text.trim(),
        'socialCategory': _selectedSocialCategory ?? '',
        'fullName': _nameController.text.trim(),
        'block': _blockController.text.trim(),
        'state': _stateController.text.trim(),
        'district': _districtController.text.trim(),
        'city': _cityController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
      };

      // Save to backend
      await ApiService.updateMemberDetails(memberId, updateData);
      
      // Update userData with member ID for future saves
      if (mounted) {
        widget.userData['memberId'] = memberId;
      }
    } catch (e) {
      // Silent fail for auto-save
      print('Auto-save error: $e');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _populateFields() {
    // Auto-populate fields from registration data
    // Priority: registrationForm > member object > direct userData fields

    final registrationForm = widget.userData['registrationForm'];
    final memberData = widget.userData['member'];

    // Personal Information Fields
    // Full Name: Can come from registration, member, or direct userData
    _nameController.text =
        registrationForm?['fullName'] ??
        widget.userData['fullName'] ??
        memberData?['fullName'] ??
        '';

    // Email: Can come from member, direct userData, or email field
    _emailController.text =
        widget.userData['email'] ??
        memberData?['email'] ??
        registrationForm?['email'] ??
        '';

    // Phone: Note that step1 sends as 'phone', backend stores as 'phoneNumber'
    _phoneController.text =
        registrationForm?['phoneNumber'] ??
        widget.userData['phoneNumber'] ??
        widget.userData['phone'] ??
        memberData?['phoneNumber'] ??
        '';

    // Location Fields
    _stateController.text =
        registrationForm?['state'] ??
        widget.userData['state'] ??
        memberData?['state'] ??
        '';

    _districtController.text =
        registrationForm?['district'] ??
        widget.userData['district'] ??
        memberData?['district'] ??
        '';

    _blockController.text =
        registrationForm?['block'] ??
        widget.userData['block'] ??
        memberData?['block'] ??
        '';

    _cityController.text =
        registrationForm?['city'] ??
        widget.userData['city'] ??
        memberData?['city'] ??
        '';

    // Demographic Fields (Additional Details)
    _aadhaarController.text =
        registrationForm?['aadhaarNumber'] ??
        memberData?['aadhaarNumber'] ??
        '';

    _streetNameController.text =
        registrationForm?['streetName'] ?? memberData?['streetName'] ?? '';

    _educationController.text =
        registrationForm?['educationalQualification'] ??
        memberData?['educationalQualification'] ??
        '';

    _religionController.text =
        registrationForm?['religion'] ?? memberData?['religion'] ?? '';

    _selectedSocialCategory =
        registrationForm?['socialCategory'] ?? memberData?['socialCategory'];

    // Ensure empty strings become null for social category dropdown
    if (_selectedSocialCategory != null && _selectedSocialCategory!.isEmpty) {
      _selectedSocialCategory = null;
    }
  }

  Future<void> _updatePersonalDetails() async {
    // Validate passwords match if provided
    if (_passwordController.text.isNotEmpty ||
        _confirmPasswordController.text.isNotEmpty) {
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwords do not match'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Get member ID from backend
      final backendData = await _loadMemberFromBackend();
      final memberId =
          backendData?['memberId'] ??
          widget.userData['_id'] ??
          widget.userData['id'] ??
          widget.userData['member']?['_id'] ??
          widget.userData['member']?['id'];

      if (memberId == null) {
        throw Exception('Member ID not found');
      }

      // Prepare update payload with all personal details
      final updateData = {
        'fullName': _nameController.text,
        'block': _blockController.text,
        'state': _stateController.text,
        'district': _districtController.text,
        'city': _cityController.text,
        'phoneNumber': _phoneController.text,
        'email': _emailController.text,
      };

      // Add password if provided
      if (_passwordController.text.isNotEmpty) {
        updateData['password'] = _passwordController.text;
      }

      // Call API to update
      final response = await ApiService.updateMemberDetails(
        memberId,
        updateData,
      );

      // Close loading dialog
      if (mounted) {
        Navigator.pop(context);
      }

      if (response['success'] == true) {
        // Clear password fields
        _passwordController.clear();
        _confirmPasswordController.clear();

        // Update local userData with new values
        widget.userData['fullName'] = _nameController.text;
        widget.userData['phoneNumber'] = _phoneController.text;
        widget.userData['email'] = _emailController.text;
        widget.userData['state'] = _stateController.text;
        widget.userData['district'] = _districtController.text;
        widget.userData['block'] = _blockController.text;
        widget.userData['city'] = _cityController.text;

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Personal details saved successfully'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to update details');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _aadhaarController.dispose();
    _streetNameController.dispose();
    _educationController.dispose();
    _religionController.dispose();
    _nameController.dispose();
    _blockController.dispose();
    _stateController.dispose();
    _districtController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Save data before allowing back navigation
        _debounceTimer?.cancel(); // Cancel any pending debounce
        await _autoSaveData(); // Force immediate save
        return true; // Allow navigation
      },
      child: Scaffold(
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
                      style: TextStyle(fontSize: 16, color: Colors.grey),
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
                                color: isActive
                                    ? Colors.blue
                                    : Colors.grey[300],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isActive
                                        ? Colors.white
                                        : Colors.grey[600],
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Step 1 of 4',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        if (_isSaving) ...[
                          const SizedBox(width: 12),
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Saving...',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Personal Details Section
                    _buildSectionCard('Personal details', [
                      FutureBuilder<Map<String, dynamic>?>(
                        future: _loadMemberFromBackend(),
                        builder: (context, snapshot) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                'Name',
                                _nameController,
                                'Enter your full name',
                              ),
                              _buildTextField(
                                'Block',
                                _blockController,
                                'Enter block',
                              ),
                              _buildTextField(
                                'State',
                                _stateController,
                                'Enter state',
                              ),
                              _buildTextField(
                                'District',
                                _districtController,
                                'Enter district',
                              ),
                              _buildTextField(
                                'City',
                                _cityController,
                                'Enter city',
                              ),
                              _buildTextField(
                                'Phone Number',
                                _phoneController,
                                'Enter phone number',
                              ),
                              _buildTextField(
                                'Email ID',
                                _emailController,
                                'Enter email',
                              ),
                              _buildPasswordField(
                                'Password',
                                _passwordController,
                                'Enter new password (optional)',
                                _obscurePassword,
                                () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              _buildPasswordField(
                                'Confirm Password',
                                _confirmPasswordController,
                                'Confirm new password',
                                _obscureConfirmPassword,
                                () {
                                  setState(() {
                                    _obscureConfirmPassword =
                                        !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _updatePersonalDetails,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color.fromARGB(
                                      255,
                                      6,
                                      139,
                                      227,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: const Text(
                                    'Save Personal Details',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Demographic Details Section
                    _buildSectionCard('Demographic Details', [
                      _buildTextField(
                        'Religion',
                        _religionController,
                        'Enter religion',
                      ),
                      _buildDropdownField(
                        'Social Category',
                        _selectedSocialCategory,
                        _socialCategories,
                        'Select category',
                      ),
                    ]),
                    const SizedBox(height: 30),

                    // Next Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _proceedToNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromRGBO(
                            33,
                            150,
                            243,
                            1,
                          ),
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

  Widget _buildPasswordField(
    String label,
    TextEditingController controller,
    String placeholder,
    bool obscureText,
    VoidCallback toggleVisibility,
  ) {
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
          obscureText: obscureText,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey[600],
              ),
              onPressed: toggleVisibility,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String placeholder,
  ) {
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDropdownField(
    String label,
    String? selectedValue,
    List<String> options,
    String placeholder,
  ) {
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
                _onFieldChanged(); // Trigger auto-save
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _proceedToNext() async {
    // No validation - all fields are optional
    // Users can proceed to next page even with empty fields

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Try to get member ID and save to backend, but don't block navigation if it fails
      String? memberId;
      try {
        final backendData = await _loadMemberFromBackend();
        memberId = backendData?['memberId'];

        if (memberId != null) {
          // Compose updates for memberdetails including personal basics
          final form =
              (backendData?['registrationForm'] as Map<String, dynamic>?) ?? {};
          final updates = {
            // Demographic fields
            'aadhaarNumber': _aadhaarController.text,
            'streetName': _streetNameController.text,
            'educationalQualification': _educationController.text,
            'religion': _religionController.text,
            'socialCategory': _selectedSocialCategory ?? '',
            // Personal information fields from the form (user may have edited them)
            'fullName': _nameController.text.isNotEmpty
                ? _nameController.text
                : form['fullName'],
            'email': _emailController.text.isNotEmpty
                ? _emailController.text
                : backendData?['email'],
            'phoneNumber': _phoneController.text.isNotEmpty
                ? _phoneController.text
                : form['phoneNumber'],
            'city': _cityController.text.isNotEmpty
                ? _cityController.text
                : form['city'],
            'state': _stateController.text.isNotEmpty
                ? _stateController.text
                : form['state'],
            'district': _districtController.text.isNotEmpty
                ? _districtController.text
                : form['district'],
            'block': _blockController.text.isNotEmpty
                ? _blockController.text
                : form['block'],
          };

          // Save demographics to memberdetails collection via updateMember
          await ApiService().updateMember(memberId, updates);
        }
      } catch (e) {
        // Continue even if backend save fails
        print('Backend save failed, continuing anyway: $e');
      }

      // Close loading dialog
      if (!mounted) return;
      Navigator.pop(context);

      // Save form data to userData for navigation
      final updatedUserData = Map<String, dynamic>.from(widget.userData);
      if (updatedUserData['registrationForm'] == null) {
        updatedUserData['registrationForm'] = {};
      }

      // Save demographic fields
      updatedUserData['registrationForm']['aadhaarNumber'] =
          _aadhaarController.text;
      updatedUserData['registrationForm']['streetName'] =
          _streetNameController.text;
      updatedUserData['registrationForm']['educationalQualification'] =
          _educationController.text;
      updatedUserData['registrationForm']['religion'] =
          _religionController.text;
      updatedUserData['registrationForm']['socialCategory'] =
          _selectedSocialCategory;

      // Save personal details (in case user edited them)
      updatedUserData['registrationForm']['fullName'] = _nameController.text;
      updatedUserData['registrationForm']['phoneNumber'] =
          _phoneController.text;
      updatedUserData['registrationForm']['state'] = _stateController.text;
      updatedUserData['registrationForm']['district'] =
          _districtController.text;
      updatedUserData['registrationForm']['block'] = _blockController.text;
      updatedUserData['registrationForm']['city'] = _cityController.text;
      updatedUserData['email'] = _emailController.text;

      if (memberId != null) {
        updatedUserData['memberId'] = memberId;
      }

      // Navigate to next step - always proceed
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              BusinessInformationForm(userData: updatedUserData),
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
