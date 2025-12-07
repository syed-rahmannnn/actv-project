import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer' as developer;
import '../models/business_profile_model.dart';
import 'api_service.dart';
import '../utils/cache_manager.dart';

class BusinessProfileService {
  static final _cache = FastCacheManager();
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
      return input.isNotEmpty ? jsonDecode(input) : {};
    } catch (e) {
      developer.log(
        '_jsonDecodeSafe error: $e, input: $input',
        name: 'BusinessProfileService',
      );
      return {'error': 'Invalid JSON response', 'raw': input};
    }
  }

  /// Clear cache for specific member
  static Future<void> clearCache(String memberId) async {
    final cacheKey = 'business_profile_$memberId';
    _cache.remove(cacheKey);
    developer.log(
      '🗑️ Cleared business profile cache for: $memberId',
      name: 'BusinessProfileService',
    );
  }

  /// Get business profile by member ID
  static Future<BusinessProfile?> getBusinessProfile(String memberId) async {
    try {
      final cacheKey = 'business_profile_$memberId';
      
      // Try cache first
      final cached = _cache.get<BusinessProfile>(cacheKey);
      if (cached != null) {
        developer.log(
          '✅ Loaded business profile from cache',
          name: 'BusinessProfileService',
        );
        return cached;
      }
      
      final url = Uri.parse('$baseUrl/profile/business-info/$memberId');
      developer.log(
        '🌐 Fetching business profile from API for: $memberId',
        name: 'BusinessProfileService',
      );

      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(_requestTimeout());

      if (response.statusCode == 200) {
        final body = _jsonDecodeSafe(response.body);
        if (body['success'] == true && body['data'] != null) {
          final businessInfo = body['data']['businessInfo'];
          if (businessInfo != null) {
            final profile = BusinessProfile.fromJson(businessInfo);
            // Cache for 3 minutes
            _cache.set(cacheKey, profile);
            return profile;
          }
        }
      } else if (response.statusCode == 404) {
        developer.log(
          'No business profile found for member: $memberId',
          name: 'BusinessProfileService',
        );
        return null;
      }

      developer.log(
        'Failed to fetch business profile: ${response.statusCode}',
        name: 'BusinessProfileService',
      );
      return null;
    } catch (e) {
      developer.log(
        'Error fetching business profile: $e',
        name: 'BusinessProfileService',
      );
      return null;
    }
  }

  /// Get business metrics (profile views, products count, etc.)
  static Future<BusinessMetrics> getBusinessMetrics(String businessId) async {
    try {
      final url = Uri.parse('$baseUrl/business/metrics?businessId=$businessId');
      developer.log(
        'Fetching business metrics for: $businessId',
        name: 'BusinessProfileService',
      );

      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(_requestTimeout());

      if (response.statusCode == 200) {
        final body = _jsonDecodeSafe(response.body);
        if (body['success'] == true && body['data'] != null) {
          return BusinessMetrics.fromJson(body['data']);
        }
      }

      // Return default metrics if API fails
      return BusinessMetrics(
        profileViews: 0,
        profileViewsChangePercent: 0,
        productsCount: 0,
        featuredProductsCount: 0,
      );
    } catch (e) {
      developer.log(
        'Error fetching business metrics: $e',
        name: 'BusinessProfileService',
      );
      // Return default metrics on error
      return BusinessMetrics(
        profileViews: 0,
        profileViewsChangePercent: 0,
        productsCount: 0,
        featuredProductsCount: 0,
      );
    }
  }

  /// Get business associations (company connections)
  static Future<List<BusinessAssociation>> getBusinessAssociations(
    String businessId,
  ) async {
    try {
      final url = Uri.parse(
        '$baseUrl/business/associations?businessId=$businessId',
      );
      developer.log(
        'Fetching business associations for: $businessId',
        name: 'BusinessProfileService',
      );

      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(_requestTimeout());

      if (response.statusCode == 200) {
        final body = _jsonDecodeSafe(response.body);
        if (body['success'] == true && body['data'] != null) {
          final associations = body['data'] as List<dynamic>;
          return associations
              .map((json) => BusinessAssociation.fromJson(json))
              .toList();
        }
      }

      // Return empty list if API fails or no associations found
      return [];
    } catch (e) {
      developer.log(
        'Error fetching business associations: $e',
        name: 'BusinessProfileService',
      );
      return [];
    }
  }

  /// Save or update business profile
  static Future<Map<String, dynamic>> saveBusinessProfile({
    required String memberId,
    required String businessName,
    required String businessType,
    String? description,
    String? mobile,
    String? area,
    String? location,
    String? logoUrl,
    String? website,
  }) async {
    try {
      final url = Uri.parse('$baseUrl/profile/business-info');
      developer.log(
        'Saving business profile for: $memberId',
        name: 'BusinessProfileService',
      );

      final payload = {
        'memberId': memberId,
        'organizationName': businessName,
        'businessType': businessType,
        if (description != null && description.isNotEmpty)
          'businessDescription': description,
        if (mobile != null && mobile.isNotEmpty) 'mobile': mobile,
        if (area != null && area.isNotEmpty) 'area': area,
        if (location != null && location.isNotEmpty) 'location': location,
        if (logoUrl != null && logoUrl.isNotEmpty) 'logoUrl': logoUrl,
        if (website != null && website.isNotEmpty) 'businessWebsite': website,
      };

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout());

      final body = _jsonDecodeSafe(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'message': body['message'] ?? 'Business profile saved successfully',
          'data': body['data'],
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Failed to save business profile',
        };
      }
    } catch (e) {
      developer.log(
        'Error saving business profile: $e',
        name: 'BusinessProfileService',
      );
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Update business profile
  static Future<Map<String, dynamic>> updateBusinessProfile({
    required String memberId,
    required Map<String, dynamic> updates,
  }) async {
    print('\n🌐🌐🌐 UPDATE BUSINESS PROFILE API CALL STARTING 🌐🌐🌐');
    print('🆔 Member ID: $memberId');
    print('📦 Updates received: $updates');

    try {
      final url = Uri.parse('$baseUrl/profile/business-info');
      print('🔗 API URL: $url');

      developer.log(
        'Updating business profile for: $memberId',
        name: 'BusinessProfileService',
      );

      final payload = {'memberId': memberId, ...updates};

      print('🔵 UPDATE PAYLOAD BEING SENT:');
      print(jsonEncode(payload));
      print('📱 Mobile in payload: ${payload['mobile']}');
      print('🏢 OrganizationName in payload: ${payload['organizationName']}');

      print('⏳ Making HTTP POST request...');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(_requestTimeout());

      print('✅ HTTP Response received!');
      print('📊 Status Code: ${response.statusCode}');
      print('📄 Response Body: ${response.body}');

      final body = _jsonDecodeSafe(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        print('✅ Success response from backend');
        return {
          'success': true,
          'message': body['message'] ?? 'Business profile updated successfully',
          'data': body['data'],
        };
      } else {
        print('❌ Error response from backend');
        return {
          'success': false,
          'message': body['message'] ?? 'Failed to update business profile',
        };
      }
    } catch (e, stackTrace) {
      print('❌❌❌ EXCEPTION IN UPDATE BUSINESS PROFILE ❌❌❌');
      print('Error: $e');
      print('Stack trace: $stackTrace');

      developer.log(
        'Error updating business profile: $e',
        name: 'BusinessProfileService',
      );
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get complete member profile including business info
  static Future<Map<String, dynamic>> getCompleteMemberProfile(
    String memberId,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/profile/$memberId');
      developer.log(
        'Fetching complete member profile for: $memberId',
        name: 'BusinessProfileService',
      );

      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(_requestTimeout());

      if (response.statusCode == 200) {
        final body = _jsonDecodeSafe(response.body);
        if (body['success'] == true && body['data'] != null) {
          return {'success': true, 'data': body['data']};
        }
      }

      return {'success': false, 'message': 'Failed to fetch member profile'};
    } catch (e) {
      developer.log(
        'Error fetching complete member profile: $e',
        name: 'BusinessProfileService',
      );
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Get all companies for a member
  static Future<List<CompanyInfo>> getMemberCompanies(String memberId) async {
    try {
      final url = Uri.parse('$baseUrl/business/companies?memberId=$memberId');
      developer.log(
        'Fetching companies for member: $memberId',
        name: 'BusinessProfileService',
      );

      final response = await http
          .get(url, headers: {'Content-Type': 'application/json'})
          .timeout(_requestTimeout());

      if (response.statusCode == 200) {
        final body = _jsonDecodeSafe(response.body);
        if (body['success'] == true && body['data'] != null) {
          final companies = body['data'] as List<dynamic>;
          return companies.map((json) => CompanyInfo.fromJson(json)).toList();
        }
      }

      // Return empty list if API fails or no companies found
      return [];
    } catch (e) {
      developer.log(
        'Error fetching member companies: $e',
        name: 'BusinessProfileService',
      );
      return [];
    }
  }
}
