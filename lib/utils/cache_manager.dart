/// Fast Cache Manager for ACTV App
/// Provides 3-minute in-memory caching for all screen data
/// 
/// Features:
/// - Automatic expiration (3 minutes)
/// - Memory-efficient LRU cache
/// - Type-safe API
/// - Async support

import 'dart:async';
import 'dart:collection';

/// Generic cache entry with expiration
class CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;

  CacheEntry(this.data, this.ttl) : timestamp = DateTime.now();

  bool get isExpired {
    return DateTime.now().difference(timestamp) > ttl;
  }

  Duration get remainingTime {
    final elapsed = DateTime.now().difference(timestamp);
    return ttl - elapsed;
  }
}

/// Fast in-memory cache manager with automatic cleanup
class FastCacheManager {
  static final FastCacheManager _instance = FastCacheManager._internal();
  factory FastCacheManager() => _instance;
  FastCacheManager._internal() {
    _startCleanupTimer();
  }

  // Default TTL: 3 minutes
  static const Duration defaultTTL = Duration(minutes: 3);
  
  // Maximum cache size (LRU eviction)
  static const int maxCacheSize = 100;

  final Map<String, CacheEntry<dynamic>> _cache = {};
  final Queue<String> _accessOrder = Queue<String>();
  Timer? _cleanupTimer;

  /// Get cached data by key
  T? get<T>(String key) {
    final entry = _cache[key];
    
    if (entry == null) {
      return null;
    }

    // Check expiration
    if (entry.isExpired) {
      _cache.remove(key);
      _accessOrder.remove(key);
      return null;
    }

    // Update LRU order
    _accessOrder.remove(key);
    _accessOrder.addLast(key);

    return entry.data as T;
  }

  /// Set cached data with optional custom TTL
  void set<T>(String key, T data, {Duration? ttl}) {
    final entry = CacheEntry<T>(data, ttl ?? defaultTTL);
    
    // Remove if exists
    if (_cache.containsKey(key)) {
      _accessOrder.remove(key);
    }

    // Evict LRU if cache is full
    if (_cache.length >= maxCacheSize) {
      final lruKey = _accessOrder.removeFirst();
      _cache.remove(lruKey);
    }

    _cache[key] = entry;
    _accessOrder.addLast(key);
  }

  /// Get or compute cached data
  Future<T> getOrSet<T>(
    String key,
    Future<T> Function() compute, {
    Duration? ttl,
  }) async {
    // Try to get from cache
    final cached = get<T>(key);
    if (cached != null) {
      return cached;
    }

    // Compute and cache
    final data = await compute();
    set(key, data, ttl: ttl);
    return data;
  }

  /// Check if key exists and is not expired
  bool has(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    
    if (entry.isExpired) {
      _cache.remove(key);
      _accessOrder.remove(key);
      return false;
    }
    
    return true;
  }

  /// Remove specific key
  void remove(String key) {
    _cache.remove(key);
    _accessOrder.remove(key);
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
    _accessOrder.clear();
  }

  /// Clear cache by prefix
  void clearByPrefix(String prefix) {
    final keysToRemove = _cache.keys.where((k) => k.startsWith(prefix)).toList();
    for (final key in keysToRemove) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }
  }

  /// Get cache statistics
  Map<String, dynamic> getStats() {
    int expiredCount = 0;
    int validCount = 0;

    for (final entry in _cache.values) {
      if (entry.isExpired) {
        expiredCount++;
      } else {
        validCount++;
      }
    }

    return {
      'totalEntries': _cache.length,
      'validEntries': validCount,
      'expiredEntries': expiredCount,
      'maxSize': maxCacheSize,
      'usagePercent': (_cache.length / maxCacheSize * 100).toStringAsFixed(1),
    };
  }

  /// Start automatic cleanup timer (runs every minute)
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _cleanupExpired();
    });
  }

  /// Remove all expired entries
  void _cleanupExpired() {
    final keysToRemove = <String>[];
    
    for (final entry in _cache.entries) {
      if (entry.value.isExpired) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }

    if (keysToRemove.isNotEmpty) {
      print('🧹 Cache cleanup: Removed ${keysToRemove.length} expired entries');
    }
  }

  /// Dispose and cleanup
  void dispose() {
    _cleanupTimer?.cancel();
    _cache.clear();
    _accessOrder.clear();
  }
}

/// Singleton instance for easy access
final cacheManager = FastCacheManager();

/// Cache key generators for different screens
class CacheKeys {
  // Dashboard
  static String dashboard(String memberId) => 'dashboard_$memberId';
  
  // Companies
  static String companies(String memberId, {int page = 1}) => 
    'companies_${memberId}_page_$page';
  static String company(String companyId) => 'company_$companyId';
  static String discoverCompanies(String memberId, String query, int page) =>
    'discover_companies_${memberId}_${query}_$page';
  
  // Products
  static String products(String companyId, {int page = 1}) => 
    'products_${companyId}_page_$page';
  static String product(String productId) => 'product_$productId';
  static String discoverProducts(String memberId, String query, int page) =>
    'discover_products_${memberId}_${query}_$page';
  
  // Members
  static String members(String memberId, {int page = 1}) => 
    'members_${memberId}_page_$page';
  static String memberProfile(String memberId) => 'member_profile_$memberId';
  static String browsemembers(String memberId, String? state, String? district) =>
    'browse_members_${memberId}_${state ?? 'all'}_${district ?? 'all'}';
  
  // Business Profile
  static String businessProfile(String memberId) => 'business_profile_$memberId';
  static String businessInfo(String memberId) => 'business_info_$memberId';
  
  // Analytics
  static String analytics(String companyId, String period) => 
    'analytics_${companyId}_$period';
  
  // Notifications
  static String notifications(String memberId) => 'notifications_$memberId';
  
  // Admin screens
  static String adminMembers(String adminId, String level, {int page = 1}) =>
    'admin_members_${adminId}_${level}_page_$page';
  static String adminApprovals(String adminId, String level) =>
    'admin_approvals_${adminId}_$level';
  
  // Location data
  static String locations() => 'locations_data';
  static String districts(String state) => 'districts_$state';
  static String blocks(String district) => 'blocks_$district';
}

/// Extension method for easy caching on Future
extension CacheableFuture<T> on Future<T> {
  /// Cache the result of this future
  Future<T> cached(String key, {Duration? ttl}) async {
    return cacheManager.getOrSet<T>(key, () => this, ttl: ttl);
  }
}
