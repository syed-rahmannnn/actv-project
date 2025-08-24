// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'financial_compliance_form.dart';

class ExtendedBusinessForm extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ExtendedBusinessForm({
    super.key,
    required this.userData,
  });

  @override
  State<ExtendedBusinessForm> createState() => _ExtendedBusinessFormState();
}

class _ExtendedBusinessFormState extends State<ExtendedBusinessForm> {
  final _additionalBusinessController = TextEditingController();
  final _businessLocationController = TextEditingController();
  final _businessWebsiteController = TextEditingController();
  final _businessDescriptionController = TextEditingController();
  final _exportLicenseController = TextEditingController();
  
  String? _selectedBusinessScale;
  String? _selectedExportStatus;
  bool? _hasExportLicense;

  
  final List<String> _businessScales = [
    'Micro',
    'Small',
    'Medium',
    'Large'
  ];
  
  final List<String> _exportStatuses = [
    'Domestic Only',
    'Export to Neighboring Countries',
    'International Export',
    'Planning to Export'
  ];

  @override
  void initState() {
    super.initState();
    _populateFields();
  }

  void _populateFields() {
    final registrationForm = widget.userData['registrationForm'];
    if (registrationForm != null) {
      _additionalBusinessController.text = registrationForm['additionalBusiness'] ?? '';
      _businessLocationController.text = registrationForm['businessLocation'] ?? '';
      _businessWebsiteController.text = registrationForm['businessWebsite'] ?? '';
      _businessDescriptionController.text = registrationForm['businessDescription'] ?? '';
      _selectedBusinessScale = registrationForm['businessScale'];
      _selectedExportStatus = registrationForm['exportStatus'];
      _hasExportLicense = registrationForm['hasExportLicense'];
      _exportLicenseController.text = registrationForm['exportLicense'] ?? '';
    }
  }

  @override
  void dispose() {
    _additionalBusinessController.dispose();
    _businessLocationController.dispose();
    _businessWebsiteController.dispose();
    _businessDescriptionController.dispose();
    _exportLicenseController.dispose();
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
                        bool isActive = index <= 2;
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
                      'Step 2 of 4 (Extended)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Extended Business Information Section
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
                              'Extended Business Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          
                          // Additional Business Details
                          _buildTextField('Additional Business Details', _additionalBusinessController, 'Enter additional business information', maxLines: 3),
                          
                          // Business Location
                          _buildTextField('Business Location', _businessLocationController, 'Enter business location'),
                          
                          // Business Website
                          _buildTextField('Business Website (Optional)', _businessWebsiteController, 'Enter website URL'),
                          
                          // Business Scale
                          _buildDropdownField('Business Scale', _selectedBusinessScale, _businessScales, 'Select business scale'),
                          
                          // Export Status
                          _buildDropdownField('Export Status', _selectedExportStatus, _exportStatuses, 'Select export status'),
                          
                          // Export License
                          _buildRadioGroup(
                            'Do you have an Export License?',
                            _hasExportLicense,
                            (value) => setState(() => _hasExportLicense = value),
                            ['Yes', 'No'],
                          ),
                          
                          if (_hasExportLicense == true) ...[
                            const SizedBox(height: 16),
                            _buildTextField('Export License Number', _exportLicenseController, 'Enter export license number'),
                          ],
                          
                          // Business Description
                          _buildTextField('Detailed Business Description', _businessDescriptionController, 'Describe your business in detail', maxLines: 4),
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
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String placeholder, {int maxLines = 1}) {
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
                  if (label == 'Business Scale') {
                    _selectedBusinessScale = newValue;
                  } else if (label == 'Export Status') {
                    _selectedExportStatus = newValue;
                  }
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildRadioGroup(String label, bool? selectedValue, Function(bool?) onChanged, List<String> options) {
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
                    onChanged: onChanged,
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

  void _proceedToNext() {
    // Validate required fields
    if (_additionalBusinessController.text.isEmpty ||
        _businessLocationController.text.isEmpty ||
        _selectedBusinessScale == null ||
        _selectedExportStatus == null ||
        _hasExportLicense == null ||
        (_hasExportLicense == true && _exportLicenseController.text.isEmpty) ||
        _businessDescriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save form data to userData
    final updatedUserData = Map<String, dynamic>.from(widget.userData);
    if (updatedUserData['registrationForm'] == null) {
      updatedUserData['registrationForm'] = {};
    }
    
    updatedUserData['registrationForm']['additionalBusiness'] = _additionalBusinessController.text;
    updatedUserData['registrationForm']['businessLocation'] = _businessLocationController.text;
    updatedUserData['registrationForm']['businessWebsite'] = _businessWebsiteController.text;
    updatedUserData['registrationForm']['businessScale'] = _selectedBusinessScale;
    updatedUserData['registrationForm']['exportStatus'] = _selectedExportStatus;
    updatedUserData['registrationForm']['hasExportLicense'] = _hasExportLicense;
    updatedUserData['registrationForm']['exportLicense'] = _exportLicenseController.text;
    updatedUserData['registrationForm']['businessDescription'] = _businessDescriptionController.text;

    // Navigate to financial compliance form
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FinancialComplianceForm(userData: updatedUserData),
      ),
    );
  }
}
