import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/payment_service.dart';
import '../../services/auth_service.dart';
import 'payment_webview_screen.dart';
import 'payment_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String? selectedPlan; // 'annual', 'lifetime', or 'support'
  TextEditingController donationController = TextEditingController();

  // Membership plan details
  Map<String, dynamic> get membershipPlans => {
    'annual': {
      'title': 'Annual Membership',
      'price': 500,
      'duration': '1 Year',
      'features': [
        'Full member directory access',
        'Event notification',
        'Access to networking',
        'Digital certificate',
        'Basic support',
      ],
      'badge': 'Most Popular',
    },
    'lifetime': {
      'title': 'Lifetime Membership',
      'price': 2500,
      'duration': 'Lifetime',
      'features': [
        'All annual benefits',
        'Priority event access',
        'Exclusive workshops',
        'Premium certification',
        'Membership upgrades',
      ],
      'badge': null,
    },
  };

  @override
  void initState() {
    super.initState();
    selectedPlan = 'annual'; // Default selection
  }

  @override
  void dispose() {
    donationController.dispose();
    super.dispose();
  }

  int _getSelectedAmount() {
    if (selectedPlan == 'annual') {
      return membershipPlans['annual']['price'];
    } else if (selectedPlan == 'lifetime') {
      return membershipPlans['lifetime']['price'];
    } else if (selectedPlan == 'support') {
      final amount = int.tryParse(donationController.text);
      return amount ?? 0;
    }
    return 0;
  }

  String _getSelectedTitle() {
    if (selectedPlan == 'annual') {
      return 'Annual Membership';
    } else if (selectedPlan == 'lifetime') {
      return 'Lifetime Membership';
    } else if (selectedPlan == 'support') {
      return 'Support ACTIV';
    }
    return '';
  }

  String _getSelectedDuration() {
    if (selectedPlan == 'annual') {
      return '1 Year';
    } else if (selectedPlan == 'lifetime') {
      return 'Lifetime';
    } else if (selectedPlan == 'support') {
      return 'One-time';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final selectedAmount = _getSelectedAmount();

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
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.black87,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.transparent,
                      ),
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
              ),

              // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 32),
                      // Title - Centered
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
                        'Choose your membership plan and secure payment',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: Color.fromARGB(255, 104, 106, 106),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Select Membership Plan - Center aligned
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

                      // Annual Membership Card
                      _buildMembershipCard(
                        'annual',
                        membershipPlans['annual']['title'],
                        membershipPlans['annual']['price'],
                        membershipPlans['annual']['duration'],
                        membershipPlans['annual']['features'],
                        badge: membershipPlans['annual']['badge'],
                      ),
                      const SizedBox(height: 16),

                      // Lifetime Membership Card
                      _buildMembershipCard(
                        'lifetime',
                        membershipPlans['lifetime']['title'],
                        membershipPlans['lifetime']['price'],
                        membershipPlans['lifetime']['duration'],
                        membershipPlans['lifetime']['features'],
                      ),
                      const SizedBox(height: 16),

                      // Support ACTIV Card
                      _buildSupportCard(),
                      const SizedBox(height: 32),

                      // Test Mode Banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.science,
                              color: Colors.green.shade700,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '🧪 TEST MODE ACTIVE - Payments simulated for testing',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Secure Payment Section
                      const Text(
                        'Secure Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.lock_outline, size: 24),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Secure Payment - Powered by Instamojo',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Your payment information is encrypted and secure',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Payment Summary
                      const Text(
                        'Payment Summary',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),

                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.1),
                              spreadRadius: 1,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getSelectedTitle(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                Text(
                                  '₹$selectedAmount',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Duration',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                Text(
                                  _getSelectedDuration(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Amount',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  '₹ $selectedAmount',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Pay Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: selectedAmount > 0
                              ? () {
                                  _showPaymentConfirmation();
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            disabledBackgroundColor: Colors.grey[300],
                          ),
                          child: Text(
                            'Pay ₹$selectedAmount',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // After Payment Section
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'After Payment',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1F2937),
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildAfterPaymentItem('Instant membership activation'),
                      _buildAfterPaymentItem('Digital certificate download'),
                      _buildAfterPaymentItem('Email & WhatsApp confirmation'),
                      _buildAfterPaymentItem('Access to member dashboard'),
                      const SizedBox(height: 32),
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

  Widget _buildMembershipCard(
    String planKey,
    String title,
    int price,
    String duration,
    List<String> features, {
    String? badge,
  }) {
    final isSelected = selectedPlan == planKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlan = planKey;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 8,
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFFF9800),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...features.map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check, size: 18, color: Color(0xFF4CAF50)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        feature,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
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
              child: Text(
                '₹$price / $duration',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportCard() {
    final isSelected = selectedPlan == 'support';

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedPlan = 'support';
        });
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF2196F3) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Support ACTIV',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'One-time Your custom amount',
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter Donation Amount',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: donationController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onTap: () {
                // Select the support plan when user taps on the text field
                setState(() {
                  selectedPlan = 'support';
                });
              },
              onChanged: (value) {
                setState(() {
                  selectedPlan =
                      'support'; // Ensure support is selected when typing
                }); // Update UI when amount changes
              },
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    '₹',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                hintText: 'Enter amount',
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF2196F3),
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Amount Will be used to support our mission',
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check, size: 18, color: Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                const Text(
                  'Digital recognition certificate',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check, size: 18, color: Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                const Text(
                  'Special recognition',
                  style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAfterPaymentItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check, size: 20, color: Color(0xFF4CAF50)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Confirm Payment',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to pay ₹${_getSelectedAmount()} for ${_getSelectedTitle()}.',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'You will be redirected to a secure payment gateway to complete your transaction.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Here you would integrate with Instamojo or payment gateway
                _processPayment();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: const Text('Proceed'),
            ),
          ],
        );
      },
    );
  }

  void _processPayment() async {
    try {
      // Get user data
      final userData = await AuthService.getUserData();

      if (userData == null) {
        _showErrorDialog(
          'Unable to retrieve user information. Please try again.',
        );
        return;
      }

      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Create payment request
      final result = await PaymentService.createPaymentRequest(
        amount: _getSelectedAmount().toDouble(),
        purpose: _getSelectedTitle(),
        buyerName: userData['fullName'] ?? 'Member',
        email: userData['email'] ?? '',
        phone: userData['phoneNumber'] ?? '',
        redirectUrl:
            'https://activ-app.com/payment/success', // Redirect URL after payment
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
            Text('Amount: ₹${_getSelectedAmount()}'),
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

              // Get user data
              final userData = await AuthService.getUserData();
              final memberName = userData?['name'] ?? 'Member';

              // Get plan details
              String planName = '';
              String validity = '';
              double amount = _getSelectedAmount().toDouble();

              if (selectedPlan == 'annual') {
                planName = 'Annual Membership';
                validity = '1 Year';
              } else if (selectedPlan == 'lifetime') {
                planName = 'Lifetime Membership';
                validity = 'LifeTime';
              } else if (selectedPlan == 'support') {
                planName = 'Support Donation';
                validity = 'N/A';
              }

              // Navigate to success screen
              if (!mounted) return;
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentSuccessScreen(
                    membershipId:
                        'ACTIV-2024-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                    memberName: memberName,
                    plan: planName,
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
