import 'package:flutter/material.dart';
import 'financial_compliance_screen.dart';

class BusinessInformationScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const BusinessInformationScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Business Information',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Header
              _buildProfileHeader(),
              const SizedBox(height: 24),
              
              // Personal & Demographic Details (Collapsed)
              _buildCollapsedSection(
                'Personal & Demographic Details',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BusinessInformationScreen(userData: userData),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Business Information (Expanded)
              _buildExpandedSection(
                'Business Information',
                'Company and registration details',
                [
                  _buildKeyValue('Business Name', userData['businessInfo']?['businessName'] ?? 'Johnson Enterprises'),
                  _buildKeyValue('Business Type', userData['businessInfo']?['businessType'] ?? 'Private Limited'),
                  _buildKeyValue('Industry', userData['businessInfo']?['industry'] ?? 'Information Technology'),
                  _buildKeyValue('GST Number', userData['businessInfo']?['gstNumber'] ?? '27ABCDE1234F1Z5'),
                  _buildKeyValue('PAN Number', userData['businessInfo']?['panNumber'] ?? 'ABCDE1234F'),
                  _buildKeyValue('Business Address', userData['businessInfo']?['businessAddress'] ?? 'Tower 5, Tech Park, Mumbai'),
                  _buildKeyValue('Annual Turnover', userData['businessInfo']?['annualTurnover'] ?? '₹5 Crores'),
                  _buildKeyValue('Number of Employees', userData['businessInfo']?['employeeCount'] ?? '120'),
                  _buildKeyValue('Business Email', userData['businessInfo']?['businessEmail'] ?? 'contact@johnsonenterprises.com'),
                  _buildKeyValue('Business Phone', userData['businessInfo']?['businessPhone'] ?? '+91 9876601234'),
                ],
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BusinessInformationScreen(userData: userData),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              
              // Financial & Compliance (Collapsed)
              _buildCollapsedSection(
                'Financial & Compliance',
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FinancialComplianceScreen(userData: userData),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedSection(String title, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedSection(String title, String subtitle, List<Widget> children, VoidCallback onTap) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildKeyValue(String key, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              key,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Picture
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[200],
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: userData['registrationForm']?['profilePicture'] != null
                  ? Image.network(
                      userData['registrationForm']['profilePicture'],
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.person,
                          size: 40,
                          color: Colors.grey,
                        );
                      },
                    )
                  : const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey,
                    ),
            ),
          ),
          const SizedBox(height: 12),
          // Name
          Text(
            userData['registrationForm']?['fullName'] ?? 'Tamilarasan',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
