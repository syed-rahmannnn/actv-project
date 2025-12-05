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

const app = express();
const PORT = process.env.PORT || 3000;

// Trust proxy setting for deployment platforms like Render, Heroku, etc.
app.set('trust proxy', 1); // trust first proxy

// Security middleware
app.use(helmet());

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: 'Too many requests from this IP, please try again later.'
});
app.use(limiter);

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
  origin: function (origin, callback) {
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

// MongoDB connection
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/membersdb')
.then(() => {
  console.log('Connected to MongoDB');
})
.catch((error) => {
  console.error('MongoDB connection error:', error);
  process.exit(1);
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/members', memberRoutes);
app.use('/api/members', memberDetailsRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/admin', adminAuthRouteFactory(mongoose.connection));
app.use('/api/applications', applicationsRouteFactory(mongoose.connection));
app.use('/api/webhook', webhookRoutes); // Webhook route for payment notifications
app.use('/api/browse-members', browseMembersRoutes); // Browse members and connections
app.use('/api/notifications', notificationsRoutes); // Notifications
app.use('/api/business', businessRoutes); // Business profile routes
app.use('/api/companies', companiesRoutes); // Companies management
app.use('/api/products', productsRoutes); // Products management
app.use('/api/discover', discoverRoutes); // Discover search for companies and products
app.use('/api/analytics', analyticsRoutes); // Analytics overview
app.use('/api/business', businessSettingsRoutes); // Business settings (mounted under /api/business for settings endpoints)
app.use('/api/dashboard', dashboardRoutes); // Dashboard stats and activities

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
