import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class BrowseMembersScreen extends StatefulWidget {
  const BrowseMembersScreen({super.key});

  @override
  BrowseMembersScreenState createState() => BrowseMembersScreenState();
}

class BrowseMembersScreenState extends State<BrowseMembersScreen> {
  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> filteredMembers = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchMembers();
    searchController.addListener(_onSearchChanged);
  }

  /// Fetch members from API
  Future<void> _fetchMembers() async {
    final response = await ApiService.getMembers();
    if (response['success']) {
      if (mounted) {
        setState(() {
          members = List<Map<String, dynamic>>.from(response['data'] ?? []);
          filteredMembers = members;
        });
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to load members')));
      }
    }
  }

  /// Search filter
  void _onSearchChanged() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredMembers = members.where((member) {
        final name = (member['name'] ?? '').toString().toLowerCase();
        final location = (member['location'] ?? '').toString().toLowerCase();
        return name.contains(query) || location.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Members')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search members...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredMembers.length,
              itemBuilder: (context, index) {
                final member = filteredMembers[index];
                final name = member['name'] ?? 'No Name';
                final location = member['location'] ?? 'No Location';
                return ListTile(
                  title: Text(name),
                  subtitle: Text(location),
                  trailing: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Connect feature coming soon!'),
                        ),
                      );
                    },
                    child: const Text('Connect'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
