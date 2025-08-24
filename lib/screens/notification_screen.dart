import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontFamily: 'YourFont', fontWeight: FontWeight.bold)),
        backgroundColor: Colors.deepPurple, // Use the same color as your explore page
      ),
      body: Container(
        color: Colors.deepPurple.shade50, // Match explore page background
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              color: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: Icon(Icons.notifications, color: Colors.deepPurple),
                title: Text('Welcome to ACTIV!', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Your account has been created.'),
              ),
            ),
            // Add more notification cards here
          ],
        ),
      ),
    );
  }
}
