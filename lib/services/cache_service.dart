import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple cache service for API responses
/// Stores data with TTL (Time To Live) to reduce unnecessary API calls
class CacheService {
  static const String _cachePrefix = 'cache_';
  static const String _timestampPrefix = 'cache_time_';

  /// Save data to cache with key
  static Future<void> set(String key, dynamic data, {Duration ttl = const Duration(minutes: 5)}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Store data as JSON string
      final jsonString = jsonEncode(data);
      await prefs.setString('$_cachePrefix$key', jsonString);
      
      // Store timestamp for TTL checking
      final expiryTime = DateTime.now().add(ttl).millisecondsSinceEpoch;
      await prefs.setInt('$_timestampPrefix$key', expiryTime);
      
      print('✅ Cache SET: $key (TTL: ${ttl.inMinutes} min)');
    } catch (e) {
      print('❌ Cache SET error for $key: $e');
    }
  }

  /// Get data from cache by key
  /// Returns null if not found or expired
  static Future<dynamic> get(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Check if cache exists
      final jsonString = prefs.getString('$_cachePrefix$key');
      if (jsonString == null) {
        print('❌ Cache MISS: $key (not found)');
        return null;
      }
      
      // Check if cache is expired
      final expiryTime = prefs.getInt('$_timestampPrefix$key');
      if (expiryTime == null || DateTime.now().millisecondsSinceEpoch > expiryTime) {
        print('❌ Cache MISS: $key (expired)');
        await clear(key); // Clean up expired cache
        return null;
      }
      
      // Return cached data
      print('✅ Cache HIT: $key');
      return jsonDecode(jsonString);
    } catch (e) {
      print('❌ Cache GET error for $key: $e');
      return null;
    }
  }

  /// Clear specific cache entry
  static Future<void> clear(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_cachePrefix$key');
      await prefs.remove('$_timestampPrefix$key');
      print('🗑️  Cache cleared: $key');
    } catch (e) {
      print('❌ Cache clear error for $key: $e');
    }
  }

  /// Clear all cache entries
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix) || key.startsWith(_timestampPrefix)) {
          await prefs.remove(key);
        }
      }
      
      print('🗑️  All cache cleared');
    } catch (e) {
      print('❌ Cache clearAll error: $e');
    }
  }

  /// Clear cache for specific pattern (e.g., all company caches)
  static Future<void> clearPattern(String pattern) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      int cleared = 0;
      for (final key in keys) {
        if ((key.startsWith(_cachePrefix) || key.startsWith(_timestampPrefix)) && 
            key.contains(pattern)) {
          await prefs.remove(key);
          cleared++;
        }
      }
      
      print('🗑️  Cache cleared for pattern "$pattern": $cleared entries');
    } catch (e) {
      print('❌ Cache clearPattern error for $pattern: $e');
    }
  }

  /// Check if cache exists and is not expired
  static Future<bool> has(String key) async {
    final data = await get(key);
    return data != null;
  }

  /// Get cache statistics
  static Future<Map<String, int>> getStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      int total = 0;
      int expired = 0;
      int valid = 0;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      
      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          total++;
          
          final cacheKey = key.replaceFirst(_cachePrefix, '');
          final expiryTime = prefs.getInt('$_timestampPrefix$cacheKey');
          
          if (expiryTime == null || now > expiryTime) {
            expired++;
          } else {
            valid++;
          }
        }
      }
      
      return {
        'total': total,
        'valid': valid,
        'expired': expired,
      };
    } catch (e) {
      print('❌ Cache stats error: $e');
      return {'total': 0, 'valid': 0, 'expired': 0};
    }
  }
}

/// Cache keys for different data types
class CacheKeys {
  // Companies
  static String companiesList(String memberId) => 'companies_$memberId';
  static String companyDetail(String companyId) => 'company_$companyId';
  
  // Products
  static String productsList(String companyId) => 'products_$companyId';
  static String productDetail(String productId) => 'product_$productId';
  
  // Discover
  static String discoverCompanies(String memberId, String query, int page) => 
      'discover_companies_${memberId}_${query}_$page';
  static String discoverProducts(String memberId, String query, int page) => 
      'discover_products_${memberId}_${query}_$page';
  
  // Dashboard
  static String dashboard(String companyId) => 'dashboard_$companyId';
  static String analytics(String companyId) => 'analytics_$companyId';
  
  // Business Profile
  static String businessProfile(String memberId) => 'business_profile_$memberId';
}

/// Cache TTL presets
class CacheTTL {
  static const Duration short = Duration(seconds: 30);    // 30 seconds
  static const Duration medium = Duration(minutes: 2);    // 2 minutes
  static const Duration long = Duration(minutes: 5);      // 5 minutes
  static const Duration veryLong = Duration(minutes: 15); // 15 minutes
}
