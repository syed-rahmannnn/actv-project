import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../services/payment_service.dart';
import '../../services/payment_verification_service.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final String paymentRequestId;

  const PaymentWebViewScreen({
    Key? key,
    required this.paymentUrl,
    required this.paymentRequestId,
  }) : super(key: key);

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
            });
            _checkForRedirect(url);
          },
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (request) {
            _checkForRedirect(request.url);
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  void _checkForRedirect(String url) {
    // Detect redirect to your callback url after payment
    if (url.contains('activ-app.com/payment/success') ||
        url.contains('payment_status') ||
        url.contains('payment_request_id')) {
      // Parse payment parameters
      final uri = Uri.parse(url);
      final paymentRequestId =
          uri.queryParameters['payment_request_id'] ?? widget.paymentRequestId;
      final paymentId = uri.queryParameters['payment_id'];
      final paymentStatus = uri.queryParameters['payment_status'];

      print('Payment redirect detected:');
      print('  URL: $url');
      print('  Payment Request ID: $paymentRequestId');
      print('  Payment ID: $paymentId');
      print('  Payment Status: $paymentStatus');

      // Verify payment status
      _verifyPaymentStatus(paymentRequestId, paymentId, paymentStatus);
    }
  }

  Future<void> _verifyPaymentStatus(
    String paymentRequestId,
    String? paymentId,
    String? paymentStatus,
  ) async {
    try {
      // Show loading
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get payment status from server (official verification)
      final result = await PaymentService.getPaymentStatus(paymentRequestId);

      // Close loading
      if (!mounted) return;
      Navigator.of(context).pop();

      if (result['success']) {
        final status = result['status'];
        final payments = result['payments'] as List?;

        // Use verification service to check payment status
        final isSuccessful = PaymentVerificationService.isPaymentSuccessful(
          status,
        );

        if (isSuccessful || (payments != null && payments.isNotEmpty)) {
          // Payment successful - verify it's complete
          bool hasCompletedPayment = false;

          if (payments != null && payments.isNotEmpty) {
            // Check if any payment has status 'Credit'
            for (var payment in payments) {
              if (PaymentVerificationService.isPaymentSuccessful(
                payment['status'] ?? '',
              )) {
                hasCompletedPayment = true;
                break;
              }
            }
          }

          if (hasCompletedPayment || status == 'Completed') {
            // Verified successful payment
            _showPaymentResultDialog(
              success: true,
              message:
                  'Payment completed successfully! Your membership will be activated shortly.',
              paymentId: paymentId,
            );
          } else {
            // Payment exists but not yet confirmed
            _showPaymentResultDialog(
              success: false,
              message:
                  'Payment is being processed. You will receive a confirmation shortly.',
              paymentId: paymentId,
            );
          }
        } else if (status == 'Pending') {
          _showPaymentResultDialog(
            success: false,
            message:
                'Payment is pending. Please wait for confirmation or check your payment status.',
            paymentId: paymentId,
          );
        } else {
          _showPaymentResultDialog(
            success: false,
            message: 'Payment failed or was cancelled. Please try again.',
            paymentId: paymentId,
          );
        }
      } else {
        _showPaymentResultDialog(
          success: false,
          message:
              'Unable to verify payment status. Please contact support with your payment ID.',
          paymentId: paymentId,
        );
      }
    } catch (e) {
      // Close loading if still open
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }

      _showPaymentResultDialog(
        success: false,
        message: 'Error verifying payment: $e. Please contact support.',
        paymentId: paymentId,
      );
    }
  }

  void _showPaymentResultDialog({
    required bool success,
    required String message,
    String? paymentId,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error_outline,
              color: success ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                success ? 'Payment Successful!' : 'Payment Failed',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: success ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 14)),
            if (paymentId != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Payment ID: $paymentId',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(
                context,
              ).pop(success); // Close webview and return result
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: success
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF2196F3),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(success ? 'Done' : 'OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Complete Payment',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
