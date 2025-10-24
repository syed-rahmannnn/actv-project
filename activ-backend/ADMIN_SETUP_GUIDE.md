# Admin System Setup Guide

This guide explains how to set up and use the admin system with four different admin roles: BlockAdmin, DistrictAdmin, StateAdmin, and SuperAdmin.

## Files Created

1. **`models/adminModels.js`** - Shared schema and models for all admin types
2. **`create-admin.js`** - CLI script to create admin accounts
3. **`routes/adminAuth.js`** - Example authentication routes
4. **`ADMIN_SETUP_GUIDE.md`** - This documentation file

## Setup Instructions

### 1. Install Dependencies

The required dependency `bcryptjs` is already installed in your project. If you need to install it manually:

```bash
npm install bcryptjs
```

### 2. Environment Configuration

Ensure your `.env` file contains the MongoDB connection string:

```env
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/your-main-db
JWT_SECRET=your-jwt-secret-key
```

### 3. Create Admin Accounts

Use the CLI script to create admin accounts:

```bash
# Create a Block Admin
node create-admin.js BlockAdmin BA001 blockadmin@example.com 'StrongP@ssw0rd!' 'Block Admin Name'

# Create a District Admin
node create-admin.js DistrictAdmin DA001 districtadmin@example.com 'StrongP@ssw0rd!' 'District Admin Name'

# Create a State Admin
node create-admin.js StateAdmin SA001 stateadmin@example.com 'StrongP@ssw0rd!' 'State Admin Name'

# Create a Super Admin
node create-admin.js SuperAdmin SU001 superadmin@example.com 'StrongP@ssw0rd!' 'Super Admin Name'
```

## Usage Examples

### 1. Using Admin Models in Routes

```javascript
// In your route files
const getAdminModels = require('../models/adminModels');
const { BlockAdmin, DistrictAdmin, StateAdmin, SuperAdmin } = getAdminModels();

// Example: Find all block admins
const blockAdmins = await BlockAdmin.find({ active: true });

// Example: Find specific admin by adminId
const admin = await SuperAdmin.findOne({ adminId: 'SU001' });
```

### 2. Integrating Admin Routes

Add the admin authentication routes to your main server file using the factory pattern:

```javascript
// In server.js
const express = require('express');
const mongoose = require('mongoose');
const adminAuthRouteFactory = require('./routes/adminAuth');

mongoose.connect(process.env.MONGO_URI, {...})
  .then(() => {
    const app = express();
    app.use(express.json());
    // mount admin auth route (pass connection)
    app.use('/api/admin', adminAuthRouteFactory(mongoose.connection));
    // other routes...
    app.listen(process.env.PORT || 4000);
  });
```

### 3. Admin Login API

**POST** `/api/admin/login`

Request body:
```json
{
  "email": "blockadmin@example.com",
  "password": "StrongP@ssw0rd!",
  "role": "BlockAdmin"
}
```

Response:
```json
{
  "token": "jwt-token-here",
  "fullName": "Block Admin Name",
  "role": "BlockAdmin",
  "adminId": "BA001"
}
```

## Additional Notes

- **JWT Configuration**: The JWT token expires in 2 days by default. You can adjust this by modifying the `JWT_EXPIRES` constant in the route file.
- **Production Security**: For production, ensure you use a strong `JWT_SECRET` stored in environment variables or a secret manager.
- **Connection Flexibility**: The route factory pattern allows you to pass different mongoose connections, making it easier to test or use multiple databases.

## Database Structure

The admin system uses a separate database called `adminsdb` with the following collections:

- `blockadmins` - Block-level administrators
- `districtadmins` - District-level administrators  
- `stateadmins` - State-level administrators
- `superadmins` - Super administrators

Each collection uses the same schema with these fields:

- `adminId` - Unique identifier (e.g., BA001, DA001)
- `email` - Admin email address (unique)
- `passwordHash` - Bcrypt hashed password
- `fullName` - Admin's full name
- `role` - Admin role type
- `active` - Whether the admin account is active
- `createdAt` - Account creation timestamp
- `lastLoginAt` - Last login timestamp
- `meta` - Additional metadata (flexible object)

## Security Features

- Passwords are hashed using bcrypt with salt rounds of 12
- JWT tokens for authentication with 24-hour expiration
- Email uniqueness enforced across each admin collection
- AdminId uniqueness enforced across each admin collection
- Active status check for login attempts

## CLI Script Options

The `create-admin.js` script accepts the following parameters:

1. **role** (required) - One of: BlockAdmin, DistrictAdmin, StateAdmin, SuperAdmin
2. **adminId** (required) - Unique identifier for the admin
3. **email** (required) - Admin's email address
4. **password** (required) - Plain text password (will be hashed)
5. **fullName** (optional) - Admin's full name (defaults to role name)

## Error Handling

The system includes comprehensive error handling for:

- Duplicate email addresses
- Duplicate admin IDs
- Invalid roles
- Missing environment variables
- Database connection issues
- Authentication failures