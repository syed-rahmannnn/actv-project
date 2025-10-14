import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  final Map<String, dynamic> completeData;
  const DashboardScreen({Key? key, required this.completeData}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use a fallback if empty
    final displayName = (completeData['fullName'] ?? '').toString().trim();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            children: [
              // Top header card (you can replace with your existing layout)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE6F0FF), Color(0xFFF0E9FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  children: [
                    // avatar
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: AssetImage('assets/images/default_avatar.png'), // change if you have an actual image url
                    ),
                    const SizedBox(width: 12),
                    // welcome text + company
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back, $displayName',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'TechCorp Solution', // keep or replace with dynamic company if available
                            style: TextStyle(fontSize: 12, color: Colors.black54),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Search bar / card etc. (you can keep your existing UI)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration.collapsed(hintText: 'Search by location...'),
                      ),
                    ),
                    Icon(Icons.search, color: Colors.grey[600]),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Example card
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text('Complete Your Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                            SizedBox(height: 8),
                            Text('65% completed\nUnlock all features by completing your profile.'),
                          ],
                        ),
                      ),
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: Image(
                          image: AssetImage('assets/images/profile_complete.png'), // optional
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // rest of your dashboard content...
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explore'),
        BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notifications'),
      ],
    );
  }
}
