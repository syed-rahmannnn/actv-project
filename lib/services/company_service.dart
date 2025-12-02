import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../models/company_model.dart';
import 'api_service.dart';

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

  /// Get all companies for a member
  static Future<List<Company>> getCompanies(String memberId) async {
    try {
      final url = Uri.parse('$baseUrl/companies?memberId=$memberId');
      developer.log(
        'Fetching companies for member: $memberId',
        name: 'CompanyService',
      );

      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(_requestTimeout());

      if (response.statusCode == 200) {
        final body = _jsonDecodeSafe(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> companiesJson = body['data'];
          return companiesJson.map((json) => Company.fromJson(json)).toList();
        }
      }

      developer.log(
        'Failed to fetch companies: ${response.statusCode}',
        name: 'CompanyService',
      );
      return [];
    } catch (e) {
      developer.log('Error fetching companies: $e', name: 'CompanyService');
      return [];
    }
  }

  /// Get a single company by ID
  static Future<Company?> getCompany(String companyId) async {
    try {
      final url = Uri.parse('$baseUrl/companies/$companyId');
      developer.log('Fetching company: $companyId', name: 'CompanyService');

      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(_requestTimeout());

      if (response.statusCode == 200) {
        final body = _jsonDecodeSafe(response.body);
        if (body['success'] == true && body['data'] != null) {
          return Company.fromJson(body['data']);
        }
      }

      return null;
    } catch (e) {
      developer.log('Error fetching company: $e', name: 'CompanyService');
      return null;
    }
  }

  /// Create a new company
  static Future<Map<String, dynamic>> createCompany({
    required String memberId,
    required String name,
    String? industry,
    String? location,
    String? city,
    String? area,
    String? description,
    String? website,
    String? mobile,
    String? email,
    String? logoUrl,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/companies');
      developer.log('Creating company: $name', name: 'CompanyService');

      final body = {
        'memberId': memberId,
        'name': name,
        if (industry != null) 'industry': industry,
        if (location != null) 'location': location,
        if (city != null) 'city': city,
        if (area != null) 'area': area,
        if (description != null) 'description': description,
        if (website != null) 'website': website,
        if (mobile != null) 'mobile': mobile,
        if (email != null) 'email': email,
        if (logoUrl != null) 'logoUrl': logoUrl,
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout());

      final responseBody = _jsonDecodeSafe(response.body);

      if (response.statusCode == 201) {
        developer.log('Company created successfully', name: 'CompanyService');
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Company created successfully',
          'data': responseBody['data'] != null
              ? Company.fromJson(responseBody['data'])
              : null,
        };
      }

      return {
        'success': false,
        'message': responseBody['message'] ?? 'Failed to create company',
      };
    } catch (e) {
      developer.log('Error creating company: $e', name: 'CompanyService');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Update a company
  static Future<Map<String, dynamic>> updateCompany({
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
      final url = Uri.parse('$baseUrl/companies/$companyId');
      developer.log('Updating company: $companyId', name: 'CompanyService');

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

      final response = await http
          .put(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(_requestTimeout());

      final responseBody = _jsonDecodeSafe(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Company updated successfully',
          'data': responseBody['data'] != null
              ? Company.fromJson(responseBody['data'])
              : null,
        };
      }

      return {
        'success': false,
        'message': responseBody['message'] ?? 'Failed to update company',
      };
    } catch (e) {
      developer.log('Error updating company: $e', name: 'CompanyService');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Delete a company
  static Future<Map<String, dynamic>> deleteCompany(String companyId) async {
    try {
      final url = Uri.parse('$baseUrl/companies/$companyId');
      developer.log('Deleting company: $companyId', name: 'CompanyService');

      final response = await http
          .delete(url, headers: {'Content-Type': 'application/json'})
          .timeout(_requestTimeout());

      final responseBody = _jsonDecodeSafe(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseBody['message'] ?? 'Company deleted successfully',
        };
      }

      return {
        'success': false,
        'message': responseBody['message'] ?? 'Failed to delete company',
      };
    } catch (e) {
      developer.log('Error deleting company: $e', name: 'CompanyService');
      return {'success': false, 'message': 'Error: $e'};
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
