import 'package:flutter/material.dart';
import 'package:activ/models/company_model.dart';
import 'package:activ/services/company_service.dart';

class EditCompanyScreen extends StatefulWidget {
  final Company company;
  final Map<String, dynamic> userData;

  const EditCompanyScreen({
    super.key,
    required this.company,
    required this.userData,
  });

  @override
  State<EditCompanyScreen> createState() => _EditCompanyScreenState();
}

class _EditCompanyScreenState extends State<EditCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _industryController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _locationController = TextEditingController();
  final _cityController = TextEditingController();
  final _areaController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with existing company data
    _nameController.text = widget.company.name;
    _industryController.text = widget.company.industry ?? '';
    _mobileController.text = widget.company.mobile ?? '';
    _emailController.text = widget.company.email ?? '';
    _websiteController.text = widget.company.website ?? '';
    _locationController.text = widget.company.location ?? '';
    _cityController.text = widget.company.city ?? '';
    _areaController.text = widget.company.area ?? '';
    _descriptionController.text = widget.company.description ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _industryController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _locationController.dispose();
    _cityController.dispose();
    _areaController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormCard(),
                        const SizedBox(height: 24),
                        _buildSaveButton(),
                      ],
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

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Edit Company',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _nameController,
            label: 'Company Name',
            icon: Icons.business,
            required: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _industryController,
            label: 'Industry / Business Type',
            icon: Icons.category,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _mobileController,
            label: 'Mobile Number',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _websiteController,
            label: 'Website',
            icon: Icons.language,
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _locationController,
            label: 'Location',
            icon: Icons.location_on,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _cityController,
            label: 'City',
            icon: Icons.location_city,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _areaController,
            label: 'Area',
            icon: Icons.map,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            icon: Icons.description,
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      validator: required
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'This field is required';
              }
              return null;
            }
          : null,
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveChanges,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Save Changes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      print('📝 Updating company: ${widget.company.id}');
      
      final updatedCompany = await CompanyService.updateCompany(
        companyId: widget.company.id,
        name: _nameController.text.trim(),
        industry: _industryController.text.trim().isEmpty ? null : _industryController.text.trim(),
        mobile: _mobileController.text.trim().isEmpty ? null : _mobileController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        area: _areaController.text.trim().isEmpty ? null : _areaController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Company updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Return the updated company to refresh previous screens
        Navigator.pop(context, updatedCompany);
      }
    } catch (e) {
      print('❌ Error updating company: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update company: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
