const compression = require('compression');

/**
 * Compression middleware with custom configuration
 */
const compressionMiddleware = compression({
    // Only compress responses larger than 1KB
    threshold: 1024,

    // Compression level (0-9, 6 is default balance)
    level: 6,

    // Filter function to determine what to compress
    filter: (req, res) => {
        // Don't compress if client doesn't support it
        if (req.headers['x-no-compression']) {
            return false;
        }

        // Use compression filter
        return compression.filter(req, res);
    }
});

module.exports = compressionMiddleware;