import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'manage_companies_screen.dart';
import 'products/products_services_screen.dart';
import 'discover_screen.dart';
import 'analytics_screen.dart';
import 'settings_screen.dart';
import 'business_profile_edit_screen.dart';
import 'edit_company_screen.dart';
import '../../models/business_profile_model.dart';
import '../../models/company_model.dart';
import '../../services/business_profile_service.dart';
import '../../services/company_service.dart';
import '../../services/dashboard_service.dart';
import '../../providers/company_selection_provider.dart';
import '../../widgets/company_switcher_widget.dart';

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
  List<BusinessAssociation> _associations = [];
  List<Company> _companies = [];
  Company? _activeCompany; // Currently active company
  bool _isLoading = true;

  // Dynamic dashboard data (company-specific)
  int _profileViews = 0;
  int _productsCount = 0;
  String _profileViewsChange = 'No change';
  String _productsChange = 'No featured';
  List<Map<String, dynamic>> _recentActivities = [];
  bool _statsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBusinessData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ✅ FIX: Use read() instead of watch() to prevent infinite rebuild loop
    // Listen to active company changes from provider
    if (!mounted) return;
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final activeCompany = context
          .read<CompanySelectionProvider>()
          .activeCompany;
      if (activeCompany != null && activeCompany.id != _activeCompany?.id) {
        setState(() {
          _activeCompany = activeCompany;
        });
        print('✅ Active company updated from provider: ${activeCompany.name}');
        // Reload company-specific data when company changes
        _loadCompanySpecificData(activeCompany.id);
      }
    });
  }

  Future<void> _loadCompanySpecificData(String companyId) async {
    try {
      print('🔄 Loading data for company: $companyId');
      
      // Load dashboard stats and activities
      final results = await Future.wait([
        DashboardService.getCompanyStats(companyId),
        DashboardService.getRecentActivities(companyId, limit: 10),
      ]);

      setState(() {
        // Update dynamic dashboard data
        final stats = results[0] as Map<String, dynamic>;
        _profileViews = stats['profileViews'] ?? 0;
        _productsCount = stats['productsCount'] ?? 0;
        _profileViewsChange = stats['profileViewsChange'] ?? 'No change';
        _productsChange = stats['productsChange'] ?? 'No featured';
        _statsLoaded = true;

        _recentActivities = results[1] as List<Map<String, dynamic>>;

        print('📊 Dashboard data loaded for company $companyId:');
        print('   Profile Views: $_profileViews');
        print('   Products Count: $_productsCount');
        print('   Profile Views Change: $_profileViewsChange');
        print('   Products Change: $_productsChange');
        print('   Recent Activities: ${_recentActivities.length} items');
        if (_recentActivities.isNotEmpty) {
          print('   First activity: ${_recentActivities[0]['title']}');
        }
      });
      print('✅ Company-specific data loaded successfully');
    } catch (e) {
      print('❌ Error loading company data: $e');
      // Set default values on error
      setState(() {
        _profileViews = 0;
        _productsCount = 0;
        _profileViewsChange = 'No change';
        _productsChange = 'No featured';
        _recentActivities = [];
        _statsLoaded = false;
      });
    }
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

      // ✅ CRITICAL FIX: Clear caches FIRST to ensure fresh data
      // This fixes the "just created but shows old data" issue
      await BusinessProfileService.clearCache(memberId);
      await CompanyService.clearCache(memberId);
      print('🗑️ Cleared caches for fresh data load');

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

      // Fetch associations and companies in parallel
      final results = await Future.wait([
        BusinessProfileService.getBusinessAssociations(profile.businessId),
        CompanyService.getCompanies(
          memberId,
        ), // Use same service as My Companies
      ]);

      setState(() {
        _businessProfile = profile;
        _associations = results[0] as List<BusinessAssociation>;
        _companies = results[1] as List<Company>;
        _isLoading = false;
      });

      print('✅ Loaded ${_companies.length} companies for dashboard');
      if (_companies.isNotEmpty) {
        _companies.forEach((c) => print('   - ${c.name} (${c.id}) - Views: ${c.views}, Products: ${c.productsCount}'));

        // Set first company as active if none is set OR if the active company doesn't belong to this member
        final companyProvider = context.read<CompanySelectionProvider>();
        Company companyToLoad;
        
        if (companyProvider.activeCompany == null) {
          companyProvider.setActiveCompany(_companies[0]);
          companyToLoad = _companies[0];
          print('✅ Set first company as active: ${_companies[0].name}');
        } else {
          // Validate that the active company from provider belongs to this member
          final activeCompanyId = companyProvider.activeCompany!.id;
          final companyIndex = _companies.indexWhere((c) => c.id == activeCompanyId);
          
          if (companyIndex != -1) {
            // ✅ CRITICAL: Use the company object from the fresh list to get updated data
            companyToLoad = _companies[companyIndex];
            // Update provider with fresh company data
            companyProvider.setActiveCompany(companyToLoad);
            print('✅ Using active company from provider: ${companyToLoad.name}');
            print('   📊 Fresh data - Views: ${companyToLoad.views}, Products: ${companyToLoad.productsCount}');
          } else {
            // Active company doesn't belong to this member - use first company instead
            companyProvider.setActiveCompany(_companies[0]);
            companyToLoad = _companies[0];
            print('⚠️ Active company from provider doesn\'t belong to this member');
            print('✅ Reset to first company: ${_companies[0].name}');
          }
        }
        
        _activeCompany = companyToLoad;
        // Load dashboard data for the active company
        await _loadCompanySpecificData(companyToLoad.id);
      } else {
        print('⚠️ No companies found - stats will not be loaded');
        setState(() {
          _statsLoaded = false;
        });
      }
    } catch (e) {
      print('❌ Error loading business data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshDashboard() async {
    print('🔄 Refreshing dashboard data...');
    await _loadBusinessData();
    if (_activeCompany != null) {
      await _loadCompanySpecificData(_activeCompany!.id);
    }
    print('✅ Dashboard refreshed');
  }

  void _showDeleteCompanyDialog() {
    if (_activeCompany == null) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Text('Delete Company'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to delete "${_activeCompany!.name}"?',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ This action cannot be undone',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Once you delete your company, all associated data will be permanently removed:',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text('• All products in this company', style: TextStyle(fontSize: 14)),
                    Text('• Company profile and settings', style: TextStyle(fontSize: 14)),
                    Text('• Business analytics and statistics', style: TextStyle(fontSize: 14)),
                    Text('• All other company resources', style: TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCompany();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete Permanently'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCompany() async {
    if (_activeCompany == null) return;

    try {
      // TODO: Call the delete company API endpoint
      // For now, show a message that this feature is being implemented
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company deletion will be implemented soon'),
          backgroundColor: Colors.orange,
          duration: Duration(milliseconds: 1500),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      print('❌ Error deleting company: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete company: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: Scaffold(
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
                    : RefreshIndicator(
                        key: const ValueKey('business_dashboard_refresh'),
                        onRefresh: _refreshDashboard,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Manage My Companies Button
                                _buildManageCompaniesButton(),
                                const SizedBox(height: 16),

                                // Active Company Card (main white card)
                                _buildActiveCompanyDetailsCard(),
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
              ),

              // Bottom Navigation Bar
              _buildBottomNavigation(),
            ],
          ),
        ),
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
    return RefreshIndicator(
      key: const ValueKey('business_empty_refresh'),
      onRefresh: _loadBusinessData,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Center(
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
                  const SizedBox(height: 8),
                  const Text(
                    'Pull down to refresh',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
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
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final memberId =
        widget.userData['_id']?.toString() ??
        widget.userData['id']?.toString() ??
        '';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
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
          if (memberId.isNotEmpty && _companies.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: CompanySwitcherWidget(
                memberId: memberId,
                textColor: Colors.black87,
                iconColor: Colors.black87,
                dropdownColor: Colors.white,
              ),
            ),
          ],
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
        onTap: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ManageCompaniesScreen(userData: widget.userData),
            ),
          );
          
          // Refresh data when returning
          if (result is Map && result['success'] == true) {
            // Company was changed, get the new active company from provider
            final companyProvider = context.read<CompanySelectionProvider>();
            if (companyProvider.activeCompany != null) {
              print('🔄 Active company changed to: ${companyProvider.activeCompany!.name}');
              setState(() {
                _activeCompany = companyProvider.activeCompany;
              });
              // Reload all data with new active company
              await _loadBusinessData();
              
              // Show success message AFTER data is loaded
              if (mounted && result['companyName'] != null) {
                // Clear any lingering snackbars first
                ScaffoldMessenger.of(context).clearSnackBars();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${result['companyName']} set as active company'),
                    backgroundColor: Colors.green,
                    duration: const Duration(milliseconds: 500),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          } else if (result != null) {
            // Just refresh in case of edits
            await _loadBusinessData();
          }
        },
      ),
    );
  }

  Widget _buildActiveCompanyDetailsCard() {
    // Main white card showing active company or prompt to select one
    if (_activeCompany == null) {
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
            Icon(
              Icons.business_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              'No active company selected',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap "Set as Active" from Manage My Companies',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

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
                      _activeCompany!.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (_activeCompany!.industry != null &&
                        _activeCompany!.industry!.isNotEmpty)
                      Text(
                        _activeCompany!.industry!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    if (_activeCompany!.mobile != null &&
                        _activeCompany!.mobile!.isNotEmpty)
                      Text(
                        _activeCompany!.mobile!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
              _buildStatusPill(_activeCompany!.status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditCompanyScreen(company: _activeCompany!),
                        ),
                      ).then((_) => _loadBusinessData());
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.blue.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                    label: const Text(
                      'Edit',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: () => _showDeleteCompanyDialog(),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.red.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    label: const Text(
                      'Delete',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
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
    // Show stats from active company (loaded via DashboardService)
    if (!_statsLoaded && _activeCompany == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.visibility_outlined,
            title: 'Profile Views',
            value: _profileViews.toString(),
            change: _profileViewsChange,
            changeColor:
                _profileViewsChange.contains('increase') ||
                    _profileViewsChange.contains('+')
                ? Colors.green
                : Colors.grey,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.inventory_2_outlined,
            title: 'Products Listed',
            value: _productsCount.toString(),
            change: _productsChange,
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
                  // Future feature: Add business association functionality
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
          if (_recentActivities.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(
                  'No recent activity',
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ...List.generate(_recentActivities.length, (index) {
              if (index > 0) {
                return Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildActivityItem(
                      icon: _getIconData(_recentActivities[index]['icon']),
                      title: _recentActivities[index]['title'] ?? '',
                      subtitle: _recentActivities[index]['subtitle'] ?? '',
                      time: _recentActivities[index]['time'] ?? '',
                      color: _getColorFromString(
                        _recentActivities[index]['color'],
                      ),
                    ),
                  ],
                );
              }
              return _buildActivityItem(
                icon: _getIconData(_recentActivities[index]['icon']),
                title: _recentActivities[index]['title'] ?? '',
                subtitle: _recentActivities[index]['subtitle'] ?? '',
                time: _recentActivities[index]['time'] ?? '',
                color: _getColorFromString(_recentActivities[index]['color']),
              );
            }),
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
                      builder: (context) =>
                          ProductsServicesScreen(userData: widget.userData),
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
                      builder: (context) =>
                          DiscoverScreen(userData: widget.userData),
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
                      builder: (context) =>
                          AnalyticsScreen(userData: widget.userData),
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
                      builder: (context) =>
                          SettingsScreen(userData: widget.userData),
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
    return RepaintBoundary(
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
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
        ),
      ),
    );
  }

  // Helper method to map icon string to IconData
  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'add_box':
        return Icons.add_box;
      case 'edit':
        return Icons.edit;
      case 'delete':
        return Icons.delete;
      case 'edit_outlined':
        return Icons.edit_outlined;
      case 'business':
        return Icons.business;
      case 'business_center':
        return Icons.business_center;
      case 'visibility':
        return Icons.visibility;
      case 'link':
        return Icons.link;
      case 'shopping_bag_outlined':
        return Icons.shopping_bag_outlined;
      default:
        return Icons.info_outline;
    }
  }

  // Helper method to map color string to Color
  Color _getColorFromString(String? colorName) {
    switch (colorName?.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'grey':
      case 'gray':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }
}
