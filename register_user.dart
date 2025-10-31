import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

/// ---- CONFIGURE THESE VALUES ----
const String apiBaseUrl =
    "https://actv-project.onrender.com/api"; // Change as needed for your backend
// Optionally, add an auth token if needed for registration API

/// Generate a valid 24-character hex string to satisfy Mongo ObjectId casting
String generateHexObjectId() {
  final r = Random();
  final bytes = List<int>.generate(12, (_) => r.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

// Location values must match active admins in DB (meta.state/district/block)
const String state = "Tamil Nadu";
const String district = "Salem";
const String block = "Attur";

Future<void> main() async {
  print("🚀 Starting automated user registration for block admin testing...\n");

  // Generate random user data each time for hassle-free testing
  final randomId = Random().nextInt(10000000).toString();
  final randomPhone = "98765${10000 + Random().nextInt(89999)}";
  final userObjectId = generateHexObjectId();

  final userPayload = {
    // Backend expects ObjectId; pass a 24-hex string to avoid cast errors
    "userId": userObjectId,
    "fullName": "Test User $randomId",
    "email": "testuser$randomId@example.com",
    "phone": randomPhone,
    "gender": "Male",
    "state": state,
    "district": district,
    "block": block,
    "formData": {
      "fieldA":
          "valueA", // Add any required fields from your member form schema
      "fieldB": "valueB",
      "businessType": "Individual",
      "category": "General",
      "registrationDate": DateTime.now().toIso8601String(),
      // Example additional fields seen in the app; add others as needed
      "gender": "Male",
      "address": "123 Test St",
      "age": "25",
    },
  };

  print("📝 Generated user data:");
  print("   User ID: ${userPayload['userId']}");
  print("   Name: ${userPayload['fullName']}");
  print("   Email: ${userPayload['email']}");
  print("   Phone: ${userPayload['phone']}");
  print(
    "   Location: ${userPayload['state']} > ${userPayload['district']} > ${userPayload['block']}\n",
  );

  // Register user and submit application
  final url = Uri.parse("$apiBaseUrl/applications/submit");

  final headers = {
    "Content-Type": "application/json",
    "Accept": "application/json",
    // If your API requires auth: "Authorization": "Bearer YOUR_TOKEN"
  };

  try {
    print("🌐 Submitting application to: $url");
    final res = await http.post(
      url,
      headers: headers,
      body: jsonEncode(userPayload),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      print("✅ Registration success!");
      print("   Status Code: ${res.statusCode}");

      // Try to parse and pretty print the response
      try {
        final responseData = jsonDecode(res.body);
        print(
          "   Response: ${JsonEncoder.withIndent('  ').convert(responseData)}",
        );
      } catch (e) {
        print("   Response: ${res.body}");
      }
    } else {
      print("❌ Registration failed!");
      print("   Status Code: ${res.statusCode}");
      print("   Error Response: ${res.body}");

      // Parse and print backend message for clarity
      try {
        final errorJson = jsonDecode(res.body);
        final msg = errorJson is Map && errorJson.containsKey('message')
            ? errorJson['message']
            : null;
        if (msg != null) print("   Backend Message: $msg");
        if (errorJson is Map && errorJson.containsKey('details')) {
          print(
            "   Details: ${JsonEncoder.withIndent('  ').convert(errorJson['details'])}",
          );
        }
      } catch (_) {
        // Ignore JSON parse errors
      }
    }
  } catch (e) {
    print("💥 Network error occurred:");
    print("   Error: $e");
    print("\n💡 Tips:");
    print("   - Check if the backend server is running");
    print("   - Verify the API URL: $apiBaseUrl");
    print("   - Ensure you have internet connectivity");
    print("   - Confirm active admins exist for $state > $district > $block");
    print("   - Ensure userId is a valid 24-hex ObjectId");
  }

  print("\n🔄 Run this script again to create another test user!");
}
