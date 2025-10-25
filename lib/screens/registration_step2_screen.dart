import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dashboard_screen.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/user_profile_provider.dart';
import '../utils/locations.dart';

class RegistrationStep2Screen extends StatefulWidget {
  final Map<String, dynamic> personalData;

  const RegistrationStep2Screen({super.key, required this.personalData});

  @override
  State<RegistrationStep2Screen> createState() =>
      _RegistrationStep2ScreenState();
}

class _RegistrationStep2ScreenState extends State<RegistrationStep2Screen> {
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  
  Locations? _locations;
  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedBlock;
  bool _isLoading = false;

  // Removed unused hardcoded _states; using _locations.getStateNames()

  // Removed unused _stateDistricts; using Locations.districtsForState()

  // Removed unused _districts getter; districts now derived via _locations.districtsForState

  @override
  void initState() {
    super.initState();
    loadLocationsFromAsset().then((loc) {
      if (mounted) {
        setState(() => _locations = loc);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE6F0FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE6F0FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Member Registration',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Step 2 of 2',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 30),

            // Tab indicator
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 1),
                      ),
                    ),
                    child: const Text(
                      'Personal Info',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                    child: const Text(
                      'Location',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Registration Form Card
            Container(
              padding: const EdgeInsets.all(24),
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
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Registration Form',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Location Details Section
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Location Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // State Field
                    const Text(
                      'State*',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedState,
                      hint: const Text('Select state'),
                      decoration: InputDecoration(
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
                      ),
                      items: (_locations?.getStateNames() ?? [])
                          .map((String state) => DropdownMenuItem<String>(
                                value: state,
                                child: Text(state),
                              ))
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedState = newValue;
                          _selectedDistrict = null;
                          _selectedBlock = null; // Reset block when state changes
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a state';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // District Field
                    const Text(
                      'District*',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedDistrict,
                      hint: const Text('Select district'),
                      decoration: InputDecoration(
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
                      ),
                      items: (_selectedState == null || _locations == null
                              ? <String>[]
                              : _locations!.districtsForState(_selectedState!))
                          .map((String district) => DropdownMenuItem<String>(
                                value: district,
                                child: Text(district),
                              ))
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedDistrict = newValue;
                          _selectedBlock = null; // Reset block when district changes
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a district';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // City Field
                    const Text(
                      'City*',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        hintText: 'Enter city name',
                        hintStyle: TextStyle(color: Colors.grey[400]),
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
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter city name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Block Field
                    const Text(
                      'Block*',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedBlock,
                      hint: const Text('Select block'),
                      decoration: InputDecoration(
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
                      ),
                      items: (_selectedState == null || _selectedDistrict == null || _locations == null
                              ? <String>[]
                              : _locations!.blocksForDistrict(_selectedState!, _selectedDistrict!))
                          .map((String block) => DropdownMenuItem<String>(
                                value: block,
                                child: Text(block),
                              ))
                          .toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedBlock = newValue;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a block';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    const SizedBox(height: 40),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text(
                                'Previous',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
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
                              onPressed: _isLoading
                                  ? null
                                  : _handleRegistration,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : const Text(
                                      'Submit',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
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
            ),
          ],
        ),
      ),
    );
  }

  // Handle registration submission
  Future<void> _handleRegistration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use DOB exactly in DD-MM-YYYY format
      final dobString = widget.personalData['dob'] as String;
      final dobParts = dobString.split('-');
      final dateOfBirthDDMMYYYY =
          '${dobParts[0].padLeft(2, '0')}-${dobParts[1].padLeft(2, '0')}-${dobParts[2]}';

      // Create ApiService instance
      final apiService = ApiService();

      // Prepare registration payload
      final payload = {
        "fullName": widget.personalData['fullName'],
        "email": widget.personalData['email'],
        "phoneNumber": widget.personalData['phone'],
        // Store DOB as DD-MM-YYYY string
        "dateOfBirth": dateOfBirthDDMMYYYY,
        "gender": widget.personalData['gender'],
        "password": widget.personalData['password'],
        "block": _selectedBlock!.trim(),
        "city": _cityController.text.trim(),
        "district": _selectedDistrict!.trim(),
        "state": _selectedState!.trim(),
        "pincode": widget.personalData['pincode'] ?? '000000',
      };

      final result = await apiService.register(payload);
      if (!mounted) return;

      if (result['ok'] == true) {
        // Registration successful
        // Persist token and member for subsequent screens
        final member = Map<String, dynamic>.from(
          result['body']['data']['member'] as Map,
        );
        final token = result['token'] as String;
        await AuthService.saveLoginData(token: token, userData: member);
        if (!mounted) return;

        // Store location data in UserProfileProvider for later use
        context.read<UserProfileProvider>().updateLocation(
          state: _selectedState!.trim(),
          district: _selectedDistrict!.trim(),
          block: _selectedBlock!.trim(),
          city: _cityController.text.trim(),
        );

        // Combine all data for dashboard display
        final completeData = {
          ...widget.personalData,
          'state': _selectedState!.trim(),
          'district': _selectedDistrict!.trim(),
          'city': _cityController.text.trim(),
          'block': _selectedBlock!.trim(),
          'member': result['body']['data']['member'],
          'token': result['token'],
        };

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(userData: completeData),
          ),
        );

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        if (!mounted) return;
        // Registration failed
        final errorMessage =
            result['body']?['message'] ?? 'Registration failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'An error occurred: $e';

        // Provide user-friendly error messages for common issues
        if (e.toString().contains('blocked') ||
            e.toString().contains('unusual activity')) {
          errorMessage =
              'Registration temporarily unavailable. Please try again in a few minutes.';
        } else if (e.toString().contains('network') ||
            e.toString().contains('connection')) {
          errorMessage =
              'Network error. Please check your internet connection and try again.';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Request timed out. Please try again.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () {
                // Retry the registration after a short delay
                Future.delayed(const Duration(seconds: 2), () {
                  _handleRegistration();
                });
              },
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }
}
