# ACTV Project - API Documentation

**Base URL:** `http://localhost:3000/api` (Development)  
**Production URL:** `https://your-domain.onrender.com/api`

**Content-Type:** `application/json` for all requests  
**Authentication:** JWT Bearer token (where applicable)

---

## Table of Contents

1. [Authentication APIs](#authentication-apis)
2. [Profile Management APIs](#profile-management-apis)
3. [Member Management APIs](#member-management-apis)
4. [Business Profile APIs](#business-profile-apis)
5. [Error Handling](#error-handling)

---

## Authentication APIs

### 1. Register New Member

**Endpoint:** `POST /api/auth/register`

**Description:** Create a new member account with personal details.

**Request Body:**
```json
{
  "fullName": "John Doe",
  "phoneNumber": "9876543210",
  "email": "john.doe@example.com",
  "password": "SecurePass123",
  "state": "Karnataka",
  "district": "Bangalore",
  "block": "Yeshwanthpur",
  "city": "Bangalore"
}
```

**Response (Success - 201):**
```json
{
  "success": true,
  "message": "Member registered successfully",
  "data": {
    "member": {
      "id": "674d1234567890abcdef1234",
      "fullName": "John Doe",
      "email": "john.doe@example.com",
      "phoneNumber": "9876543210",
      "state": "Karnataka",
      "district": "Bangalore",
      "block": "Yeshwanthpur",
      "city": "Bangalore",
      "profileCompleted": false,
      "createdAt": "2025-12-02T10:30:00.000Z"
    }
  }
}
```

**Response (Error - 400):**
```json
{
  "success": false,
  "message": "All fields are required"
}
```

**Response (Error - 409):**
```json
{
  "success": false,
  "message": "Member with this email already exists"
}
```

---

### 2. Login Member

**Endpoint:** `POST /api/auth/login`

**Description:** Authenticate member and receive JWT token.

**Request Body:**
```json
{
  "email": "john.doe@example.com",
  "password": "SecurePass123"
}
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "member": {
      "id": "674d1234567890abcdef1234",
      "memberId": "674d1234567890abcdef1234",
      "fullName": "John Doe",
      "email": "john.doe@example.com",
      "phoneNumber": "9876543210",
      "state": "Karnataka",
      "district": "Bangalore",
      "block": "Yeshwanthpur",
      "city": "Bangalore",
      "profileCompleted": false
    }
  }
}
```

**Response (Error - 401):**
```json
{
  "success": false,
  "message": "Invalid password"
}
```

**Response (Error - 404):**
```json
{
  "success": false,
  "message": "Member not found"
}
```

---

## Profile Management APIs

### 3. Get Complete Member Profile

**Endpoint:** `GET /api/profile/:memberId`

**Description:** Retrieve complete profile including business info, financial info, and declarations.

**Request:**
```
GET /api/profile/674d1234567890abcdef1234
```

**Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "member": {
      "id": "674d1234567890abcdef1234",
      "fullName": "John Doe",
      "email": "john.doe@example.com",
      "phoneNumber": "9876543210",
      "state": "Karnataka",
      "district": "Bangalore",
      "profileCompleted": false
    },
    "businessInfo": {
      "_id": "674d9876543210fedcba5678",
      "memberId": "674d1234567890abcdef1234",
      "fullName": "John Doe",
      "email": "john.doe@example.com",
      "organizationName": "Doe Enterprises",
      "businessType": "Service Provider",
      "mobile": "9876543210",
      "area": "Yeshwanthpur",
      "location": "Bangalore, Karnataka",
      "businessDescription": "IT consulting services",
      "logoUrl": "https://...",
      "status": "UNDER_REVIEW",
      "createdAt": "2025-12-02T10:45:00.000Z",
      "updatedAt": "2025-12-02T11:00:00.000Z"
    },
    "financialInfo": {
      "_id": "674dabcd567890fedcba1234",
      "memberId": "674d1234567890abcdef1234",
      "panNumber": "ABCDE1234F",
      "gstNumber": "29ABCDE1234F1Z5",
      "turnoverRange": "10-50 Lakhs"
    },
    "declaration": {
      "_id": "674defgh567890fedcba5678",
      "memberId": "674d1234567890abcdef1234",
      "agreeToDeclaration": true,
      "profileCompleted": true
    }
  }
}
```

**Response (Error - 404):**
```json
{
  "success": false,
  "message": "Member not found"
}
```

---

## Business Profile APIs

### 4. Get Business Information

**Endpoint:** `GET /api/profile/business-info/:memberId`

**Description:** Retrieve business profile for a specific member.

**Request:**
```
GET /api/profile/business-info/674d1234567890abcdef1234
```

**Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "businessInfo": {
      "_id": "674d9876543210fedcba5678",
      "memberId": "674d1234567890abcdef1234",
      "fullName": "John Doe",
      "email": "john.doe@example.com",
      "organizationName": "Doe Enterprises",
      "constitutionType": "OPC",
      "businessType": "Service Provider",
      "businessActivities": "Software Development, IT Consulting",
      "businessCommencementYear": "2020",
      "numberOfEmployees": "10-50",
      "memberOfOtherChamber": false,
      "registeredWithGovtOrganization": ["MSME"],
      "mobile": "9876543210",
      "area": "Yeshwanthpur",
      "location": "Bangalore, Karnataka",
      "businessDescription": "IT consulting and software development services",
      "businessWebsite": "https://doeenterprises.com",
      "logoUrl": "https://storage.example.com/logos/doe.png",
      "status": "UNDER_REVIEW",
      "createdAt": "2025-12-02T10:45:00.000Z",
      "updatedAt": "2025-12-02T11:00:00.000Z"
    }
  }
}
```

**Response (Error - 404):**
```json
{
  "success": false,
  "message": "Business information not found"
}
```

---

### 5. Save/Update Business Information

**Endpoint:** `POST /api/profile/business-info`

**Description:** Create or update business profile. Uses upsert logic - creates if not exists, updates if exists.

**Request Body (Create/Update):**
```json
{
  "memberId": "674d1234567890abcdef1234",
  "organizationName": "Doe Enterprises",
  "constitutionType": "OPC",
  "businessType": "Service Provider",
  "businessActivities": "Software Development, IT Consulting",
  "businessCommencementYear": "2020",
  "numberOfEmployees": "10-50",
  "memberOfOtherChamber": false,
  "otherChamber": "",
  "registeredWithGovtOrganization": ["MSME"],
  "doingBusiness": true,
  "additionalBusiness": "Cloud Solutions",
  "businessLocation": "Bangalore",
  "businessWebsite": "https://doeenterprises.com",
  "businessScale": "Medium",
  "exportStatus": "Yes",
  "hasExportLicense": true,
  "exportLicense": "EXP123456",
  "businessDescription": "IT consulting and software development services",
  "mobile": "9876543210",
  "area": "Yeshwanthpur",
  "location": "Bangalore, Karnataka",
  "logoUrl": "https://storage.example.com/logos/doe.png",
  "status": "UNDER_REVIEW"
}
```

**Minimal Request Body (Dashboard Edit):**
```json
{
  "memberId": "674d1234567890abcdef1234",
  "organizationName": "Updated Company Name",
  "businessType": "Manufacturing",
  "businessDescription": "Updated description",
  "mobile": "8888888888",
  "area": "Malleswaram",
  "location": "Bangalore, Karnataka"
}
```

**Allowed Fields:**
- `organizationName` (String)
- `constitutionType` (String: "OPC", "TRUST", "SOCIETY")
- `businessType` (String: "Manufacturing", "Trader", "Service Provider", "Others")
- `businessActivities` (String)
- `businessCommencementYear` (String)
- `numberOfEmployees` (String)
- `memberOfOtherChamber` (Boolean)
- `otherChamber` (String)
- `registeredWithGovtOrganization` (Array of Strings: "MSME", "KVIC", "NABARD", "None", "Others")
- `doingBusiness` (Boolean)
- `additionalBusiness` (String)
- `businessLocation` (String)
- `businessWebsite` (String)
- `businessScale` (String)
- `exportStatus` (String)
- `hasExportLicense` (Boolean)
- `exportLicense` (String)
- `businessDescription` (String)
- `mobile` (String) ⭐ **Important for dashboard display**
- `area` (String)
- `location` (String)
- `logoUrl` (String)
- `status` (String: "UNDER_REVIEW", "APPROVED", "ACTIVE", "REJECTED", "PENDING")

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Business information saved successfully",
  "data": {
    "businessInfo": {
      "_id": "674d9876543210fedcba5678",
      "memberId": "674d1234567890abcdef1234",
      "fullName": "John Doe",
      "email": "john.doe@example.com",
      "organizationName": "Updated Company Name",
      "businessType": "Manufacturing",
      "businessDescription": "Updated description",
      "mobile": "8888888888",
      "area": "Malleswaram",
      "location": "Bangalore, Karnataka",
      "status": "UNDER_REVIEW",
      "createdAt": "2025-12-02T10:45:00.000Z",
      "updatedAt": "2025-12-02T12:30:00.000Z"
    }
  }
}
```

**Response (Error - 400):**
```json
{
  "success": false,
  "message": "Member ID is required"
}
```

**Response (Error - 404):**
```json
{
  "success": false,
  "message": "Member not found"
}
```

---

### 6. Save/Update Financial Information

**Endpoint:** `POST /api/profile/financial-info`

**Description:** Create or update financial profile information.

**Request Body:**
```json
{
  "memberId": "674d1234567890abcdef1234",
  "panNumber": "ABCDE1234F",
  "gstNumber": "29ABCDE1234F1Z5",
  "udyamNumber": "UDYAM-KA-00-0123456",
  "filedITR": true,
  "itrYears": ["2021-22", "2022-23", "2023-24"],
  "turnoverRange": "10-50 Lakhs",
  "fy2021": "15 Lakhs",
  "fy2020": "12 Lakhs",
  "fy2019": "10 Lakhs",
  "govtSchemeBenefit": true,
  "scheme1": "MSME Support",
  "scheme2": "Startup India",
  "scheme3": ""
}
```

**Allowed Fields:**
- `panNumber` (String)
- `gstNumber` (String)
- `udyamNumber` (String)
- `filedITR` (Boolean)
- `itrYears` (Array of Strings)
- `turnoverRange` (String)
- `fy2021`, `fy2020`, `fy2019` (String)
- `govtSchemeBenefit` (Boolean)
- `scheme1`, `scheme2`, `scheme3` (String)

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Financial information saved successfully",
  "data": {
    "financialInfo": {
      "_id": "674dabcd567890fedcba1234",
      "memberId": "674d1234567890abcdef1234",
      "fullName": "John Doe",
      "email": "john.doe@example.com",
      "panNumber": "ABCDE1234F",
      "gstNumber": "29ABCDE1234F1Z5",
      "turnoverRange": "10-50 Lakhs",
      "createdAt": "2025-12-02T10:50:00.000Z",
      "updatedAt": "2025-12-02T10:50:00.000Z"
    }
  }
}
```

---

### 7. Submit Declaration

**Endpoint:** `POST /api/profile/declaration`

**Description:** Submit final declaration and mark profile as completed.

**Request Body:**
```json
{
  "memberId": "674d1234567890abcdef1234",
  "sisterConcerns": true,
  "companyNames": ["Sister Company A", "Sister Company B"],
  "showOneFieldPerName": false,
  "agreeToDeclaration": true,
  "profileCompleted": true,
  "submissionDate": "2025-12-02T11:00:00.000Z"
}
```

**Allowed Fields:**
- `sisterConcerns` (Boolean)
- `companyNames` (Array of Strings)
- `showOneFieldPerName` (Boolean)
- `agreeToDeclaration` (Boolean)
- `profileCompleted` (Boolean)
- `submissionDate` (String/Date)

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Declaration submitted successfully",
  "data": {
    "declaration": {
      "_id": "674defgh567890fedcba5678",
      "memberId": "674d1234567890abcdef1234",
      "fullName": "John Doe",
      "email": "john.doe@example.com",
      "sisterConcerns": true,
      "companyNames": ["Sister Company A", "Sister Company B"],
      "agreeToDeclaration": true,
      "profileCompleted": true,
      "submissionDate": "2025-12-02T11:00:00.000Z",
      "createdAt": "2025-12-02T11:00:00.000Z",
      "updatedAt": "2025-12-02T11:00:00.000Z"
    }
  }
}
```

---

### 8. Complete Profile Status

**Endpoint:** `PUT /api/profile/complete-profile/:memberId`

**Description:** Mark member profile as completed.

**Request:**
```
PUT /api/profile/complete-profile/674d1234567890abcdef1234
```

**Response (Success - 200):**
```json
{
  "success": true,
  "message": "Profile marked as completed",
  "data": {
    "member": {
      "_id": "674d1234567890abcdef1234",
      "fullName": "John Doe",
      "email": "john.doe@example.com",
      "profileCompleted": true,
      "updatedAt": "2025-12-02T11:05:00.000Z"
    }
  }
}
```

---

## Member Management APIs

### 9. Get All Members (Paginated)

**Endpoint:** `GET /api/members?page=1&limit=10`

**Description:** Retrieve paginated list of all members.

**Query Parameters:**
- `page` (Number, optional, default: 1)
- `limit` (Number, optional, default: 10)

**Request:**
```
GET /api/members?page=1&limit=10
```

**Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "members": [
      {
        "_id": "674d1234567890abcdef1234",
        "fullName": "John Doe",
        "email": "john.doe@example.com",
        "phoneNumber": "9876543210",
        "state": "Karnataka",
        "district": "Bangalore",
        "profileCompleted": false,
        "createdAt": "2025-12-02T10:30:00.000Z"
      }
    ],
    "pagination": {
      "currentPage": 1,
      "totalPages": 5,
      "totalMembers": 47,
      "hasNext": true,
      "hasPrev": false
    }
  }
}
```

---

### 10. Get Member by Email

**Endpoint:** `GET /api/members/by-email?email=john.doe@example.com`

**Description:** Search for a member by email address.

**Query Parameters:**
- `email` (String, required)

**Request:**
```
GET /api/members/by-email?email=john.doe@example.com
```

**Response (Success - 200):**
```json
{
  "success": true,
  "data": {
    "_id": "674d1234567890abcdef1234",
    "fullName": "John Doe",
    "email": "john.doe@example.com",
    "phoneNumber": "9876543210",
    "state": "Karnataka",
    "district": "Bangalore",
    "block": "Yeshwanthpur",
    "city": "Bangalore",
    "profileCompleted": false,
    "createdAt": "2025-12-02T10:30:00.000Z"
  }
}
```

**Response (Error - 404):**
```json
{
  "success": false,
  "message": "Member not found"
}
```

---

## Error Handling

All API endpoints follow a consistent error response format:

### Standard Error Response

```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error message (in development mode)"
}
```

### HTTP Status Codes

- **200 OK** - Request successful
- **201 Created** - Resource created successfully
- **400 Bad Request** - Invalid request data
- **401 Unauthorized** - Authentication failed
- **403 Forbidden** - Access denied
- **404 Not Found** - Resource not found
- **409 Conflict** - Resource already exists
- **500 Internal Server Error** - Server error

### Common Error Messages

**Missing Required Fields:**
```json
{
  "success": false,
  "message": "All fields are required"
}
```

**Member Not Found:**
```json
{
  "success": false,
  "message": "Member not found"
}
```

**Duplicate Email:**
```json
{
  "success": false,
  "message": "Member with this email already exists"
}
```

**Network/Server Error:**
```json
{
  "success": false,
  "message": "Internal server error",
  "error": "Detailed error trace"
}
```

---

## Notes & Best Practices

### 1. Mobile Number Field (Important!)

The `mobile` field in business profile is critical for dashboard display:

```json
{
  "mobile": "9876543210"  // 10-digit mobile number
}
```

- Always include this field when creating/updating business profiles
- Frontend displays "Mobile: Not set" in red if this field is null or empty
- Field is trimmed and stored as String in database

### 2. Status Field

Business profile status enum values:
- `UNDER_REVIEW` (default for new profiles)
- `APPROVED`
- `ACTIVE`
- `REJECTED`
- `PENDING`

### 3. Upsert Behavior

`POST /api/profile/business-info` uses **upsert**:
- If `memberId` has no business profile → **CREATE**
- If `memberId` has existing profile → **UPDATE** (merge with existing)

### 4. Field Whitelisting

Backend uses field whitelisting for security. Only allowed fields are processed:
- Unknown fields in request body are ignored
- This prevents database pollution and injection attacks

### 5. Common Fields

All profile collections automatically include:
```json
{
  "fullName": "From MemberDetails",
  "email": "From MemberDetails",
  "memberId": "Reference to MemberDetails._id"
}
```

---

## Flutter/Frontend Integration

### Example: Update Business Profile

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<Map<String, dynamic>> updateBusinessProfile({
  required String memberId,
  required Map<String, dynamic> updates,
}) async {
  final url = Uri.parse('http://localhost:3000/api/profile/business-info');
  
  final payload = {
    'memberId': memberId,
    ...updates,
  };

  print('Update payload: ${jsonEncode(payload)}');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(payload),
  );

  final responseBody = jsonDecode(response.body);
  
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return {
      'success': true,
      'data': responseBody['data'],
    };
  } else {
    return {
      'success': false,
      'message': responseBody['message'],
    };
  }
}
```

### Example: Get Business Profile

```dart
Future<BusinessProfile?> getBusinessProfile(String memberId) async {
  final url = Uri.parse(
    'http://localhost:3000/api/profile/business-info/$memberId'
  );

  final response = await http.get(
    url,
    headers: {'Content-Type': 'application/json'},
  );

  if (response.statusCode == 200) {
    final body = jsonDecode(response.body);
    if (body['success'] == true) {
      return BusinessProfile.fromJson(body['data']['businessInfo']);
    }
  }
  
  return null;
}
```

---

## Changelog

**v1.0.0 - December 2, 2025**
- Initial API documentation
- Fixed mobile number update issue in business profile
- Added explicit field logging for debugging
- Implemented `$set` operator for MongoDB updates

---

**For issues or questions, contact the development team.**
