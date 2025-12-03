import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/analytics_overview.dart';
import '../services/api_service.dart';

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsOverview? _overview;
  bool _isLoading = false;
  String? _error;
  String? _currentCompanyId;

  // Getters
  AnalyticsOverview? get overview => _overview;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentCompanyId => _currentCompanyId;

  /// Load analytics for a specific company
  Future<void> loadAnalytics(String companyId) async {
    if (companyId.isEmpty) {
      print('⚠️ Cannot load analytics: companyId is empty');
      return;
    }

    _isLoading = true;
    _error = null;
    _currentCompanyId = companyId;
    notifyListeners();

    try {
      // ApiService.baseUrl already includes '/api', so we only need to add the route path
      final uri = Uri.parse(
        '${ApiService.baseUrl}/analytics/overview',
      ).replace(queryParameters: {'companyId': companyId});

      print('🔍 Loading analytics for company: $companyId');
      print('📡 Analytics API URL: $uri');
      print('📡 Base URL: ${ApiService.baseUrl}');

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

      print('📊 Analytics response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'success') {
          _overview = AnalyticsOverview.fromJson(jsonData['data']);
          print('✅ Loaded analytics successfully');
          print('   - Profile Views: ${_overview!.profileViews}');
          print('   - Product Views: ${_overview!.productViews}');
          print(
            '   - Weekly data points: ${_overview!.weeklyProfileViews.length}',
          );
          print('   - Top products: ${_overview!.topProducts.length}');
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to load analytics');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load analytics');
      }
    } catch (e) {
      print('❌ Error loading analytics: $e');
      _error = e.toString();
      _overview = null; // Clear overview on error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear all data
  void clear() {
    _overview = null;
    _error = null;
    _currentCompanyId = null;
    notifyListeners();
  }

  /// Reload analytics for current company
  Future<void> reload() async {
    if (_currentCompanyId != null) {
      await loadAnalytics(_currentCompanyId!);
    }
  }
}
