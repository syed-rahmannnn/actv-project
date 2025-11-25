import 'package:flutter/material.dart';

class LocationSelectionScreen extends StatefulWidget {
  const LocationSelectionScreen({super.key});

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  String? selectedState;
  String? selectedDistrict;
  String? selectedBlock;

  // Sample data
  final List<String> states = [
    'Tamil Nadu',
    'Kerala',
    'Karnataka',
    'Andhra Pradesh',
    'Maharashtra',
  ];

  final Map<String, List<String>> districts = {
    'Tamil Nadu': ['Chennai', 'Coimbatore', 'Madurai', 'Trichy', 'Salem'],
    'Kerala': ['Thiruvananthapuram', 'Kochi', 'Kozhikode', 'Thrissur'],
    'Karnataka': ['Bangalore', 'Mysore', 'Hubli', 'Mangalore'],
    'Andhra Pradesh': ['Visakhapatnam', 'Vijayawada', 'Guntur', 'Tirupati'],
    'Maharashtra': ['Mumbai', 'Pune', 'Nagpur', 'Nashik'],
  };

  final Map<String, List<String>> blocks = {
    'Chennai': [
      'North Block',
      'South Block',
      'Central Block',
      'East Block',
      'West Block',
    ],
    'Coimbatore': ['Block A', 'Block B', 'Block C', 'Block D'],
    'Madurai': ['Block 1', 'Block 2', 'Block 3', 'Block 4'],
    'Bangalore': ['Urban Block', 'Rural Block', 'Tech Block'],
    'Mumbai': ['Western Block', 'Eastern Block', 'Central Block'],
  };

  void resetSelection() {
    setState(() {
      selectedState = null;
      selectedDistrict = null;
      selectedBlock = null;
    });
  }

  void confirmSelection() {
    if (selectedState != null &&
        selectedDistrict != null &&
        selectedBlock != null) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location selected: $selectedState, $selectedDistrict, $selectedBlock',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select all fields'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.44, 0.74],
            colors: [
              Color(0xFFC5E2FF), // 44% - Light blue #C5E2FF
              Color(0xFFE6E8FF), // 74% - Light purple #E6E8FF
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Title
                    const Text(
                      'Location Selection',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtitle
                    const Text(
                      'Select your state, district, and block',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Color(0xFF5F6368)),
                    ),

                    const SizedBox(height: 32),

                    // State Label
                    const Text(
                      'State',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // State Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedState,
                          hint: const Text(
                            'Choose a state',
                            style: TextStyle(
                              color: Color(0xFF5F6368),
                              fontSize: 15,
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF5F6368),
                          ),
                          items: states.map((String state) {
                            return DropdownMenuItem<String>(
                              value: state,
                              child: Text(state),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedState = newValue;
                              selectedDistrict = null;
                              selectedBlock = null;
                            });
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // District Label
                    const Text(
                      'District',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // District Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedDistrict,
                          hint: const Text(
                            'Choose a district',
                            style: TextStyle(
                              color: Color(0xFF5F6368),
                              fontSize: 15,
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF5F6368),
                          ),
                          items: selectedState != null
                              ? districts[selectedState]!.map((
                                  String district,
                                ) {
                                  return DropdownMenuItem<String>(
                                    value: district,
                                    child: Text(district),
                                  );
                                }).toList()
                              : [],
                          onChanged: selectedState != null
                              ? (String? newValue) {
                                  setState(() {
                                    selectedDistrict = newValue;
                                    selectedBlock = null;
                                  });
                                }
                              : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Block Label
                    const Text(
                      'Block',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Block Dropdown
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: selectedBlock,
                          hint: const Text(
                            'Choose a block',
                            style: TextStyle(
                              color: Color(0xFF5F6368),
                              fontSize: 15,
                            ),
                          ),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF5F6368),
                          ),
                          items:
                              selectedDistrict != null &&
                                  blocks.containsKey(selectedDistrict)
                              ? blocks[selectedDistrict]!.map((String block) {
                                  return DropdownMenuItem<String>(
                                    value: block,
                                    child: Text(block),
                                  );
                                }).toList()
                              : [],
                          onChanged: selectedDistrict != null
                              ? (String? newValue) {
                                  setState(() {
                                    selectedBlock = newValue;
                                  });
                                }
                              : null,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Confirm Selection Button
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: confirmSelection,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF78909C),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Confirm Selection',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Reset Button
                    SizedBox(
                      height: 50,
                      child: OutlinedButton(
                        onPressed: resetSelection,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF5F6368),
                          side: const BorderSide(
                            color: Color(0xFFE0E0E0),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
