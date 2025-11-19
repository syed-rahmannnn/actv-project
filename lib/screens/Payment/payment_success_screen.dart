import 'package:flutter/material.dart';
import '../Member Dashboard/member_dashboard_screen.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final String membershipId;
  final String memberName;
  final String plan;
  final double amount;
  final String validity;
  final String paymentReference;

  const PaymentSuccessScreen({
    super.key,
    required this.membershipId,
    required this.memberName,
    required this.plan,
    required this.amount,
    required this.validity,
    required this.paymentReference,
  });

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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Success Icon
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Color(0xFF4285F4),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 60,
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Success Title
                const Text(
                  'Payment Successful!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4285F4),
                  ),
                ),

                const SizedBox(height: 12),

                // Subtitle
                const Text(
                  'Welcome to ACTIV – Your membership is now active',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Color(0xFF5F6368)),
                ),

                const SizedBox(height: 32),

                // Membership Details Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with Active badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Membership Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF202124),
                            ),
                          ),
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
                              'Active',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Membership ID
                      _buildDetailRow('Membership ID', membershipId),

                      const SizedBox(height: 16),

                      // Member Name
                      _buildDetailRow('Member Name', memberName),

                      const SizedBox(height: 16),

                      // Plan
                      _buildDetailRow('Plan', plan),

                      const SizedBox(height: 16),

                      // Amount Paid
                      _buildDetailRow(
                        'Amount Paid',
                        '₹${amount.toStringAsFixed(0)}',
                        valueColor: const Color(0xFF4285F4),
                      ),

                      const SizedBox(height: 16),

                      // Valid
                      _buildDetailRow('Valid', validity),

                      const SizedBox(height: 16),

                      // Payment Reference
                      _buildDetailRow('Payment Reference', paymentReference),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Download Documents Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Download Documents',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF202124),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Download Membership Certificate Button
                      _buildDownloadButton(
                        icon: Icons.description_outlined,
                        text: 'Download Membership Certificate',
                        onTap: () {
                          // TODO: Implement certificate download
                        },
                      ),

                      const SizedBox(height: 12),

                      // Download Payment Receipt Button
                      _buildDownloadButton(
                        icon: Icons.receipt_outlined,
                        text: 'Download Payment Receipt',
                        onTap: () {
                          // TODO: Implement receipt download
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Confirmation Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF4285F4).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF4285F4),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Confirmation has been sent to your registered email and WhatsApp number. Keep these for your records.',
                          style: TextStyle(
                            fontSize: 13,
                            color: const Color(0xFF4285F4),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // What's Next Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'What\'s Next?',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF202124),
                        ),
                      ),

                      const SizedBox(height: 20),

                      _buildNextStepItem(
                        icon: Icons.person_outline,
                        text:
                            'Access your member dashboard to update profile and browse other members.',
                      ),

                      const SizedBox(height: 16),

                      _buildNextStepItem(
                        icon: Icons.event_outlined,
                        text:
                            'Join area-specific events and networking opportunities.',
                      ),

                      const SizedBox(height: 16),

                      _buildNextStepItem(
                        icon: Icons.people_outline,
                        text:
                            'Connect with fellow ACTIV members in your region.',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Go to Member Dashboard Button
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Navigate to member dashboard
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const MemberDashboardScreen(),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4285F4),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Go to Member Dashboard',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF5F6368)),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF202124),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDownloadButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8EAED), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF202124), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF202124),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextStepItem({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Color(0xFF4285F4),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF5F6368),
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
