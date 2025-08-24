import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const ProfileScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Text(
          'Profile Screen for ${userData['fullName'] ?? 'User'}',
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}