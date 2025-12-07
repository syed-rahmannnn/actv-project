/**
 * Redis Cache Service for Production
 * Provides fast, distributed caching for PM2 cluster mode
 */

const redis = require('redis');

class RedisCacheService {
    constructor() {
        this.client = null;
        this.isConnected = false;
    }

    /**
     * Initialize Redis connection
     */
    async connect() {
        // In development without REDIS_URL, skip Redis entirely
        if (!process.env.REDIS_URL && process.env.NODE_ENV !== 'production') {
            console.log('ℹ️  Redis disabled in development (set REDIS_URL to enable)');
            this.isConnected = false;
            return false;
        }

        try {
            // Use environment variable or default to localhost
            const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';

            this.client = redis.createClient({
                url: redisUrl,
                socket: {
                    connectTimeout: 5000,
                    reconnectStrategy: (retries) => {
                        if (retries > 3) {
                            console.log('⚠️  Redis unavailable, using memory cache');
                            return new Error('Redis reconnection failed');
                        }
                        return Math.min(retries * 1000, 3000);
                    }
                }
            });

            // Suppress error logs in development
            this.client.on('error', (err) => {
                if (process.env.NODE_ENV === 'production') {
                    console.error('❌ Redis Error:', err.message);
                }
                this.isConnected = false;
            });

            this.client.on('connect', () => {
                console.log('✅ Redis connected');
                this.isConnected = true;
            });

            this.client.on('ready', () => {
                console.log('✅ Redis ready for caching');
            });

            await this.client.connect();
            return true;
        } catch (error) {
            if (process.env.NODE_ENV === 'production') {
                console.error('❌ Redis connection failed:', error.message);
            }
            console.log('⚠️  Using in-memory cache fallback');
            this.isConnected = false;
            return false;
        }
    }

    /**
     * Get value from cache
     */
    async get(key) {
        if (!this.isConnected) return null;

        try {
            const value = await this.client.get(key);
            if (value) {
                return JSON.parse(value);
            }
            return null;
        } catch (error) {
            console.error('Redis get error:', error);
            return null;
        }
    }

    /**
     * Set value in cache with TTL
     */
    async set(key, value, ttlSeconds = 180) {
        if (!this.isConnected) return false;

        try {
            await this.client.setEx(key, ttlSeconds, JSON.stringify(value));
            return true;
        } catch (error) {
            console.error('Redis set error:', error);
            return false;
        }
    }

    /**
     * Delete key from cache
     */
    async del(key) {
        if (!this.isConnected) return false;

        try {
            await this.client.del(key);
            return true;
        } catch (error) {
            console.error('Redis del error:', error);
            return false;
        }
    }

    /**
     * Delete keys by pattern
     */
    async delByPattern(pattern) {
        if (!this.isConnected) return false;

        try {
            const keys = await this.client.keys(pattern);
            if (keys.length > 0) {
                await this.client.del(keys);
            }
            return true;
        } catch (error) {
            console.error('Redis delByPattern error:', error);
            return false;
        }
    }

    /**
     * Check if key exists
     */
    async exists(key) {
        if (!this.isConnected) return false;

        try {
            return await this.client.exists(key) === 1;
        } catch (error) {
            console.error('Redis exists error:', error);
            return false;
        }
    }

    /**
     * Get cache statistics
     */
    async getStats() {
        if (!this.isConnected) {
            return {
                connected: false,
                keys: 0,
                memory: 'N/A'
            };
        }

        try {
            const info = await this.client.info('stats');
            const dbSize = await this.client.dbSize();

            return {
                connected: true,
                keys: dbSize,
                info: info
            };
        } catch (error) {
            console.error('Redis stats error:', error);
            return { connected: false };
        }
    }

    /**
     * Disconnect from Redis
     */
    async disconnect() {
        if (this.client && this.isConnected) {
            await this.client.quit();
            this.isConnected = false;
            console.log('✅ Redis disconnected');
        }
    }
}

// Singleton instance
const redisCache = new RedisCacheService();

module.exports = redisCache;