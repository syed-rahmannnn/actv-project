import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../services/application_service.dart';
import 'districtadmin_dashboard.dart' show UserDetailsDropdown;

class DistrictAdminMembersPage extends StatefulWidget {
  final String apiBaseUrl;
  final String districtAdminId;
  final String districtName;
  final String? token;

  const DistrictAdminMembersPage({
    super.key,
    required this.apiBaseUrl,
    required this.districtAdminId,
    required this.districtName,
    this.token,
  });

  @override
  State<DistrictAdminMembersPage> createState() =>
      _DistrictAdminMembersPageState();
}

class _DistrictAdminMembersPageState extends State<DistrictAdminMembersPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _all = [];
  String _query = '';
  final TextEditingController _searchCtrl = TextEditingController();
  final DateFormat _fmt = DateFormat('dd/MM/yyyy');
  late ApplicationService _svc;

  @override
  void initState() {
    super.initState();
    debugPrint('[DA_MEMBERS] init for districtId=${widget.districtAdminId}');
    _svc = ApplicationService(widget.apiBaseUrl);
    _load();
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      debugPrint('DA[_load]: called');
      debugPrint('[DA_API] GET /members?districtId=${widget.districtAdminId}');
      final apps = await _svc.getDistrictApplications(
        districtAdminId: widget.districtAdminId,
        status: 'all',
      );
      _all = List<Map<String, dynamic>>.from(apps);
      debugPrint('[DA_UI] users dropdown loaded: count=${_all.length}');
      debugPrint('[DA_API] response 200 ${_all.length}');
      debugPrint('DA[_load]: fetched applications count = ${_all.length}');
    } catch (e) {
      debugPrint('[DA_API] error 500 ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading members: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_query.isEmpty) return _all;
    return _all.where((app) {
      final name = (app['name'] ?? '').toString().toLowerCase();
      final phone = (app['phone'] ?? '').toString().toLowerCase();
      final district = (app['district'] ?? '').toString().toLowerCase();
      return name.contains(_query) ||
          phone.contains(_query) ||
          district.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F6FF),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _buildMembersList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFF1F6FF), Color(0xFFE9F0FF)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'District Members',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage ${widget.districtName} Members',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha((0.1 * 255).toInt()),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.group, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        decoration: const InputDecoration(
          hintText: 'Search members by name, phone, or district...',
          prefixIcon: Icon(Icons.search, color: Color(0xFF6B7280)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildMembersList() {
    final members = _filtered;
    debugPrint('DA[buildMembersList]: displaying ${members.length} cards');

    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _query.isEmpty ? Icons.group_outlined : Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _query.isEmpty
                  ? 'No members found'
                  : 'No members match your search',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      itemBuilder: (context, index) {
        final member = members[index];
        return _buildMemberCard(member);
      },
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> member) {
    final status = member['status'] ?? '';
    final name =
        (member['fullName'] ??
                member['name'] ??
                member['memberName'] ??
                'Unknown')
            .toString();
    final phone = (member['phone'] ?? 'N/A').toString();
    final block = (member['block'] ?? 'N/A').toString();
    final email = (member['email'] ?? member['memberEmail'] ?? 'N/A')
        .toString();
    // Resolve gender from top-level or nested personalInfo, default to NA
    final Map<String, dynamic>? personalInfo =
        member['personalInfo'] as Map<String, dynamic>?;
    final gender =
        (member['gender'] ??
                (personalInfo != null ? personalInfo['gender'] : null) ??
                'NA')
            .toString();
    final appliedAt =
        member['blockApprovedAt'] ?? member['createdAt'] ?? member['appliedOn'];
    String appliedOnStr = 'N/A';
    try {
      if (appliedAt != null) {
        final dt = DateTime.parse(appliedAt.toString());
        appliedOnStr = _fmt.format(dt);
      }
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).toInt()),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFF3B82F6,
                    ).withAlpha((0.1 * 255).toInt()),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF3B82F6),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phone: $phone',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(
                      status,
                    ).withAlpha((0.1 * 255).toInt()),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Text(
                  'Block: $block',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Text(
                  'Applied: $appliedOnStr',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Second line: Email (left) and Gender (right)
            Row(
              children: [
                const Icon(Icons.email, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Email: $email',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF374151),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.person, size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 6),
                Text(
                  'Gender: $gender',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _openProfile(member),
                child: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProfile(Map<String, dynamic> member) {
    final app = Map<String, dynamic>.from(member);
    final userId = app['userId'] ?? app['memberId'] ?? app['_id'];
    debugPrint('[DA_UI] user selected userId=${userId ?? 'unknown'}');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          UserDetailsDropdown(app: app, onApprove: () {}, onReject: () {}),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending-District':
        return const Color(0xFFF59E0B);
      case 'Pending-State':
        return const Color(0xFF10B981);
      case 'Rejected':
        return const Color(0xFFEF4444);
      case 'Approved':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'Pending-District':
        return 'Pending';
      case 'Pending-State':
        return 'Approved';
      case 'Rejected':
        return 'Rejected';
      case 'Approved':
        return 'Approved';
      default:
        return status;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(date.toString());
      return _fmt.format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }
}
