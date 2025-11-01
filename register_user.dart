// Simple script to register a test user and submit an application
// Run with: dart run register_user.dart

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

  // 1) Register user
  final registerPayload = {
    "fullName": fullName,
    "email": email,
    "phoneNumber": phone,
    "dateOfBirth": "01-01-1990",
    "gender": gender,
    "password": "Password@123",
    "block": "Attur",
    "city": "Attur",
    "district": "Salem",
    "state": "Tamil Nadu",
    "pincode": "636102",
  };

  final regRes = await http.post(
    Uri.parse('$apiBaseUrl/auth/register'),
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(registerPayload),
  );
  final regBody = jsonDecode(regRes.body);
  if (regRes.statusCode < 200 || regRes.statusCode >= 300) {
    print('Registration failed: ${regBody}');
    return;
  }
  final token = regBody['data']?['token'] ?? regBody['token'];
  final memberId = regBody['data']?['member']?['_id'] ?? regBody['member']?['_id'];
  print('Registered userId=$memberId, gender=$gender');

  // 2) Submit application
  final appPayload = {
    'userId': memberId,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'state': 'Tamil Nadu',
    'district': 'Salem',
    'block': 'Attur',
    // Top-level gender aligns with backend route and schema
    'gender': gender,
    'formData': {
      'agreeToDeclaration': true,
      'timestamp': DateTime.now().toIso8601String(),
      // Optional duplication not needed; backend reads top-level gender
    },
  };

  final appRes = await http.post(
    Uri.parse('$apiBaseUrl/applications/submit'),
    headers: {
      "Content-Type": "application/json",
      if (token != null) "Authorization": "Bearer $token",
    },
    body: jsonEncode(appPayload),
  );
  final appBody = jsonDecode(appRes.body);
  print('Application submit status=${appRes.statusCode}, body=${appBody}');
}
