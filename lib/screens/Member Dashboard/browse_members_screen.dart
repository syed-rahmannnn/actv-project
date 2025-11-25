import 'package:flutter/material.dart';
import 'location_selection_screen.dart';
import '../../services/browse_members_service.dart';
import 'member_dashboard_screen.dart';

class BrowseMembersScreen extends StatefulWidget {
  const BrowseMembersScreen({super.key});

  @override
  State<BrowseMembersScreen> createState() => _BrowseMembersScreenState();
}

class _BrowseMembersScreenState extends State<BrowseMembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> members = [];
  bool isLoading = true;
  String? currentUserId;
  int currentPage = 1;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _loadCurrentUser();
    await _loadMembers();
  }

  Future<void> _loadCurrentUser() async {
    currentUserId = await BrowseMembersService.getCurrentUserId();
    print('📱 Current user ID: $currentUserId');
  }

  Future<void> _loadMembers({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        members = [];
        currentPage = 1;
        hasMore = true;
        isLoading = true;
      });
    }

    try {
      print('🔄 Loading members - Page: $currentPage, Refresh: $refresh');
      print('🚫 Excluding current user: $currentUserId');

      final response = await BrowseMembersService.getApprovedMembers(
        page: currentPage,
        limit: 20,
        search: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        excludeUserId: currentUserId,
      );

      print('📦 API Response: ${response['success']}');
      print('📊 Total members in response: ${response['data']?.length ?? 0}');

      if (response['success'] == true) {
        final List<dynamic> fetchedMembers = response['data'] ?? [];

        print('✅ Processing ${fetchedMembers.length} members');

        // Log each member for debugging
        if (fetchedMembers.isEmpty) {
          print('⚠️ No members found! This means:');
          print('   - No users have been approved by state admin, OR');
          print('   - No users have completed payment (active membership), OR');
          print('   - No users have completed their profile');
        } else {
          fetchedMembers.take(3).forEach((member) {
            print('👤 Member: ${member['name']}');
            print(
              '   Status: ${member['approvalStatus']} / ${member['paymentStatus']}',
            );
          });
        }

        setState(() {
          if (refresh) {
            members = fetchedMembers.cast<Map<String, dynamic>>();
          } else {
            members.addAll(fetchedMembers.cast<Map<String, dynamic>>());
          }
          isLoading = false;
          hasMore = fetchedMembers.length == 20;
        });

        print('✅ Loaded ${fetchedMembers.length} members');
      } else {
        print('❌ API returned success: false');
        print('   Message: ${response['message']}');
        setState(() => isLoading = false);
      }
    } catch (e, stackTrace) {
      print('❌ Error loading members: $e');
      print('Stack trace: $stackTrace');
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleConnect(String recipientId, String recipientName) async {
    if (currentUserId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please login to connect')));
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await BrowseMembersService.sendConnectionRequest(
        senderId: currentUserId!,
        recipientId: recipientId,
        message: 'Wants to connect with you',
      );

      Navigator.pop(context); // Close loading dialog

      if (response['success'] == true) {
        // Immediately remove user from list
        setState(() {
          members.removeWhere((member) => member['id'] == recipientId);
        });

        print('✅ Connection request sent and user removed from list');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection request sent to $recipientName'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to send request'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleViewProfile(String userId, String userName) async {
    print('👤 Viewing full dashboard for: $userName (ID: $userId)');

    // Navigate to member's full dashboard screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberDashboardScreen(memberId: userId),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: Column(
          children: [
            // Header Section with Light Blue Background
            Container(
              color: const Color(0xFFE3F2FD),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                children: [
                  // Back button and Browse Members title
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                          size: 24,
                        ),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Expanded(
                        child: Center(
                          child: const Text(
                            'Browse Members',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF202124),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Center(
                    child: Text(
                      'Connect with community members and leaders',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar with Filter
            Container(
              color: const Color(0xFFE3F2FD),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search by state, District, or Block',
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
                            borderSide: const BorderSide(
                              color: Color(0xFF4285F4),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Filter Button
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF4285F4),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.filter_list,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const LocationSelectionScreen(),
                            ),
                          );
                        },
                        tooltip: 'Filter',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Members List
            Expanded(
              child: Container(
                color: const Color(0xFFE3F2FD),
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : members.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No members found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _loadMembers(refresh: true),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: members.length,
                          itemBuilder: (context, index) {
                            return _buildMemberCard(members[index]);
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    // Extract data safely
    final String name = member['name'] ?? 'Unknown';
    final String role = member['role'] ?? 'Member';
    final String gender = member['gender'] ?? 'N/A';
    final String organization = member['organization'] ?? 'N/A';
    final Map<String, dynamic> location = member['location'] ?? {};
    final String block = location['block'] ?? 'Unknown';
    final String id = member['id'] ?? '';
    final bool isActive = member['isActive'] ?? true;

    // Generate initials
    final List<String> nameParts = name.split(' ');
    final String initials = nameParts.length >= 2
        ? '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase()
        : nameParts[0].length >= 2
        ? nameParts[0].substring(0, 2).toUpperCase()
        : nameParts[0][0].toUpperCase();

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
                decoration: const BoxDecoration(
                  color: Color(0xFF4285F4),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials,
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
                      name,
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
                          role,
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
                          gender,
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
              if (isActive)
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

          // Location and Organization
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Location: ',
                    style: TextStyle(fontSize: 13, color: Color(0xFF5F6368)),
                  ),
                  Text(
                    block,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF202124),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (organization != 'N/A') ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text(
                      'Organization: ',
                      style: TextStyle(fontSize: 13, color: Color(0xFF5F6368)),
                    ),
                    Expanded(
                      child: Text(
                        organization,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF202124),
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleViewProfile(id, name),
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleConnect(id, name),
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
