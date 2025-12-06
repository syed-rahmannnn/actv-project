import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/discover_company.dart';
import '../models/discover_product.dart';
import '../services/api_service.dart';

class DiscoverProvider extends ChangeNotifier {
  List<DiscoverCompany> _companies = [];
  List<DiscoverProduct> _products = [];
  bool _isLoadingCompanies = false;
  bool _isLoadingProducts = false;
  String? _companiesError;
  String? _productsError;

  // Getters
  List<DiscoverCompany> get companies => _companies;
  List<DiscoverProduct> get products => _products;
  bool get isLoadingCompanies => _isLoadingCompanies;
  bool get isLoadingProducts => _isLoadingProducts;
  String? get companiesError => _companiesError;
  String? get productsError => _productsError;

  /// Load companies with optional search query
  /// Requires memberId to filter companies by business account
  Future<void> loadCompanies({
    required String memberId,
    String query = '',
    int page = 1,
    int limit = 20,
  }) async {
    if (memberId.isEmpty) {
      _companiesError = 'Member ID is required';
      _companies = [];
      notifyListeners();
      return;
    }

    _isLoadingCompanies = true;
    _companiesError = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/discover/companies').replace(
        queryParameters: {
          'memberId': memberId,
          'query': query,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      print('🔍 Loading companies: $uri');

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

      print('📡 Companies response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'success') {
          final List<dynamic> data = jsonData['data'] ?? [];
          _companies = data
              .map((json) => DiscoverCompany.fromJson(json))
              .toList();
          print('✅ Loaded ${_companies.length} companies');
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to load companies');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load companies');
      }
    } catch (e) {
      print('❌ Error loading companies: $e');
      _companiesError = e.toString();
      _companies = []; // Clear companies on error
    } finally {
      _isLoadingCompanies = false;
      notifyListeners();
    }
  }

  /// Load products with optional search query
  /// Requires memberId to filter products by business account
  Future<void> loadProducts({
    required String memberId,
    String query = '',
    int page = 1,
    int limit = 20,
  }) async {
    if (memberId.isEmpty) {
      _productsError = 'Member ID is required';
      _products = [];
      notifyListeners();
      return;
    }

    _isLoadingProducts = true;
    _productsError = null;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/discover/products').replace(
        queryParameters: {
          'memberId': memberId,
          'query': query,
          'page': page.toString(),
          'limit': limit.toString(),
        },
      );

      print('🔍 Loading products: $uri');

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Request timed out');
            },
          );

      print('📡 Products response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);

        if (jsonData['status'] == 'success') {
          final List<dynamic> data = jsonData['data'] ?? [];
          _products = data
              .map((json) => DiscoverProduct.fromJson(json))
              .toList();
          print('✅ Loaded ${_products.length} products');
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to load products');
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to load products');
      }
    } catch (e) {
      print('❌ Error loading products: $e');
      _productsError = e.toString();
      _products = []; // Clear products on error
    } finally {
      _isLoadingProducts = false;
      notifyListeners();
    }
  }

  /// Clear all data
  void clear() {
    _companies = [];
    _products = [];
    _companiesError = null;
    _productsError = null;
    notifyListeners();
  }
}
