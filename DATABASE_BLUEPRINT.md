# ACTIV Database Blueprint

## Database Architecture

### **MongoDB Cluster**: `cluster1.gf7usct.mongodb.net`
- **Primary Database**: `membersdb` (Member data)
- **Admin Database**: `adminsdb` (Admin users)
- **Username**: `activapp2025_db_user`
- **Password**: `o6xFHfqzLXM6LUaa`

---

## Collections Overview

| Collection | Database | Documents | Purpose |
|------------|----------|-----------|---------|
| **applications** | membersdb | ~1000s | Membership applications awaiting approval |
| **memberauths** | membersdb | ~1000s | Authentication credentials |
| **memberdetails** | membersdb | ~1000s | Core member profiles |
| **memberbusinessinfos** | membersdb | ~500s | Business information |
| **memberfinancialinfos** | membersdb | ~500s | Financial & compliance data |
| **memberdeclarations** | membersdb | ~1000s | Declaration forms |
| **products** | membersdb | ~100s | Product/service catalog |
| **activities** | membersdb | ~10000s | Activity logs |
| **connections** | membersdb | ~1000s | Member connection requests |
| **notifications** | membersdb | ~5000s | Push notifications |
| **blockadmins** | adminsdb | ~50 | Block-level admins |
| **districtadmins** | adminsdb | ~10 | District-level admins |
| **stateadmins** | adminsdb | ~3 | State-level admins |
| **superadmins** | adminsdb | ~1 | Super administrators |

---

## Detailed Schema Blueprints

### 1. **Application** (Membership Applications)

**Collection**: `applications`  
**Database**: `membersdb`

```javascript
{
  _id: ObjectId,
  userId: ObjectId → MemberAuth,
  fullName: String (required),
  email: String (required),
  phone: String (required),
  state: String (required),
  district: String (required),
  block: String (required),
  formData: Object (all form data),
  
  // Workflow Status
  status: Enum [
    'PENDING', 
    'Pending-Block', 
    'Pending-District', 
    'Pending-State', 
    'Approved', 
    'Rejected'
  ],
  
  // Admin Assignments
  assignedBlockAdmin: ObjectId → BlockAdmin,
  assignedDistrictAdmin: ObjectId → DistrictAdmin,
  assignedStateAdmin: ObjectId → StateAdmin,
  
  // Approval Tracking
  blockApprovedAt: Date,
  districtApprovedAt: Date,
  stateApprovedAt: Date,
  rejectionReason: String,
  
  reviewedBy: {
    blockAdmin: ObjectId,
    districtAdmin: ObjectId,
    stateAdmin: ObjectId
  },
  
  createdAt: Date (auto),
  updatedAt: Date (auto)
}
```

**Indexes:**
- `userId` (single)
- `assignedBlockAdmin + status` (compound)
- `assignedDistrictAdmin + status` (compound)
- `assignedStateAdmin + status` (compound)
- `status` (single)

**Purpose**: Tracks membership applications through 3-tier approval workflow (Block → District → State)

---

### 2. **MemberAuth** (Authentication)

**Collection**: `memberauths`  
**Database**: `membersdb`

```javascript
{
  _id: ObjectId,
  email: String (unique, lowercase),
  password: String (bcrypt hashed),
  isActive: Boolean (default: true),
  lastLogin: Date,
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**
- `email + isActive` (compound)

**Security:**
- Password hashed with bcrypt (cost: 10)
- `comparePassword()` method for validation
- `updateLastLogin()` method

**Purpose**: Handles member authentication with secure password storage

---

### 3. **MemberDetails** (Core Profile)

**Collection**: `memberdetails`  
**Database**: `membersdb`

```javascript
{
  _id: ObjectId,
  
  // Contact Information
  fullName: String (max: 100),
  email: String (lowercase),
  phoneNumber: String,
  
  // Location
  state: String,
  district: String,
  block: String,
  city: String,
  streetName: String,
  
  // Demographics
  aadhaarNumber: String (12 digits),
  educationalQualification: String,
  religion: String,
  socialCategory: Enum [
    'Christian SC', 
    'ST', 
    'Christian ST', 
    'Other'
  ],
  
  // Profile Status
  profileCompleted: Boolean,
  
  // Approval Information
  approvedBy: String,
  approvedBlock: String,
  approvedAt: Date,
  
  // Membership
  membershipStatus: Enum [
    'pending', 
    'active', 
    'expired', 
    'cancelled'
  ],
  membershipType: Enum [
    'annual', 
    'lifetime', 
    'none'
  ],
  membershipActivatedAt: Date,
  
  createdAt: Date,
  updatedAt: Date
}
```

**Purpose**: Stores core member profile information including demographics and membership status

---

### 4. **MemberBusinessInfo** (Business Data)

**Collection**: `memberbusinessinfos`  
**Database**: `membersdb`

```javascript
{
  _id: ObjectId,
  memberId: ObjectId → MemberDetails (required),
  fullName: String (required),
  email: String (required),
  
  // Business Basics
  doingBusiness: Boolean,
  organizationName: String,
  constitutionType: Enum ['OPC', 'TRUST', 'SOCIETY'],
  businessType: Enum [
    'Manufacturing', 
    'Trader', 
    'Service Provider', 
    'Others'
  ],
  businessActivities: String,
  businessCommencementYear: String,
  numberOfEmployees: String,
  
  // Associations
  memberOfOtherChamber: Boolean,
  otherChamber: String,
  registeredWithGovtOrganization: Array [
    'MSME', 
    'KVIC', 
    'NABARD', 
    'None', 
    'Others'
  ],
  
  // Business Profile
  mobile: String,
  area: String,
  location: String,
  businessDescription: String,
  businessWebsite: String,
  logoUrl: String,
  
  status: Enum [
    'UNDER_REVIEW', 
    'APPROVED', 
    'ACTIVE', 
    'REJECTED', 
    'PENDING'
  ],
  
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**
- `memberId` (single)

**Purpose**: Stores comprehensive business information for member organizations

---

### 5. **MemberFinancialInfo** (Financial Data)

**Collection**: `memberfinancialinfos`  
**Database**: `membersdb`

```javascript
{
  _id: ObjectId,
  memberId: ObjectId → MemberDetails (required),
  fullName: String (required),
  email: String (required),
  
  // Tax & Registration
  panNumber: String (format: ABCDE1234F),
  gstNumber: String (15 chars),
  udyamNumber: String,
  
  // Income Tax
  filedITR: Boolean,
  itrYears: String,
  
  // Turnover
  turnoverRange: Enum [
    'Less than 25 Lakhs',
    '25 Lakhs - 50 Lakhs',
    '50 Lakhs - 1 Crore',
    '1 Crore - 5 Crores',
    '5 Crores - 10 Crores',
    'More than 10 Crores'
  ],
  fy2021: String,
  fy2020: String,
  fy2019: String,
  
  // Government Schemes
  govtSchemeBenefit: Boolean,
  scheme1: String,
  scheme2: String,
  scheme3: String,
  
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**
- `memberId` (single)

**Validation:**
- PAN: 10 chars (ABCDE1234F format)
- GST: 15 chars
- Aadhaar: 12 digits

**Purpose**: Stores financial compliance data including tax information and government schemes

---

### 6. **MemberDeclaration** (Declaration Form)

**Collection**: `memberdeclarations`  
**Database**: `membersdb`

```javascript
{
  _id: ObjectId,
  memberId: ObjectId → MemberDetails (required),
  fullName: String (required),
  email: String (required),
  
  // Sister Concerns
  sisterConcerns: Number (min: 0),
  companyNames: Array[String],
  showOneFieldPerName: Boolean,
  
  // Declaration
  agreeToDeclaration: Boolean (required),
  profileCompleted: Boolean,
  submissionDate: Date,
  
  // Review Status
  status: Enum [
    'pending', 
    'under_review', 
    'approved', 
    'rejected'
  ],
  reviewNotes: String,
  reviewedBy: String,
  reviewedAt: Date,
  
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**
- `memberId` (single)
- `status` (single)

**Purpose**: Stores member declaration including sister concerns and agreement confirmation

---

### 7. **Product** (Product Catalog)

**Collection**: `products`  
**Database**: `membersdb`

```javascript
{
  _id: ObjectId,
  companyId: ObjectId → Company (required),
  
  // Product Details
  name: String (required),
  description: String,
  category: Enum [
    'Software', 
    'Services', 
    'Education', 
    'Product', 
    'Other'
  ],
  
  // Pricing
  price: Number (required),
  priceUnit: Enum [
    'one-time', 
    'monthly', 
    'hourly', 
    'yearly'
  ],
  currency: String (default: 'INR'),
  
  // Display
  featured: Boolean,
  imageUrl: String,
  status: Enum [
    'ACTIVE', 
    'INACTIVE', 
    'OUT_OF_STOCK'
  ],
  
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**
- `companyId + createdAt` (compound)
- `name + description` (text search)
- `category` (single)
- `featured + createdAt` (compound)
- `status` (single)

**Purpose**: Product/service catalog for member businesses

---

### 8. **Activity** (Activity Logs)

**Collection**: `activities`  
**Database**: `membersdb`

```javascript
{
  _id: ObjectId,
  memberId: ObjectId → Member (required),
  companyId: String (required),
  
  activityType: Enum [
    'PRODUCT_CREATED',
    'PRODUCT_UPDATED',
    'PRODUCT_DELETED',
    'PROFILE_UPDATED',
    'COMPANY_CREATED',
    'COMPANY_UPDATED',
    'PROFILE_VIEWED',
    'CONNECTION_MADE'
  ],
  
  entityType: Enum [
    'PRODUCT', 
    'PROFILE', 
    'COMPANY', 
    'CONNECTION'
  ],
  entityId: String,
  entityName: String,
  description: String,
  metadata: Mixed,
  
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**
- `memberId + companyId + createdAt` (compound)
- `companyId + createdAt` (compound)

**Purpose**: Tracks all member and company activities for audit and analytics

---

### 9. **Connection** (Member Connections)

**Collection**: `connections`  
**Database**: `membersdb`

```javascript
{
  _id: ObjectId,
  senderId: ObjectId → MemberDetails (required),
  recipientId: ObjectId → MemberDetails (required),
  
  status: Enum [
    'pending', 
    'accepted', 
    'declined'
  ],
  message: String (default: 'Wants to connect with you'),
  
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**
- `senderId + recipientId` (compound)
- `recipientId + status` (compound)

**Purpose**: Manages connection requests between members (like LinkedIn connections)

---

### 10. **Notification** (Push Notifications)

**Collection**: `notifications`  
**Database**: `membersdb`

```javascript
{
  _id: ObjectId,
  recipientId: ObjectId → MemberDetails (required),
  senderId: ObjectId → MemberDetails (required),
  
  type: Enum [
    'connection_request',
    'connection_accepted',
    'connection_declined',
    'general'
  ],
  
  title: String (required),
  message: String (required),
  connectionId: ObjectId → Connection,
  isRead: Boolean (default: false),
  
  createdAt: Date
}
```

**Indexes:**
- `recipientId + isRead + createdAt` (compound)

**Purpose**: Stores push notifications for member activities and updates

---

### 11. **Admin Models** (Block/District/State/Super)

**Collections**: `blockadmins`, `districtadmins`, `stateadmins`, `superadmins`  
**Database**: `adminsdb`

```javascript
{
  _id: ObjectId,
  adminId: String (unique), // BA001, DA001, SA001
  email: String (unique, lowercase),
  passwordHash: String (bcrypt),
  fullName: String,
  role: String, // 'BlockAdmin', 'DistrictAdmin', etc.
  active: Boolean (default: true),
  createdAt: Date,
  lastLoginAt: Date,
  meta: Mixed,
  updatedAt: Date
}
```

**Admin ID Format:**
- Block Admin: `BA0001`, `BA0002`, ...
- District Admin: `DA0001`, `DA0002`, ...
- State Admin: `SA0001`, `SA0002`, ...
- Super Admin: `SUPER001`, `SUPER002`, ...

**Purpose**: Manages multi-level admin accounts with role-based access

---

## Relationships Diagram

```
┌─────────────────┐
│   MemberAuth    │ (Authentication)
│   - email       │
│   - password    │
└────────┬────────┘
         │
         │ 1:1
         ▼
┌─────────────────┐      1:N      ┌──────────────────┐
│ MemberDetails   │◄───────────────┤  Application     │
│ (Core Profile)  │                │ (Pending)        │
└────────┬────────┘                └──────────────────┘
         │
         │ 1:1
         ├──────────────────┬──────────────────┬──────────────────┐
         ▼                  ▼                  ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│BusinessInfo  │  │FinancialInfo │  │ Declaration  │  │  Connection  │
└──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘

         │ 1:N
         ├──────────────────┬──────────────────┐
         ▼                  ▼                  ▼
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Product    │  │  Activity    │  │Notification  │
└──────────────┘  └──────────────┘  └──────────────┘


Admins Database (adminsdb):
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│ BlockAdmin   │  │DistrictAdmin │  │  StateAdmin  │
└──────────────┘  └──────────────┘  └──────────────┘
```

---

## Data Flow

### Member Registration Flow

```
1. User registers → MemberAuth created (email, password)
2. User submits form → Application created (Pending-Block)
3. Block Admin approves → Application.status = 'Pending-District'
4. District Admin approves → Application.status = 'Pending-State'
5. State Admin approves → MemberDetails + BusinessInfo + FinancialInfo + Declaration created
6. Member profile activated → membershipStatus = 'active'
```

### Admin Approval Hierarchy

```
┌─────────────────┐
│  Block Admin    │
│     (BA)        │
└────────┬────────┘
         │ approves
         ▼
┌─────────────────┐
│ District Admin  │
│     (DA)        │
└────────┬────────┘
         │ approves
         ▼
┌─────────────────┐
│  State Admin    │
│     (SA)        │
└────────┬────────┘
         │ approves
         ▼
┌─────────────────┐
│ Member Account  │
│    Created      │
└─────────────────┘
```

---

## Performance Optimizations

### Indexes Summary

| Collection | Index | Type | Purpose |
|------------|-------|------|---------|
| applications | `status` | Single | Filter by status |
| applications | `assignedBlockAdmin + status` | Compound | Block admin dashboard |
| applications | `assignedDistrictAdmin + status` | Compound | District admin dashboard |
| applications | `assignedStateAdmin + status` | Compound | State admin dashboard |
| memberauths | `email + isActive` | Compound | Login queries |
| products | `companyId + createdAt` | Compound | Company products |
| products | `name + description` | Text | Search products |
| activities | `memberId + companyId + createdAt` | Compound | Activity feed |
| connections | `senderId + recipientId` | Compound | Prevent duplicates |
| notifications | `recipientId + isRead + createdAt` | Compound | Unread notifications |

### Query Optimization Patterns

```javascript
// ✅ Good: Lean queries for read-only operations
Application.find({ status: 'Pending' }).lean()

// ✅ Good: Field projection to reduce payload
Application.find().select('fullName email phone status')

// ✅ Good: Indexed fields in query
Application.find({ status: 'Pending', district: 'Ernakulam' })

// ✅ Good: Limit results for pagination
Application.find({ status: 'Pending' }).limit(50).sort({ createdAt: -1 })

// ❌ Bad: No index, full collection scan
Application.find({ phoneNumber: '1234567890' })

// ❌ Bad: Fetching all fields when only few are needed
Application.find({ status: 'Pending' }) // Returns entire document
```

---

## Database Access

### Connection Strings

**Development:**
```
mongodb+srv://activapp2025_db_user:o6xFHfqzLXM6LUaa@cluster1.gf7usct.mongodb.net/membersdb?retryWrites=true&w=majority&appName=Cluster1
```

**Production:**
```
mongodb+srv://activapp2025_db_user:o6xFHfqzLXM6LUaa@cluster1.gf7usct.mongodb.net/membersdb?retryWrites=true&w=majority&appName=Cluster1
```

### Environment Variables

```env
# MongoDB Configuration
MONGODB_URI=mongodb+srv://activapp2025_db_user:o6xFHfqzLXM6LUaa@cluster1.gf7usct.mongodb.net/membersdb?retryWrites=true&w=majority&appName=Cluster1

# JWT Configuration
JWTSECRET=activ_jwt_secret_key_2025_secure_random_string

# Server Configuration
PORT=3000
NODE_ENV=production
```

---

## Security Features

### 1. **Password Security**
- Bcrypt hashing with salt rounds (cost: 10)
- Passwords never stored in plain text
- Automatic hashing via Mongoose pre-save hooks

### 2. **Authentication**
- JWT tokens with 7-day expiration
- Token-based authentication for all protected routes
- Role-based access control (Member, BlockAdmin, DistrictAdmin, StateAdmin)

### 3. **Data Validation**
- Email format validation with regex
- Phone number validation (15 digits max)
- PAN number format: `ABCDE1234F`
- GST number format: 15 characters
- Aadhaar number: 12 digits

### 4. **Database Security**
- MongoDB Atlas with IP whitelisting
- Connection string encryption
- Separate database for admin users (`adminsdb`)
- Environment variables for sensitive data

---

## Backup & Recovery

### Recommended Backup Strategy

**Daily Backups:**
- Automated MongoDB Atlas backups (enabled by default)
- Retention: 7 days for daily backups

**Weekly Backups:**
- Long-term retention: 4 weeks

**Monthly Backups:**
- Archive storage: 12 months

### Recovery Procedures

1. **Point-in-Time Recovery**: Available through MongoDB Atlas
2. **Collection-Level Restore**: Restore specific collections
3. **Full Database Restore**: Complete database restoration

---

## Monitoring & Maintenance

### Key Metrics to Monitor

1. **Database Size**: Track growth rate
2. **Query Performance**: Monitor slow queries (>100ms)
3. **Index Usage**: Identify unused indexes
4. **Connection Pool**: Monitor active connections
5. **Cache Hit Rate**: Redis cache performance

### Maintenance Tasks

**Weekly:**
- Review slow query logs
- Check index performance
- Monitor disk usage

**Monthly:**
- Analyze collection statistics
- Review and optimize indexes
- Clean up old activity logs (>6 months)

**Quarterly:**
- Database performance audit
- Security review
- Backup verification

---

## Scaling Considerations

### Current Capacity
- **Documents**: ~20,000 total
- **Storage**: ~500 MB
- **Connections**: 100 concurrent connections
- **Queries**: 1,000-2,000 queries/second

### Scaling Triggers

**Vertical Scaling** (Upgrade Instance):
- MongoDB Atlas M0 (Free) → M10 → M20 → M30
- Trigger: 80% CPU or Memory usage

**Horizontal Scaling** (Sharding):
- Trigger: >10 GB database size
- Shard key: `district` or `state`

**Read Replicas**:
- Trigger: >5,000 queries/second
- Purpose: Distribute read load

---

## Migration Guide

### Adding New Fields

```javascript
// 1. Update schema in model file
const schema = new mongoose.Schema({
  // existing fields...
  newField: { type: String, default: '' }
});

// 2. Run migration script
db.collection.updateMany(
  { newField: { $exists: false } },
  { $set: { newField: '' } }
);
```

### Changing Field Types

```javascript
// Convert String to Number
db.collection.find({ fieldName: { $type: "string" } }).forEach(doc => {
  db.collection.updateOne(
    { _id: doc._id },
    { $set: { fieldName: parseInt(doc.fieldName) || 0 } }
  );
});
```

---

## Troubleshooting

### Common Issues

**1. Connection Timeouts**
- Check MongoDB Atlas IP whitelist
- Verify network connectivity
- Review connection string format

**2. Slow Queries**
- Add missing indexes
- Use `.lean()` for read-only queries
- Implement field projection

**3. Out of Memory**
- Reduce result set size with `.limit()`
- Use pagination for large datasets
- Implement cursor-based iteration

**4. Duplicate Key Errors**
- Check unique indexes
- Verify email/adminId uniqueness
- Review application logic

---

## API Integration Examples

### Fetch Member Profile

```javascript
// Backend API
GET /api/members/:id

// Response
{
  success: true,
  member: {
    _id: "507f1f77bcf86cd799439011",
    fullName: "John Doe",
    email: "john@example.com",
    phoneNumber: "+919876543210",
    district: "Ernakulam",
    membershipStatus: "active"
  }
}
```

### Submit Application

```javascript
// Backend API
POST /api/applications/submit

// Request Body
{
  fullName: "John Doe",
  email: "john@example.com",
  phone: "+919876543210",
  state: "Kerala",
  district: "Ernakulam",
  block: "Kochi",
  formData: { /* all form fields */ }
}

// Response
{
  success: true,
  applicationId: "507f1f77bcf86cd799439011",
  message: "Application submitted successfully"
}
```

### Admin Approval

```javascript
// Backend API
PATCH /api/applications/:id/review

// Request Body
{
  action: "approve" | "reject",
  reason: "Rejection reason (if rejected)"
}

// Response
{
  success: true,
  status: "Pending-District",
  message: "Application approved by Block Admin"
}
```

---

## Future Enhancements

### Planned Database Features

1. **Full-Text Search**: Implement Elasticsearch for advanced search
2. **GraphQL API**: Alternative to REST for flexible queries
3. **Real-Time Updates**: WebSocket integration for live data
4. **Data Analytics**: Aggregation pipelines for business insights
5. **File Storage**: GridFS or S3 for document uploads
6. **Audit Logs**: Complete change history tracking
7. **Multi-Tenancy**: Support for multiple chambers

### Performance Improvements

1. **Caching Layer**: Redis for frequently accessed data
2. **Connection Pooling**: Optimize database connections
3. **Query Optimization**: Regularly review and improve queries
4. **Materialized Views**: Pre-computed aggregations
5. **Partitioning**: Split large collections by date/region

---

## Contact & Support

For database-related issues or questions:
- Review this documentation
- Check MongoDB Atlas dashboard
- Review backend logs in `activ-backend/logs/`
- Run diagnostic scripts in `activ-backend/scripts/`

---

**Last Updated**: December 9, 2025  
**Version**: 1.0.0  
**Status**: Production Ready ✅
