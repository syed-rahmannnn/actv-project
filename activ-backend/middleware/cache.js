// Simple in-memory cache middleware
const NodeCache = require('node-cache');
const cache = new NodeCache({ stdTTL: 300, checkperiod: 60 }); // 5 min default TTL

/**
 * Cache middleware for GET requests
 * @param {number} duration - Cache duration in seconds
 */
const cacheMiddleware = (duration = 300) => {
    return (req, res, next) => {
        // Only cache GET requests
        if (req.method !== 'GET') {
            return next();
        }

        const key = req.originalUrl || req.url;
        const cachedResponse = cache.get(key);

        if (cachedResponse) {
            console.log(`✅ Cache HIT: ${key}`);
            return res.json(cachedResponse);
        }

        console.log(`❌ Cache MISS: ${key}`);

        // Override res.json to cache the response
        const originalJson = res.json.bind(res);
        res.json = (body) => {
            if (res.statusCode === 200) {
                cache.set(key, body, duration);
            }
            return originalJson(body);
        };

        next();
    };
};

/**
 * Clear cache for specific pattern
 */
const clearCache = (pattern) => {
    const keys = cache.keys();
    const matchingKeys = keys.filter(key => key.includes(pattern));
    matchingKeys.forEach(key => cache.del(key));
    console.log(`🗑️  Cleared ${matchingKeys.length} cache entries for pattern: ${pattern}`);
};

/**
 * Clear all cache
 */
const clearAllCache = () => {
    cache.flushAll();
    console.log('🗑️  All cache cleared');
};

module.exports = {
    cacheMiddleware,
    clearCache,
    clearAllCache,
    cache
};