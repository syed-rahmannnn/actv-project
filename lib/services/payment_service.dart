import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class PaymentService {
  // 🧪 TEST MODE - Set to true to simulate payments without Instamojo API
  static const bool isTestMode = true;
  static const String baseUrl = 'https://api.instamojo.com/v2';

  static Future<Map<String, dynamic>> createPaymentRequest({
    required double amount,
    required String purpose,
    required String buyerName,
    required String email,
    required String phone,
    required String redirectUrl,
  }) async {
    try {
      // TEST MODE: Simulate successful payment
      if (isTestMode) {
        if (kDebugMode) {
          print('🧪 TEST MODE: Simulating payment request');
          print('💰 Amount: ₹$amount');
          print('📝 Purpose: $purpose');
        }
        
        // Simulate API delay
        await Future.delayed(const Duration(seconds: 1));
        
        // Generate mock payment data
        final testPaymentId = 'TEST_${DateTime.now().millisecondsSinceEpoch}';
        final testPaymentUrl = 'https://test-payment-simulator.com?amount=$amount&id=$testPaymentId';
        
        if (kDebugMode) {
          print('✅ Test payment created: $testPaymentId');
        }
        
        return {
          'success': true,
          'payment_url': testPaymentUrl,
          'payment_request_id': testPaymentId,
          'test_mode': true,
        };
      }

      // LIVE MODE: Call actual Instamojo API
      final apiKey = dotenv.env['INSTAMOJO_API_KEY'] ?? '';
      final authToken = dotenv.env['INSTAMOJO_AUTH_TOKEN'] ?? '';

      if (apiKey.isEmpty || authToken.isEmpty) {
        if (kDebugMode) {
          print('❌ ERROR: Instamojo credentials are missing');
        }
        return {
          'success': false,
          'error': 'Payment service not configured. Please contact support.',
        };
      }

      final url = Uri.parse('$baseUrl/payment_requests/');

      final headers = {
        'X-Api-Key': apiKey,
        'X-Auth-Token': authToken,
        'Content-Type': 'application/json',
      };

      final bodyMap = {
        'purpose': purpose,
        'amount': amount.toString(),
        'buyer_name': buyerName,
        'email': email,
        'phone': phone,
        'redirect_url': redirectUrl,
      };

      final body = jsonEncode(bodyMap);

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'payment_url': responseData['payment_request']['longurl'],
          'payment_request_id': responseData['payment_request']['id'],
        };
      } else {
        if (kDebugMode) {
          print('Payment request failed: ${response.body}');
        }
        return {'success': false, 'error': response.body};
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Exception in createPaymentRequest: $e');
        print('Stack trace: $stackTrace');
      }
      return {'success': false, 'error': 'An error occurred: $e'};
    }
  }

  static Future<Map<String, dynamic>> getPaymentStatus(String requestId) async {
    try {
      final apiKey = dotenv.env['INSTAMOJO_API_KEY'];
      final authToken = dotenv.env['INSTAMOJO_AUTH_TOKEN'];

      if (apiKey == null ||
          apiKey.isEmpty ||
          authToken == null ||
          authToken.isEmpty) {
        print('❌ Instamojo credentials not found');
        return {'success': false, 'error': 'Payment service not configured'};
      }

      final url = Uri.parse('$baseUrl/payment_requests/$requestId/');
      final headers = {'X-Api-Key': apiKey, 'X-Auth-Token': authToken};

      print('📤 Checking payment status for: $requestId');

      final response = await http.get(url, headers: headers);

      print('📥 Payment status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('✅ Payment status retrieved');
        return {
          'success': true,
          'status': responseData['payment_request']['status'],
          'payments': responseData['payment_request']['payments'],
        };
      } else {
        print('❌ Failed to get payment status: ${response.body}');
        return {'success': false, 'error': response.body};
      }
    } catch (e) {
      print('❌ Exception in getPaymentStatus: $e');
      return {'success': false, 'error': 'An error occurred: $e'};
    }
  }
}
