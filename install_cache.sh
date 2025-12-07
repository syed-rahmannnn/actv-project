#!/bin/bash
# ACTV App - Cache System Installation Script
# Run this to install all caching dependencies

echo "🚀 Installing ACTV App Cache System..."
echo ""

# Install Flutter dependencies
echo "📦 Installing Flutter packages..."
flutter pub add flutter_cache_manager dio dio_cache_interceptor dio_cache_interceptor_hive_store path_provider hive

echo ""
echo "✅ Cache packages installed!"
echo ""

# Get dependencies
echo "📥 Getting all dependencies..."
flutter pub get

echo ""
echo "🎉 Cache system installed successfully!"
echo ""
echo "📝 Next steps:"
echo "   1. Import cache_manager.dart in your screens"
echo "   2. Use cacheManager.getOrSet() for data fetching"
echo "   3. See CACHE_USAGE_GUIDE.dart for examples"
echo ""
echo "🚀 Example usage:"
echo ""
echo "   import 'package:activ/utils/cache_manager.dart';"
echo ""
echo "   final data = await cacheManager.getOrSet<List<Company>>("
echo "     CacheKeys.companies(memberId),"
echo "     () async => await fetchCompaniesFromAPI(),"
echo "   );"
echo ""
echo "✨ Happy caching!"
