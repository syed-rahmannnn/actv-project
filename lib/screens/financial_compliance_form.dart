// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'declaration_form.dart';

class FinancialComplianceForm extends StatefulWidget {
  final Map<String, dynamic> userData;

  const FinancialComplianceForm({
    super.key,
    required this.userData,
  });

  @override
  State<FinancialComplianceForm> createState() => _FinancialComplianceFormState();
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
  
  final List<String> _turnoverRanges = [
    'Less than 25 Lakhs',
    '25 Lakhs - 50 Lakhs',
    '50 Lakhs - 1 Crore',
    '1 Crore - 5 Crores',
    '5 Crores - 10 Crores',
    'More than 10 Crores'
  ];

  @override
  void initState() {
    super.initState();
    _populateFields();
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
                      'Step 3 of 4',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
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
                          _buildTextField('PAN Number', _panController, 'Enter PAN number'),
                          const Text(
                            'Validate PAN Number (10 chars alphanumeric)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // GST Number
                          _buildTextField('GST Number', _gstController, 'Enter GST number'),
                          const Text(
                            'Validate GST Number (15 chars)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Udyam Number
                          _buildTextField('Udyam Number', _udyamController, 'Enter Udyam number'),
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
                            _buildTextField('How many continuous years have you filed ITR?', _itrYearsController, 'Enter number of years'),
                          ],
                          
                          // Turnover
                          _buildDropdownField('Turnover', _selectedTurnoverRange, _turnoverRanges, 'Select turnover range'),
                          
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
                          
                          _buildTextField('FY 2021-22', _fy2021Controller, 'Enter turnover amount'),
                          _buildTextField('FY 2020-21', _fy2020Controller, 'Enter turnover amount'),
                          _buildTextField('FY 2019-20', _fy2019Controller, 'Enter turnover amount'),
                          
                          // Government Schemes Benefit
                          _buildRadioGroup(
                            'Have you got benefited through any Govt. schemes in your Business?',
                            _govtSchemeBenefit,
                            (value) => setState(() => _govtSchemeBenefit = value),
                            ['Yes', 'No'],
                          ),
                          
                          if (_govtSchemeBenefit == true) ...[
                            _buildTextField('Scheme 1', _scheme1Controller, 'Enter scheme name'),
                            _buildTextField('Scheme 2', _scheme2Controller, 'Enter scheme name'),
                            _buildTextField('Scheme 3', _scheme3Controller, 'Enter scheme name'),
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
                  _selectedTurnoverRange = newValue;
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
    if (_panController.text.isEmpty ||
        _gstController.text.isEmpty ||
        _filedITR == null ||
        (_filedITR == true && _itrYearsController.text.isEmpty) ||
        _selectedTurnoverRange == null ||
        _fy2021Controller.text.isEmpty ||
        _fy2020Controller.text.isEmpty ||
        _fy2019Controller.text.isEmpty ||
        _govtSchemeBenefit == null ||
        (_govtSchemeBenefit == true && (_scheme1Controller.text.isEmpty || _scheme2Controller.text.isEmpty || _scheme3Controller.text.isEmpty))) {
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
    
    updatedUserData['registrationForm']['panNumber'] = _panController.text;
    updatedUserData['registrationForm']['gstNumber'] = _gstController.text;
    updatedUserData['registrationForm']['udyamNumber'] = _udyamController.text;
    updatedUserData['registrationForm']['filedITR'] = _filedITR;
    updatedUserData['registrationForm']['itrYears'] = _itrYearsController.text;
    updatedUserData['registrationForm']['turnoverRange'] = _selectedTurnoverRange;
    updatedUserData['registrationForm']['fy2021'] = _fy2021Controller.text;
    updatedUserData['registrationForm']['fy2020'] = _fy2020Controller.text;
    updatedUserData['registrationForm']['fy2019'] = _fy2019Controller.text;
    updatedUserData['registrationForm']['govtSchemeBenefit'] = _govtSchemeBenefit;
    updatedUserData['registrationForm']['scheme1'] = _scheme1Controller.text;
    updatedUserData['registrationForm']['scheme2'] = _scheme2Controller.text;
    updatedUserData['registrationForm']['scheme3'] = _scheme3Controller.text;

    // Navigate to declaration form
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeclarationForm(userData: updatedUserData),
      ),
    );
  }
}
