import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class InstamojoConfig {
  static String get apiKey => dotenv.env['INSTAMOJO_API_KEY'] ?? '';
  static String get authToken => dotenv.env['INSTAMOJO_AUTH_TOKEN'] ?? '';
  static String get privateSalt => dotenv.env['INSTAMOJO_PRIVATE_SALT'] ?? '';

  // Base URL for Instamojo API
  static const String baseUrl = 'https://api.instamojo.com/v2/';
  static const String paymentRequestUrl = '${baseUrl}payment_requests/';

  // For testing - print values to verify they're loaded (use only in development)
  static void printCredentials() {
    if (kDebugMode) {
      print('API Key: ${apiKey.isNotEmpty ? "✓ Loaded" : "✗ Missing"}');
      print('Auth Token: ${authToken.isNotEmpty ? "✓ Loaded" : "✗ Missing"}');
      print('Private Salt: ${privateSalt.isNotEmpty ? "✓ Loaded" : "✗ Missing"}');
    }
  }

  // Check if all credentials are available
  static bool get isConfigured {
    return apiKey.isNotEmpty && authToken.isNotEmpty && privateSalt.isNotEmpty;
  }
}
