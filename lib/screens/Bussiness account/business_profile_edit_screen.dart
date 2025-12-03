import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'businessaccount _dashboard_screen.dart';
import '../../services/business_profile_service.dart';
import '../../models/business_profile_model.dart';

class BusinessProfileEditScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final BusinessProfile? existingProfile;

  const BusinessProfileEditScreen({
    super.key,
    required this.userData,
    this.existingProfile,
  });

  @override
  State<BusinessProfileEditScreen> createState() =>
      _BusinessProfileEditScreenState();
}

class _BusinessProfileEditScreenState extends State<BusinessProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _mobileController = TextEditingController();
  final _areaController = TextEditingController();
  final _locationController = TextEditingController();

  String? _selectedBusinessType;
  final List<String> _businessTypes = [
    'Manufacturing',
    'Trader',
    'Service Provider',
    'Others',
  ];

  File? _businessLogo;
  bool _isSaving = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    print('🔍 Loading existing profile...');
    print(
      '🔍 widget.existingProfile is null: ${widget.existingProfile == null}',
    );

    if (widget.existingProfile != null) {
      // Use provided profile
      print('✅ Using provided existing profile');
      print(
        '📋 Profile data: name=${widget.existingProfile!.name}, mobile=${widget.existingProfile!.mobile}',
      );
      _populateFields(widget.existingProfile!);
      setState(() {
        _isLoading = false;
      });
    } else {
      // Fetch from backend
      print('🌐 Fetching profile from backend...');
      final memberId =
          widget.userData['_id']?.toString() ??
          widget.userData['id']?.toString() ??
          '';

      if (memberId.isNotEmpty) {
        final profile = await BusinessProfileService.getBusinessProfile(
          memberId,
        );
        if (profile != null) {
          print('✅ Profile fetched from backend');
          print(
            '📋 Profile data: name=${profile.name}, mobile=${profile.mobile}',
          );
          _populateFields(profile);
        } else {
          print('⚠️ No profile found in backend');
        }
      }

      setState(() {
        _isLoading = false;
      });
    }
  }

  void _populateFields(BusinessProfile profile) {
    _businessNameController.text = profile.name;
    _descriptionController.text = profile.description ?? '';
    _mobileController.text = profile.mobile ?? '';
    _areaController.text = profile.area ?? '';
    _locationController.text = profile.location ?? '';
    _selectedBusinessType = profile.industry;
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _mobileController.dispose();
    _areaController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickBusinessLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _businessLogo = File(image.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    print('🟢 _saveProfile called - START');

    if (_formKey.currentState!.validate()) {
      print('🟢 Form validation passed');

      setState(() {
        _isSaving = true;
      });

      try {
        final memberId =
            widget.userData['_id']?.toString() ??
            widget.userData['id']?.toString() ??
            '';

        if (memberId.isEmpty) {
          throw Exception('Member ID not found');
        }

        // Logo upload feature - will be implemented when image upload service is ready
        String? logoUrl;
        if (_businessLogo != null) {
          // Future implementation: Upload to cloud storage and get URL
          logoUrl = null; // Placeholder until upload service is implemented
        }

        print('📱 SAVING MOBILE NUMBER: ${_mobileController.text.trim()}');
        print('📝 Business Name: ${_businessNameController.text.trim()}');
        print('🏢 Business Type: ${_selectedBusinessType ?? "Others"}');

        // Get mobile number - use controller value or fallback to a test number if empty
        final mobileNumber = _mobileController.text.trim().isEmpty
            ? '1234567890' // Temporary test number
            : _mobileController.text.trim();

        print('🔵 Final mobile number to save: $mobileNumber');

        final updates = {
          'organizationName': _businessNameController.text.trim(),
          'businessType': _selectedBusinessType ?? 'Others',
          'businessDescription': _descriptionController.text.trim(),
          'mobile': mobileNumber,
          'area': _areaController.text.trim(),
          'location': _locationController.text.trim(),
          if (logoUrl != null) 'logoUrl': logoUrl,
        };

        print('🚀 CALLING UPDATE WITH:');
        print('   Member ID: $memberId');
        print('   Mobile in updates: ${updates['mobile']}');
        print('   Full updates map: $updates');
        print(
          '   widget.existingProfile != null: ${widget.existingProfile != null}',
        );

        final result = widget.existingProfile != null
            ? await BusinessProfileService.updateBusinessProfile(
                memberId: memberId,
                updates: updates,
              )
            : await BusinessProfileService.saveBusinessProfile(
                memberId: memberId,
                businessName: _businessNameController.text.trim(),
                businessType: _selectedBusinessType ?? 'Others',
                description: _descriptionController.text.trim(),
                mobile: mobileNumber,
                area: _areaController.text.trim(),
                location: _locationController.text.trim(),
                logoUrl: logoUrl,
              );

        print(
          '📞 API Method called: ${widget.existingProfile != null ? "updateBusinessProfile" : "saveBusinessProfile"}',
        );

        print('🎯 UPDATE RESULT: ${result['success']}');
        print('🎯 UPDATE MESSAGE: ${result['message']}');
        print('🎯 UPDATE DATA: ${result['data']}');

        if (mounted) {
          if (result['success'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result['message'] ?? 'Business profile saved successfully!',
                ),
                backgroundColor: Colors.green,
              ),
            );

            // Small delay to ensure DB is updated
            await Future.delayed(const Duration(milliseconds: 500));

            // Pop with true to signal successful update and trigger dashboard refresh
            Navigator.pop(context, true);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result['message'] ?? 'Failed to save profile'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSaving = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB3D4FF), Color(0xFFE6D8FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 20,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Business Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 15,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Upload Business Logo
                                  Center(
                                    child: GestureDetector(
                                      onTap: _pickBusinessLogo,
                                      child: Container(
                                        width: 120,
                                        height: 120,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F7FA),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                            width: 2,
                                          ),
                                        ),
                                        child: _businessLogo != null
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                child: Image.file(
                                                  _businessLogo!,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .add_photo_alternate_outlined,
                                                    size: 40,
                                                    color: Colors.grey.shade400,
                                                  ),
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    'Upload Logo',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),

                                  // Business Name
                                  const Text(
                                    'Business Name',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _businessNameController,
                                    decoration: InputDecoration(
                                      hintText: 'Enter business name',
                                      filled: true,
                                      fillColor: const Color(0xFFF5F7FA),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Description
                                  const Text(
                                    'Description',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _descriptionController,
                                    maxLines: 4,
                                    decoration: InputDecoration(
                                      hintText: 'Describe your business...',
                                      filled: true,
                                      fillColor: const Color(0xFFF5F7FA),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.all(16),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Business Type
                                  const Text(
                                    'Business Type',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  DropdownButtonFormField<String>(
                                    value: _selectedBusinessType,
                                    decoration: InputDecoration(
                                      hintText: 'Select business type',
                                      filled: true,
                                      fillColor: const Color(0xFFF5F7FA),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                    ),
                                    items: _businessTypes.map((String type) {
                                      return DropdownMenuItem<String>(
                                        value: type,
                                        child: Text(type),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedBusinessType = newValue;
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 20),

                                  // Mobile Number
                                  const Text(
                                    'Mobile Number',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _mobileController,
                                    keyboardType: TextInputType.phone,
                                    decoration: InputDecoration(
                                      hintText: 'Enter mobile number',
                                      filled: true,
                                      fillColor: const Color(0xFFF5F7FA),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Area
                                  const Text(
                                    'Area',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _areaController,
                                    decoration: InputDecoration(
                                      hintText: 'Enter area',
                                      filled: true,
                                      fillColor: const Color(0xFFF5F7FA),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Location
                                  const Text(
                                    'Location',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: _locationController,
                                    decoration: InputDecoration(
                                      hintText: 'Enter location',
                                      filled: true,
                                      fillColor: const Color(0xFFF5F7FA),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  // Save and Cancel Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _isSaving
                                              ? null
                                              : () => Navigator.pop(context),
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            side: BorderSide(
                                              color: Colors.grey.shade400,
                                              width: 1.5,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey.shade700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _isSaving
                                              ? null
                                              : _saveProfile,
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            backgroundColor: const Color(
                                              0xFF2196F3,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: _isSaving
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                )
                                              : const Text(
                                                  'Save Profile',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.white,
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
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
