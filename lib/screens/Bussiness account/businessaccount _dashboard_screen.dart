import 'package:flutter/material.dart';
import 'manage_companies_screen.dart';
import 'products_services_screen.dart';
import 'discover_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'business_profile_edit_screen.dart';
import '../../models/business_profile_model.dart';
import '../../services/business_profile_service.dart';

class BusinessDashboardScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  final Map<String, dynamic>? businessData;

  const BusinessDashboardScreen({
    super.key,
    required this.userData,
    this.businessData,
  });

  @override
  State<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  BusinessProfile? _businessProfile;
  BusinessMetrics? _businessMetrics;
  List<BusinessAssociation> _associations = [];
  List<CompanyInfo> _companies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  Future<void> _loadBusinessData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final memberId =
          widget.userData['_id']?.toString() ??
          widget.userData['id']?.toString() ??
          '';

      if (memberId.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Fetch business profile
      final profile = await BusinessProfileService.getBusinessProfile(memberId);

      if (profile == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('📱 Business Profile Mobile: ${profile.mobile}');
      print('🏢 Business Profile Industry: ${profile.industry}');
      print(
        '📋 Business Profile Data: name=${profile.name}, status=${profile.status}',
      );
      print('⏰ Profile loaded at: ${DateTime.now()}');

      // Fetch metrics, associations, and companies in parallel
      final results = await Future.wait([
        BusinessProfileService.getBusinessMetrics(profile.businessId),
        BusinessProfileService.getBusinessAssociations(profile.businessId),
        BusinessProfileService.getMemberCompanies(memberId),
      ]);

      setState(() {
        _businessProfile = profile;
        _businessMetrics = results[0] as BusinessMetrics;
        _associations = results[1] as List<BusinessAssociation>;
        _companies = results[2] as List<CompanyInfo>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB3D4FF), Color(0xFFE6D8FF)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Main Content
              Expanded(
                child: _isLoading
                    ? _buildLoadingState()
                    : _businessProfile == null
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Manage My Companies Button
                              _buildManageCompaniesButton(),
                              const SizedBox(height: 16),

                              // My Business Card
                              _buildMyBusinessCard(),
                              const SizedBox(height: 16),

                              // Profile Stats Row
                              _buildStatsRow(),
                              const SizedBox(height: 16),

                              // Company Associations Section
                              if (_associations.isNotEmpty)
                                _buildCompanyAssociationsSection(),
                              if (_associations.isNotEmpty)
                                const SizedBox(height: 16),

                              // Recent Activity Section
                              _buildRecentActivitySection(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
              ),

              // Bottom Navigation Bar
              _buildBottomNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading business profile...',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.business_outlined,
                size: 64,
                color: Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No business profile found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete onboarding to create your business profile',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BusinessProfileEditScreen(
                      userData: widget.userData,
                      existingProfile: _businessProfile,
                    ),
                  ),
                ).then((_) => _loadBusinessData());
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Business Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Business Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Manage your business presence',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          if (_businessProfile != null)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black87),
              onPressed: _loadBusinessData,
            ),
        ],
      ),
    );
  }

  Widget _buildManageCompaniesButton() {
    return Container(
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.business_center,
            color: Colors.blue.shade700,
            size: 24,
          ),
        ),
        title: const Text(
          'Manage My Companies',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _companies.length.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ManageCompaniesScreen(userData: widget.userData),
            ),
          ).then((_) => _loadBusinessData()); // Refresh data when returning
        },
      ),
    );
  }

  Widget _buildMyBusinessCard() {
    if (_businessProfile == null) return const SizedBox.shrink();

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.business,
                  color: Colors.blue.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _businessProfile!.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (_businessProfile!.industry != null &&
                        _businessProfile!.industry!.isNotEmpty)
                      Text(
                        _businessProfile!.industry!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    // DEBUG: Always show mobile status
                    Text(
                      _businessProfile!.mobile?.isNotEmpty == true
                          ? _businessProfile!.mobile!
                          : 'Mobile: Not set',
                      style: TextStyle(
                        fontSize: 13,
                        color: _businessProfile!.mobile?.isNotEmpty == true
                            ? Colors.black87
                            : Colors.red.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusPill(_businessProfile!.status),
            ],
          ),
          if (_businessProfile!.description != null &&
              _businessProfile!.description!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _businessProfile!.description!,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BusinessProfileEditScreen(
                      userData: widget.userData,
                      existingProfile: _businessProfile,
                    ),
                  ),
                ).then((_) => _loadBusinessData());
              },
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.blue.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Edit Profile',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String displayText = _businessProfile!.statusDisplay;

    switch (status.toUpperCase()) {
      case 'APPROVED':
      case 'ACTIVE':
        bgColor = Colors.green.shade50;
        borderColor = Colors.green.shade200;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle;
        break;
      case 'REJECTED':
        bgColor = Colors.red.shade50;
        borderColor = Colors.red.shade200;
        textColor = Colors.red.shade700;
        icon = Icons.cancel;
        break;
      default:
        bgColor = Colors.orange.shade50;
        borderColor = Colors.orange.shade200;
        textColor = Colors.orange.shade700;
        icon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            displayText,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    if (_businessMetrics == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.visibility_outlined,
            title: 'Profile Views',
            value: _businessMetrics!.profileViews.toString(),
            change: _businessMetrics!.profileViewsChangeDisplay,
            changeColor: _businessMetrics!.profileViewsChangePercent >= 0
                ? Colors.green
                : Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.inventory_2_outlined,
            title: 'Products Listed',
            value: _businessMetrics!.productsCount.toString(),
            change: _businessMetrics!.featuredProductsDisplay.isNotEmpty
                ? _businessMetrics!.featuredProductsDisplay
                : 'No featured',
            changeColor: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required String change,
    required Color changeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            change,
            style: TextStyle(
              fontSize: 11,
              color: changeColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyAssociationsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Company Associations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // TODO: Add new association
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._associations.asMap().entries.map((entry) {
            final index = entry.key;
            final association = entry.value;
            return Column(
              children: [
                if (index > 0) const Divider(height: 24),
                _buildAssociationItem(
                  name: association.name,
                  role: association.role,
                  location: association.location,
                ),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAssociationItem({
    required String name,
    required String role,
    required String location,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.business, color: Colors.blue.shade700, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$role  •  $location',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.open_in_new, size: 18),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              color: Colors.grey.shade600,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentActivitySection() {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            icon: Icons.shopping_bag_outlined,
            title: 'Product viewed',
            subtitle: 'Premium Software Suite',
            time: '2 hours ago',
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            icon: Icons.edit_outlined,
            title: 'Profile updated',
            subtitle: 'Business description',
            time: '1 day ago',
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            icon: Icons.link,
            title: 'New connection',
            subtitle: 'Tech Solutions Inc.',
            time: '2 days ago',
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBottomNavItem(
                icon: Icons.business,
                label: 'Business',
                isSelected: true,
                onTap: () {},
              ),
              _buildBottomNavItem(
                icon: Icons.dashboard_outlined,
                label: 'Products',
                isSelected: false,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductsServicesScreen(
                        userData: widget.userData,
                        businessData: widget.businessData,
                      ),
                    ),
                  );
                },
              ),
              _buildBottomNavItem(
                icon: Icons.search,
                label: 'Discover',
                isSelected: false,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DiscoverScreen(
                        userData: widget.userData,
                        businessData: widget.businessData,
                      ),
                    ),
                  );
                },
              ),
              _buildBottomNavItem(
                icon: Icons.analytics_outlined,
                label: 'Analytics',
                isSelected: false,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnalyticsScreen(
                        userData: widget.userData,
                        businessData: widget.businessData,
                      ),
                    ),
                  );
                },
              ),
              _buildBottomNavItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                isSelected: false,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SettingsScreen(
                        userData: widget.userData,
                        businessData: widget.businessData,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? Colors.blue : Colors.grey[600],
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey[600],
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
