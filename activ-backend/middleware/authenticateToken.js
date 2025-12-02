const jwt = require('jsonwebtoken');

const authenticateToken = (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access token is required'
      });
    }

    const JWT_SECRET = process.env.JWT_SECRET || process.env.JWTSECRET || 'your-secret-key-here';
    jwt.verify(token, JWT_SECRET, (err, decoded) => {
      if (err) {
        console.error('Token verification error:', err.message);
        return res.status(403).json({
          success: false,
          message: 'Invalid or expired token'
        });
      }

      // Attach user info to request
      req.user = {
        userId: decoded.userId,
        email: decoded.email,
        fullName: decoded.fullName
      };

      console.log('✅ Authenticated user:', req.user.email);
      next();
    });
  } catch (error) {
    console.error('Authentication middleware error:', error);
    res.status(500).json({
      success: false,
      message: 'Authentication failed'
    });
  }
};

module.exports = authenticateToken;
