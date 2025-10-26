# Admin ID Usage Guide

This document outlines the proper usage patterns for admin identification across the ACTIV application backend and frontend.

## Overview

The ACTIV application uses a dual admin identification system:
- **MongoDB ObjectId (`_id`)**: Internal database identifier
- **Admin Code (`adminId`)**: Human-readable identifier (e.g., BA001, DA001, SA001)

## Admin ID Formats

### Admin Code Patterns
- **Block Admin**: `BA` + 8-digit number (e.g., `BA28027005`)
- **District Admin**: `DA` + 6-digit number (e.g., `DA001001`)
- **State Admin**: `SA` + 3-digit number (e.g., `SA001`)
- **Super Admin**: `SU` + 3-digit number (e.g., `SU001`)

### MongoDB ObjectId
- 24-character hexadecimal string (e.g., `507f1f77bcf86cd799439011`)
- Generated automatically by MongoDB

## Backend Implementation

### resolveAdminObjectId Function

The `resolveAdminObjectId` function in `routes/applications.js` handles admin identification:

```javascript
async function resolveAdminObjectId(role, id, Models) {
  // Accepts either MongoDB ObjectId or admin code
  // Returns MongoDB ObjectId string or null
}
```

**Supported Input Types:**
- Admin codes (BA001, DA001, etc.)
- Email addresses (fallback)
- MongoDB ObjectIds (direct pass-through)

### API Endpoints

#### Route Parameters
All admin-related routes accept both ObjectId and admin codes:

```javascript
// These all work:
GET /applications/block/BA28027005
GET /applications/block/507f1f77bcf86cd799439011
GET /applications/district/DA001001
GET /applications/state/SA001
```

#### Request Body
Review endpoints require `adminId` in the request body:

```javascript
POST /applications/block-review/:appId
{
  "adminId": "BA28027005",  // Admin code or ObjectId
  "action": "approve",
  "reason": "Application meets all criteria"
}
```

### Error Handling

#### Standardized Error Messages

**Admin Not Found (400 status):**
```json
{
  "success": false,
  "message": "Admin not found for role 'block' and ID 'BA28027005'"
}
```

**Authorization Failed (403 status):**
```json
{
  "success": false,
  "message": "You are not authorized to review this application"
}
```

#### Error Logging
All admin resolution failures are logged with:
```javascript
console.error("resolveAdminObjectId failed for [role] admin:", adminId);
```

## Frontend Implementation

### Authentication Storage
After successful login, admin data is stored with both identifiers:

```javascript
await AuthService.saveLoginData({
  token: token,
  userData: {
    'adminId': adminId,    // MongoDB ObjectId (preferred)
    'mongoId': mongoId,    // MongoDB ObjectId (backup)
    'role': adminRole,
    'email': email,
    'isAdmin': true,
  },
});
```

### API Service Calls

#### Inbox Endpoints
```dart
Future<List<dynamic>> getBlockInbox(String blockAdminId) async {
  // blockAdminId can be ObjectId or admin code
  final res = await http.get(
    Uri.parse('$baseUrl/applications/block/$blockAdminId'),
    headers: _headers,
  );
  
  // Handle error responses
  if (res.statusCode != 200) {
    throw Exception(data['message'] ?? 'Failed to fetch block inbox');
  }
  
  return (data['applications'] ?? []) as List<dynamic>;
}
```

#### Review Endpoints
```dart
Future<Map<String, dynamic>> blockReview({
  required String appId,
  required String adminId,  // ObjectId or admin code
  required String action,
  String? reason,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/applications/block-review/$appId'),
    headers: _headers,
    body: jsonEncode({
      'adminId': adminId,
      'action': action,
      'reason': reason,
    }),
  );
  
  // Handle error responses
  if (res.statusCode != 200) {
    throw Exception(data['message'] ?? 'Failed to process block review');
  }
  
  return data;
}
```

## Best Practices

### 1. Prefer MongoDB ObjectId
When available, use MongoDB ObjectId for better performance:
```javascript
// Good: Use ObjectId from authentication
const adminId = userData['adminId']; // This is ObjectId after login

// Acceptable: Use admin code when ObjectId unavailable
const adminId = 'BA28027005';
```

### 2. Error Handling
Always handle both admin not found (400) and authorization (403) errors:

```dart
try {
  final result = await applicationService.blockReview(
    appId: appId,
    adminId: adminId,
    action: 'approve',
  );
} catch (e) {
  if (e.toString().contains('Admin not found')) {
    // Handle invalid admin ID
  } else if (e.toString().contains('not authorized')) {
    // Handle authorization failure
  } else {
    // Handle other errors
  }
}
```

### 3. Validation
Validate admin ID format before API calls:

```dart
bool isValidAdminId(String adminId) {
  // Check if it's a MongoDB ObjectId (24 hex chars)
  if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(adminId)) {
    return true;
  }
  
  // Check if it's a valid admin code
  if (RegExp(r'^(BA|DA|SA|SU)\d+$').hasMatch(adminId)) {
    return true;
  }
  
  return false;
}
```

## Database Schema

### Admin Models
All admin models include both identifiers:

```javascript
const AdminSchema = new mongoose.Schema({
  _id: ObjectId,                    // MongoDB ObjectId (auto-generated)
  adminId: {                        // Human-readable code
    type: String,
    required: true,
    unique: true
  },
  email: String,
  passwordHash: String,
  fullName: String,
  role: String,
  active: Boolean,
  // ... other fields
});
```

### Application Model
Applications reference admins by ObjectId:

```javascript
const ApplicationSchema = new mongoose.Schema({
  assignedBlockAdmin: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'BlockAdmin'
  },
  assignedDistrictAdmin: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'DistrictAdmin'
  },
  assignedStateAdmin: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'StateAdmin'
  },
  // ... other fields
});
```

## Migration Notes

### From Admin Code to ObjectId
If migrating from admin code-based system:

1. Update authentication to return ObjectId as `adminId`
2. Keep admin codes for backward compatibility
3. Use `resolveAdminObjectId` for flexible input handling
4. Update frontend to prefer ObjectId when available

### Error Message Updates
Clients depending on specific error messages should handle:
- Old: `"Invalid block admin id"`
- New: `"Admin not found for role 'block' and ID 'BA28027005'"`

## Troubleshooting

### Common Issues

1. **ObjectId Casting Error**
   - Cause: Passing null/undefined to MongoDB ObjectId constructor
   - Solution: Use `resolveAdminObjectId` validation guard

2. **Admin Not Found**
   - Cause: Invalid admin ID or admin doesn't exist
   - Solution: Verify admin ID format and database records

3. **Authorization Failed**
   - Cause: Admin exists but not authorized for the operation
   - Solution: Check admin role and assignment permissions

### Debug Logging
Enable debug logging to trace admin resolution:

```javascript
console.log("Resolving admin:", { role, id });
const resolved = await resolveAdminObjectId(role, id, Models);
console.log("Resolution result:", resolved);
```

## Security Considerations

1. **Input Validation**: Always validate admin IDs before database queries
2. **Authorization**: Verify admin permissions for each operation
3. **Logging**: Log admin actions for audit trails
4. **Error Messages**: Don't expose sensitive information in error messages

## Testing

### Unit Tests
Test admin resolution with various input types:

```javascript
describe('resolveAdminObjectId', () => {
  it('should resolve admin code to ObjectId', async () => {
    const result = await resolveAdminObjectId('block', 'BA28027005', Models);
    expect(result).toMatch(/^[0-9a-fA-F]{24}$/);
  });
  
  it('should handle invalid admin ID', async () => {
    const result = await resolveAdminObjectId('block', 'INVALID', Models);
    expect(result).toBeNull();
  });
});
```

### Integration Tests
Test API endpoints with both ObjectId and admin codes:

```javascript
describe('Block Admin Inbox', () => {
  it('should work with admin code', async () => {
    const response = await request(app)
      .get('/applications/block/BA28027005')
      .expect(200);
  });
  
  it('should work with ObjectId', async () => {
    const response = await request(app)
      .get('/applications/block/507f1f77bcf86cd799439011')
      .expect(200);
  });
});
```