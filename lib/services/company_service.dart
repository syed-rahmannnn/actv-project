import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../models/company_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class CompanyService {
  static final String baseUrl = ApiService.baseUrl;

  static Duration _requestTimeout() {
    try {
      final isRender = baseUrl.contains('onrender.com');
      return Duration(seconds: isRender ? 75 : 12);
    } catch (_) {
      return const Duration(seconds: 12);
    }
  }

  static dynamic _jsonDecodeSafe(String input) {
    try {
      return input.isNotEmpty ? jsonDecode(input) : null;
    } catch (e) {
      developer.log('_jsonDecodeSafe error: $e', name: 'CompanyService');
      return input;
    }
  }

  /// Get all companies for the logged-in member (uses auth token)
  static Future<List<Company>> getCompanies() async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('$baseUrl/companies');
      print('🌐 Companies URL: $url');
      print('🔑 Token (first 30 chars): ${token.substring(0, 30)}...');

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(_requestTimeout());

      print('📊 Response Status: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final body = _jsonDecodeSafe(response.body);
        developer.log(
          '✅ Parsed response body successfully',
          name: 'CompanyService',
        );

        if (body is Map && body['success'] == true) {
          if (body['data'] == null) {
            developer.log(
              '⚠️ Response has no data field',
              name: 'CompanyService',
            );
            return [];
          }

          final List<dynamic> companiesJson = body['data'];
          developer.log(
            '📦 Found ${companiesJson.length} companies in response',
            name: 'CompanyService',
          );

          final companies = companiesJson.map((json) {
            developer.log('🏢 Parsing company: $json', name: 'CompanyService');
            return Company.fromJson(json);
          }).toList();

          developer.log(
            '✅ Fetched ${companies.length} companies',
            name: 'CompanyService',
          );
          return companies;
        } else {
          developer.log(
            '❌ Response success=false or invalid format',
            name: 'CompanyService',
          );
          throw Exception('Invalid response format');
        }
      }

      developer.log(
        '❌ Failed to fetch companies: ${response.statusCode}',
        name: 'CompanyService',
      );
      developer.log(
        '❌ Error response body: ${response.body}',
        name: 'CompanyService',
      );

      // Provide specific error messages based on status code
      if (response.statusCode == 401) {
        throw Exception('Authentication required. Please login again.');
      } else if (response.statusCode == 403) {
        throw Exception('Session expired. Please logout and login again.');
      } else if (response.statusCode == 404) {
        throw Exception('Companies endpoint not found. Check API URL.');
      } else {
        throw Exception('Failed to fetch companies: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      developer.log('❌ Error fetching companies: $e', name: 'CompanyService');
      developer.log('📍 Stack trace: $stackTrace', name: 'CompanyService');

      // Re-throw with more context if it's a generic exception
      if (e.toString().contains('Failed to fetch companies')) {
        rethrow;
      } else {
        throw Exception('Failed to fetch companies: $e');
      }
    }
  }

  /// Get a single company by ID
  static Future<Company?> getCompany(String companyId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('$baseUrl/companies/$companyId');
      developer.log('🔍 Fetching company: $companyId', name: 'CompanyService');

      final response = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(_requestTimeout());

      if (response.statusCode == 200) {
        final body = _jsonDecodeSafe(response.body);
        if (body['success'] == true && body['data'] != null) {
          return Company.fromJson(body['data']);
        }
      }

      return null;
    } catch (e) {
      developer.log('❌ Error fetching company: $e', name: 'CompanyService');
      return null;
    }
  }

  /// Create a new company
  static Future<Company> createCompany({
    required String organizationName,
    required String businessType,
    String? mobile,
    String? area,
    String? location,
    String? businessDescription,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('$baseUrl/companies');
      developer.log(
        '📝 Creating company: $organizationName',
        name: 'CompanyService',
      );

      final body = {
        'name': organizationName, // Backend expects 'name'
        'industry': businessType, // Backend expects 'industry'
        if (mobile != null) 'mobile': mobile,
        if (area != null) 'area': area,
        if (location != null) 'location': location,
        if (businessDescription != null)
          'description': businessDescription, // Backend expects 'description'
      };

      developer.log('📦 Request body: $body', name: 'CompanyService');

      final response = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout());

      developer.log(
        '📊 Response Status: ${response.statusCode}',
        name: 'CompanyService',
      );
      developer.log(
        '📄 Response Body: ${response.body}',
        name: 'CompanyService',
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseBody = _jsonDecodeSafe(response.body);
        if (responseBody['success'] == true) {
          developer.log(
            '✅ Company created successfully',
            name: 'CompanyService',
          );
          return Company.fromJson(responseBody['data']);
        } else {
          final errorMsg = responseBody['message'] ?? 'Unknown error';
          developer.log(
            '❌ Backend returned success=false: $errorMsg',
            name: 'CompanyService',
          );
          throw Exception(errorMsg);
        }
      }

      // Handle error responses
      final errorBody = _jsonDecodeSafe(response.body);
      final errorMessage =
          errorBody['message'] ??
          errorBody['error'] ??
          'Failed to create company';
      developer.log('❌ Server error: $errorMessage', name: 'CompanyService');
      throw Exception(errorMessage);
    } catch (e) {
      developer.log('❌ Error creating company: $e', name: 'CompanyService');
      rethrow;
    }
  }

  /// Delete a company
  static Future<void> deleteCompany(String companyId) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('$baseUrl/companies/$companyId');
      developer.log('🗑️ Deleting company: $companyId', name: 'CompanyService');

      final response = await http
          .delete(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(_requestTimeout());

      if (response.statusCode != 200) {
        throw Exception('Failed to delete company');
      }

      developer.log('✅ Company deleted successfully', name: 'CompanyService');
    } catch (e) {
      developer.log('❌ Error deleting company: $e', name: 'CompanyService');
      rethrow;
    }
  }

  /// Update a company
  static Future<Company> updateCompany({
    required String companyId,
    String? name,
    String? industry,
    String? location,
    String? city,
    String? area,
    String? description,
    String? website,
    String? mobile,
    String? email,
    String? logoUrl,
    String? status,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      final url = Uri.parse('$baseUrl/companies/$companyId');
      developer.log('📝 Updating company: $companyId', name: 'CompanyService');

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (industry != null) body['industry'] = industry;
      if (location != null) body['location'] = location;
      if (city != null) body['city'] = city;
      if (area != null) body['area'] = area;
      if (description != null) body['description'] = description;
      if (website != null) body['website'] = website;
      if (mobile != null) body['mobile'] = mobile;
      if (email != null) body['email'] = email;
      if (logoUrl != null) body['logoUrl'] = logoUrl;
      if (status != null) body['status'] = status;

      developer.log('📦 Update body: $body', name: 'CompanyService');

      final response = await http
          .put(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout());

      developer.log(
        '📊 Response Status: ${response.statusCode}',
        name: 'CompanyService',
      );
      developer.log(
        '📄 Response Body: ${response.body}',
        name: 'CompanyService',
      );

      if (response.statusCode == 200) {
        final responseBody = _jsonDecodeSafe(response.body);
        if (responseBody['success'] == true && responseBody['data'] != null) {
          developer.log(
            '✅ Company updated successfully',
            name: 'CompanyService',
          );
          return Company.fromJson(responseBody['data']);
        } else {
          throw Exception(
            responseBody['message'] ?? 'Failed to update company',
          );
        }
      }

      final errorBody = _jsonDecodeSafe(response.body);
      final errorMessage = errorBody['message'] ?? 'Failed to update company';
      throw Exception(errorMessage);
    } catch (e) {
      developer.log('❌ Error updating company: $e', name: 'CompanyService');
      rethrow;
    }
  }

  /// Increment company views
  static Future<void> incrementViews(String companyId) async {
    try {
      final url = Uri.parse('$baseUrl/companies/$companyId/increment-views');
      await http
          .patch(url, headers: {'Content-Type': 'application/json'})
          .timeout(_requestTimeout());
    } catch (e) {
      developer.log('Error incrementing views: $e', name: 'CompanyService');
    }
  }
}
