import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/business_settings.dart';
import '../services/api_service.dart';

class SettingsProvider extends ChangeNotifier {
  BusinessSettings? _settings;
  bool _isLoading = false;
  String? _error;
  String? _currentBusinessId;

  // Getters
  BusinessSettings? get settings => _settings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentBusinessId => _currentBusinessId;

  /// Load settings for a specific business
  Future<void> loadSettings(String businessId) async {
    if (businessId.isEmpty) {
      print('⚠️ Cannot load settings: businessId is empty');
      return;
    }

    _isLoading = true;
    _error = null;
    _currentBusinessId = businessId;
    notifyListeners();

    try {
      final uri = Uri.parse(
        '${ApiService.baseUrl}/business/$businessId/settings',
      );

      print('🔍 Loading settings for business: $businessId');
      print('📡 Settings API URL: $uri');

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

      print('📊 Settings response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'success') {
          _settings = BusinessSettings.fromJson(jsonData['data']);
          print('✅ Loaded settings successfully');
          print('   - Public Profile: ${_settings!.publicProfile}');
          print(
            '   - Show Products Publicly: ${_settings!.showProductsPublicly}',
          );
          print('   - Private Analytics: ${_settings!.privateAnalytics}');
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to load settings');
        }
      } else if (response.statusCode == 404) {
        // No settings found, use defaults
        print('ℹ️ No settings found, using defaults');
        _settings = BusinessSettings.defaults(businessId);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load settings');
      }
    } catch (e) {
      print('❌ Error loading settings: $e');
      _error = e.toString();
      // Use defaults on error
      _settings = BusinessSettings.defaults(businessId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update settings for current business
  Future<void> updateSettings(BusinessSettings newSettings) async {
    if (newSettings.businessId.isEmpty) {
      print('⚠️ Cannot update settings: businessId is empty');
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final uri = Uri.parse(
        '${ApiService.baseUrl}/business/${newSettings.businessId}/settings',
      );

      print('🔄 Updating settings for business: ${newSettings.businessId}');
      print('📡 Settings API URL: $uri');

      final response = await http
          .put(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(newSettings.toJsonWithoutId()),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

      print('📊 Update response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'success') {
          _settings = newSettings;
          print('✅ Settings updated successfully');
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to update settings');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update settings');
      }
    } catch (e) {
      print('❌ Error updating settings: $e');
      _error = e.toString();
      // Revert to previous settings on error
      notifyListeners();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear all data
  void clear() {
    _settings = null;
    _error = null;
    _currentBusinessId = null;
    notifyListeners();
  }

  /// Reload settings for current business
  Future<void> reload() async {
    if (_currentBusinessId != null) {
      await loadSettings(_currentBusinessId!);
    }
  }
}
