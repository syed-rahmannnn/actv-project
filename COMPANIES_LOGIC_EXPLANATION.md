# 🏢 Companies Management - Complete Logic Explanation

## Overview
Companies are business entities created by members. Each company belongs to exactly ONE member (via `memberId`), and members can create multiple companies.

---

## 🗄️ Database Storage

### MongoDB Collection: `companies`

**Schema Structure:**
```javascript
{
  memberId: ObjectId,           // References MemberDetails._id (OWNER)
  name: String,                 // Company name
  industry: String,             // Business type (Manufacturing, Trader, etc.)
  location: String,             // City/state
  city: String,
  area: String,
  description: String,
  website: String,
  mobile: String,
  email: String,
  logoUrl: String,
  status: String,               // ACTIVE, UNDER_REVIEW, PENDING, REJECTED
  productsCount: Number,        // Count of products
  views: Number,                // Profile views
  connections: Number,          // Business connections
  createdAt: Date,             // Auto-generated
  updatedAt: Date              // Auto-generated
}
```

**Key Index:** `memberId` is indexed for fast queries

---

## 🔄 Backend API Endpoints

### 1. **GET /api/companies?memberId={id}**
Fetches ALL companies created by a specific member.

**Request:**
```
GET http://localhost:3000/api/companies?memberId=675293b5a2b088c84e7bde1b
```

**Logic:**
```javascript
// 1. Receive memberId as query parameter
// 2. Convert string to MongoDB ObjectId
// 3. Query: Company.find({ memberId: ObjectId(memberId) })
// 4. Return array of companies sorted by createdAt (newest first)
```

**Response:**
```json
{
  "success": true,
  "count": 3,
  "data": [
    {
      "_id": "675abcd123...",
      "memberId": "675293b5a2b088c84e7bde1b",
      "name": "Tech Solutions Inc",
      "industry": "Software",
      "mobile": "9092317264",
      ...
    },
    ...
  ]
}
```

---

### 2. **POST /api/companies**
Creates a new company for a member.

**Request:**
```json
POST http://localhost:3000/api/companies
Content-Type: application/json

{
  "memberId": "675293b5a2b088c84e7bde1b",
  "name": "My New Company",
  "industry": "Trader",
  "mobile": "9876543210",
  "area": "Downtown",
  "location": "Chennai",
  "description": "We trade goods"
}
```

**Logic:**
```javascript
// 1. Validate memberId and name (required)
// 2. Convert memberId to ObjectId
// 3. Create new Company document
// 4. Save to MongoDB
// 5. Return created company
```

**Storage Location:** 
- Collection: `companies`
- Document ID: Auto-generated MongoDB ObjectId
- Linked to member via: `memberId` field

---

## 📱 Flutter/Dart Frontend

### Service: `CompanyService`
Location: `lib/services/company_service.dart`

**1. Fetch Companies:**
```dart
static Future<List<Company>> getCompanies(String memberId) async {
  // Calls: GET /api/companies?memberId={memberId}
  // Returns: List<Company> - all companies for that member
}
```

**2. Create Company:**
```dart
static Future<Map<String, dynamic>> createCompany({
  required String memberId,
  required String name,
  String? industry,
  ...
}) async {
  // Calls: POST /api/companies
  // Body: { memberId, name, industry, ... }
  // Returns: { success: true/false, message, data }
}
```

---

## 🖥️ UI Screens

### 1. **Business Dashboard** (`businessaccount_dashboard_screen.dart`)

**On Load:**
```dart
void initState() {
  _loadBusinessData();
  // Fetches companies using memberId from widget.userData
}

_loadBusinessData() {
  final memberId = widget.userData['_id'] ?? widget.userData['id'];
  
  // Calls CompanyService.getCompanies(memberId)
  _companies = await CompanyService.getCompanies(memberId);
  
  // Sets first company as active
  if (_companies.isNotEmpty) {
    _activeCompany = _companies[0];
  }
}
```

**Display:**
- Shows "Manage My Companies" button with count
- Lists all companies created by the member
- Allows switching between companies

---

### 2. **Manage Companies Screen** (`manage_companies_screen.dart`)

**Purpose:** View, add, edit, delete companies

**Fetch Logic:**
```dart
_loadCompanies() {
  final memberId = widget.userData['_id'] ?? widget.userData['id'];
  _companies = await CompanyService.getCompanies(memberId);
}
```

**Add Company:**
- Opens `add_company_screen.dart` or `business_profile_screen.dart` (mode: 'createCompany')
- Calls `CompanyService.createCompany()` with memberId
- New company is saved to DB
- Screen refreshes to show new company

---

### 3. **Add Company Screen** (`add_company_screen.dart`)

**Create Flow:**
```dart
Future<void> _createCompany() async {
  final memberId = widget.userData['_id'] ?? widget.userData['id'];
  
  final result = await CompanyService.createCompany(
    memberId: memberId,
    name: _companyNameController.text,
    industry: _selectedIndustry,
    mobile: _mobileController.text,
    area: _areaController.text,
    location: _locationController.text,
  );
  
  // Returns to previous screen if successful
  if (result['success']) {
    Navigator.pop(context, true);
  }
}
```

---

## 🔐 Data Ownership & Security

### **Ownership Model:**
1. Each company has a `memberId` field
2. `memberId` references the `MemberDetails._id` (user who created it)
3. Only companies with matching `memberId` are fetched
4. **One member can create MULTIPLE companies**
5. **Each company belongs to EXACTLY ONE member**

### **Query Filter:**
```javascript
// Backend ALWAYS filters by memberId
Company.find({ memberId: ObjectId(currentMemberId) })

// This ensures users only see THEIR companies
// NOT companies from other users
```

---

## 📊 Data Flow Diagram

```
┌─────────────────────────────────────────────────┐
│          User Logs In                           │
│  (userData contains memberId/id)                │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│     Business Dashboard Screen Opens             │
│  Extracts memberId from widget.userData         │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│  CompanyService.getCompanies(memberId)          │
│  → Calls: GET /api/companies?memberId=xxx       │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│         Backend (Node.js/Express)               │
│  1. Receives memberId                           │
│  2. Converts to ObjectId                        │
│  3. Queries MongoDB:                            │
│     Company.find({ memberId: ObjectId })        │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│           MongoDB Database                      │
│  Collection: companies                          │
│  Finds all documents where:                     │
│  memberId === current user's _id                │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│         Returns JSON Array                      │
│  [{ company1 }, { company2 }, ...]              │
└─────────────────┬───────────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────────┐
│    Flutter Displays Companies                   │
│  • Lists all companies                          │
│  • Shows count badge                            │
│  • Allows switching between them                │
└─────────────────────────────────────────────────┘
```

---

## 🆕 Creating a New Company - Complete Flow

```
User Action                     System Action
───────────────────────────────────────────────────────────────

1. Clicks "Add Company"    →   Opens add_company_screen.dart

2. Fills form:             →   Stores in text controllers:
   - Company name               _companyNameController
   - Industry/Type              _selectedIndustry
   - Mobile                     _mobileController
   - Area                       _areaController
   - Location                   _locationController

3. Clicks "Save"           →   Calls CompanyService.createCompany()
                                {
                                  memberId: userData['id'],
                                  name: "New Company",
                                  industry: "Trader",
                                  ...
                                }

4. Service sends POST      →   Backend receives:
   to /api/companies           POST /api/companies
                               Body: { memberId, name, ... }

5. Backend validates       →   • Check memberId & name exist
                               • Convert memberId to ObjectId

6. Backend creates doc     →   new Company({
                                 memberId: ObjectId(...),
                                 name: "New Company",
                                 status: "UNDER_REVIEW",
                                 ...
                               })

7. Save to MongoDB         →   await newCompany.save()
                               → Stored in 'companies' collection

8. Return success          →   { success: true, data: {...} }

9. Flutter receives        →   Shows success message
                               Pops screen
                               Refreshes company list

10. Dashboard updates      →   Fetches companies again
                               Shows new company in list
                               Count badge updates
```

---

## ✅ Key Points

### **Data Ownership:**
- ✅ Companies are owned by members via `memberId`
- ✅ Each company has exactly ONE owner
- ✅ One member can own MULTIPLE companies
- ✅ Filtering ALWAYS happens by `memberId`

### **Database:**
- ✅ Collection: `companies`
- ✅ Primary link: `memberId` (ObjectId reference)
- ✅ Indexed for fast queries
- ✅ Auto timestamps (createdAt, updatedAt)

### **API Security:**
- ✅ `memberId` required for all queries
- ✅ Users only see THEIR companies
- ✅ No cross-user data leakage
- ✅ Business-scoped isolation

### **Frontend:**
- ✅ `CompanyService` handles all API calls
- ✅ Dashboard shows companies for logged-in user
- ✅ Manage screen allows CRUD operations
- ✅ Company switcher for multi-company accounts

---

## 🔍 Example Query Results

**User A (memberId: 111):**
```json
[
  { "_id": "aaa", "memberId": "111", "name": "Company A1" },
  { "_id": "bbb", "memberId": "111", "name": "Company A2" }
]
```

**User B (memberId: 222):**
```json
[
  { "_id": "ccc", "memberId": "222", "name": "Company B1" },
  { "_id": "ddd", "memberId": "222", "name": "Company B2" },
  { "_id": "eee", "memberId": "222", "name": "Company B3" }
]
```

**User A will NEVER see companies ccc, ddd, eee**  
**User B will NEVER see companies aaa, bbb**

---

## 📁 Related Files

### Backend:
- `activ-backend/routes/companies.js` - API routes & schema
- `activ-backend/server.js` - Mounts routes at `/api/companies`

### Frontend:
- `lib/services/company_service.dart` - API service
- `lib/models/company_model.dart` - Company data model
- `lib/screens/Bussiness account/businessaccount_dashboard_screen.dart` - Main dashboard
- `lib/screens/Bussiness account/manage_companies_screen.dart` - Company list
- `lib/screens/Bussiness account/add_company_screen.dart` - Create company
- `lib/screens/Bussiness account/edit_company_screen.dart` - Edit company
- `lib/providers/company_selection_provider.dart` - Active company state

---

## 🎯 Summary

**Where companies are stored:** MongoDB `companies` collection  
**How to identify owner:** Via `memberId` field (ObjectId)  
**How to fetch:** `GET /api/companies?memberId={currentUserId}`  
**How to create:** `POST /api/companies` with `{ memberId, name, ... }`  
**Security:** All queries filtered by memberId - users only see THEIR companies  
**Multi-company:** One user can own and switch between multiple companies
