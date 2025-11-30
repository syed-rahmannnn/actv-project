// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'declaration_form.dart';
import 'package:activ/services/api_service.dart';

class FinancialComplianceForm extends StatefulWidget {
  final Map<String, dynamic> userData;

  const FinancialComplianceForm({super.key, required this.userData});

  @override
  State<FinancialComplianceForm> createState() =>
      _FinancialComplianceFormState();
}

class _FinancialComplianceFormState extends State<FinancialComplianceForm> {
  final _panController = TextEditingController();
  final _gstController = TextEditingController();
  final _udyamController = TextEditingController();
  final _itrYearsController = TextEditingController();
  final _turnoverController = TextEditingController();
  final _fy2021Controller = TextEditingController();
  final _fy2020Controller = TextEditingController();
  final _fy2019Controller = TextEditingController();
  final _scheme1Controller = TextEditingController();
  final _scheme2Controller = TextEditingController();
  final _scheme3Controller = TextEditingController();

  bool? _filedITR;
  bool? _govtSchemeBenefit;
  String? _selectedTurnoverRange;

  // Auto-save debounce timer
  Timer? _debounceTimer;
  bool _isSaving = false;

  final List<String> _turnoverRanges = [
    'Less than 25 Lakhs',
    '25 Lakhs - 50 Lakhs',
    '50 Lakhs - 1 Crore',
    '1 Crore - 5 Crores',
    '5 Crores - 10 Crores',
    'More than 10 Crores',
  ];

  @override
  void initState() {
    super.initState();
    _populateFields();
    _setupAutoSaveListeners();
  }

  void _setupAutoSaveListeners() {
    final controllers = [
      _panController,
      _gstController,
      _udyamController,
      _itrYearsController,
      _turnoverController,
      _fy2021Controller,
      _fy2020Controller,
      _fy2019Controller,
      _scheme1Controller,
      _scheme2Controller,
      _scheme3Controller,
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
      String? memberId =
          widget.userData['memberId'] ??
          widget.userData['member']?['_id'] ??
          widget.userData['member']?['id'] ??
          widget.userData['_id'] ??
          widget.userData['id'];

      // If no member ID, try loading from backend
      if (memberId == null) {
        final email =
            widget.userData['email'] ?? widget.userData['member']?['email'];
        if (email != null && email.toString().trim().isNotEmpty) {
          final res = await ApiService.getMemberByEmail(email);
          if (res['success'] == true && res['data'] != null) {
            final member = res['data'] as Map<String, dynamic>;
            memberId = member['memberId'] ?? member['id'] ?? member['_id'];
          }
        }
      }

      if (memberId == null) return;

      final financialData = {
        'panNumber': _panController.text.trim(),
        'gstNumber': _gstController.text.trim(),
        'udyamNumber': _udyamController.text.trim(),
        'filedITR': _filedITR,
        'itrYears': _itrYearsController.text.trim(),
        'turnoverRange': _selectedTurnoverRange,
        'turnover': _turnoverController.text.trim(),
        'fy2021': _fy2021Controller.text.trim(),
        'fy2020': _fy2020Controller.text.trim(),
        'fy2019': _fy2019Controller.text.trim(),
        'govtSchemeBenefit': _govtSchemeBenefit,
        'scheme1': _scheme1Controller.text.trim(),
        'scheme2': _scheme2Controller.text.trim(),
        'scheme3': _scheme3Controller.text.trim(),
      };

      await ApiService.saveFinancialInfo(memberId, financialData);
    } catch (e) {
      // Silent fail
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  bool _isValidPan(String input) {
    final value = input.trim().toUpperCase();
    return RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value);
  }

  bool _isValidGst(String input) {
    final value = input.trim().toUpperCase();
    return RegExp(
      r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
    ).hasMatch(value);
  }

  void _populateFields() {
    final registrationForm = widget.userData['registrationForm'];
    if (registrationForm != null) {
      _panController.text = registrationForm['panNumber'] ?? '';
      _gstController.text = registrationForm['gstNumber'] ?? '';
      _udyamController.text = registrationForm['udyamNumber'] ?? '';
      _itrYearsController.text = registrationForm['itrYears'] ?? '';
      _turnoverController.text = registrationForm['turnover'] ?? '';
      _fy2021Controller.text = registrationForm['fy2021'] ?? '';
      _fy2020Controller.text = registrationForm['fy2020'] ?? '';
      _fy2019Controller.text = registrationForm['fy2019'] ?? '';
      _scheme1Controller.text = registrationForm['scheme1'] ?? '';
      _scheme2Controller.text = registrationForm['scheme2'] ?? '';
      _scheme3Controller.text = registrationForm['scheme3'] ?? '';
      _filedITR = registrationForm['filedITR'];
      _govtSchemeBenefit = registrationForm['govtSchemeBenefit'];
      _selectedTurnoverRange = registrationForm['turnoverRange'];
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _panController.dispose();
    _gstController.dispose();
    _udyamController.dispose();
    _itrYearsController.dispose();
    _turnoverController.dispose();
    _fy2021Controller.dispose();
    _fy2020Controller.dispose();
    _fy2019Controller.dispose();
    _scheme1Controller.dispose();
    _scheme2Controller.dispose();
    _scheme3Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          _debounceTimer?.cancel();
          await _autoSaveData();
        }
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
                          bool isActive = index <= 2;
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
                        'Step 3 of 4',
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 30),

                      // Financial & Compliance Information Section
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
                              'Financial & Compliance Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // PAN Number
                            _buildTextField(
                              'PAN Number',
                              _panController,
                              'Enter PAN number',
                            ),
                            const Text(
                              'Validate PAN Number (10 chars alphanumeric)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // GST Number
                            _buildTextField(
                              'GST Number',
                              _gstController,
                              'Enter GST number',
                            ),
                            const Text(
                              'Validate GST Number (15 chars)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Udyam Number
                            _buildTextField(
                              'Udyam Number',
                              _udyamController,
                              'Enter Udyam number',
                            ),
                            const Text(
                              'Optional',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Filed Income Tax Returns
                            _buildRadioGroup(
                              'Filed Income Tax Returns',
                              _filedITR,
                              (value) => setState(() => _filedITR = value),
                              ['Yes', 'No'],
                            ),

                            if (_filedITR == true) ...[
                              _buildTextField(
                                'How many continuous years have you filed ITR?',
                                _itrYearsController,
                                'Enter number of years',
                              ),
                            ],

                            // Turnover
                            _buildDropdownField(
                              'Turnover',
                              _selectedTurnoverRange,
                              _turnoverRanges,
                              'Select turnover range',
                            ),

                            // Turnover for Last 3 FYs
                            const Text(
                              'Turnover for Last 3 FYs',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildTextField(
                              'FY 2021-22',
                              _fy2021Controller,
                              'Enter turnover amount',
                            ),
                            _buildTextField(
                              'FY 2020-21',
                              _fy2020Controller,
                              'Enter turnover amount',
                            ),
                            _buildTextField(
                              'FY 2019-20',
                              _fy2019Controller,
                              'Enter turnover amount',
                            ),

                            // Government Schemes Benefit
                            _buildRadioGroup(
                              'Have you got benefited through any Govt. schemes in your Business?',
                              _govtSchemeBenefit,
                              (value) =>
                                  setState(() => _govtSchemeBenefit = value),
                              ['Yes', 'No'],
                            ),

                            if (_govtSchemeBenefit == true) ...[
                              _buildTextField(
                                'Scheme 1',
                                _scheme1Controller,
                                'Enter scheme name',
                              ),
                              _buildTextField(
                                'Scheme 2',
                                _scheme2Controller,
                                'Enter scheme name',
                              ),
                              _buildTextField(
                                'Scheme 3',
                                _scheme3Controller,
                                'Enter scheme name',
                              ),
                            ],
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
          enabled: _isFieldEnabled(label),
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
                  _selectedTurnoverRange = newValue;
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

  bool _isFieldEnabled(String label) {
    // Disable ITR years when _filedITR is false or null
    if (label == 'How many continuous years have you filed ITR?') {
      return _filedITR == true;
    }
    // Disable scheme fields unless govtSchemeBenefit is true
    if (label == 'Scheme 1' || label == 'Scheme 2' || label == 'Scheme 3') {
      return _govtSchemeBenefit == true;
    }
    return true;
  }

  Future<void> _proceedToNext() async {
    // No validation - all fields are optional
    // Users can proceed even with empty fields

    // Optional PAN/GST format validation only if fields are filled
    final pan = _panController.text.trim().toUpperCase();
    if (pan.isNotEmpty && !_isValidPan(pan)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid PAN format. Example: ABCDE1234F'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final gst = _gstController.text.trim().toUpperCase();
    if (gst.isNotEmpty && !_isValidGst(gst)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Invalid GST format. Must be 15 characters (##ABCDE1234F1Z5)',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save financial info to backend (optional, don't block navigation)
    try {
      final memberId =
          widget.userData['memberId'] ??
          widget.userData['_id'] ??
          widget.userData['id'] ??
          widget.userData['member']?['_id'] ??
          widget.userData['member']?['id'];

      if (memberId != null) {
        // Sanitize dependent fields
        final sanitizedItrYears = _filedITR == true
            ? _itrYearsController.text.trim()
            : '';
        final scheme1 = _govtSchemeBenefit == true
            ? _scheme1Controller.text.trim()
            : '';
        final scheme2 = _govtSchemeBenefit == true
            ? _scheme2Controller.text.trim()
            : '';
        final scheme3 = _govtSchemeBenefit == true
            ? _scheme3Controller.text.trim()
            : '';

        final financialData = {
          'panNumber': pan,
          'gstNumber': gst,
          'udyamNumber': _udyamController.text.trim(),
          'filedITR': _filedITR,
          'itrYears': sanitizedItrYears,
          'turnoverRange': _selectedTurnoverRange,
          'fy2021': _fy2021Controller.text.trim(),
          'fy2020': _fy2020Controller.text.trim(),
          'fy2019': _fy2019Controller.text.trim(),
          'govtSchemeBenefit': _govtSchemeBenefit,
          'scheme1': scheme1,
          'scheme2': scheme2,
          'scheme3': scheme3,
        };

        final result = await ApiService.saveFinancialInfo(
          memberId,
          financialData,
        );
        if (result['success'] != true) {
          throw Exception(
            result['body']?['message'] ?? 'Failed to save financial info',
          );
        }
      } else {
        // No member ID available, just continue without saving to backend
        print('No member ID found, skipping backend save');
      }
    } catch (e) {
      // Don't block navigation on save failure
      if (mounted) {
        print('Failed to save financial info: $e');
      }
    }

    // Save form data to userData - always proceed with navigation
    final updatedUserData = Map<String, dynamic>.from(widget.userData);
    if (updatedUserData['registrationForm'] == null) {
      updatedUserData['registrationForm'] = {};
    }

    updatedUserData['registrationForm']['panNumber'] = pan;
    updatedUserData['registrationForm']['gstNumber'] = gst;
    updatedUserData['registrationForm']['udyamNumber'] = _udyamController.text
        .trim();
    updatedUserData['registrationForm']['filedITR'] = _filedITR;
    updatedUserData['registrationForm']['itrYears'] = _filedITR == true
        ? _itrYearsController.text.trim()
        : '';
    updatedUserData['registrationForm']['turnoverRange'] =
        _selectedTurnoverRange;
    updatedUserData['registrationForm']['fy2021'] = _fy2021Controller.text
        .trim();
    updatedUserData['registrationForm']['fy2020'] = _fy2020Controller.text
        .trim();
    updatedUserData['registrationForm']['fy2019'] = _fy2019Controller.text
        .trim();
    updatedUserData['registrationForm']['govtSchemeBenefit'] =
        _govtSchemeBenefit;
    updatedUserData['registrationForm']['scheme1'] = _govtSchemeBenefit == true
        ? _scheme1Controller.text.trim()
        : '';
    updatedUserData['registrationForm']['scheme2'] = _govtSchemeBenefit == true
        ? _scheme2Controller.text.trim()
        : '';
    updatedUserData['registrationForm']['scheme3'] = _govtSchemeBenefit == true
        ? _scheme3Controller.text.trim()
        : '';

    // Navigate to declaration form
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeclarationForm(userData: updatedUserData),
      ),
    );
  }
}
