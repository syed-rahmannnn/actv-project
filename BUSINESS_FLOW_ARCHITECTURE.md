# Business Flow Architecture

## Overview
This document describes the complete business account flow, including backend APIs, frontend services, and cache management strategy.

---

## 🏗️ Backend Architecture

### Cache Strategy
- **Middleware**: `hybrid-cache.js` (Redis with memory fallback)
- **TTL**: 180 seconds (3 minutes)
- **Cache Key Format**: `api:/api/{endpoint}?{params}`
- **Invalidation**: Pattern-based clearing using `clearCacheByPattern()`

### API Endpoints Structure

#### 1. Profile/Business Info Routes (`/api/profile`)
**Base Path**: `/api/profile`

| Method | Endpoint | Description | Cache Behavior |
|--------|----------|-------------|----------------|
| GET | `/:memberId` | Get complete member profile | Cached (180s) |
| POST | `/business-info` | Save/Update business info + Auto-create company | **Clears cache**: `memberId={id}` |
| GET | `/business-info/:memberId` | Get business info only | Cached (180s) |
| POST | `/financial-info` | Save financial information | No cache clearing |
| POST | `/declaration` | Save declaration | No cache clearing |

**Cache Clearing After Business Save**:
```javascript
// Clears ALL cache entries for this member
await clearCacheByPattern(`memberId=${memberId}`);
// This clears:
// - api:/api/companies?memberId=xxx
// - api:/api/profile/xxx
// - api:/api/profile/business-info/xxx
```

---

#### 2. Companies Routes (`/api/companies`)
**Base Path**: `/api/companies`

| Method | Endpoint | Description | Cache Behavior |
|--------|----------|-------------|----------------|
| GET | `/?memberId={id}` | Get all companies for member | Cached (180s) |
| GET | `/:companyId` | Get single company by ID | Cached (180s) |
| POST | `/` | Create new company | **Clears cache**: `memberId={id}` |
| PUT | `/:companyId` | Update company | **Clears cache**: `memberId={id}` |
| DELETE | `/:companyId` | Delete company | **Clears cache**: `memberId={id}` |
| PATCH | `/:companyId/increment-views` | Increment view count | No cache clearing |

**Cache Clearing Logic**:
```javascript
// After CREATE
await clearCacheByPattern(`memberId=${memberId}`);

// After UPDATE/DELETE
await clearCacheByPattern(`memberId=${company.memberId}`);
```

---

#### 3. Products Routes (`/api/products`)
**Base Path**: `/api/products`

| Method | Endpoint | Description | Cache Behavior |
|--------|----------|-------------|----------------|
| GET | `/?companyId={id}` | Get all products for company | Cached (180s) |
| POST | `/` | Create new product | **Clears cache**: `companyId={id}` |
| PUT | `/:id` | Update product | **Clears cache**: `companyId={id}` |
| DELETE | `/:id` | Delete product | **Clears cache**: `companyId={id}` |

**Cache Clearing Logic**:
```javascript
// After CREATE
await clearCacheByPattern(`companyId=${companyId}`);

// After UPDATE/DELETE
await clearCacheByPattern(`companyId=${product.companyId}`);
```

---

## 📱 Frontend Architecture

### Service Layer Structure

#### 1. BusinessProfileService
**Location**: `lib/services/business_profile_service.dart`

**Features**:
- ✅ Frontend caching (FastCacheManager)
- ✅ Cache TTL: Not specified (default)
- ✅ Manual cache clearing: `clearCache(memberId)`

**Methods**:
| Method | Cache Strategy | Notes |
|--------|---------------|-------|
| `getBusinessProfile(memberId)` | Try cache → API → Cache result | Returns BusinessProfile or null |
| `saveBusinessInfo(...)` | No caching (POST) | Saves business info + auto-creates company |
| `clearCache(memberId)` | Remove cache entry | Called before fetching fresh data |

**Cache Key Format**: `business_profile_{memberId}`

---

#### 2. CompanyService
**Location**: `lib/services/company_service.dart`

**Features**:
- ✅ Frontend caching (FastCacheManager)
- ✅ Cache TTL: 3 minutes
- ✅ Manual cache clearing: `clearCache(memberId)`
- ✅ **Auto-clear after createCompany**

**Methods**:
| Method | Cache Strategy | Notes |
|--------|---------------|-------|
| `getCompanies(memberId)` | Try cache → API → Cache result | Returns List<Company> |
| `getCompanyById(companyId)` | No cache (direct API call) | Returns single Company |
| `createCompany(...)` | No cache + **Auto-clear** | Clears cache after success |
| `updateCompany(...)` | No cache | Updates company data |
| `deleteCompany(companyId)` | No cache | Deletes company |

**Cache Key Format**: `companies_{memberId}`

**Auto Cache Clearing**:
```dart
if (response.statusCode == 201) {
  // 🗑️ Clear frontend cache after successful creation
  await clearCache(memberId);
  return {...};
}
```

---

#### 3. ProductService
**Location**: `lib/services/product_service.dart`

**Features**:
- ❌ No frontend caching
- ✅ Always fetches fresh data from API
- ✅ Backend cache handles performance

**Methods**:
| Method | Cache Strategy | Notes |
|--------|---------------|-------|
| `getProducts(companyId)` | Always fetch from API | Relies on backend cache |
| `createProduct(product)` | No cache | Backend clears cache |
| `updateProduct(id, product)` | No cache | Backend clears cache |
| `deleteProduct(productId)` | No cache | Backend clears cache |

**Why No Frontend Cache?**
- Products change frequently
- Backend cache (180s) provides sufficient performance
- Simpler cache invalidation (backend-only)

---

## 🔄 Complete Flow Diagrams

### Flow 1: Create Business Account
```
User Action: Fill business profile form → Submit
    ↓
Frontend: business_profile_screen.dart
    ↓
Service: BusinessProfileService.saveBusinessInfo()
    ↓ POST /api/profile/business-info
Backend: routes/profile.js
    ↓
1. Save MemberBusinessInfo to MongoDB
2. Auto-create Company document
3. Clear cache: clearCacheByPattern(`memberId=${memberId}`)
    ↓ Response: {success: true}
Frontend: Wait 1500ms for backend completion
    ↓
Navigate to: BusinessDashboardScreen
    ↓
Screen: businessaccount_dashboard_screen.dart
    ↓
1. clearCache(memberId) - Clear frontend caches
2. Fetch: getBusinessProfile(memberId)
3. Fetch: getCompanies(memberId)
    ↓
Backend: Returns fresh data (cache cleared)
    ↓
UI: Display company with 0 products ✅
```

### Flow 2: Add New Company
```
User Action: Click "Add Company" → Fill form → Submit
    ↓
Frontend: manage_companies_screen.dart
    ↓
Service: CompanyService.createCompany()
    ↓ POST /api/companies
Backend: routes/companies.js
    ↓
1. Create Company document
2. Clear cache: clearCacheByPattern(`memberId=${memberId}`)
    ↓ Response: {success: true, data: company}
Frontend Service: clearCache(memberId) - Auto clear
    ↓
Screen: Navigator.pop(context, true)
    ↓
Parent Screen: Reload companies list
    ↓
Service: getCompanies(memberId) - Cache cleared, fresh fetch
    ↓
Backend: Returns fresh data
    ↓
UI: New company appears immediately ✅
```

### Flow 3: Add Product
```
User Action: Click "Add Product" → Fill form → Submit
    ↓
Frontend: add_product_new_screen.dart
    ↓
Direct HTTP POST: POST /api/products
    ↓
Backend: routes/products.js
    ↓
1. Create Product document
2. Clear cache: clearCacheByPattern(`companyId=${companyId}`)
    ↓ Response: {success: true}
Frontend: Navigator.pop(context, true)
    ↓
Parent Screen: products_services_screen.dart
    ↓
Service: ProductService.getProducts(companyId)
    ↓ GET /api/products?companyId=xxx
Backend: Cache cleared → Fresh database query
    ↓
UI: New product appears immediately ✅
```

---

## 🐛 Common Issues & Solutions

### Issue 1: "Company shows 0 after creation"
**Cause**: Backend cache not cleared after auto-company creation
**Solution**: ✅ FIXED - Added `clearCacheByPattern()` in profile.js after company creation

### Issue 2: "Product doesn't show after adding"
**Cause**: Backend cache not cleared after product creation
**Solution**: ✅ FIXED - Added `clearCacheByPattern()` in products.js after CRUD operations

### Issue 3: "Failed to load" errors
**Cause**: 
- Network timeout (slow connection)
- Backend render.com cold start
- Frontend timeout too short

**Solutions**:
1. **Increased Timeouts**:
   - CompanyService: 75s for render.com, 12s for local
   - ProductService: 10s timeout
   - BusinessProfileService: 75s for render.com, 12s for local

2. **Retry Logic** (Recommended to add):
```dart
static Future<T> _retryRequest<T>(
  Future<T> Function() request, {
  int maxRetries = 3,
  Duration delay = const Duration(seconds: 2),
}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      return await request();
    } catch (e) {
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(delay);
    }
  }
  throw Exception('Max retries exceeded');
}
```

### Issue 4: "Data shows old values after refresh"
**Cause**: Frontend cache not cleared before fetching
**Solution**: ✅ FIXED - All screens clear cache before loading:
```dart
await BusinessProfileService.clearCache(memberId);
await CompanyService.clearCache(memberId);
// Then fetch fresh data
```

---

## ⚡ Performance Optimization

### Backend Optimizations
1. ✅ Hybrid cache with 180s TTL
2. ✅ Pattern-based cache invalidation
3. ✅ Lean queries: `.lean()` for read-only data
4. ✅ Indexed queries: MongoDB indexes on `memberId`, `companyId`

### Frontend Optimizations
1. ✅ Parallel API calls: `Future.wait([...])`
2. ✅ FastCacheManager for offline support
3. ✅ Selective cache clearing (by memberId/companyId)
4. ✅ Pull-to-refresh on all screens

### Recommended Future Optimizations
1. **Add retry logic** to all API calls
2. **Add offline indicator** when backend unreachable
3. **Add request deduplication** for rapid repeated calls
4. **Add pagination** for large product/company lists
5. **Add WebSocket** for real-time updates

---

## 📊 Cache Invalidation Matrix

| Action | Backend Cache Cleared | Frontend Cache Cleared | Pattern Used |
|--------|----------------------|------------------------|--------------|
| **Business Profile Save** | ✅ | ❌ | `memberId={id}` |
| **Company Create** | ✅ | ✅ (auto) | `memberId={id}` |
| **Company Update** | ✅ | ❌ | `memberId={id}` |
| **Company Delete** | ✅ | ❌ | `memberId={id}` |
| **Product Create** | ✅ | N/A | `companyId={id}` |
| **Product Update** | ✅ | N/A | `companyId={id}` |
| **Product Delete** | ✅ | N/A | `companyId={id}` |
| **Pull-to-Refresh** | ❌ | ✅ | Manual clear |

---

## 🔍 Debugging Guide

### Check Backend Cache
```javascript
// In any route, log cache stats
const { getCacheStats } = require('../middleware/hybrid-cache');
const stats = await getCacheStats();
console.log('Cache stats:', stats);
```

### Check Frontend Cache
```dart
// In any screen
print('📦 Cache keys: ${_cache.getAllKeys()}');
```

### Monitor Cache Hits/Misses
**Backend logs show**:
- `✅ Memory cache HIT: api:/api/companies?memberId=xxx` (cached)
- `📦 Memory cache SET: api:/api/companies?memberId=xxx (180s)` (new cache)
- `🧹 Memory cache cleared: 2 entries for pattern: memberId=xxx` (invalidated)

**Frontend logs show**:
- `✅ Loaded 3 companies from cache` (cache hit)
- `🌐 Fetching companies from API for memberId: xxx` (cache miss)
- `🗑️ Cleared companies cache for: xxx` (manual clear)

---

## 🎯 Testing Checklist

### Test 1: New Business Account Creation
- [ ] Register new user
- [ ] Fill business profile form
- [ ] Submit → Wait 1.5s → Navigate to dashboard
- [ ] **Expected**: Company shows immediately with 0 products
- [ ] **Check logs**: Backend clears cache, frontend fetches fresh

### Test 2: Add New Company
- [ ] Go to Manage Companies
- [ ] Click Add Company → Fill form → Submit
- [ ] **Expected**: New company appears in list immediately
- [ ] **Check logs**: Backend clears cache, frontend auto-clears

### Test 3: Add Product
- [ ] Go to Products & Services
- [ ] Click Add Product → Fill form → Submit
- [ ] **Expected**: New product appears in list immediately
- [ ] **Check logs**: Backend clears cache, frontend fetches fresh

### Test 4: Pull-to-Refresh
- [ ] On any business screen, pull down to refresh
- [ ] **Expected**: Loading indicator → Fresh data loaded
- [ ] **Check logs**: Frontend clears cache before fetch

### Test 5: Network Issues
- [ ] Disconnect internet → Try to load data
- [ ] **Expected**: Cached data shown OR timeout error
- [ ] Reconnect internet → Pull to refresh
- [ ] **Expected**: Fresh data loaded

---

## 📝 Implementation Status

| Feature | Status | Notes |
|---------|--------|-------|
| Business Profile Cache Clearing | ✅ | Clears on save |
| Company Cache Clearing | ✅ | Clears on CREATE/UPDATE/DELETE |
| Product Cache Clearing | ✅ | Clears on CREATE/UPDATE/DELETE |
| Frontend Auto-Clear (Company) | ✅ | After createCompany() |
| Pull-to-Refresh | ✅ | All business screens |
| Retry Logic | ❌ | Recommended to add |
| Offline Mode | ❌ | Frontend cache provides partial support |
| Real-time Updates | ❌ | Future enhancement |

---

## 🚀 Quick Reference

### Backend Cache Commands
```javascript
// Clear cache by pattern
await clearCacheByPattern('memberId=123');
await clearCacheByPattern('companyId=456');

// Get cache stats
const stats = await getCacheStats();
```

### Frontend Cache Commands
```dart
// Clear company cache
await CompanyService.clearCache(memberId);

// Clear business profile cache
await BusinessProfileService.clearCache(memberId);

// Products don't use frontend cache
```

### File Locations
```
Backend:
├── middleware/hybrid-cache.js         (Cache logic)
├── routes/profile.js                  (Business info + auto-company)
├── routes/companies.js                (Company CRUD)
└── routes/products.js                 (Product CRUD)

Frontend:
├── services/business_profile_service.dart
├── services/company_service.dart
├── services/product_service.dart
└── screens/Bussiness account/
    ├── business_profile_screen.dart
    ├── businessaccount_dashboard_screen.dart
    ├── manage_companies_screen.dart
    └── Products/products_services_screen.dart
```

---

**Last Updated**: December 7, 2025
**Status**: ✅ All cache issues resolved
**Next Steps**: Add retry logic, improve error handling
