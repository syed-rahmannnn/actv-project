import 'package:flutter/material.dart';
import 'package:activ/services/auth_service.dart';
import 'package:activ/services/api_service.dart';

class ProfileDetailScreen extends StatefulWidget {
  const ProfileDetailScreen({super.key});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  bool personalExpanded = true; // Start expanded

  Future<Map<String, dynamic>?> _loadMemberFromBackend() async {
    try {
      // Get user data from AuthService instead of Firebase
      final userData = await AuthService.getUserData();
      if (userData == null) return null;
      
      final email = userData['email'] ?? userData['member']?['email'];
      if (email == null) return userData;
      
      final res = await ApiService.getMemberByEmail(email);
      if (res['success'] == true) {
        // Normalize to structure similar to previous userData for minimal UI changes
        final member = Map<String, dynamic>.from(res['data'] as Map);
        return {
          'email': email,
          'fullName': member['fullName'],
          'phoneNumber': member['phoneNumber'],
          'dateOfBirth': member['dateOfBirth'],
          'registrationForm': {
            'fullName': member['fullName'],
            'phoneNumber': member['phoneNumber'],
            'dateOfBirth': member['dateOfBirth'],
            'state': member['state'],
            'district': member['district'],
            'block': member['block'],
            'completeAddress': member['address'],
          }
        };
      }
      return await AuthService.getUserData();
    } catch (_) {
      return await AuthService.getUserData();
    }
  }

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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black54),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile Picture and Name
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/profile.png',
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.person,
                                size: 50,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // User Name
                    FutureBuilder<Map<String, dynamic>?>(
                      future: AuthService.getUserData(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          final userData = snapshot.data!;
                          final registrationForm = userData['registrationForm'] as Map<String, dynamic>?;
                          return Text(
                            registrationForm?['fullName'] ?? userData['fullName'] ?? 'Tamilarasan',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          );
                        }
                        return const Text(
                          'Tamilarasan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Personal & Demographic Details Section
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Section Header
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          personalExpanded = !personalExpanded;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Personal Details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Icon(
                              personalExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                              color: Colors.grey[600],
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Personal Details Content
                    if (personalExpanded) ...[
                      const Divider(height: 1, color: Colors.grey),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: FutureBuilder<Map<String, dynamic>?>(
                          future: _loadMemberFromBackend(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData && snapshot.data != null) {
                              final userData = snapshot.data!;
                              final registrationForm = userData['registrationForm'] as Map<String, dynamic>?;
                              
                              String s(dynamic v) => (v == null || (v is String && v.isEmpty)) ? '—' : v.toString();
                              return Column(
                                children: [
                                  _buildDetailRow('Name', s(registrationForm?['fullName'] ?? userData['fullName'])),
                                  _buildDetailRow('Block', s(registrationForm?['block'])),
                                  _buildDetailRow('State', s(registrationForm?['state'])),
                                  _buildDetailRow('District', s(registrationForm?['district'])),
                                  _buildDetailRow('Phone Number', s(registrationForm?['phoneNumber'] ?? userData['phoneNumber'])),
                                  _buildDetailRow('Email ID', s(userData['email'])),
                                  _buildDetailRow('Date of Birth', s(_formatDate(registrationForm?['dateOfBirth'] ?? userData['dateOfBirth']))),
                                  _buildDetailRow('Street Name', s(registrationForm?['completeAddress'])),
                                ],
                              );
                            }
                            
                            // Default data when no user data is available (matching the image)
                            return const Center(
                              child: Text(
                                'No profile data found',
                                style: TextStyle(color: Colors.grey),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  String? _formatDate(dynamic date) {
    if (date == null) return null;
    
    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return null;
      }
      
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return null;
    }
  }
}
