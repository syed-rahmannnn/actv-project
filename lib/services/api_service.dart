import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Your local backend server URL
  // static const String baseUrl = 'http://localhost:3000/api'; // Local development
  //static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android Emulator  
  static const String baseUrl = 'http://192.168.29.130:4000';
  // Active Wi‑Fi IP
  // Headers for requests
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Firebase validate (allow only registered members)
  static Future<Map<String, dynamic>> firebaseValidate({
    required String firebaseUid,
    required String? email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/firebase-validate'),
        headers: headers,
        body: jsonEncode({
          'firebaseUid': firebaseUid,
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body)['message'] ?? 'Validation failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> getMemberByFirebaseUid(String uid) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/members/by-firebase?uid=$uid'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body)['message'] ?? 'Fetch failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
  // Login user
  static Future<Map<String, dynamic>> loginUser({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: headers,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data,
          'user': data['user'],
          'token': data['token'], // If you're using JWT
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body)['message'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
  /// Registers a user with combined data from step1 + step2.
  static Future<Map<String, dynamic>> registerUser({
    required String fullName,
    required String phoneNumber,
    required String email,
    required String dateOfBirth,
    required String gender,
    required String password,
    String? address,
    String? block,
    String? city,
    String? district,
    String? state,
    String? pincode,
    String? profilePicture,
    String? memberType,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/register');
      final payload = {
        'fullName': fullName,
        'phone': phoneNumber,
        'email': email,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'password': password,
        'address': address,
        'block': block,
        'city': city,
        'district': district,
        'state': state,
        'pincode': pincode,
        'profilePicture': profilePicture,
        'memberType': memberType,
      };

      final resp = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(payload),
      );

      final body = jsonDecode(resp.body);

      if (resp.statusCode == 201 || resp.statusCode == 200) {
        return {'success': true, 'data': body};
      } else {
        return {'success': false, 'status': resp.statusCode, 'data': body};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>> getUserProfile({
    required String userId,
    String? token,
  }) async {
    try {
      Map<String, String> requestHeaders = {...headers};
      if (token != null) {
        requestHeaders['Authorization'] = 'Bearer $token';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/user/$userId'),
        headers: requestHeaders,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body)['message'] ?? 'Failed to get user profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Check if email exists
  static Future<Map<String, dynamic>> checkEmailExists(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/check-email?email=$email'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'exists': jsonDecode(response.body)['exists'],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to check email',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Check if phone number exists
  static Future<Map<String, dynamic>> checkPhoneExists(String phoneNumber) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/check-phone?phoneNumber=$phoneNumber'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'exists': jsonDecode(response.body)['exists'],
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to check phone number',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    required String fullName,
    required String phoneNumber,
    required DateTime dateOfBirth,
    required String state,
    required String district,
    required String completeAddress,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/$userId/profile'),
        headers: headers,
        body: jsonEncode({
          'fullName': fullName,
          'phoneNumber': phoneNumber,
          'dateOfBirth': dateOfBirth.toIso8601String(),
          'state': state,
          'district': district,
          'completeAddress': completeAddress,
        }),
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body)['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Upload profile picture
  static Future<Map<String, dynamic>> uploadProfilePicture({
    required String userId,
    required String imagePath,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user/$userId/profile-picture'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'profilePicture',
          imagePath,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': jsonDecode(response.body)['message'] ?? 'Failed to upload profile picture',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  // Get members
  static Future<Map<String, dynamic>> getMembers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/members'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(response.body),
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch members',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }
}
