import 'package:flutter/material.dart';
import 'package:activ/models/company_model.dart';
import 'package:activ/services/company_service.dart';
import 'edit_company_screen.dart';

class CompanyDetailsScreen extends StatefulWidget {
  final String companyId;
  final Map<String, dynamic> userData;

  const CompanyDetailsScreen({
    super.key,
    required this.companyId,
    required this.userData,
  });

  @override
  State<CompanyDetailsScreen> createState() => _CompanyDetailsScreenState();
}

class _CompanyDetailsScreenState extends State<CompanyDetailsScreen> {
  Company? _company;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCompanyDetails();
  }

  Future<void> _loadCompanyDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('📋 Loading company details: ${widget.companyId}');
      final company = await CompanyService.getCompany(widget.companyId);
      
      if (company == null) {
        throw Exception('Company not found');
      }

      setState(() {
        _company = company;
        _isLoading = false;
      });
      print('✅ Company loaded: ${company.name}');
    } catch (e) {
      print('❌ Error loading company: $e');
      setState(() {
        _errorMessage = 'Unable to load company details. Please try again.';
        _isLoading = false;
      });
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
              _buildHeader(),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                        ? _buildErrorState()
                        : _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context, _company), // Return updated company
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
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _company != null ? _navigateToEdit : null,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadCompanyDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_company == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Business Logo
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: _company!.logoUrl != null && _company!.logoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          _company!.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildLogoPlaceholder(),
                        ),
                      )
                    : _buildLogoPlaceholder(),
              ),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Business Logo',
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 24),

            // Form Fields in White Card
            Container(
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
                  _buildReadOnlyField('Business Name', _company!.name, Icons.business),
                  const SizedBox(height: 20),
                  _buildReadOnlyTextField(
                    'Description',
                    _company!.description ?? 'No description',
                    Icons.description,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),
                  _buildReadOnlyField(
                    'Business Type',
                    _company!.industry ?? 'Not specified',
                    Icons.category,
                    suffixIcon: Icons.arrow_drop_down,
                  ),
                  const SizedBox(height: 20),
                  _buildReadOnlyField(
                    'Mobile Number',
                    _company!.mobile ?? 'Not specified',
                    Icons.phone,
                  ),
                  const SizedBox(height: 20),
                  _buildReadOnlyField(
                    'Area',
                    _company!.area ?? 'Not specified',
                    Icons.map,
                  ),
                  const SizedBox(height: 20),
                  _buildReadOnlyField(
                    'Location',
                    _company!.location ?? 'Not specified',
                    Icons.location_on,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Additional Info Card
            if (_company!.city != null || _company!.email != null || _company!.website != null)
              Container(
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
                    const Text(
                      'Additional Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_company!.city != null && _company!.city!.isNotEmpty)
                      _buildInfoRow(Icons.location_city, 'City', _company!.city!),
                    if (_company!.email != null && _company!.email!.isNotEmpty)
                      _buildInfoRow(Icons.email, 'Email', _company!.email!),
                    if (_company!.website != null && _company!.website!.isNotEmpty)
                      _buildInfoRow(Icons.language, 'Website', _company!.website!),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey.shade400),
        const SizedBox(height: 8),
        Text(
          'No Logo',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(
    String label,
    String value,
    IconData icon, {
    IconData? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                  ),
                ),
              ),
              if (suffixIcon != null)
                Icon(suffixIcon, color: Colors.grey.shade400, size: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyTextField(
    String label,
    String value,
    IconData icon, {
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                  maxLines: maxLines,
                  overflow: TextOverflow.visible,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateToEdit() async {
    if (_company == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditCompanyScreen(
          company: _company!,
          userData: widget.userData,
        ),
      ),
    );

    // Reload company details if edited
    if (result != null) {
      _loadCompanyDetails();
    }
  }
}
