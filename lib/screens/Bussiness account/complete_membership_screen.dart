import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/payment_service.dart';
import '../../services/auth_service.dart';
import '../../services/application_status_service.dart';
import '../Payment/payment_webview_screen.dart';
import '../Payment/payment_success_screen.dart';

class CompleteMembershipScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const CompleteMembershipScreen({super.key, required this.userData});

  @override
  State<CompleteMembershipScreen> createState() =>
      _CompleteMembershipScreenState();
}

class _CompleteMembershipScreenState extends State<CompleteMembershipScreen> {
  // Toggle state
  bool _isCompany = true; // true = Company, false = Aspirant

  // Company experience selection
  String _selectedExperience = '5 – 10 years';

  // Selected plan
  String _selectedPlan = 'Intermediate Plan';

  // Lock status based on member type
  bool _isLockedToAspirant = false;
  bool _isLockedToCompany = false;
  String? _memberType;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeMemberType();
  }

  Future<void> _initializeMemberType() async {
    try {
      // Fetch application status to determine member type
      final result = await ApplicationStatusService.fetchApplicationStatus();

      print('🔍 Application fetch result: ${result.success}');
      print('🔍 Applications count: ${result.applications.length}');

      if (result.success && result.applications.isNotEmpty) {
        // Get the most recent application
        final application = result.applications.first;
        final formData = application.formData;

        print('🔍 FormData: $formData');

        // Check memberType - could be at root level or need to determine from data
        String? memberType = formData['memberType']?.toString().toUpperCase();

        // If memberType not explicitly set, determine from application data
        if (memberType == null) {
          // Check if business information exists (indicates COMPANY member)
          final personalDetails = formData['personalDetails'];
          final businessInfo = formData['businessInfo'];

          if (personalDetails != null &&
              personalDetails['doingBusiness'] == true) {
            memberType = 'COMPANY';
            print(
              '✅ Detected COMPANY member from personalDetails.doingBusiness',
            );
          } else if (personalDetails != null &&
              personalDetails['businessType'] != null) {
            memberType = 'COMPANY';
            print(
              '✅ Detected COMPANY member from personalDetails.businessType',
            );
          } else if (businessInfo != null) {
            memberType = 'COMPANY';
            print('✅ Detected COMPANY member from businessInfo');
          } else if (personalDetails != null &&
              personalDetails['memberType'] == 'ASPIRANT') {
            memberType = 'ASPIRANT';
            print('✅ Detected ASPIRANT member from personalDetails.memberType');
          } else {
            print(
              '⚠️ Cannot determine member type - defaulting to full access',
            );
          }
        } else {
          print('✅ Member Type explicitly set: $memberType');
        }

        _memberType = memberType;

        if (memberType == 'ASPIRANT') {
          print('🔒 Locking to ASPIRANT');
          if (mounted) {
            setState(() {
              _isLockedToAspirant = true;
              _isCompany = false;
              _selectedPlan = 'Aspirant Plan';
              _isLoading = false;
            });
          }
          return;
        } else if (memberType == 'COMPANY') {
          print('🔒 Locking to COMPANY');
          // Lock to Company plans only
          if (mounted) {
            setState(() {
              _isLockedToAspirant = false;
              _isLockedToCompany = true;
              _isCompany = true;
              _selectedPlan = 'Intermediate Plan';
              _isLoading = false;
            });
          }
          return;
        }
      } else {
        print('❌ No applications found or fetch failed');
      }

      // If no application found or no memberType, allow full access
      print('⚠️ No lock applied - allowing full access');
      if (mounted) {
        setState(() {
          _isLockedToAspirant = false;
          _isLockedToCompany = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching application status: $e');
      // On error, allow full access to avoid blocking users
      if (mounted) {
        setState(() {
          _isLockedToAspirant = false;
          _isLockedToCompany = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.44, 0.74],
            colors: [
              Color(0xFFC5E2FF), // 44% - Light blue #C5E2FF
              Color(0xFFE6E8FF), // 74% - Light purple #E6E8FF
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            _buildHeader(),
                            const SizedBox(height: 30),
                            _buildUserTypeToggle(),
                            const SizedBox(height: 30),
                            _buildMembershipPlansSection(),
                            const SizedBox(height: 30),
                            _buildSecurePaymentSection(),
                            const SizedBox(height: 20),
                            _buildPaymentSummary(),
                            const SizedBox(height: 20),
                            _buildPayButton(),
                            const SizedBox(height: 30),
                            _buildAfterPaymentSection(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 20, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.black87, size: 24),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            style: IconButton.styleFrom(backgroundColor: Colors.transparent),
          ),
          const SizedBox(width: 8),
          const Text(
            'Back to Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Text(
          'Complete Your Membership',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: Color.fromARGB(255, 21, 21, 21),
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Select your membership type and pay securely',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: Color.fromARGB(255, 104, 106, 106),
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildUserTypeToggle() {
    // If locked to either Aspirant or Company, don't show toggle buttons
    if (_isLockedToAspirant || _isLockedToCompany) {
      return const SizedBox.shrink(); // Return empty widget
    }

    // Show both options only if memberType is not determined
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildToggleButton(
                label: 'Aspirant (Student)',
                isSelected: !_isCompany,
                onTap: () {
                  setState(() {
                    _isCompany = false;
                    _selectedPlan = 'Aspirant Plan';
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildToggleButton(
                label: 'Company',
                isSelected: _isCompany,
                onTap: () {
                  setState(() {
                    _isCompany = true;
                    _selectedPlan = 'Intermediate Plan';
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2196F3) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(right: 6),
                child: Icon(Icons.check_circle, color: Colors.white, size: 18),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanyExperienceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Company Experience',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 400) {
              return Row(
                children: [
                  Expanded(child: _buildExperienceOption('Less than 5 years')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildExperienceOption('5 – 10 years')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildExperienceOption('10+ years')),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildExperienceOption('Less than 5 years'),
                  const SizedBox(height: 8),
                  _buildExperienceOption('5 – 10 years'),
                  const SizedBox(height: 8),
                  _buildExperienceOption('10+ years'),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildExperienceOption(String experience) {
    final isSelected = _selectedExperience == experience;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedExperience = experience;
          // Auto-select plan based on experience
          if (experience == 'Less than 5 years') {
            _selectedPlan = 'Basic Plan';
          } else if (experience == '5 – 10 years') {
            _selectedPlan = 'Intermediate Plan';
          } else {
            _selectedPlan = 'Ideal Plan';
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2196F3) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            experience,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF757575),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMembershipPlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Membership Plan',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 16),
        if (_isCompany) ...[
          _buildCompanyPlanCard(
            title: 'Basic Plan',
            subtitle: 'For companies less than 5 years',
            benefits: [
              'Compliance and documentation guidance',
              'Access to networking forums',
              'Standard email support',
            ],
            price: '₹5,000',
            period: 'annum',
            planKey: 'Basic Plan',
          ),
          const SizedBox(height: 16),
          _buildCompanyPlanCard(
            title: 'Intermediate Plan',
            subtitle: 'For companies 5 – 10 years',
            benefits: [
              'All Basic benefits',
              'Priority event invitations',
              'Growth and scaling advisory sessions',
            ],
            price: '₹10,000',
            period: 'annum',
            planKey: 'Intermediate Plan',
            showBadge: true,
          ),
          const SizedBox(height: 16),
          _buildCompanyPlanCard(
            title: 'Ideal Plan',
            subtitle: 'For companies 10+ years',
            benefits: [
              'All Intermediate benefits',
              'Premium advisory and consulting',
              'Featured listing and special recognition',
            ],
            price: '₹20,000',
            period: 'annum',
            planKey: 'Ideal Plan',
          ),
        ] else ...[
          _buildCompanyPlanCard(
            title: 'Aspirant Plan',
            subtitle: 'For students without company experience',
            benefits: [
              'Access to learning resources and webinars',
              'Student-only events and competitions',
              'Mentorship and career guidance',
              'Networking with professionals',
            ],
            price: '₹2,000',
            period: 'annum',
            planKey: 'Aspirant Plan',
          ),
        ],
      ],
    );
  }

  Widget _buildCompanyPlanCard({
    required String title,
    required String subtitle,
    required List<String> benefits,
    required String price,
    required String period,
    required String planKey,
    bool showBadge = false,
  }) {
    final isSelected = _selectedPlan == planKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlan = planKey;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE3F2FD) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...benefits.map(
                  (benefit) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF4CAF50),
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            benefit,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF212121),
                        ),
                      ),
                      Text(
                        '/ $period',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showBadge)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Most Popular',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFFA726),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurePaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Secure Payment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.lock, color: Color(0xFF4CAF50), size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Secure Payment',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '- Powered by Instamojo',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Your payment information is encrypted and secure',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildSummaryRow(
                'Member Type',
                _isCompany ? 'Company' : 'Aspirant (Student)',
              ),
              if (_isCompany) ...[
                const SizedBox(height: 12),
                _buildSummaryRow('Experience', _selectedExperience),
              ],
              const SizedBox(height: 12),
              _buildSummaryRow('Plan', _selectedPlan),
              const Divider(height: 24, thickness: 1),
              _buildSummaryRow(
                'Total Amount',
                _getCurrentPrice(),
                isBold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[700],
            fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            color: const Color(0xFF212121),
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _processPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Text(
          'Pay ${_getCurrentPrice()}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildAfterPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'After Payment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 12),
        _buildAfterPaymentItem('Instant membership activation'),
        _buildAfterPaymentItem('Digital certificate download'),
        _buildAfterPaymentItem('Email & WhatsApp confirmation'),
        _buildAfterPaymentItem('Access to member dashboard'),
      ],
    );
  }

  Widget _buildAfterPaymentItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentPrice() {
    switch (_selectedPlan) {
      case 'Aspirant Plan':
        return '₹2,000';
      case 'Basic Plan':
        return '₹5,000';
      case 'Intermediate Plan':
        return '₹10,000';
      case 'Ideal Plan':
        return '₹20,000';
      default:
        return '₹0';
    }
  }

  int _getCurrentAmount() {
    switch (_selectedPlan) {
      case 'Aspirant Plan':
        return 2000;
      case 'Basic Plan':
        return 5000;
      case 'Intermediate Plan':
        return 10000;
      case 'Ideal Plan':
        return 20000;
      default:
        return 0;
    }
  }

  String _getValidityPeriod() {
    // All plans are 1 year validity
    return '1 Year';
  }

  void _processPayment() async {
    try {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2196F3)),
        ),
      );

      // Create payment request
      final result = await PaymentService.createPaymentRequest(
        amount: _getCurrentAmount().toDouble(),
        purpose: _selectedPlan,
        buyerName:
            widget.userData['fullName'] ?? widget.userData['name'] ?? 'Member',
        email: widget.userData['email'] ?? '',
        phone: widget.userData['phoneNumber'] ?? '',
        redirectUrl: 'https://activ-app.com/payment/success',
      );

      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      if (result['success']) {
        // Check if in test mode
        if (result['test_mode'] == true) {
          // TEST MODE: Show immediate success
          await Future.delayed(const Duration(seconds: 1));
          _showTestSuccessDialog(result['payment_request_id']);
          return;
        }

        // LIVE MODE: Navigate to payment WebView
        final paymentResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWebViewScreen(
              paymentUrl: result['payment_url'],
              paymentRequestId: result['payment_request_id'],
            ),
          ),
        );

        // Handle payment result
        if (paymentResult == true) {
          // Payment was successful
          _showSuccessDialog(
            'Your payment has been completed successfully! Your membership will be activated shortly.',
          );
        } else if (paymentResult == false) {
          // Payment failed or was cancelled
          _showErrorDialog(
            'Payment was not completed. Please try again or contact support.',
          );
        }
      } else {
        _showErrorDialog('Payment failed: ${result['error']}');
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
      _showErrorDialog('An error occurred: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Payment Error'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showTestSuccessDialog(String paymentId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '✅ TEST PAYMENT SUCCESSFUL!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Payment ID: $paymentId'),
            Text('Amount: ${_getCurrentPrice()}'),
            const SizedBox(height: 12),
            const Text(
              '🧪 This is a test transaction.\nIn production, real payment will be processed.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog

              final memberName =
                  widget.userData['fullName'] ??
                  widget.userData['name'] ??
                  'Member';
              final amount = _getCurrentAmount().toDouble();
              final validity = _getValidityPeriod();

              // Navigate to success screen
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentSuccessScreen(
                    membershipId:
                        'ACTIV-2024-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                    memberName: memberName,
                    plan: _selectedPlan,
                    amount: amount,
                    validity: validity,
                    paymentReference: paymentId,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
