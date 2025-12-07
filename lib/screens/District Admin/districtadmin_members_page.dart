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

      // Fetch pending applications (Pending-District status)
      final pending = await _svc.getDistrictInbox(widget.districtAdminId);

      // Fetch approved applications
      final approved = await _svc.getDistrictApplicationsByStatus(
        districtAdminId: widget.districtAdminId,
        status: 'Approved',
      );

      // Fetch rejected applications
      final rejected = await _svc.getDistrictApplicationsByStatus(
        districtAdminId: widget.districtAdminId,
        status: 'Rejected',
      );

      // Combine all lists
      _all = [
        ...List<Map<String, dynamic>>.from(pending),
        ...List<Map<String, dynamic>>.from(approved),
        ...List<Map<String, dynamic>>.from(rejected),
      ];

      debugPrint('[DA_UI] users dropdown loaded: count=${_all.length}');
      debugPrint(
        '[DA_API] response 200 pending=${pending.length} approved=${approved.length} rejected=${rejected.length}',
      );
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
    // Only show district-relevant statuses: Approved, Rejected, Pending-District
    bool isAllowed(Map<String, dynamic> app) {
      final raw = (app['status'] ?? '').toString();
      final status = raw.trim();
      return status == 'Approved' ||
          status == 'Rejected' ||
          status == 'Pending-District';
    }

    final base = _all.where(isAllowed).toList();
    if (_query.isEmpty) return base;

    return base.where((app) {
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

    // Gender extraction logic matching Block Admin implementation
    final form = member['formData'] != null
        ? Map<String, dynamic>.from(member['formData'])
        : <String, dynamic>{};

    String normalizeGender(dynamic g) {
      if (g == null) return 'Not Specified';
      final v = g.toString().trim();
      if (v.isEmpty) return 'Not Specified';
      final lc = v.toLowerCase();
      if (lc == 'm' || lc == 'male' || lc.startsWith('male')) {
        return 'Male';
      }
      if (lc == 'f' || lc == 'female' || lc.startsWith('female')) {
        return 'Female';
      }
      if (lc == 'o' || lc == 'other' || lc.startsWith('other')) {
        return 'Other';
      }
      return v; // show as-is if unknown
    }

    final Map<String, dynamic>? personalInfo =
        form['personalInfo'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(form['personalInfo'])
        : null;
    final Map<String, dynamic>? personalDetails =
        form['personalDetails'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(form['personalDetails'])
        : null;

    // Also check if personalDetails exists directly in member (not in formData)
    final Map<String, dynamic>? memberPersonalDetails =
        member['personalDetails'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(member['personalDetails'])
        : null;

    final dynamic rawGender =
        member['gender'] ??
        form['gender'] ??
        personalInfo?['gender'] ??
        personalDetails?['gender'] ??
        memberPersonalDetails?['gender'];

    // Debug logging to see what data we have
    debugPrint(
      '[DA_MEMBERS_GENDER_DEBUG] Member ${member['_id']}: rawGender=$rawGender, '
      'member.gender=${member['gender']}, form.gender=${form['gender']}, '
      'personalInfo.gender=${personalInfo?['gender']}, '
      'personalDetails.gender=${personalDetails?['gender']}, '
      'memberPersonalDetails.gender=${memberPersonalDetails?['gender']}, '
      'formData keys=${member['formData']?.keys.toList()}, '
      'personalDetails keys=${personalDetails?.keys.toList()}, '
      'member keys=${member.keys.toList()}',
    );

    final String gender = normalizeGender(rawGender);
    debugPrint(
      '[DA_MEMBERS_GENDER_DEBUG] Member ${member['_id']}: normalized gender=$gender',
    );

    final appliedAt =
        member['blockApprovedAt'] ?? member['createdAt'] ?? member['appliedOn'];
    String appliedOnStr = 'N/A';
    try {
      if (appliedAt != null) {
        final dt = DateTime.parse(appliedAt.toString());
        appliedOnStr = _fmt.format(dt);
      }
    } catch (_) {}

    return InkWell(
      onTap: () => _openProfile(member),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.05 * 255).toInt()),
              blurRadius: 14,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 22,
                    backgroundColor: Color(0xFFE5E7EB),
                    child: Icon(Icons.person, color: Color(0xFF6B7280)),
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
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.email,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
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
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.person,
                        size: 16,
                        color: Color(0xFF6B7280),
                      ),
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
                ],
              ),
              // Removed explicit button; entire card is tappable
            ],
          ),
        ),
      ),
    );
  }

  void _openProfile(Map<String, dynamic> member) async {
    // Same behavior as approval page: try full profile by email, else fallback
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final email = member["email"] ?? member["memberEmail"];
      if (email != null) {
        final memberRes = await ApiService.getMemberByEmail(email);
        if (memberRes['success'] == true && memberRes['data'] != null) {
          final memberId =
              memberRes['data']['id'] ??
              memberRes['data']['memberId'] ??
              memberRes['data']['_id'];
          if (memberId != null) {
            final profileRes = await ApiService.getMemberProfile(
              memberId.toString(),
            );
            if (mounted) Navigator.pop(context);
            if (profileRes['success'] == true && profileRes['data'] != null) {
              if (mounted) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => UserDetailsDropdown(
                    memberProfile: Map<String, dynamic>.from(
                      profileRes['data'],
                    ),
                    showActions: false,
                    onApprove: () {},
                    onReject: () {},
                  ),
                );
                return;
              }
            }
          }
        }
      }
      if (mounted) Navigator.pop(context);
      if (mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => UserDetailsDropdown(
            app: Map<String, dynamic>.from(member),
            showActions: false,
            onApprove: () {},
            onReject: () {},
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending-District':
        return const Color(0xFFF59E0B);
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
        return 'Pending-District';
      case 'Rejected':
        return 'Rejected';
      case 'Approved':
        return 'Approved';
      default:
        return status;
    }
  }
}
