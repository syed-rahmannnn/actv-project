// Script to register a user and then submit an application
// Usage: dart run register_user.dart

import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

const String apiBaseUrl = "https://actv-project.onrender.com/api";

Future<void> main() async {
  final rand = Random();
  final suffix = DateTime.now().millisecondsSinceEpoch.toString();
  final email = 'test.user.$suffix@example.com';
  final phone = '9${rand.nextInt(900000000) + 100000000}';
  final fullName = 'Test User $suffix';
  final genders = ['Male', 'Female', 'Other'];
  final gender = genders[rand.nextInt(genders.length)];

  // 1) Register user (backend expects phoneNumber here)
  final registerPayload = {
    'fullName': fullName,
    'email': email,
    'phoneNumber': phone,
    'dateOfBirth': '01-01-1990',
    'gender': gender,
    'password': 'Password@123',
    'block': 'Attur',
    'city': 'Attur',
    'district': 'Salem',
    'state': 'Tamil Nadu',
    'pincode': '636102',
  };

  final regRes = await http.post(
    Uri.parse('$apiBaseUrl/auth/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(registerPayload),
  );

  Map<String, dynamic> regBody;
  try {
    regBody = jsonDecode(regRes.body) as Map<String, dynamic>;
  } catch (_) {
    print('Registration failed: invalid JSON response');
    print(regRes.body);
    return;
  }

  if (regRes.statusCode < 200 || regRes.statusCode >= 300) {
    print('Registration failed (${regRes.statusCode}): $regBody');
    return;
  }

  final token = regBody['data']?['token'] ?? regBody['token'];
  final memberId = regBody['data']?['member']?['id'] ?? regBody['member']?['id'];

  if (memberId == null || memberId.toString().isEmpty) {
    print(
      'Registration succeeded but userId not found in response. Body: $regBody',
    );
    return;
  }
  if (token == null || token.toString().isEmpty) {
    print(
      'Registration succeeded but token not found in response. Body: $regBody',
    );
    return;
  }

  print('Registered userId=$memberId, gender=$gender');

  // 2) Submit application (backend expects these exact top-level fields)
  final appPayload = {
    'userId': memberId,
    'fullName': fullName,
    'email': email,
    'phone': phone, // note: application expects `phone`
    'gender': gender, // top-level gender used by backend
    'state': 'Tamil Nadu',
    'district': 'Salem',
    'block': 'Attur',
    'formData': {
      'agreeToDeclaration': true,
      'timestamp': DateTime.now().toIso8601String(),
    },
  };

  final appRes = await http.post(
    Uri.parse('$apiBaseUrl/applications/submit'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token', // required for application submission
    },
    body: jsonEncode(appPayload),
  );

  Map<String, dynamic> appBody;
  try {
    appBody = jsonDecode(appRes.body) as Map<String, dynamic>;
  } catch (_) {
    print('Application submission failed: invalid JSON response');
    print(appRes.body);
    return;
  }

  print('Application submit status=${appRes.statusCode}, body=$appBody');
}
