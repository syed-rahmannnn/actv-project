import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:activ/models/company_model.dart';
import 'package:activ/services/company_service.dart';
import 'package:activ/providers/company_selection_provider.dart';
import 'package:activ/providers/analytics_provider.dart';
import 'business_profile_screen.dart';
import 'business_profile_view_screen.dart';

class ManageCompaniesScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ManageCompaniesScreen({super.key, required this.userData});

  @override
  State<ManageCompaniesScreen> createState() => _ManageCompaniesScreenState();
}

class _ManageCompaniesScreenState extends State<ManageCompaniesScreen> {
  List<Company> _companies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    setState(() => _isLoading = true);

    try {
      final memberId =
          widget.userData['_id']?.toString() ??
          widget.userData['id']?.toString() ??
          '';

      if (memberId.isEmpty) {
        throw Exception('Member ID not found in user data');
      }

      // ✅ FIX: Enhanced debug logging to track which user's data is being loaded
      print('🔍 Loading companies for memberId: $memberId');
      print('👤 User: ${widget.userData['fullName'] ?? 'Unknown'}');
      print('📧 Email: ${widget.userData['email'] ?? 'Unknown'}');
      print('📱 Phone: ${widget.userData['phoneNumber'] ?? 'Unknown'}');
      print('📋 Full userData keys: ${widget.userData.keys.toList()}');

      final companies = await CompanyService.getCompanies(memberId);

      setState(() {
        _companies = companies;
        _isLoading = false;
      });
      print('✅ Loaded ${companies.length} companies');

      if (companies.isEmpty) {
        print('⚠️ No companies returned from API');
        print('⚠️ Check if memberId $memberId matches companies in database');
      } else {
        companies.forEach((c) => print('   - ${c.name} (${c.id})'));
      }
    } catch (e) {
      print('❌ Error loading companies: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load companies: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onViewDetails(Company company) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BusinessProfileViewScreen(companyId: company.id),
      ),
    );
  }

  void _onSetActive(Company company) {
    // Set as active company
    context.read<CompanySelectionProvider>().setActiveCompany(company);

    // Reload analytics for new active company
    context.read<AnalyticsProvider>().loadAnalytics(company.id);

    // Clear any existing snackbars before navigating
    ScaffoldMessenger.of(context).clearSnackBars();
    
    // Return to Business dashboard with company data
    Navigator.pop(context, {'success': true, 'companyName': company.name});
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
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
                    ? const Center(child: CircularProgressIndicator())
                    : _companies.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadCompanies,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _companies.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Column(
                                children: [
                                  _buildInfoCard(),
                                  const SizedBox(height: 16),
                                ],
                              );
                            }
                            final company = _companies[index - 1];
                            return Column(
                              children: [
                                _buildCompanyCard(company),
                                const SizedBox(height: 16),
                              ],
                            );
                          },
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
              children: [
                const Text(
                  'My Companies',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  '${_companies.length} ${_companies.length == 1 ? "company" : "companies"}',
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => BusinessProfileScreen(
                    userData: widget.userData,
                    mode: 'createCompany',
                  ),
                ),
              );
              // Reload companies if a new one was created
              if (result == true) {
                _loadCompanies();
              }
            },
            icon: const Icon(Icons.add, size: 18, color: Colors.white),
            label: const Text(
              'Add',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: _loadCompanies,
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
                  Icon(
                    Icons.business_outlined,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No companies yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap Add to create your first company',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.black45),
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

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Manage multiple companies under your account. Each company can have its own products and profile.',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(Company company) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Company Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Logo/Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: company.logoUrl != null && company.logoUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          company.logoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.business,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.business,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 12),
              // Company Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${company.industry ?? "Business"} · ${company.mobile ?? "No mobile"}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              _buildStatusBadge(company.statusDisplay, company.status),
            ],
          ),

          const SizedBox(height: 16),

          // Stats Row - Display actual company metrics
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildMetricItem('Products', company.productsCount),
                _buildMetricItem('Views', company.views),
                _buildMetricItem('Connections', company.connections),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _onViewDetails(company),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _onSetActive(company),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Set as Active',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String text, String status) {
    Color backgroundColor;
    Color textColor;

    switch (status.toUpperCase()) {
      case 'ACTIVE':
        backgroundColor = const Color(0xFFD4EDDA);
        textColor = const Color(0xFF155724);
        break;
      case 'UNDER_REVIEW':
      case 'PENDING':
        backgroundColor = const Color(0xFFFFF3CD);
        textColor = const Color(0xFF856404);
        break;
      case 'REJECTED':
        backgroundColor = const Color(0xFFF8D7DA);
        textColor = const Color(0xFF721C24);
        break;
      default:
        backgroundColor = Colors.grey.shade200;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, int value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatNumber(value),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              _buildNavItem(Icons.business, 'Business', true),
              _buildNavItem(Icons.grid_view, 'Products', false),
              _buildNavItem(Icons.explore, 'Discover', false),
              _buildNavItem(Icons.bar_chart, 'Analytics', false),
              _buildNavItem(Icons.settings, 'Settings', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: isActive ? Colors.blue : Colors.grey, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? Colors.blue : Colors.grey,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
