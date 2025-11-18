import 'package:flutter/material.dart';

class BrowseMembersScreen extends StatefulWidget {
  const BrowseMembersScreen({super.key});

  @override
  State<BrowseMembersScreen> createState() => _BrowseMembersScreenState();
}

class _BrowseMembersScreenState extends State<BrowseMembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  // Sample members data
  final List<Map<String, dynamic>> members = [
    {
      'name': 'Aditi Sharma',
      'role': 'Community Leader',
      'gender': 'Female',
      'location': 'Adidravidar Block',
      'initials': 'AS',
      'color': Color(0xFF4285F4),
      'isActive': true,
    },
    {
      'name': 'Rajesh Kumar',
      'role': 'Block Coordinator',
      'gender': 'Male',
      'location': 'Central Block',
      'initials': 'RK',
      'color': Color(0xFF4285F4),
      'isActive': true,
    },
    {
      'name': 'Priya Patel',
      'role': 'Member',
      'gender': 'Female',
      'location': 'North Block',
      'initials': 'PP',
      'color': Color(0xFF4285F4),
      'isActive': true,
    },
    {
      'name': 'Suresh Reddy',
      'role': 'District Admin',
      'gender': 'Male',
      'location': 'South Block',
      'initials': 'SR',
      'color': Color(0xFF4285F4),
      'isActive': true,
    },
    {
      'name': 'Meera Singh',
      'role': 'Member',
      'gender': 'Female',
      'location': 'East Block',
      'initials': 'MS',
      'color': Color(0xFF4285F4),
      'isActive': true,
    },
    {
      'name': 'Amit Gupta',
      'role': 'Block Admin',
      'gender': 'Male',
      'location': 'West Block',
      'initials': 'AG',
      'color': Color(0xFF4285F4),
      'isActive': true,
    },
    {
      'name': 'Kavya Nair',
      'role': 'Member',
      'gender': 'Female',
      'location': 'Central Block',
      'initials': 'KN',
      'color': Color(0xFF4285F4),
      'isActive': true,
    },
    {
      'name': 'Ravi Verma',
      'role': 'Community Volunteer',
      'gender': 'Male',
      'location': 'North Block',
      'initials': 'RV',
      'color': Color(0xFF4285F4),
      'isActive': true,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section with White Background
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Back Button and Title
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Column(
                            children: [
                              Text(
                                'Browse Members',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF202124),
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Connect with community members and leaders',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF5F6368),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 48), // Balance for back button
                      ],
                    ),
                  ),
                  
                  // Breadcrumb
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: const Color(0xFFE3F2FD),
                    child: Row(
                      children: [
                        Text(
                          'Home',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          '  >  ',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                        const Text(
                          'Members',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1976D2),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search by name, area, or role',
                        hintStyle: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey[600],
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF4285F4), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Members List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  return _buildMemberCard(members[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          // Header: Avatar, Name, and Active Badge
          Row(
            children: [
              // Avatar with Initials
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: member['color'],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    member['initials'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Name and Role
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member['name'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF202124),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          member['role'],
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF5F6368),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF5F6368),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          member['gender'],
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF5F6368),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Active Badge
              if (member['isActive'])
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4285F4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Activ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Location
          Row(
            children: [
              const Text(
                'Location: ',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF5F6368),
                ),
              ),
              Text(
                member['location'],
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF202124),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // View profile functionality
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4285F4),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'View Profile',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // Connect functionality
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF34A853),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Connect',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
