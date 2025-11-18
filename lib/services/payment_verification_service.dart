import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentVerificationService {
  /// Verify payment signature using MD5 hash
  /// This should ideally be done on the backend for security
  static bool verifyPaymentSignature(Map<String, dynamic> webhookData) {
    try {
      final privateSalt = dotenv.env['INSTAMOJO_PRIVATE_SALT'] ?? '';

      if (privateSalt.isEmpty) {
        print('Private salt not configured');
        return false;
      }

      // Extract MAC from webhook data
      final receivedMac = webhookData['mac'];

      if (receivedMac == null) {
        print('MAC not found in webhook data');
        return false;
      }

      // Create a copy without mac for verification
      final dataForVerification = Map<String, dynamic>.from(webhookData);
      dataForVerification.remove('mac');

      // Sort keys and create message string
      final sortedKeys = dataForVerification.keys.toList()..sort();
      String message = '';

      for (var key in sortedKeys) {
        message += '$key=${dataForVerification[key]}|';
      }
      message += privateSalt;

      // Calculate MD5 hash
      final bytes = utf8.encode(message);
      final calculatedMac = md5.convert(bytes).toString();

      // Compare MACs
      return calculatedMac == receivedMac;
    } catch (e) {
      print('Error verifying payment signature: $e');
      return false;
    }
  }

  /// Extract payment details from callback URL
  static Map<String, String> extractPaymentDetailsFromUrl(String url) {
    final uri = Uri.parse(url);
    return {
      'payment_id': uri.queryParameters['payment_id'] ?? '',
      'payment_request_id': uri.queryParameters['payment_request_id'] ?? '',
      'payment_status': uri.queryParameters['payment_status'] ?? '',
    };
  }

  /// Validate payment data completeness
  static bool isPaymentDataComplete(Map<String, dynamic> paymentData) {
    final requiredFields = [
      'payment_id',
      'payment_request_id',
      'status',
      'amount',
    ];

    for (var field in requiredFields) {
      if (!paymentData.containsKey(field) ||
          paymentData[field] == null ||
          paymentData[field].toString().isEmpty) {
        return false;
      }
    }

    return true;
  }

  /// Check if payment status indicates success
  static bool isPaymentSuccessful(String status) {
    // Instamojo payment statuses:
    // 'Credit' = Payment successful
    // 'Failed' = Payment failed
    // 'Pending' = Payment pending
    return status.toLowerCase() == 'credit' ||
        status.toLowerCase() == 'completed';
  }
}
