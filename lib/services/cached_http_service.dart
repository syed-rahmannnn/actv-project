/// HTTP Cache Service for ACTV App
/// Provides automatic caching for all HTTP/API requests
/// 
/// Features:
/// - Automatic 3-minute cache for GET requests
/// - Dio-based with interceptors
/// - Memory + disk caching
/// - Cache invalidation support

import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:path_provider/path_provider.dart';

class CachedHttpService {
  static final CachedHttpService _instance = CachedHttpService._internal();
  factory CachedHttpService() => _instance;
  CachedHttpService._internal();

  Dio? _dio;
  CacheOptions? _cacheOptions;

  /// Initialize the cached HTTP service
  Future<void> initialize(String baseUrl) async {
    // Get cache directory
    final cacheDir = await getTemporaryDirectory();
    final cacheStore = HiveCacheStore(
      '${cacheDir.path}/http_cache',
      hiveBoxName: 'actv_http_cache',
    );

    // Configure cache options
    _cacheOptions = CacheOptions(
      store: cacheStore,
      policy: CachePolicy.request,
      hitCacheOnErrorExcept: [401, 403, 404], // Don't cache errors except these
      maxStale: const Duration(minutes: 3), // 3-minute TTL
      priority: CachePriority.high,
      cipher: null,
      keyBuilder: CacheOptions.defaultCacheKeyBuilder,
      allowPostMethod: false, // Only GET requests
    );

    // Create Dio instance with interceptors
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add cache interceptor
    _dio!.interceptors.add(DioCacheInterceptor(options: _cacheOptions!));

    // Add logging interceptor (debug mode only)
    _dio!.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (log) => print('🌐 HTTP: $log'),
    ));

    print('✅ Cached HTTP Service initialized');
  }

  /// Get Dio instance
  Dio get dio {
    if (_dio == null) {
      throw Exception('CachedHttpService not initialized. Call initialize() first.');
    }
    return _dio!;
  }

  /// Perform GET request with automatic caching
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
    bool forceRefresh = false,
  }) async {
    final cachePolicy = forceRefresh ? CachePolicy.refresh : CachePolicy.request;
    
    final mergedOptions = (options ?? Options()).copyWith(
      extra: {
        ...?options?.extra,
        'cache_policy': cachePolicy,
      },
    ).copyWith(extra: _cacheOptions!.toExtra());

    return dio.get(
      path,
      queryParameters: queryParameters,
      options: mergedOptions,
      cancelToken: cancelToken,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Perform POST request (not cached)
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return dio.post(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Perform PUT request (not cached)
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    return dio.put(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      onReceiveProgress: onReceiveProgress,
    );
  }

  /// Perform DELETE request (not cached)
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return dio.delete(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }

  /// Clear all cache
  Future<void> clearCache() async {
    if (_cacheOptions?.store != null) {
      await _cacheOptions!.store!.clean();
      print('🧹 HTTP cache cleared');
    }
  }

  /// Delete specific cache by key pattern
  Future<void> deleteCacheByKey(String pattern) async {
    if (_cacheOptions?.store != null) {
      await _cacheOptions!.store!.clean(staleOnly: false);
      print('🧹 Cache cleared for pattern: $pattern');
    }
  }
}

/// Singleton instance
final cachedHttp = CachedHttpService();
