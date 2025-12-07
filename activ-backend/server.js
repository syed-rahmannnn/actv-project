const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
// Load environment variables
if (process.env.NODE_ENV === 'production') {
    require('dotenv').config({ path: './production.env' });
} else {
    require('dotenv').config({ path: './config.env' });
}

// Import routes
const authRoutes = require('./routes/auth');
const memberRoutes = require('./routes/members');
const profileRoutes = require('./routes/profile');
const memberDetailsRoutes = require('./routes/memberDetails');
const adminAuthRouteFactory = require('./routes/adminAuth');
const applicationsRouteFactory = require('./routes/applications');
const webhookRoutes = require('./routes/webhook');
const browseMembersRoutes = require('./routes/browseMembers');
const notificationsRoutes = require('./routes/notifications');
const businessRoutes = require('./routes/business');
const companiesRoutes = require('./routes/companies');
const productsRoutes = require('./routes/products');
const discoverRoutes = require('./routes/discover');
const analyticsRoutes = require('./routes/analytics');
const businessSettingsRoutes = require('./routes/businessSettings');
const dashboardRoutes = require('./routes/dashboard');

// Import optimization middleware
const compressionMiddleware = require('./middleware/compression');
const performanceMiddleware = require('./middleware/performance');
const { cacheMiddleware } = require('./middleware/cache');
const { hybridCacheMiddleware } = require('./middleware/hybrid-cache');

const app = express();
const PORT = process.env.PORT || 3000;

// Trust proxy setting for deployment platforms like Render, Heroku, etc.
app.set('trust proxy', 1); // trust first proxy

// Security middleware
app.use(helmet());

// Compression middleware (must be before other middleware)
app.use(compressionMiddleware);

// Performance monitoring
app.use(performanceMiddleware);

// Rate limiting - DISABLED for development/testing
// Extremely high limits effectively disable rate limiting while keeping middleware active
const limiter = rateLimit({
    windowMs: 1 * 60 * 1000, // 1 minute window
    max: 10000, // 10,000 requests per minute (effectively unlimited)
    message: 'Too many requests from this IP, please try again later.',
    standardHeaders: true,
    legacyHeaders: false,
    skipSuccessfulRequests: false,
    skipFailedRequests: false
});

// Same unlimited config for API endpoints
const apiLimiter = rateLimit({
    windowMs: 1 * 60 * 1000, // 1 minute window
    max: 10000, // 10,000 requests per minute (effectively unlimited)
    message: 'Too many requests from this IP, please try again later.',
    standardHeaders: true,
    legacyHeaders: false
});

// Auth limiter - still lenient for testing
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 1000, // 1000 login attempts per 15 minutes (effectively unlimited)
    message: 'Too many login attempts, please try again later.',
    skipSuccessfulRequests: true // Don't count successful requests
});

// CORS configuration
const allowedOrigins = [
    'http://localhost:3000',
    'http://localhost:8080',
    'http://localhost:5000',
    'http://127.0.0.1:5000',
    'http://192.168.29.130:3000',
    'http://10.201.103.174:3000',
    'http://localhost:5173',
    'http://127.0.0.1:5173',
    'https://actv-project.onrender.com',
    'https://actv-project.onrender.com/'
];

app.use(cors({
    origin: function(origin, callback) {
        // Allow requests with no origin (like mobile apps or curl requests)
        if (!origin) return callback(null, true);

        if (allowedOrigins.indexOf(origin) !== -1) {
            callback(null, true);
        } else {
            callback(new Error('Not allowed by CORS'));
        }
    },
    credentials: true
}));

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Log ALL incoming requests for debugging
app.use((req, res, next) => {
    console.log('\n>>> INCOMING REQUEST <<<');
    console.log(`Method: ${req.method}`);
    console.log(`Path: ${req.url}`);
    console.log(`Time: ${new Date().toISOString()}`);
    console.log(`Headers:`, req.headers);
    next();
});

// ✅ Initialize Redis Cache (if available) - PRODUCTION READY
const redisCache = require('./utils/redis-cache');
redisCache.connect().then(connected => {
    if (connected) {
        console.log('✅ Redis cache initialized for production (shared across PM2 cluster)');
    } else {
        console.log('⚠️  Redis not available, using in-memory cache fallback');
    }
}).catch(err => {
    console.log('⚠️  Redis connection failed, using in-memory cache');
});

// ✅ GLOBAL MONGOOSE OPTIMIZATIONS - Applied to ALL queries automatically
mongoose.set('strictQuery', true); // Strict mode for better performance
mongoose.set('autoIndex', false); // Disable auto-indexing in production (indexes should be pre-built)

// ✅ OPTIMIZED: MongoDB connection with connection pooling and auto-reconnection
const connectDB = async(retryCount = 0) => {
    const maxRetries = 5;
    const retryDelay = 2000; // 2 seconds between retries (faster recovery)

    try {
        await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/membersdb', {
            maxPoolSize: 100, // Increased for high concurrency
            minPoolSize: 20, // Warmed pool for instant queries
            serverSelectionTimeoutMS: 10000, // Faster failure detection (10s)
            socketTimeoutMS: 30000, // Shorter socket timeout (30s)
            family: 4, // Use IPv4, skip trying IPv6
            maxIdleTimeMS: 60000, // Keep connections alive longer (60s)
            retryWrites: true, // Automatically retry write operations
            w: 1, // Faster writes (acknowledge from primary only)
            autoIndex: false, // Indexes already created manually
            connectTimeoutMS: 10000, // Faster initial connection (10s)
            heartbeatFrequencyMS: 5000, // Check server every 5 seconds
            compressors: ['zlib'], // Enable compression for faster data transfer
        });

        console.log('✅ Connected to MongoDB with ULTRA-OPTIMIZED connection pool');
        console.log(`   Max Pool Size: 100 | Min Pool Size: 20`);
        console.log(`   Connection timeout: 10s | Socket timeout: 30s`);
        console.log(`   Compression: ENABLED | Write Concern: w=1 (fast)`);
    } catch (error) {
        console.error(`❌ MongoDB connection error (attempt ${retryCount + 1}/${maxRetries}):`, error.message);

        if (retryCount < maxRetries) {
            console.log(`⏳ Retrying connection in ${retryDelay/1000} seconds...`);
            await new Promise(resolve => setTimeout(resolve, retryDelay));
            return connectDB(retryCount + 1);
        } else {
            console.error('❌ Failed to connect to MongoDB after maximum retries');
            console.error('💡 Check your internet connection and MongoDB Atlas access');
            process.exit(1);
        }
    }
};

// Connect to database
connectDB();

// ✅ Handle MongoDB connection events for better debugging
mongoose.connection.on('connected', () => {
    console.log('📡 MongoDB connection established');
});

mongoose.connection.on('disconnected', () => {
    console.warn('⚠️  MongoDB disconnected. Will attempt to reconnect...');
});

mongoose.connection.on('reconnected', () => {
    console.log('✅ MongoDB reconnected successfully');
});

mongoose.connection.on('error', (err) => {
    console.error('❌ MongoDB connection error:', err.message);
    // Attempt immediate reconnection on error
    if (mongoose.connection.readyState === 0) {
        console.log('🔄 Attempting immediate reconnection...');
        connectDB();
    }
});

mongoose.connection.on('disconnected', () => {
    console.log('⚠️  MongoDB connection lost - attempting to reconnect...');
});

mongoose.connection.on('reconnected', () => {
    console.log('✅ MongoDB reconnected successfully');
});

// ============================================================================
// HEALTH CHECK ENDPOINT (Production Monitoring)
// ============================================================================
app.get('/health', (req, res) => {
    const dbState = mongoose.connection.readyState;
    const dbStateMap = {
        0: 'disconnected',
        1: 'connected',
        2: 'connecting',
        3: 'disconnecting'
    };

    const isHealthy = dbState === 1;
    const healthcheck = {
        status: isHealthy ? 'ok' : 'degraded',
        timestamp: new Date().toISOString(),
        uptime: process.uptime(),
        environment: process.env.NODE_ENV || 'development',
        mongodb: {
            state: dbStateMap[dbState] || 'unknown',
            stateCode: dbState,
            connected: isHealthy
        },
        memory: {
            usedMB: Math.round(process.memoryUsage().heapUsed / 1024 / 1024),
            totalMB: Math.round(process.memoryUsage().heapTotal / 1024 / 1024),
            percentUsed: Math.round((process.memoryUsage().heapUsed / process.memoryUsage().heapTotal) * 100)
        }
    };

    // Return 503 if database is not connected
    res.status(isHealthy ? 200 : 503).json(healthcheck);
});

// Detailed health check with DB test
app.get('/health/detailed', async(req, res) => {
    try {
        const startTime = Date.now();

        // Test database connectivity with timeout
        let dbPing = null;
        let pingTime = null;

        if (mongoose.connection.readyState === 1) {
            try {
                dbPing = await Promise.race([
                    mongoose.connection.db.admin().ping(),
                    new Promise((_, reject) =>
                        setTimeout(() => reject(new Error('Ping timeout')), 5000)
                    )
                ]);
                pingTime = Date.now() - startTime;
            } catch (pingError) {
                dbPing = { ok: 0, error: pingError.message };
                pingTime = Date.now() - startTime;
            }
        }

        const dbState = mongoose.connection.readyState;
        const isHealthy = dbState === 1 && dbPing && dbPing.ok === 1;

        res.status(isHealthy ? 200 : 503).json({
            status: isHealthy ? 'ok' : 'degraded',
            timestamp: new Date().toISOString(),
            uptime: process.uptime(),
            environment: process.env.NODE_ENV || 'development',
            mongodb: {
                connected: dbState === 1,
                readyState: dbState,
                ping: dbPing ? (dbPing.ok === 1 ? 'success' : 'failed') : 'not_tested',
                pingTimeMs: pingTime,
                host: mongoose.connection.host || 'unknown'
            },
            memory: process.memoryUsage(),
            cpu: process.cpuUsage()
        });
    } catch (error) {
        res.status(503).json({
            status: 'error',
            message: 'Health check failed',
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

// Routes with optimizations
// Auth routes with stricter rate limiting
app.use('/api/auth', authLimiter, authRoutes);

// Lenient rate limiting for frequently accessed mobile app endpoints
app.use('/api/profile', apiLimiter, profileRoutes);
app.use('/api/dashboard', apiLimiter, hybridCacheMiddleware(60), dashboardRoutes); // Redis/Memory cache 1 min
app.use('/api/companies', apiLimiter, hybridCacheMiddleware(180), companiesRoutes); // Redis/Memory cache 3 min
app.use('/api/products', apiLimiter, hybridCacheMiddleware(180), productsRoutes); // Redis/Memory cache 3 min
app.use('/api/analytics', apiLimiter, hybridCacheMiddleware(300), analyticsRoutes); // Redis/Memory cache 5 min
app.use('/api/business', apiLimiter, businessRoutes);
app.use('/api/business', apiLimiter, businessSettingsRoutes);

// General rate limiting for other routes
app.use('/api/members', limiter, memberRoutes);
app.use('/api/members', limiter, memberDetailsRoutes);
app.use('/api/admin', authLimiter, adminAuthRouteFactory(mongoose.connection));
app.use('/api/applications', limiter, applicationsRouteFactory(mongoose.connection));
app.use('/api/webhook', webhookRoutes); // No rate limit for webhooks
app.use('/api/browse-members', limiter, hybridCacheMiddleware(60), browseMembersRoutes); // Redis/Memory cache 1 min
app.use('/api/notifications', limiter, notificationsRoutes);
app.use('/api/discover', limiter, hybridCacheMiddleware(180), discoverRoutes); // Redis/Memory cache 3 min

// Health check endpoint
app.get('/api/health', (req, res) => {
    res.status(200).json({
        status: 'success',
        message: 'ACTIV Backend API is running',
        timestamp: new Date().toISOString()
    });
});

// Error handling middleware
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({
        status: 'error',
        message: 'Something went wrong!',
        error: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
    });
});

// 404 handler
app.use('*', (req, res) => {
    res.status(404).json({
        status: 'error',
        message: 'Route not found'
    });
});

// Start server with error handling
const server = app.listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});

// Handle port already in use error
server.on('error', (err) => {
    if (err.code === 'EADDRINUSE') {
        console.error(`❌ Port ${PORT} is already in use!`);
        console.error('💡 Solutions:');
        console.error('   1. Kill the process using this port:');
        console.error(`      netstat -ano | findstr :${PORT}`);
        console.error('      taskkill /PID <PID> /F');
        console.error('   2. Or use a different port by setting PORT environment variable');
        console.error('   3. Or use npm run dev (which uses nodemon)');
        process.exit(1);
    } else {
        console.error('❌ Server error:', err);
        process.exit(1);
    }
});

module.exports = app;