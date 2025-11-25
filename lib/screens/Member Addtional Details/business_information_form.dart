// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'financial_compliance_form.dart';
import '../../services/api_service.dart';

class BusinessInformationForm extends StatefulWidget {
  final Map<String, dynamic> userData;

  const BusinessInformationForm({super.key, required this.userData});

  @override
  State<BusinessInformationForm> createState() =>
      _BusinessInformationFormState();
}

class _BusinessInformationFormState extends State<BusinessInformationForm> {
  final _organizationNameController = TextEditingController();
  final _businessActivitiesController = TextEditingController();
  final _employeesController = TextEditingController();
  final _otherChamberController = TextEditingController();

  bool? _doingBusiness;
  String? _selectedConstitution;
  String? _selectedYear;
  bool? _memberOfOtherChamber;

  final List<String> _constitutionTypes = ['OPC', 'TRUST', 'SOCIETY'];

  final List<String> _years = List.generate(
    50,
    (index) => (2024 - index).toString(),
  );

  final List<String> _businessTypes = [
    'Manufacturing',
    'Trader',
    'Service Provider',
    'Others',
  ];

  final List<String> _govtOrganizations = [
    'MSME',
    'KVIC',
    'NABARD',
    'None',
    'Others',
  ];

  Set<String> _selectedBusinessTypes = {};
  Set<String> _selectedGovtOrganizations = {};

  // Auto-save debounce timer
  Timer? _debounceTimer;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _populateFields();
    _setupAutoSaveListeners();
  }

  void _setupAutoSaveListeners() {
    final controllers = [
      _organizationNameController,
      _businessActivitiesController,
      _employeesController,
      _otherChamberController,
    ];

    for (var controller in controllers) {
      controller.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 2), _autoSaveData);
  }

  Future<void> _autoSaveData() async {
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      String? memberId = widget.userData['memberId'] ??
          widget.userData['member']?['_id'] ??
          widget.userData['member']?['id'] ??
          widget.userData['_id'] ??
          widget.userData['id'];

      // If no member ID, try loading from backend
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

      if (memberId == null) return;

      final businessData = {
        'doingBusiness': _doingBusiness,
        'organizationName': _organizationNameController.text.trim(),
        'constitutionType': _selectedConstitution,
        'businessTypes': _selectedBusinessTypes.toList(),
        'businessActivities': _businessActivitiesController.text.trim(),
        'businessCommencementYear': _selectedYear,
        'numberOfEmployees': _employeesController.text.trim(),
        'memberOfOtherChamber': _memberOfOtherChamber,
        'otherChamber': _otherChamberController.text.trim(),
        'govtOrganizations': _selectedGovtOrganizations.toList(),
      };

      await ApiService.saveBusinessInfo(memberId, businessData);
    } catch (e) {
      // Silent fail
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _populateFields() {
    final registrationForm = widget.userData['registrationForm'];
    if (registrationForm != null) {
      _organizationNameController.text =
          registrationForm['organizationName'] ?? '';
      _businessActivitiesController.text =
          registrationForm['businessActivities'] ?? '';
      _employeesController.text = registrationForm['numberOfEmployees'] ?? '';
      _otherChamberController.text = registrationForm['otherChamber'] ?? '';
      _doingBusiness = registrationForm['doingBusiness'];
      _selectedConstitution = registrationForm['constitutionType'];
      _selectedYear = registrationForm['businessCommencementYear'];
      _memberOfOtherChamber = registrationForm['memberOfOtherChamber'];

      if (registrationForm['businessTypes'] != null) {
        _selectedBusinessTypes = Set<String>.from(
          registrationForm['businessTypes'],
        );
      }
      if (registrationForm['govtOrganizations'] != null) {
        _selectedGovtOrganizations = Set<String>.from(
          registrationForm['govtOrganizations'],
        );
      }
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _organizationNameController.dispose();
    _businessActivitiesController.dispose();
    _employeesController.dispose();
    _otherChamberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _debounceTimer?.cancel();
        await _autoSaveData();
        return true;
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
                        bool isActive = index <= 1;
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
                      'Step 2 of 4',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 30),

                    // Business Information Section
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
                          const Center(
                            child: Text(
                              'Business Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Doing Business
                          _buildRadioGroup(
                            'Doing Business',
                            _doingBusiness,
                            (value) => setState(() => _doingBusiness = value),
                            ['Yes', 'No'],
                          ),
                          const SizedBox(height: 16),

                          // Show business-specific fields only when doing business is "Yes"
                          if (_doingBusiness == true) ...[
                            // Organization Name
                            _buildTextField(
                              'Name of the Organization',
                              _organizationNameController,
                              'Enter organization name',
                            ),

                            // Constitution
                            _buildDropdownField(
                              'Constitution of the Company',
                              _selectedConstitution,
                              _constitutionTypes,
                              'Select constitution type',
                            ),

                            // Business Types
                            _buildCheckboxGroup(
                              'Type of Business',
                              _selectedBusinessTypes,
                              _businessTypes,
                            ),

                            // Business Activities
                            _buildTextField(
                              'Business Activities',
                              _businessActivitiesController,
                              'Enter business activities',
                              maxLines: 3,
                            ),

                            // Commencement Year
                            _buildDropdownField(
                              'Business Commencement Year',
                              _selectedYear,
                              _years,
                              'Select year',
                            ),

                            // Number of Employees
                            _buildTextField(
                              'Number of Employees',
                              _employeesController,
                              'Enter number of employees',
                            ),
                          ],

                          // Member of other Chamber/Association
                          _buildRadioGroup(
                            'Member of any other Chamber/Association',
                            _memberOfOtherChamber,
                            (value) =>
                                setState(() => _memberOfOtherChamber = value),
                            ['Yes', 'No'],
                          ),

                          if (_memberOfOtherChamber == true) ...[
                            const SizedBox(height: 16),
                            _buildTextField(
                              'Name of Chamber/Association',
                              _otherChamberController,
                              'Enter chamber/association name',
                            ),
                          ],

                          // Government Organizations
                          _buildCheckboxGroup(
                            'Registered with Govt. Organization',
                            _selectedGovtOrganizations,
                            _govtOrganizations,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Navigation Buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
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
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SizedBox(
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
      ),
    );
  }

  Widget _buildRadioGroup(
    String label,
    bool? selectedValue,
    Function(bool?) onChanged,
    List<String> options,
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
        Row(
          children: options.map((option) {
            return Expanded(
              child: Row(
                children: [
                  Radio<bool>(
                    value: option == 'Yes' ? true : false,
                    groupValue: selectedValue,
                    onChanged: (value) {
                      onChanged(value);
                      _onFieldChanged(); // Trigger auto-save
                    },
                    activeColor: Colors.blue,
                  ),
                  Text(option),
                ],
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String placeholder, {
    int maxLines = 1,
  }) {
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
          maxLines: maxLines,
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
                  if (label == 'Constitution of the Company') {
                    _selectedConstitution = newValue;
                  } else if (label == 'Business Commencement Year') {
                    _selectedYear = newValue;
                  }
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

  Widget _buildCheckboxGroup(
    String label,
    Set<String> selectedValues,
    List<String> options,
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
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: options.map((option) {
            bool isSelected = selectedValues.contains(option);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        selectedValues.add(option);
                      } else {
                        selectedValues.remove(option);
                      }
                    });
                    _onFieldChanged(); // Trigger auto-save
                  },
                  activeColor: Colors.blue,
                ),
                Text(option),
              ],
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _proceedToNext() async {
    // Validate required fields
    // No validation - all fields are optional
    // Users can proceed even with empty fields

    // Save form data to userData
    final updatedUserData = Map<String, dynamic>.from(widget.userData);
    if (updatedUserData['registrationForm'] == null) {
      updatedUserData['registrationForm'] = {};
    }

    updatedUserData['registrationForm']['doingBusiness'] = _doingBusiness;

    // Only save business-specific data if doing business is "Yes"
    if (_doingBusiness == true) {
      updatedUserData['registrationForm']['organizationName'] =
          _organizationNameController.text;
      updatedUserData['registrationForm']['constitutionType'] =
          _selectedConstitution;
      updatedUserData['registrationForm']['businessType'] =
          _selectedBusinessTypes.isNotEmpty
          ? _selectedBusinessTypes.first
          : null;
      updatedUserData['registrationForm']['businessActivities'] =
          _businessActivitiesController.text;
      updatedUserData['registrationForm']['businessCommencementYear'] =
          _selectedYear;
      updatedUserData['registrationForm']['numberOfEmployees'] =
          _employeesController.text;
    } else {
      // Clear business-specific data if not doing business
      updatedUserData['registrationForm']['organizationName'] = null;
      updatedUserData['registrationForm']['constitutionType'] = null;
      updatedUserData['registrationForm']['businessType'] = null;
      updatedUserData['registrationForm']['businessActivities'] = null;
      updatedUserData['registrationForm']['businessCommencementYear'] = null;
      updatedUserData['registrationForm']['numberOfEmployees'] = null;
    }

    updatedUserData['registrationForm']['memberOfOtherChamber'] =
        _memberOfOtherChamber;
    updatedUserData['registrationForm']['otherChamber'] =
        _otherChamberController.text;
    updatedUserData['registrationForm']['registeredWithGovtOrganization'] =
        _selectedGovtOrganizations.toList();

    // Save business information to database
    try {
      final memberId =
          widget.userData['member']?['id'] ??
          widget.userData['data']?['member']?['id'];

      if (memberId != null) {
        final businessInfoPayload = {
          'memberId': memberId,
          'doingBusiness': _doingBusiness,
          'organizationName': _doingBusiness == true
              ? _organizationNameController.text
              : null,
          'constitutionType': _doingBusiness == true
              ? _selectedConstitution
              : null,
          'businessType':
              _doingBusiness == true && _selectedBusinessTypes.isNotEmpty
              ? _selectedBusinessTypes.first
              : null,
          'businessActivities': _doingBusiness == true
              ? _businessActivitiesController.text
              : null,
          'businessCommencementYear': _doingBusiness == true
              ? _selectedYear
              : null,
          'numberOfEmployees': _doingBusiness == true
              ? _employeesController.text
              : null,
          'memberOfOtherChamber': _memberOfOtherChamber,
          'otherChamber': _otherChamberController.text,
          'registeredWithGovtOrganization': _selectedGovtOrganizations.toList(),
        };

        final result = await ApiService.saveBusinessInfo(
          memberId,
          businessInfoPayload,
        );

        if (!result['success']) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to save business information: ${result['error']}',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving business information: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Navigate to financial compliance form
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            FinancialComplianceForm(userData: updatedUserData),
      ),
    );
  }
}
