# ACTIV Backend Architecture

## Overview
ACTIV Backend is a Node.js/Express REST API for managing chamber of commerce member applications, profiles, and admin workflows. Built with MongoDB, Redis caching, and optimized for high performance.

---

## Tech Stack

### Core Technologies
- **Runtime**: Node.js
- **Framework**: Express.js v4.18.2
- **Database**: MongoDB (Mongoose v8.0.3)
- **Cache**: Redis v5.10.0, Node-Cache v5.1.2
- **Authentication**: JWT (jsonwebtoken v9.0.2), bcryptjs v2.4.3

### Security & Performance
- **Security**: Helmet v7.1.0, express-rate-limit v7.1.5
- **Optimization**: Compression v1.8.1, Redis caching, Query optimization
- **Validation**: express-validator v7.3.1, validator v13.15.23

### Development Tools
- **Process Manager**: PM2 v6.0.14
- **Dev Server**: nodemon v3.1.11
- **HTTP Client**: axios v1.13.2

---

## Project Structure

```
activ-backend/
├── server.js                      # Main entry point
├── package.json                   # Dependencies & scripts
├── config.env                     # Development environment variables
├── production.env                 # Production environment variables
├── pm2.config.js                  # PM2 process configuration
│
├── models/                        # Mongoose schemas
│   ├── Activity.js               # Activity/event model
│   ├── adminModels.js            # District/Block/State admin models
│   ├── applicationModel.js       # Membership application model
│   ├── Connection.js             # Member connection requests
│   ├── MemberAuth.js             # Member authentication
│   ├── MemberBusinessInfo.js     # Business information
│   ├── MemberDeclaration.js      # Declaration data
│   ├── MemberDetails.js          # Core member profile
│   ├── MemberFinancialInfo.js    # Financial compliance data
│   ├── Notification.js           # Push notifications
│   └── Product.js                # Products/services catalog
│
├── routes/                        # API endpoints
│   ├── adminAuth.js              # Admin authentication & management
│   ├── analytics.js              # Analytics & reporting
│   ├── applications.js           # Application approval workflow
│   ├── auth.js                   # Member authentication
│   ├── browseMembers.js          # Member directory browsing
│   ├── business.js               # Business profile management
│   ├── businessSettings.js       # Business settings & preferences
│   ├── companies.js              # Company/organization management
│   ├── dashboard.js              # Dashboard stats & metrics
│   ├── discover.js               # Member discovery & search
│   ├── memberDetails.js          # Detailed member profiles
│   ├── members.js                # Member CRUD operations
│   ├── notifications.js          # Notification management
│   ├── products.js               # Product catalog management
│   ├── profile.js                # Member profile operations
│   └── webhook.js                # Webhook integrations
│
├── middleware/                    # Custom middleware
│   ├── cache.js                  # Node-cache middleware
│   ├── compression.js            # Response compression
│   ├── hybrid-cache.js           # Redis + Node-cache hybrid
│   ├── performance.js            # Performance monitoring
│   └── validation.js             # Request validation helpers
│
├── utils/                         # Utility functions
│   ├── queryOptimizer.js         # MongoDB query optimization
│   └── redis-cache.js            # Redis cache utilities
│
├── scripts/                       # Utility scripts
│   └── (various admin & maintenance scripts)
│
├── test/                          # Testing utilities
│   └── (load testing & API tests)
│
└── logs/                          # Application logs (PM2)
```

---

## Core Features

### 1. Authentication & Authorization
- **Member Auth**: JWT-based authentication for members
- **Admin Auth**: Multi-level admin authentication (District, Block, State)
- **Role-Based Access**: Different permissions for members and admin levels
- **Password Security**: bcrypt hashing with salt rounds

### 2. Application Workflow
- **Multi-Level Approval**: Block Admin → District Admin → State Admin
- **Status Tracking**: Pending, Approved, Rejected with timestamps
- **Rich Form Data**: Demographics, business info, financial details, declarations
- **Admin Actions**: Approve/reject with reasons and audit trail

### 3. Member Management
- **Profile System**: Complete member profiles with business & financial data
- **Member Directory**: Searchable, filterable member listing
- **Member Discovery**: AI-powered recommendations and connections
- **Business Profiles**: Company information, products, services

### 4. Admin Dashboard
- **Real-Time Stats**: Pending, approved, rejected counts
- **Application Lists**: Filtered views by status and admin level
- **Performance Metrics**: Response times, cache hit rates
- **Analytics**: Member growth, approval rates, trends

### 5. Business Features
- **Company Management**: Multiple companies per member
- **Product Catalog**: Products/services with categories
- **Business Settings**: Preferences and configurations
- **Browse Members**: Public directory with filtering

### 6. Notifications
- **Push Notifications**: Real-time updates for status changes
- **Webhook Integration**: External system integrations
- **Event Tracking**: Application events and status changes

---

## API Architecture

### REST API Design
- **Base URL**: `http://localhost:3000/api`
- **Authentication**: Bearer token in Authorization header
- **Content Type**: JSON (application/json)
- **Rate Limiting**: 100 requests per 15 minutes per IP

### Key Endpoints

#### Authentication
```
POST   /api/auth/login              # Member login
POST   /api/auth/register           # Member registration
POST   /api/admin/login             # Admin login
GET    /api/auth/verify             # Verify JWT token
```

#### Applications
```
GET    /api/applications/:id                     # Get application by ID
POST   /api/applications/submit                  # Submit new application
PATCH  /api/applications/:id/review              # Admin review (approve/reject)
GET    /api/applications/block/:adminId          # Block admin applications
GET    /api/applications/district/:adminId       # District admin applications
GET    /api/applications/state/:adminId          # State admin applications
GET    /api/applications/stats/block/:adminId    # Block admin stats
GET    /api/applications/stats/district/:adminId # District admin stats
GET    /api/applications/stats/state/:adminId    # State admin stats
```

#### Members
```
GET    /api/members                 # List all members
GET    /api/members/:id             # Get member details
PUT    /api/members/:id             # Update member
DELETE /api/members/:id             # Delete member
GET    /api/members/search          # Search members
GET    /api/browse-members          # Public member directory
```

#### Profile
```
GET    /api/profile/:memberId       # Get member profile
PUT    /api/profile/:memberId       # Update profile
GET    /api/member-details/:id      # Detailed member info
```

#### Dashboard
```
GET    /api/dashboard/stats         # Dashboard statistics
GET    /api/analytics/reports       # Analytics reports
```

#### Business
```
GET    /api/companies               # List companies
POST   /api/companies               # Create company
PUT    /api/companies/:id           # Update company
GET    /api/products                # List products
POST   /api/products                # Create product
```

---

## Data Models

### Application Model
```javascript
{
  fullName: String,
  email: String,
  phone: String,
  state: String,
  district: String,
  block: String,
  status: String,  // 'pending', 'approved', 'rejected'
  formData: {
    personalDetails: Object,
    businessInfo: Object,
    financialInfo: Object,
    declaration: Object
  },
  submittedAt: Date,
  blockApprovedAt: Date,
  districtApprovedAt: Date,
  stateApprovedAt: Date,
  rejectedBy: String,
  rejectionReason: String
}
```

### Member Model
```javascript
{
  memberId: String,        // Unique member ID
  fullName: String,
  email: String,
  phoneNumber: String,
  password: String,        // Hashed
  memberType: String,      // 'regular', 'premium', etc.
  status: String,          // 'active', 'inactive'
  businessInfo: ObjectId,
  financialInfo: ObjectId,
  declaration: ObjectId,
  createdAt: Date,
  updatedAt: Date
}
```

### Admin Models
```javascript
DistrictAdmin {
  adminId: String,         // DA0001
  email: String,
  password: String,        // Hashed
  name: String,
  district: String,
  isActive: Boolean
}

BlockAdmin {
  adminId: String,         // BA0001
  email: String,
  password: String,
  name: String,
  district: String,
  block: String,
  isActive: Boolean
}

StateAdmin {
  adminId: String,         // SA0001
  email: String,
  password: String,
  name: String,
  state: String,
  isActive: Boolean
}
```

---

## Performance Optimization

### 1. Caching Strategy
- **Redis Cache**: Primary cache for frequent queries
- **Node-Cache**: In-memory fallback for Redis failures
- **Hybrid Caching**: Automatic failover between Redis and Node-Cache
- **Cache TTL**: 5-60 minutes based on data type
- **Cache Keys**: Structured by entity type and ID

### 2. Database Optimization
- **Indexes**: Created on frequently queried fields
  - `status`, `district`, `block`, `email`
  - Compound indexes: `(status, district)`, `(status, block)`
- **Lean Queries**: `.lean()` for read-only operations
- **Projection**: Select only required fields
- **Aggregation**: Efficient stats calculation

### 3. Middleware
- **Compression**: Gzip response compression
- **Rate Limiting**: Prevents API abuse
- **CORS**: Configured for Flutter app origin
- **Helmet**: Security headers
- **Performance Monitoring**: Request timing logs

### 4. Query Patterns
```javascript
// Optimized query example
const applications = await Application.find({
  status: 'pending',
  district: adminDistrict
})
.select('fullName email phone status submittedAt')
.sort({ submittedAt: -1 })
.limit(50)
.lean();
```

---

## Security Features

### 1. Authentication
- JWT tokens with 7-day expiration
- Bcrypt password hashing (10 salt rounds)
- Token verification on protected routes
- Role-based access control

### 2. API Security
- Helmet.js security headers
- CORS whitelisting
- Rate limiting (100 req/15min)
- Input validation with express-validator
- SQL injection prevention (NoSQL)
- XSS protection

### 3. Environment Variables
```env
PORT=3000
MONGODB_URI=mongodb://...
JWT_SECRET=...
REDIS_URL=redis://...
NODE_ENV=production
```

---

## Deployment & Operations

### PM2 Configuration
```javascript
{
  name: 'activ-backend',
  script: 'server.js',
  instances: 2,
  exec_mode: 'cluster',
  max_memory_restart: '500M',
  error_file: './logs/pm2-error.log',
  out_file: './logs/pm2-out.log',
  time: true
}
```

### NPM Scripts
```bash
npm start          # Start production server
npm run dev        # Start with nodemon (development)
npm run optimize   # Run optimization scripts
npm run load-test  # Run load testing
npm run setup      # Setup optimization
```

### Monitoring
- **Performance**: Request timing logged per endpoint
- **Cache Metrics**: Hit/miss rates tracked
- **Error Logging**: PM2 logs in `./logs/`
- **Health Check**: `/api/health` endpoint

---

## Error Handling

### Standard Error Response
```javascript
{
  success: false,
  message: "Error description",
  error: "Detailed error (dev only)"
}
```

### HTTP Status Codes
- `200 OK`: Successful request
- `201 Created`: Resource created
- `400 Bad Request`: Invalid input
- `401 Unauthorized`: Invalid/missing token
- `403 Forbidden`: Insufficient permissions
- `404 Not Found`: Resource not found
- `429 Too Many Requests`: Rate limit exceeded
- `500 Internal Server Error`: Server error

---

## Development Workflow

### Local Development
1. Install dependencies: `npm install`
2. Configure `config.env` with MongoDB URI, JWT secret
3. Start MongoDB locally or use cloud instance
4. Start Redis (optional, falls back to Node-Cache)
5. Run: `npm run dev`
6. Test: Access `http://localhost:3000/api`

### Testing
- Use `test-api.js` for endpoint testing
- Use `run-load-test.bat` for performance testing
- Check `test/` directory for more test utilities

### Database Setup
- Run `create-admin.js` to create initial admins
- Run `check-*.js` scripts to verify data
- Use `diagnose-data.js` for debugging

---

## Integration with Flutter App

### API Configuration
```dart
class ApiService {
  static const String baseUrl = 'http://10.42.208.174:3000/api';
  
  static Future<Map<String, dynamic>> login(email, password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      body: json.encode({'email': email, 'password': password}),
      headers: {'Content-Type': 'application/json'}
    );
    return json.decode(response.body);
  }
}
```

### State Management
- JWT token stored in SharedPreferences
- Token passed in Authorization header: `Bearer <token>`
- Automatic token refresh on expiration
- Logout clears stored token

---

## Future Enhancements

### Planned Features
1. **Real-time Updates**: WebSocket for live notifications
2. **File Uploads**: Document/image upload for applications
3. **Email Service**: Automated email notifications
4. **SMS Service**: OTP verification
5. **Analytics Dashboard**: Advanced reporting
6. **Export Features**: PDF/Excel export of data
7. **Audit Logs**: Complete action history
8. **GraphQL API**: Alternative to REST

### Performance Improvements
1. **Database Sharding**: Horizontal scaling
2. **CDN Integration**: Static asset delivery
3. **Load Balancing**: Multi-instance deployment
4. **Advanced Caching**: Redis Cluster
5. **Queue System**: Background job processing

---

## Troubleshooting

### Common Issues

**MongoDB Connection Failed**
- Check `MONGODB_URI` in `.env` file
- Verify network connectivity
- Check MongoDB Atlas whitelist

**Redis Connection Failed**
- Falls back to Node-Cache automatically
- Check `REDIS_URL` configuration
- Verify Redis server is running

**Authentication Errors**
- Verify JWT secret matches across restarts
- Check token expiration
- Ensure proper Authorization header format

**Performance Issues**
- Check cache hit rates
- Review MongoDB indexes
- Monitor PM2 logs for errors
- Use load testing to identify bottlenecks

---

## Support & Documentation

### Additional Resources
- `README.md`: Quick start guide
- `ADMIN_SETUP_GUIDE.md`: Admin creation guide
- `WEBHOOK_COMPLETE.md`: Webhook integration
- `OPTIMIZATION_GUIDE.md`: Performance optimization
- `SERVER_MANAGEMENT.md`: Deployment guide
- `PM2_COMMANDS.md`: PM2 usage guide

### Contact
For issues or questions, refer to the project repository or documentation files.

---

**Last Updated**: December 2025  
**Version**: 1.0.0  
**Status**: Production Ready ✅
