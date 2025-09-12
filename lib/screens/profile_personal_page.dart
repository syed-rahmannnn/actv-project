import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'business_information_screen.dart';

class ProfilePersonalPage extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ProfilePersonalPage({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Personal & Demographic Details',
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
              _section(
                'Personal & Demographic Details',
                [
                  _kv('Name', userData['registrationForm']?['fullName'] ?? '—'),
                  _kv('Block', userData['registrationForm']?['block'] ?? '—'),
                  _kv('City', userData['registrationForm']?['city'] ?? '—'),
                  _kv('District', userData['registrationForm']?['district'] ?? '—'),
                  _kv('Phone Number', userData['registrationForm']?['phoneNumber'] ?? '—'),
                  _kv('Email ID', userData['email'] ?? '—'),
                  _kv('Date of Birth', userData['registrationForm']?['dateOfBirth'] ?? '—'),
                  _kv('Aadhaar No.', userData['registrationForm']?['aadhaarNumber'] ?? '—'),
                  _kv('Street Name', userData['registrationForm']?['streetName'] ?? '—'),
                  _kv('Educational Qualification', userData['registrationForm']?['educationalQualification'] ?? '—'),
                  _kv('Religion', userData['registrationForm']?['religion'] ?? '—'),
                  _kv('Social Category', userData['registrationForm']?['socialCategory'] ?? '—'),
                ],
              ),
              const SizedBox(height: 24),
              _navRow(context),
              const SizedBox(height: 16),
              _logoutButton(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> rows) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 8),
          ...rows,
        ],
      ),
    );
  }

  Widget _kv(String k, String v) {
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
          Expanded(child: Text(k, style: const TextStyle(fontSize: 12, color: Colors.grey))),
          const SizedBox(width: 12),
          Text(v, style: const TextStyle(fontSize: 12, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _navRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.purple), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), minimumSize: const Size.fromHeight(48)),
            child: const Text('Previous', style: TextStyle(color: Colors.purple, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BusinessInformationScreen(userData: userData),
              ),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), minimumSize: const Size.fromHeight(48)),
            child: const Text('Next >', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
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

  Widget _logoutButton(BuildContext context) {
    return TextButton(
      onPressed: () async {
        await AuthService.logout();
        if (context.mounted) Navigator.of(context).pushReplacementNamed('/login');
      },
      child: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
    );
  }
}
