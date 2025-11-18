import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  // Load .env file
  await dotenv.load(fileName: ".env");

  // Test credentials
  print('\n🔐 Testing Instamojo Credentials from .env:');
  print('─' * 50);

  final apiKey = dotenv.env['INSTAMOJO_API_KEY'];
  final authToken = dotenv.env['INSTAMOJO_AUTH_TOKEN'];
  final privateSalt = dotenv.env['INSTAMOJO_PRIVATE_SALT'];

  print(
    'API Key: ${apiKey != null && apiKey.isNotEmpty ? "✅ Loaded (${apiKey.substring(0, 8)}...)" : "❌ Missing"}',
  );
  print(
    'Auth Token: ${authToken != null && authToken.isNotEmpty ? "✅ Loaded (${authToken.substring(0, 8)}...)" : "❌ Missing"}',
  );
  print(
    'Private Salt: ${privateSalt != null && privateSalt.isNotEmpty ? "✅ Loaded (${privateSalt.substring(0, 8)}...)" : "❌ Missing"}',
  );

  print('─' * 50);

  if (apiKey != null &&
      apiKey.isNotEmpty &&
      authToken != null &&
      authToken.isNotEmpty) {
    print('✅ All credentials loaded successfully!');
    print('\nFull values:');
    print('API Key: $apiKey');
    print('Auth Token: $authToken');
    print('Private Salt: $privateSalt');
  } else {
    print('❌ Some credentials are missing!');
  }
}
