import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfileScreen({
    super.key,
    required this.userData,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool personalExpanded = false;
  bool businessExpanded = false;
  bool financialExpanded = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'My profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black54),
            onPressed: () {
              // Show more options
            },
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Profile Picture and Name Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
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
                        child: widget.userData['registrationForm']?['profilePicture'] != null
                            ? Image.network(
                                widget.userData['registrationForm']['profilePicture'],
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
                      widget.userData['registrationForm']?['fullName'] ?? 'Tamilarasan',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Expandable Sections
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F0FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFB3D9FF), width: 1),
                ),
                child: Column(
                  children: [
                    // Personal & Demographic Details
                    _buildExpandableSection(
                      'Personal & Demographic Details',
                      personalExpanded,
                      () {
                        setState(() {
                          personalExpanded = !personalExpanded;
                        });
                      },
                      _buildPersonalDetails(),
                    ),
                    
                    // Business Information
                    _buildExpandableSection(
                      'Business Information',
                      businessExpanded,
                      () {
                        setState(() {
                          businessExpanded = !businessExpanded;
                        });
                      },
                      _buildBusinessInformation(),
                    ),
                    
                    // Financial & Compliance
                    _buildExpandableSection(
                      'Financial & Compliance',
                      financialExpanded,
                      () {
                        setState(() {
                          financialExpanded = !financialExpanded;
                        });
                      },
                      _buildFinancialCompliance(),
                    ),
                    
                    // Logout Button
                    _buildLogoutButton(),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Home', true),
                _buildNavItem(Icons.explore, 'Explore', false),
                _buildNavItem(Icons.notifications, 'Notifications', false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandableSection(String title, bool isExpanded, VoidCallback onTap, Widget content) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.grey[600],
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: content,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildPersonalDetails() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildDetailRow('Name', widget.userData['registrationForm']?['fullName'] ?? 'Sarah Johnson'),
          _buildDetailRow('Block', widget.userData['registrationForm']?['block'] ?? 'Downtown'),
          _buildDetailRow('City', widget.userData['registrationForm']?['city'] ?? 'Mumbai'),
          _buildDetailRow('District', widget.userData['registrationForm']?['district'] ?? 'Mumbai Central'),
          _buildDetailRow('Phone Number', widget.userData['registrationForm']?['phoneNumber'] ?? '+91 9876543210'),
          _buildDetailRow('Email ID', widget.userData['email'] ?? 'sarah.j@email.com'),
          _buildDetailRow('Date of Birth', widget.userData['registrationForm']?['dateOfBirth'] ?? '15/08/1985'),
          _buildDetailRow('Aadhaar No.', widget.userData['registrationForm']?['aadhaarNumber'] ?? 'XXXX-XXXX-3456'),
          _buildDetailRow('Street Name', widget.userData['registrationForm']?['streetName'] ?? 'MG Road, Sector 15'),
          _buildDetailRow('Educational Qualification', widget.userData['registrationForm']?['educationalQualification'] ?? 'MBA'),
          _buildDetailRow('Religion', widget.userData['registrationForm']?['religion'] ?? 'Hindu'),
          _buildDetailRow('Social Category', widget.userData['registrationForm']?['socialCategory'] ?? 'General'),
        ],
      ),
    );
  }

  Widget _buildBusinessInformation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildDetailRow('Business Name', widget.userData['businessInfo']?['businessName'] ?? 'Johnson Enterprises'),
          _buildDetailRow('Business Type', widget.userData['businessInfo']?['businessType'] ?? 'Private Limited'),
          _buildDetailRow('Industry', widget.userData['businessInfo']?['industry'] ?? 'Information Technology'),
          _buildDetailRow('GST Number', widget.userData['businessInfo']?['gstNumber'] ?? '27ABCDE1234F1Z5'),
          _buildDetailRow('PAN Number', widget.userData['businessInfo']?['panNumber'] ?? 'ABCDE1234F'),
          _buildDetailRow('Business Address', widget.userData['businessInfo']?['businessAddress'] ?? 'Tower 5, Tech Park, Mumbai'),
          _buildDetailRow('Annual Turnover', widget.userData['businessInfo']?['annualTurnover'] ?? '₹5 Crores'),
          _buildDetailRow('Number of Employees', widget.userData['businessInfo']?['employeeCount'] ?? '120'),
          _buildDetailRow('Business Email', widget.userData['businessInfo']?['businessEmail'] ?? 'contact@johnsonenterprises.com'),
          _buildDetailRow('Business Phone', widget.userData['businessInfo']?['businessPhone'] ?? '+91 9876601234'),
        ],
      ),
    );
  }

  Widget _buildFinancialCompliance() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildDetailRow('Bank Name', widget.userData['financialInfo']?['bankName'] ?? 'HDFC Bank'),
          _buildDetailRow('Account Number', widget.userData['financialInfo']?['accountNumber'] ?? 'XXXX-XXXX-7890'),
          _buildDetailRow('IFSC Code', widget.userData['financialInfo']?['ifscCode'] ?? 'HDFC0001234'),
          _buildDetailRow('Branch', widget.userData['financialInfo']?['branch'] ?? 'Mumbai Central'),
          _buildDetailRow('Tax Registration No (TIN)', widget.userData['financialInfo']?['tinNumber'] ?? '27345678901'),
          _buildDetailRowWithStatus('GST Compliance', 'Yes', true),
          _buildDetailRowWithStatus('Income Tax Filing Status', 'Up to Date', true),
          _buildDetailRowWithBadge('Credit Rating', 'A+', Colors.green),
          _buildDetailRow('Financial Year', widget.userData['financialInfo']?['financialYear'] ?? '2023-24'),
          _buildDetailRowWithStatus('Compliance Status', 'Verified', true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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

  Widget _buildDetailRowWithStatus(String key, String value, bool isVerified) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
          Row(
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isVerified ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isVerified ? Icons.check : Icons.close,
                  size: 8,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRowWithBadge(String key, String value, Color badgeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: badgeColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        // Add logout functionality here
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logout functionality coming soon!'),
            backgroundColor: Colors.red,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                'Logout',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.red,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.red[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return GestureDetector(
      onTap: () {
        if (label == 'Home') {
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label feature coming soon!'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? Colors.blue : Colors.grey[600],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive ? Colors.blue : Colors.grey[600],
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}


