/**
 * Hybrid Cache Middleware
 * Uses Redis if available, falls back to node-cache
 */

const redisCache = require('../utils/redis-cache');
const NodeCache = require('node-cache');

// Fallback in-memory cache
const memoryCache = new NodeCache({
    stdTTL: 180, // 3 minutes default
    checkperiod: 60, // Check for expired keys every minute
    useClones: false
});

/**
 * Smart cache middleware that uses Redis first, falls back to memory
 */
function hybridCacheMiddleware(ttlSeconds = 180) {
    return async(req, res, next) => {
        // Only cache GET requests
        if (req.method !== 'GET') {
            return next();
        }

        // Generate cache key
        const cacheKey = `api:${req.originalUrl || req.url}`;

        try {
            // Try Redis first
            if (redisCache.isConnected) {
                const cachedData = await redisCache.get(cacheKey);
                if (cachedData) {
                    console.log(`✅ Redis cache HIT: ${cacheKey}`);
                    return res.json(cachedData);
                }
            } else {
                // Fallback to memory cache
                const cachedData = memoryCache.get(cacheKey);
                if (cachedData) {
                    console.log(`✅ Memory cache HIT: ${cacheKey}`);
                    return res.json(cachedData);
                }
            }

            // Cache MISS - intercept response
            const originalJson = res.json.bind(res);
            res.json = async(data) => {
                // Cache the response
                if (res.statusCode === 200 && data) {
                    try {
                        if (redisCache.isConnected) {
                            await redisCache.set(cacheKey, data, ttlSeconds);
                            console.log(`📦 Redis cache SET: ${cacheKey} (${ttlSeconds}s)`);
                        } else {
                            memoryCache.set(cacheKey, data, ttlSeconds);
                            console.log(`📦 Memory cache SET: ${cacheKey} (${ttlSeconds}s)`);
                        }
                    } catch (error) {
                        console.error('Cache set error:', error);
                    }
                }
                return originalJson(data);
            };

            next();
        } catch (error) {
            console.error('Cache middleware error:', error);
            next();
        }
    };
}

/**
 * Clear cache by pattern
 */
async function clearCacheByPattern(pattern) {
    try {
        if (redisCache.isConnected) {
            await redisCache.delByPattern(pattern);
            console.log(`🧹 Redis cache cleared: ${pattern}`);
        } else {
            // Clear memory cache by pattern
            const keys = memoryCache.keys();
            const matchingKeys = keys.filter(key => key.includes(pattern));
            matchingKeys.forEach(key => memoryCache.del(key));
            console.log(`🧹 Memory cache cleared: ${matchingKeys.length} entries for pattern: ${pattern}`);
        }
    } catch (error) {
        console.error('Clear cache error:', error);
    }
}

/**
 * Get cache statistics
 */
async function getCacheStats() {
    if (redisCache.isConnected) {
        return await redisCache.getStats();
    } else {
        return {
            connected: false,
            type: 'memory',
            keys: memoryCache.keys().length,
            stats: memoryCache.getStats()
        };
    }
}

module.exports = {
    hybridCacheMiddleware,
    clearCacheByPattern,
    getCacheStats
};