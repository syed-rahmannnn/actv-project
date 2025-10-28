# User Registration Script for Block Admin Testing

This script automates user registration for testing the block admin workflow. It creates fresh test users and submits applications via your backend API.

## Files Created

1. **`register_user.dart`** - Main registration script
2. **`pubspec_script.yaml`** - Dependencies for the script
3. **`README_registration_script.md`** - This documentation

## Quick Start

### 1. Install Dependencies
```bash
dart pub get
```

### 2. Run the Script
```bash
dart run register_user.dart
```

The script will:
- Generate a random test user with unique ID, email, and phone
- Use valid location data (Tamil Nadu > Salem > Attur)
- Submit the application to your backend API
- Display detailed results with helpful error messages

## Configuration

### API URL
The script is configured to use: `https://actv-project.onrender.com/api`

To change this, edit the `apiBaseUrl` constant in `register_user.dart`:
```dart
const String apiBaseUrl = "http://localhost:3000/api"; // For local testing
```

### Location Data
Currently uses:
- **State**: Tamil Nadu
- **District**: Salem  
- **Block**: Attur

To use different locations, update the `userPayload` in `register_user.dart`. Make sure the location exists in your `assets/data/locations_nested.json` file.

### Form Data
The script includes basic form data. Add more fields as needed:
```dart
"formData": {
  "fieldA": "valueA",
  "fieldB": "valueB", 
  "businessType": "Individual",
  "category": "General",
  "registrationDate": DateTime.now().toIso8601String(),
  // Add more fields here as required by your backend
}
```

## Troubleshooting

### Common Errors

#### 1. "No matching admins found for this location" (404)
**Problem**: No block/district/state admins exist for the specified location.

**Solution**: 
- Set up admins for the location using your admin creation scripts
- Or change the location in the script to one that has admins
- Check your admin collections in MongoDB

#### 2. "Server Error" (500)
**Problem**: Backend server error, often due to missing required fields.

**Solutions**:
- Check backend logs for detailed error information
- Ensure all required fields are included in the payload
- Verify the backend server is running and accessible

#### 3. "You already have a pending application" (409)
**Problem**: User already has a pending application.

**Solution**: The script generates random user IDs to avoid this, but if it happens:
- Run the script again (it will generate a new random user)
- Or manually clean up test data from your database

#### 4. Network/Connection Errors
**Solutions**:
- Check if the backend server is running
- Verify the API URL is correct
- Ensure you have internet connectivity
- For local testing, use `http://localhost:3000/api` instead

### Backend Requirements

For the script to work, your backend needs:

1. **Admin Setup**: Block, District, and State admins must exist for the test location
2. **Database Connection**: MongoDB must be running and accessible
3. **API Endpoints**: The `/applications/submit` endpoint must be working
4. **Required Fields**: All fields in the payload must match your schema

### Setting Up Test Admins

If you need to create test admins for the Tamil Nadu > Salem > Attur location, you can:

1. Use your existing admin creation scripts
2. Or manually insert admin records in MongoDB
3. Or modify the script to use a location that already has admins

## Customization

### Adding Authentication
If your API requires authentication, add an Authorization header:
```dart
final headers = {
  "Content-Type": "application/json",
  "Accept": "application/json",
  "Authorization": "Bearer YOUR_TOKEN_HERE"
};
```

### Multiple Locations
To test multiple locations, you can modify the script to randomly select from a list:
```dart
final locations = [
  {"state": "Tamil Nadu", "district": "Salem", "block": "Attur"},
  {"state": "Tamil Nadu", "district": "Chennai", "block": "Chennai"},
  // Add more locations
];
final location = locations[Random().nextInt(locations.length)];
```

### Batch Registration
To create multiple users at once, wrap the registration logic in a loop:
```dart
for (int i = 0; i < 5; i++) {
  // Registration logic here
  await Future.delayed(Duration(seconds: 1)); // Avoid rate limiting
}
```

## Output Examples

### Successful Registration
```
🚀 Starting automated user registration for block admin testing...

📝 Generated user data:
   User ID: testuser2941106
   Name: Test User 2941106
   Email: testuser2941106@example.com
   Phone: 9876595720
   Location: Tamil Nadu > Salem > Attur

🌐 Submitting application to: https://actv-project.onrender.com/api/applications/submit
✅ Registration success!
   Status Code: 201
   Response: {
     "success": true,
     "message": "Application submitted successfully",
     "application": { ... }
   }

🔄 Run this script again to create another test user!
```

### Failed Registration
```
❌ Registration failed!
   Status Code: 404
   Error Response: {
     "success": false,
     "message": "No matching admins found for this location",
     "details": {
       "blockAdminFound": false,
       "districtAdminFound": false, 
       "stateAdminFound": false
     }
   }
```

## Next Steps

After successful registration:
1. Check your block admin dashboard to see the new application
2. Test the approval workflow
3. Verify notifications and status updates work correctly
4. Test with different user data and locations

## Support

If you encounter issues:
1. Check the backend server logs
2. Verify your MongoDB collections have the required admin data
3. Ensure all API endpoints are working correctly
4. Test with a REST client like Postman first to isolate issues