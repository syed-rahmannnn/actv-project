import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';

class ProductService {
  static const String baseUrl = 'http://10.42.208.174:3000/api/products';
  static const Duration timeoutDuration = Duration(seconds: 10);

  /// Get all products for a company
  static Future<List<Product>> getProducts(String companyId) async {
    try {
      print('🔄 Fetching products for company: $companyId');

      final uri = Uri.parse('$baseUrl?companyId=$companyId');

      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(timeoutDuration);

      print('📦 Products API Response Status: ${response.statusCode}');
      print('📦 Products API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final List<dynamic> productsJson = data['data'];
          final products = productsJson
              .map((json) => Product.fromJson(json))
              .toList();

          print('✅ Successfully loaded ${products.length} products');
          return products;
        } else {
          print('⚠️ API returned success=false or no data');
          return [];
        }
      } else {
        print('❌ Failed to load products: ${response.statusCode}');
        throw Exception('Failed to load products: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching products: $e');
      rethrow;
    }
  }

  /// Create a new product
  static Future<Map<String, dynamic>> createProduct(Product product) async {
    try {
      print('🔄 Creating product: ${product.name}');

      final response = await http
          .post(
            Uri.parse(baseUrl),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(product.toJson()),
          )
          .timeout(timeoutDuration);

      print('📦 Create Product Response Status: ${response.statusCode}');
      print('📦 Create Product Response Body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✅ Product created successfully');
        return {
          'success': true,
          'message': data['message'] ?? 'Product created successfully',
          'data': data['data'],
        };
      } else {
        print('❌ Failed to create product: ${response.statusCode}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create product',
        };
      }
    } catch (e) {
      print('❌ Error creating product: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Update an existing product
  static Future<Map<String, dynamic>> updateProduct(
    String productId,
    Product product,
  ) async {
    try {
      print('🔄 Updating product: $productId');

      final response = await http
          .put(
            Uri.parse('$baseUrl/$productId'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(product.toJson()),
          )
          .timeout(timeoutDuration);

      print('📦 Update Product Response Status: ${response.statusCode}');
      print('📦 Update Product Response Body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        print('✅ Product updated successfully');
        return {
          'success': true,
          'message': data['message'] ?? 'Product updated successfully',
          'data': data['data'],
        };
      } else {
        print('❌ Failed to update product: ${response.statusCode}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update product',
        };
      }
    } catch (e) {
      print('❌ Error updating product: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }

  /// Delete a product
  static Future<Map<String, dynamic>> deleteProduct(String productId) async {
    try {
      print('🔄 Deleting product: $productId');

      final response = await http
          .delete(
            Uri.parse('$baseUrl/$productId'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(timeoutDuration);

      print('📦 Delete Product Response Status: ${response.statusCode}');
      print('📦 Delete Product Response Body: ${response.body}');

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        print('✅ Product deleted successfully');
        return {
          'success': true,
          'message': data['message'] ?? 'Product deleted successfully',
        };
      } else {
        print('❌ Failed to delete product: ${response.statusCode}');
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete product',
        };
      }
    } catch (e) {
      print('❌ Error deleting product: $e');
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
