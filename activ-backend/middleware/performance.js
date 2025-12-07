/**
 * Performance monitoring middleware
 */
const performanceMiddleware = (req, res, next) => {
    const start = Date.now();

    // Log when response finishes
    res.on('finish', () => {
        const duration = Date.now() - start;
        const size = res.get('Content-Length') || 0;

        console.log(`⚡ [${req.method}] ${req.originalUrl}`);
        console.log(`   Duration: ${duration}ms | Size: ${size} bytes | Status: ${res.statusCode}`);

        // Warn if response is slow
        if (duration > 1000) {
            console.warn(`⚠️  SLOW REQUEST: ${duration}ms for ${req.originalUrl}`);
        }
    });

    next();
};

module.exports = performanceMiddleware;