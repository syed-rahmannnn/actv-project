import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'application_submitted_screen.dart';
import 'package:activ/services/api_service.dart';
import 'package:activ/services/application_service.dart';
import 'package:activ/services/user_profile_provider.dart';
import 'package:activ/services/auth_service.dart';

class DeclarationForm extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String? baseUrl;
  final String? userId;
  final String? email;
  final String? fullName;
  final String? phone;
  final String? token;

  const DeclarationForm({
    super.key,
    required this.userData,
    this.baseUrl,
    this.userId,
    this.email,
    this.fullName,
    this.phone,
    this.token,
  });

  @override
  State<DeclarationForm> createState() => _DeclarationFormState();
}

class _DeclarationFormState extends State<DeclarationForm> {
  final _sisterConcernsController = TextEditingController();
  final _companyNamesController = TextEditingController();
  bool _showOneFieldPerName = false;
  bool _agreeToDeclaration = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    final registrationForm = widget.userData['registrationForm'];
    if (registrationForm != null) {
      _sisterConcernsController.text = registrationForm['sisterConcerns'] ?? '';
      _companyNamesController.text = registrationForm['companyNames'] ?? '';
      _showOneFieldPerName = registrationForm['showOneFieldPerName'] ?? false;
      _agreeToDeclaration = registrationForm['agreeToDeclaration'] ?? false;
    }
  }

  @override
  void dispose() {
    _sisterConcernsController.dispose();
    _companyNamesController.dispose();
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
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                    const SizedBox(height: 20),

                    // Progress Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        bool isActive = index <= 3;
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
                    const Text(
                      'Step 4 of 4',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),

                    // Declaration Section
                    Container(
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
                          const Text(
                            'Declaration',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // No. of Sister Concerns
                          _buildTextField(
                            'No. of Sister Concerns',
                            _sisterConcernsController,
                            'Enter number',
                          ),
                          const Text(
                            'Positive integers only',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 16),

                          // Name(s) of Company
                          _buildTextField(
                            'Name(s) of Company',
                            _companyNamesController,
                            'Enter company name',
                          ),
                          const SizedBox(height: 16),

                          // Add Another Company Button
                          SizedBox(
                            width: double.infinity,
                            height: 40,
                            child: OutlinedButton(
                              onPressed: () {
                                // Add logic to add another company field
                                setState(() {
                                  _companyNamesController.text += '\n';
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.grey[400]!),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Add Another Company',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Checkbox for showing one field per name
                          Row(
                            children: [
                              Checkbox(
                                value: _showOneFieldPerName,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _showOneFieldPerName = value ?? false;
                                  });
                                },
                                activeColor: Colors.blue,
                              ),
                              const Text(
                                'Show one field per name entered above',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Declaration Text
                          const Text(
                            'Declaration',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'This application is under the Verification and Screening Process. We have every right to ACCEPT or REJECT this application according to our membership policy. I confirm the above information is true and correct.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Agreement Checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: _agreeToDeclaration,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _agreeToDeclaration = value ?? false;
                                  });
                                },
                                activeColor: Colors.blue,
                              ),
                              const Expanded(
                                child: Text(
                                  'I agree to the above declaration and confirm that all information provided is accurate',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Navigation Buttons
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.purple),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Previous',
                              style: TextStyle(
                                color: Colors.purple,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _submitting ? null : _submitApplication,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: _submitting
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Submitting...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Submit Application',
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
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

  Future<void> _submitApplication() async {
    // Validate required fields
    if (_sisterConcernsController.text.isEmpty ||
        _companyNamesController.text.isEmpty ||
        !_agreeToDeclaration) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in all required fields and agree to the declaration',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate sister concerns is a positive integer
    final sisterConcerns = int.tryParse(_sisterConcernsController.text);
    if (sisterConcerns == null || sisterConcerns <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter a valid positive number for sister concerns',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Start submitting state
    if (mounted) setState(() => _submitting = true);

    // Save form data to userData
    final updatedUserData = Map<String, dynamic>.from(widget.userData);
    if (updatedUserData['registrationForm'] == null) {
      updatedUserData['registrationForm'] = {};
    }

    updatedUserData['registrationForm']['sisterConcerns'] =
        _sisterConcernsController.text;
    updatedUserData['registrationForm']['companyNames'] =
        _companyNamesController.text;
    updatedUserData['registrationForm']['showOneFieldPerName'] =
        _showOneFieldPerName;
    updatedUserData['registrationForm']['agreeToDeclaration'] =
        _agreeToDeclaration;
    updatedUserData['registrationForm']['profileCompleted'] = true;
    updatedUserData['registrationForm']['submissionDate'] = DateTime.now()
        .toIso8601String();

    // Save declaration to backend and submit application for approval workflow
    try {
      // Check if we have the new parameters, use them if available
      if (widget.baseUrl != null &&
          widget.userId != null &&
          widget.email != null &&
          widget.fullName != null &&
          widget.phone != null) {
        // Use the new simplified approach
        final location = context.read<UserProfileProvider>();
        final svc = ApplicationService(widget.baseUrl!, token: widget.token);

        final result = await svc.submitApplication(
          userId: widget.userId!,
          fullName: widget.fullName!,
          email: widget.email!,
          phone: widget.phone!,
          state: location.state ?? '',
          district: location.district ?? '',
          block: location.block ?? '',
          formData: {
            "sisterConcerns": sisterConcerns,
            "companyNames": _companyNamesController.text
                .split('\n')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList(),
            "showOneFieldPerName": _showOneFieldPerName,
            "agreeToDeclaration": _agreeToDeclaration,
            "timestamp": DateTime.now().toIso8601String(),
          },
        );

        if (mounted) setState(() => _submitting = false);

        if (result['success'] == true) {
          if (!mounted) return;
          Navigator.pushReplacementNamed(
            context,
            '/application_submitted',
            arguments: result['application'],
          );
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'] ?? 'Submission failed')),
          );
        }
        return;
      }

      // Fall back to existing logic if new parameters are not provided
      final memberId = updatedUserData['memberId'];
      if (memberId == null) {
        throw Exception('Member ID not found');
      }

      // Get stored location data from UserProfileProvider
      final userProfileProvider = context.read<UserProfileProvider>();
      final locationData = userProfileProvider.getLocationData();

      // Get authentication token using AuthService
      final token = await AuthService.getToken();
      if (token == null || token.trim().isEmpty) {
        if (mounted) setState(() => _submitting = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired or invalid. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Convert company names into array (split by new lines)
      final companyNames = _companyNamesController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // First save the declaration to the existing profile endpoint
      final declarationPayload = {
        'sisterConcerns': sisterConcerns,
        'companyNames': companyNames,
        'showOneFieldPerName': _showOneFieldPerName,
        'agreeToDeclaration': _agreeToDeclaration,
        'profileCompleted': true,
        'submissionDate': DateTime.now().toIso8601String(),
      };

      final declarationResult = await ApiService.saveDeclaration(
        memberId,
        declarationPayload,
      );
      if (declarationResult['success'] != true &&
          declarationResult['ok'] != true) {
        throw Exception(
          declarationResult['error'] ??
              declarationResult['message'] ??
              'Failed to save declaration',
        );
      }

      // Now submit the application using ApplicationService with stored location data
      final applicationService = ApplicationService(
        ApiService.baseUrl,
        token: token,
      );
      final state = (locationData['state'] ?? '').toString().trim();
      final district = (locationData['district'] ?? '').toString().trim();
      final block = (locationData['block'] ?? '').toString().trim();

      final userData = updatedUserData['registrationForm'] ?? {};
      final declarationFormDataMap = {
        'sisterConcerns': sisterConcerns,
        'companyNames': companyNames,
        'showOneFieldPerName': _showOneFieldPerName,
        'agreeToDeclaration': _agreeToDeclaration,
        'personalDetails': userData,
        'businessInfo': updatedUserData['businessInfo'],
        'financialInfo': updatedUserData['financialInfo'],
      };

      final result = await applicationService.submitApplication(
        userId: memberId,
        fullName: userData['fullName'] ?? '',
        email: updatedUserData['email'] ?? '',
        phone: userData['phoneNumber'] ?? '',
        state: state,
        district: district,
        block: block,
        formData: declarationFormDataMap,
      );

      if (result['success'] == true) {
        // Optional: capture application info if returned
        if (!mounted) return;
        // Reset submitting state before navigation
        setState(() => _submitting = false);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                ApplicationSubmittedScreen(userData: updatedUserData),
          ),
        );
        return;
      } else {
        if (!mounted) return;
        final msg =
            result['message']?.toString() ??
            result['error']?.toString() ??
            'Failed to submit application';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
        return;
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit application: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}
