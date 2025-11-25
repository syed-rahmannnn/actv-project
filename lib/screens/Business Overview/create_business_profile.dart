import 'package:flutter/material.dart';
import 'manage_business_page.dart';

class CreateBusinessProfile extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const CreateBusinessProfile({super.key, this.userData});

  @override
  State<CreateBusinessProfile> createState() => _CreateBusinessProfileState();
}

class _CreateBusinessProfileState extends State<CreateBusinessProfile> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String? _businessType;
  int _descChars = 0;

  final List<String> _businessTypes = [
    'Retail',
    'Services',
    'Manufacturing',
    'Agriculture',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill from userData when available
    final u = widget.userData ?? {};
    _nameController.text = u['businessName'] ?? u['organization_name'] ?? '';
    _locationController.text = u['location'] ?? '';
    _descriptionController.addListener(() {
      setState(() {
        _descChars = _descriptionController.text.length;
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    print('🔥 _saveProfile called');
    print('🔥 Business Type: $_businessType');
    print('🔥 Name: ${_nameController.text}');
    print('🔥 Description: ${_descriptionController.text}');
    print('🔥 Location: ${_locationController.text}');

    final isValid = _formKey.currentState?.validate() ?? false;
    print('🔥 Form validation result: $isValid');

    if (isValid) {
      print('🔥 Validation passed, creating businessData');

      // Prepare business data to pass to manage page
      final businessData = {
        'businessName': _nameController.text,
        'description': _descriptionController.text,
        'businessType': _businessType,
        'location': _locationController.text,
      };

      print('🔥 businessData created: $businessData');
      print('🔥 Navigating to ManageBusinessPage immediately');

      // Navigate to manage business page (replace current), use root navigator
      Navigator.of(context, rootNavigator: true)
          .pushReplacement(
            MaterialPageRoute(
              builder: (context) {
                print('🔥 ManageBusinessPage builder called');
                return ManageBusinessPage(businessData: businessData);
              },
            ),
          )
          .then((_) {
            print(
              '🔥 Navigation completed successfully - user returned from ManageBusinessPage',
            );
          })
          .catchError((error) {
            print('🔥 Navigation error: $error');
          });
    } else {
      print('🔥 Validation failed - showing error message');
      // Show validation error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Business Profile',
          style: TextStyle(color: Colors.black87, fontSize: 16),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // TODO: implement image picker
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Upload logo tapped')),
                        );
                      },
                      child: CircleAvatar(
                        radius: 36,
                        backgroundColor: Colors.blue.shade50,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.business, color: Colors.blue, size: 28),
                            SizedBox(height: 4),
                            Text(
                              'Upload\nbusiness logo',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              const Text('Business Name *', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter business name'
                    : null,
              ),

              const SizedBox(height: 12),
              const Text('Description *', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descriptionController,
                maxLines: 6,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Describe your business...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a description'
                    : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$_descChars/500 characters',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ),

              const SizedBox(height: 12),
              const Text('Business Type *', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _businessType,
                items: _businessTypes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _businessType = v),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'Please select business type'
                    : null,
              ),

              const SizedBox(height: 12),
              const Text('Location *', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  hintText: 'City, Country',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter location'
                    : null,
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    print('🔥🔥🔥 Save Profile button tapped!');
                    _saveProfile();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Save Profile',
                    style: TextStyle(fontSize: 15, color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
