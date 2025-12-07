# ACTV App - Cache System Installation Script (Windows)
# Run this to install all caching dependencies

Write-Host "🚀 Installing ACTV App Cache System..." -ForegroundColor Cyan
Write-Host ""

# Install Flutter dependencies
Write-Host "📦 Installing Flutter packages..." -ForegroundColor Yellow
flutter pub add flutter_cache_manager
flutter pub add dio
flutter pub add dio_cache_interceptor
flutter pub add dio_cache_interceptor_hive_store
flutter pub add path_provider
flutter pub add hive

Write-Host ""
Write-Host "✅ Cache packages installed!" -ForegroundColor Green
Write-Host ""

# Get dependencies
Write-Host "📥 Getting all dependencies..." -ForegroundColor Yellow
flutter pub get

Write-Host ""
Write-Host "🎉 Cache system installed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Next steps:" -ForegroundColor Cyan
Write-Host "   1. Import cache_manager.dart in your screens"
Write-Host "   2. Use cacheManager.getOrSet() for data fetching"
Write-Host "   3. See CACHE_USAGE_GUIDE.dart for examples"
Write-Host ""
Write-Host "🚀 Example usage:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   import 'package:activ/utils/cache_manager.dart';"
Write-Host ""
Write-Host "   final data = await cacheManager.getOrSet<List<Company>>(" -ForegroundColor White
Write-Host "     CacheKeys.companies(memberId)," -ForegroundColor White
Write-Host "     () async => await fetchCompaniesFromAPI()," -ForegroundColor White
Write-Host "   );" -ForegroundColor White
Write-Host ""
Write-Host "✨ Happy caching!" -ForegroundColor Magenta
