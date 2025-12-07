# Frontend Caching Implementation Guide

## Overview
This guide explains the Flutter frontend caching system that works in tandem with the backend optimizations to reduce API calls and improve app performance.

## Architecture

### Cache Service
**File**: `lib/services/cache_service.dart`

Simple in-memory caching using `shared_preferences`:
- **TTL Support**: Automatic expiration based on time-to-live
- **JSON Serialization**: Stores complex objects as JSON strings
- **Pattern Clearing**: Clear specific cache patterns (e.g., all company caches)
- **Statistics**: Track cache hits, misses, and expiration

### Cache Strategy

```dart
// Cache check flow:
1. Check if cache exists and is not expired
2. If cache hit: Return cached data (no API call)
3. If cache miss: Fetch from API and store in cache
4. On error: Return cached data if available (stale-while-revalidate)
```

## Usage Examples

### 1. DiscoverProvider Caching

The `DiscoverProvider` now supports caching with the `forceRefresh` parameter:

```dart
// Load with cache (default)
await provider.loadCompanies(
  memberId: memberId,
  query: 'software',
  page: 1,
);

// Force refresh (bypass cache)
await provider.loadCompanies(
  memberId: memberId,
  query: 'software',
  page: 1,
  forceRefresh: true,
);

// Refresh all discover data
await provider.refresh(memberId: memberId, query: query);
```

### 2. Manual Cache Operations

```dart
import '../services/cache_service.dart';

// Store data
await CacheService.set(
  'my_key',
  {'data': 'value'},
  ttl: Duration(minutes: 5),
);

// Retrieve data
final data = await CacheService.get('my_key');

// Clear specific cache
await CacheService.clear('my_key');

// Clear pattern
await CacheService.clearPattern('discover_');

// Clear all cache
await CacheService.clearAll();

// Check cache stats
final stats = await CacheService.getStats();
print('Valid: ${stats['valid']}, Expired: ${stats['expired']}');
```

### 3. Cache Keys

Predefined cache keys for consistency:

```dart
// Companies
CacheKeys.companiesList(memberId)
CacheKeys.companyDetail(companyId)

// Products
CacheKeys.productsList(companyId)
CacheKeys.productDetail(productId)

// Discover
CacheKeys.discoverCompanies(memberId, query, page)
CacheKeys.discoverProducts(memberId, query, page)

// Dashboard
CacheKeys.dashboard(companyId)
CacheKeys.analytics(companyId)

// Business Profile
CacheKeys.businessProfile(memberId)
```

### 4. TTL Presets

```dart
CacheTTL.short     // 30 seconds
CacheTTL.medium    // 2 minutes (default for discover)
CacheTTL.long      // 5 minutes
CacheTTL.veryLong  // 15 minutes (for analytics)
```

## Implementation Guide

### Adding Cache to Existing Providers

#### Step 1: Import Cache Service
```dart
import '../services/cache_service.dart';
```

#### Step 2: Add Cache Check
```dart
Future<void> loadData({bool forceRefresh = false}) async {
  _isLoading = true;
  notifyListeners();

  try {
    // Cache check
    if (!forceRefresh) {
      final cacheKey = CacheKeys.myDataKey(id);
      final cachedData = await CacheService.get(cacheKey);
      
      if (cachedData != null) {
        _data = MyModel.fromJson(cachedData);
        _isLoading = false;
        notifyListeners();
        return;
      }
    }

    // API call
    final response = await http.get(uri);
    
    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      _data = MyModel.fromJson(jsonData);
      
      // Store in cache
      final cacheKey = CacheKeys.myDataKey(id);
      await CacheService.set(cacheKey, jsonData, ttl: CacheTTL.medium);
    }
  } catch (e) {
    // Handle error
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
```

#### Step 3: Add Refresh Method
```dart
Future<void> refresh() async {
  await loadData(forceRefresh: true);
}
```

### Pull-to-Refresh Example

```dart
RefreshIndicator(
  onRefresh: () async {
    final provider = context.read<DiscoverProvider>();
    await provider.refresh(memberId: widget.memberId, query: _searchQuery);
  },
  child: ListView.builder(
    // Your list items
  ),
)
```

## Cache Invalidation Strategies

### 1. Time-Based (Automatic)
Cache expires after TTL:
```dart
await CacheService.set(key, data, ttl: Duration(minutes: 2));
```

### 2. Event-Based (Manual)
Clear cache when data changes:
```dart
// After creating a company
await CacheService.clearPattern('companies_');
await CacheService.clearPattern('discover_companies_');

// After updating a product
await CacheService.clear(CacheKeys.productDetail(productId));
await CacheService.clearPattern('products_${companyId}');
```

### 3. User-Triggered
Add refresh button in UI:
```dart
IconButton(
  icon: Icon(Icons.refresh),
  onPressed: () async {
    await provider.refresh(memberId: memberId);
  },
)
```

## Performance Metrics

### Expected Improvements

| Operation | Without Cache | With Cache | Improvement |
|-----------|---------------|------------|-------------|
| Discover Companies | 3563ms | <50ms | **98.6% faster** |
| Discover Products | 1279ms | <50ms | **96.1% faster** |
| Repeated Searches | 1000-3500ms | <50ms | **95-98% faster** |

### Cache Hit Rate Targets
- **Cold Start**: 0% (first time)
- **Normal Usage**: 60-80% (most searches cached)
- **Heavy Usage**: 80-95% (same searches repeated)

## Best Practices

### 1. Choose Appropriate TTL
```dart
// Frequently changing data
ttl: CacheTTL.short  // 30 seconds

// Moderately changing data
ttl: CacheTTL.medium  // 2 minutes

// Rarely changing data
ttl: CacheTTL.long  // 5 minutes

// Static data (analytics, reports)
ttl: CacheTTL.veryLong  // 15 minutes
```

### 2. Clear Cache on Mutations
```dart
// After POST/PUT/DELETE operations
await CacheService.clearPattern('relevant_pattern_');
```

### 3. Handle Cache Errors Gracefully
```dart
try {
  final cached = await CacheService.get(key);
  if (cached != null) return cached;
} catch (e) {
  // Log error but continue to API call
  print('Cache error: $e');
}
```

### 4. Monitor Cache Performance
```dart
// Periodically check stats
final stats = await CacheService.getStats();
print('Cache stats: $stats');

// Look for cache hit logs
// ✅ Cache HIT: discover_companies_123_software_1
// ❌ Cache MISS: discover_products_456_hardware_2
```

### 5. Clean Up Expired Entries
```dart
// Optional: Run on app startup
await CacheService.clearAll();

// Or periodically clean expired only
final stats = await CacheService.getStats();
if (stats['expired']! > 50) {
  // Clear expired entries
  await CacheService.clearAll();
}
```

## Debugging

### Enable Cache Logs
Cache service already logs all operations:
- `✅ Cache HIT`: Data loaded from cache
- `❌ Cache MISS`: Cache not found or expired
- `✅ Cache SET`: Data stored in cache
- `🗑️ Cache cleared`: Cache entry removed

### Check Cache Contents
```dart
// Get all cache stats
final stats = await CacheService.getStats();
print('Total: ${stats['total']}');
print('Valid: ${stats['valid']}');
print('Expired: ${stats['expired']}');

// Check specific key
final hasCache = await CacheService.has('my_key');
print('Has cache: $hasCache');
```

## Testing Cache

### Test Cache Hit/Miss
```dart
// Test cache miss (first call)
await provider.loadCompanies(memberId: '123', query: 'test');
// Should see: "❌ Cache MISS" in logs

// Test cache hit (second call within TTL)
await provider.loadCompanies(memberId: '123', query: 'test');
// Should see: "✅ Cache HIT" in logs

// Test cache expiry (wait for TTL to expire)
await Future.delayed(Duration(minutes: 3));
await provider.loadCompanies(memberId: '123', query: 'test');
// Should see: "❌ Cache MISS (expired)" in logs
```

### Test Force Refresh
```dart
// Should bypass cache
await provider.loadCompanies(
  memberId: '123',
  query: 'test',
  forceRefresh: true,
);
// Should NOT see cache hit log
```

## Migration Checklist

To add caching to other screens:

- [ ] Import `cache_service.dart` in provider
- [ ] Add `forceRefresh` parameter to load methods
- [ ] Add cache check before API call
- [ ] Store API response in cache after successful call
- [ ] Add refresh method for force refresh
- [ ] Add cache clearing on data mutations (POST/PUT/DELETE)
- [ ] Add pull-to-refresh widget in UI
- [ ] Test cache hit/miss scenarios
- [ ] Monitor cache performance

## Combined Backend + Frontend Performance

With both optimizations:

1. **First Request** (cold cache):
   - Backend N+1 fix: 3563ms → ~150ms
   - Frontend cache: No benefit (first time)
   - **Total improvement**: ~95% faster

2. **Subsequent Requests** (warm cache):
   - Backend: ~150ms (if cache miss)
   - Frontend: <50ms (cache hit)
   - **Total improvement**: ~98% faster

3. **Expected User Experience**:
   - First search: 150ms (EXCELLENT)
   - Repeat search: <50ms (INSTANT)
   - Pull-to-refresh: 150ms (EXCELLENT)

## Troubleshooting

### Issue: Cache not working
- Check if `shared_preferences` is added to `pubspec.yaml`
- Verify cache logs appear in console
- Ensure TTL is not too short

### Issue: Stale data shown
- Reduce TTL for that data type
- Add manual cache clearing on updates
- Implement pull-to-refresh

### Issue: Cache takes too much space
- Reduce TTL values
- Clear cache more frequently
- Use shorter cache keys

### Issue: Performance still slow
- Check if cache hit rate is low (see logs)
- Verify backend optimizations are deployed
- Test network latency separately

## Related Documentation
- `OPTIMIZATION_GUIDE.md` - Backend optimization details
- `OPTIMIZATION_SUMMARY.md` - Quick performance reference
- `API_DOCUMENTATION.md` - API endpoint documentation
- `test/README.md` - Load testing guide
