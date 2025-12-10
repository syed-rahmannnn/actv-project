# Business Account Creation Workflow - Complete A to Z Guide

## Overview
This document provides a complete end-to-end workflow for creating and managing business accounts in the ACTIV application, from the member dashboard to full business profile setup.

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Dashboard Entry Point](#dashboard-entry-point)
3. [Business Profile Creation Flow](#business-profile-creation-flow)
4. [Company Creation Flow](#company-creation-flow)
5. [Business Dashboard](#business-dashboard)
6. [Data Architecture](#data-architecture)
7. [API Endpoints](#api-endpoints)
8. [Key Features](#key-features)

---

## Prerequisites

### User Requirements
- ✅ User must be logged in as a Member
- ✅ User must have completed member registration
- ✅ User must have valid member ID stored in session

### Technical Requirements
- Member data available in `userData` object with fields:
  - `_id` or `id` (Member MongoDB ID)
  - `email`
  - `fullName`
  - `mobile` or `mobileNumber` (optional, pre-filled if available)

---

## Dashboard Entry Point

### Location
**File:** `lib/screens/Member Bottom Navigation/dashboard_screen.dart`

### Access Point
From the Member Dashboard, users can access business features through:

1. **"Start Business Account" Button**
   - Located in the main dashboard view
   - Triggers navigation to Business Profile creation screen
   - Shows if user has not created a business profile yet

2. **"My Business" Card/Section**
   - Appears after business profile is created
   - Shows existing business profile summary
   - Quick access to Business Dashboard

### Navigation Code
```dart
// Navigate to Business Profile Creation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BusinessProfileScreen(
      userData: userData,
      mode: 'profile', // or 'createCompany'
    ),
  ),
);
```

---

## Business Profile Creation Flow

### Step 1: Business Profile Screen
**File:** `lib/screens/Bussiness account/business_profile_screen.dart`

#### Purpose
Create the primary business profile for the member. This is the parent entity that can have multiple companies.

#### Form Fields

| Field Name | Type | Required | Validation | Description |
|------------|------|----------|------------|-------------|
| Business Name | Text | ✅ Yes | Min 3 chars | Primary business name |
| Business Type/Industry | Dropdown | ✅ Yes | From list | Manufacturing, Trader, Service Provider, Others |
| Description | Text Area | ✅ Yes | Min 10 chars | Business description |
| Mobile Number | Text | ✅ Yes | 10 digits | Auto-filled from member profile |
| Area | Text | ✅ Yes | - | Business area/locality |
| Location | Text | ✅ Yes | - | Complete business address |
| Business Logo | Image | ❌ No | - | Optional logo upload |

#### Business Types Available
```dart
final List<String> _businessTypes = [
  'Manufacturing',
  'Trader',
  'Service Provider',
  'Others',
];
```

#### Form Validation
```dart
if (_formKey.currentState!.validate()) {
  // All required fields filled
  // Proceed to save
}
```

### Step 2: Save Business Profile

#### Service Call
**File:** `lib/services/business_profile_service.dart`

```dart
final result = await BusinessProfileService.saveBusinessProfile(
  memberId: memberId,
  businessName: _businessNameController.text.trim(),
  businessType: _selectedBusinessType ?? 'Others',
  description: _descriptionController.text.trim(),
  mobile: _mobileController.text.trim(),
  area: _areaController.text.trim(),
  location: _locationController.text.trim(),
  logoUrl: logoUrl,
);
```

#### Backend API Call
**Endpoint:** `POST /api/profile/business-info`

**Request Payload:**
```json
{
  "memberId": "507f1f77bcf86cd799439011",
  "businessName": "Johnson Enterprises",
  "businessType": "Manufacturing",
  "description": "Premium manufacturing company",
  "mobile": "9876543210",
  "area": "Tech Park",
  "location": "Mumbai, Maharashtra",
  "logoUrl": "https://..."
}
```

**Response:**
```json
{
  "success": true,
  "message": "Business profile saved successfully",
  "data": {
    "businessInfo": {
      "_id": "507f1f77bcf86cd799439012",
      "memberId": "507f1f77bcf86cd799439011",
      "businessId": "BIZ-1234567890",
      "name": "Johnson Enterprises",
      "industry": "Manufacturing",
      "status": "active",
      ...
    }
  }
}
```

### Step 3: Post-Creation Actions

#### Cache Management
After saving business profile:
```dart
// Clear cache to ensure fresh data
await BusinessProfileService.clearCache(memberId);
```

#### Navigation
Navigate to Business Dashboard:
```dart
Navigator.pushReplacement(
  context,
  MaterialPageRoute(
    builder: (context) => BusinessDashboardScreen(
      userData: userData,
      businessData: result['data'],
    ),
  ),
);
```

---

## Company Creation Flow

### When to Create Companies?
- **After** business profile is created
- A business profile can have **multiple companies**
- Each company represents a separate business entity under the main business

### Step 1: Access Company Creation

#### From Business Dashboard
1. Click "Manage Companies" tab
2. Click "Add New Company" FAB button
3. Opens `BusinessProfileScreen` with `mode: 'createCompany'`

#### Navigation Code
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => BusinessProfileScreen(
      userData: widget.userData,
      mode: 'createCompany', // ✅ Important: Company creation mode
    ),
  ),
);
```

### Step 2: Company Creation Form
**File:** `lib/screens/Bussiness account/business_profile_screen.dart`

#### Same Form Fields as Business Profile
The form UI is reused, but the data is saved as a **Company** entity:

| Field Name | Type | Required | Maps To |
|------------|------|----------|---------|
| Business Name | Text | ✅ | Company Name |
| Business Type | Dropdown | ✅ | Company Industry |
| Description | Text Area | ✅ | Company Description |
| Mobile Number | Text | ✅ | Company Contact |
| Area | Text | ✅ | Company Area |
| Location | Text | ✅ | Company Location |

### Step 3: Save Company

#### Service Call
**File:** `lib/services/company_service.dart`

```dart
await CompanyService.createCompany(
  memberId: memberId,
  name: _businessNameController.text.trim(),
  industry: _selectedBusinessType ?? 'Others',
  mobile: _mobileController.text.trim(),
  area: _areaController.text.trim(),
  location: _locationController.text.trim(),
  description: _descriptionController.text.trim(),
);
```

#### Backend API Call
**Endpoint:** `POST /api/companies`

**Request Payload:**
```json
{
  "memberId": "507f1f77bcf86cd799439011",
  "name": "TechCorp Solutions",
  "industry": "Service Provider",
  "description": "IT consulting services",
  "mobile": "9876543210",
  "area": "Cyber City",
  "location": "Hyderabad, Telangana"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Company created successfully",
  "data": {
    "company": {
      "_id": "507f1f77bcf86cd799439013",
      "memberId": "507f1f77bcf86cd799439011",
      "companyId": "COMP-1234567890",
      "name": "TechCorp Solutions",
      "industry": "Service Provider",
      "status": "active",
      "views": 0,
      "productsCount": 0,
      ...
    }
  }
}
```

### Step 4: Post-Company Creation

#### Cache Clearing
```dart
await CompanyService.clearCache(memberId);
await BusinessProfileService.clearCache(memberId);
```

#### Activity Logging
Backend automatically logs:
```javascript
await ActivityLog.create({
  memberId,
  companyId: company._id,
  activityType: 'COMPANY_CREATED',
  description: `Created company: ${name}`,
  metadata: { companyName: name, industry }
});
```

#### Navigation
Return to Business Dashboard with updated company list:
```dart
Navigator.pop(context);
// Dashboard automatically refreshes company list
```

---

## Business Dashboard

### Location
**File:** `lib/screens/Bussiness account/businessaccount _dashboard_screen.dart`

### Key Components

#### 1. Company Switcher
**Widget:** `CompanySwitcherWidget`
- Shows all companies owned by member
- Allows switching between companies
- Updates dashboard data dynamically

```dart
CompanySwitcherWidget(
  companies: _companies,
  activeCompany: _activeCompany,
  onCompanySelected: (company) {
    setState(() {
      _activeCompany = company;
    });
    _loadCompanySpecificData(company.id);
  },
)
```

#### 2. Business Profile Card
Displays:
- Business name
- Business type/industry
- Status (Active/Inactive)
- Member name
- Mobile number
- Location

#### 3. Quick Stats (Company-Specific)
Dynamic stats for selected company:
- **Profile Views:** Number of profile views
- **Products/Services:** Count of products listed
- **View Change:** Percentage change indicator
- **Featured Products:** Count of featured items

```dart
_buildStatCard(
  'Profile Views',
  _profileViews.toString(),
  Icons.visibility,
  Colors.blue,
  _profileViewsChange,
),
_buildStatCard(
  'Products',
  _productsCount.toString(),
  Icons.inventory,
  Colors.orange,
  _productsChange,
),
```

#### 4. Recent Activities (Company-Specific)
Shows recent activities for the selected company:
- Company created events
- Product added/updated
- Profile views
- Inquiries received

```dart
ListView.builder(
  itemCount: _recentActivities.length,
  itemBuilder: (context, index) {
    final activity = _recentActivities[index];
    return _buildActivityItem(
      activity['title'],
      activity['subtitle'],
      activity['timestamp'],
      activity['icon'],
    );
  },
);
```

#### 5. Bottom Navigation
Navigation tabs:
1. **Dashboard** - Home/Overview
2. **My Companies** - Manage all companies
3. **Products** - Manage products/services
4. **Discover** - Browse other businesses
5. **Analytics** - View insights & statistics
6. **Settings** - Business settings & preferences

### Data Loading Flow

#### Initial Load
```dart
@override
void initState() {
  super.initState();
  _loadBusinessData();
}

Future<void> _loadBusinessData() async {
  // 1. Clear caches for fresh data
  await BusinessProfileService.clearCache(memberId);
  await CompanyService.clearCache(memberId);
  
  // 2. Fetch business profile
  final profile = await BusinessProfileService.getBusinessProfile(memberId);
  
  // 3. Fetch companies in parallel
  final companies = await CompanyService.getCompanies(memberId);
  
  // 4. Set first company as active
  if (companies.isNotEmpty) {
    _activeCompany = companies[0];
    await _loadCompanySpecificData(companies[0].id);
  }
}
```

#### Company-Specific Data Load
```dart
Future<void> _loadCompanySpecificData(String companyId) async {
  // Load dashboard stats
  final stats = await DashboardService.getCompanyStats(companyId);
  
  // Load recent activities
  final activities = await DashboardService.getRecentActivities(companyId);
  
  setState(() {
    _profileViews = stats['profileViews'];
    _productsCount = stats['productsCount'];
    _recentActivities = activities;
  });
}
```

### Company Provider Integration
**File:** `lib/providers/company_selection_provider.dart`

Uses Provider pattern for state management:
```dart
final companyProvider = context.read<CompanySelectionProvider>();
companyProvider.setActiveCompany(selectedCompany);

// Access active company anywhere in the widget tree
final activeCompany = context.watch<CompanySelectionProvider>().activeCompany;
```

---

## Data Architecture

### Database Collections

#### 1. MemberBusinessInfo Collection
**Purpose:** Stores primary business profile for each member

**Schema:**
```javascript
{
  _id: ObjectId,
  memberId: ObjectId (ref: MemberDetails),
  businessId: String (unique: "BIZ-timestamp"),
  
  // Business Details
  name: String (required),
  industry: String (enum: ['Manufacturing', 'Trader', ...]),
  description: String,
  mobile: String (required),
  area: String,
  location: String,
  logoUrl: String,
  
  // Status
  status: String (enum: ['active', 'inactive', 'suspended']),
  
  // Metadata
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**
```javascript
{ memberId: 1 }  // Find business by member
{ businessId: 1 } // Find business by business ID
```

#### 2. Company Collection
**Purpose:** Stores individual companies under a business profile

**Schema:**
```javascript
{
  _id: ObjectId,
  memberId: ObjectId (ref: MemberDetails),
  companyId: String (unique: "COMP-timestamp"),
  
  // Company Details
  name: String (required),
  industry: String (required),
  description: String,
  mobile: String (required),
  area: String,
  location: String,
  logoUrl: String,
  
  // Statistics
  views: Number (default: 0),
  productsCount: Number (default: 0),
  
  // Status
  status: String (enum: ['active', 'inactive']),
  
  // Metadata
  createdAt: Date,
  updatedAt: Date
}
```

**Indexes:**
```javascript
{ memberId: 1, createdAt: -1 } // Get companies by member, sorted
{ companyId: 1 }               // Find company by company ID
{ status: 1 }                  // Filter by status
```

#### 3. ActivityLog Collection
**Purpose:** Track all business and company activities

**Schema:**
```javascript
{
  _id: ObjectId,
  memberId: ObjectId (required),
  companyId: ObjectId,
  
  // Activity Details
  activityType: String (enum: ['COMPANY_CREATED', 'PRODUCT_ADDED', ...]),
  description: String,
  metadata: Object,
  
  // Timestamp
  timestamp: Date (default: Date.now)
}
```

**Indexes:**
```javascript
{ companyId: 1, timestamp: -1 } // Recent activities for company
{ memberId: 1, timestamp: -1 }  // Recent activities for member
```

### Relationships

```
Member (MemberDetails)
  └─── Business Profile (MemberBusinessInfo) [1:1]
         └─── Companies (Company) [1:many]
                ├─── Products (Product) [1:many]
                ├─── Activity Logs (ActivityLog) [1:many]
                └─── Analytics (CompanyAnalytics) [1:1]
```

---

## API Endpoints

### Business Profile Endpoints

#### Create/Update Business Profile
```
POST /api/profile/business-info
```
**Request:**
```json
{
  "memberId": "string",
  "businessName": "string",
  "businessType": "string",
  "description": "string",
  "mobile": "string",
  "area": "string",
  "location": "string",
  "logoUrl": "string"
}
```

#### Get Business Profile
```
GET /api/profile/business-info/:memberId
```
**Response:**
```json
{
  "success": true,
  "data": {
    "businessInfo": { ... }
  }
}
```

### Company Endpoints

#### Create Company
```
POST /api/companies
```
**Request:**
```json
{
  "memberId": "string",
  "name": "string",
  "industry": "string",
  "description": "string",
  "mobile": "string",
  "area": "string",
  "location": "string"
}
```

#### Get All Companies for Member
```
GET /api/companies/member/:memberId
```
**Response:**
```json
{
  "success": true,
  "data": {
    "companies": [...]
  }
}
```

#### Get Single Company
```
GET /api/companies/:companyId
```

#### Update Company
```
PUT /api/companies/:companyId
```

#### Delete Company
```
DELETE /api/companies/:companyId
```

### Dashboard Endpoints

#### Get Company Stats
```
GET /api/dashboard/company-stats/:companyId
```
**Response:**
```json
{
  "success": true,
  "data": {
    "profileViews": 150,
    "productsCount": 12,
    "profileViewsChange": "+15%",
    "productsChange": "2 featured"
  }
}
```

#### Get Recent Activities
```
GET /api/dashboard/recent-activities/:companyId?limit=10
```
**Response:**
```json
{
  "success": true,
  "data": {
    "activities": [
      {
        "title": "Company created",
        "subtitle": "TechCorp Solutions",
        "timestamp": "2024-12-10T10:30:00Z",
        "icon": "business"
      }
    ]
  }
}
```

---

## Complete User Journey

### 1. Member Login ✅
User logs in as a member

### 2. Dashboard Access ✅
User sees member dashboard

### 3. Business Account Creation ✅
**Option A:** Click "Start Business Account" button
- Opens business profile creation form
- Fill in business details
- Save business profile
- Navigate to business dashboard

**Option B:** Member already has business profile
- Click "My Business" card
- Directly access business dashboard

### 4. Company Management ✅
From business dashboard:
- View existing companies
- Create new companies
- Edit company details
- Delete companies
- Switch between companies

### 5. Feature Access ✅
After company creation:
- Add products/services
- View analytics
- Browse other businesses
- Manage settings
- Track activities

---

## File Structure

```
lib/
├── screens/
│   ├── Member Bottom Navigation/
│   │   └── dashboard_screen.dart (Entry point)
│   └── Bussiness account/
│       ├── business_profile_screen.dart (Create business/company)
│       ├── businessaccount_dashboard_screen.dart (Main dashboard)
│       ├── business_profile_edit_screen.dart (Edit business)
│       ├── business_profile_view_screen.dart (View business)
│       ├── manage_companies_screen.dart (List all companies)
│       └── edit_company_screen.dart (Edit company)
├── services/
│   ├── business_profile_service.dart (Business API calls)
│   ├── company_service.dart (Company API calls)
│   └── dashboard_service.dart (Dashboard data)
├── models/
│   ├── business_profile_model.dart
│   └── company_model.dart
├── providers/
│   └── company_selection_provider.dart (State management)
└── widgets/
    └── company_switcher_widget.dart (Company dropdown)

activ-backend/
├── routes/
│   ├── business.js (Business profile routes)
│   ├── companies.js (Company routes)
│   ├── dashboard.js (Dashboard data routes)
│   └── profile.js (Member profile + business)
└── models/
    ├── MemberBusinessInfo.js (Business schema)
    ├── Company.js (Company schema)
    └── ActivityLog.js (Activity tracking)
```

---

## Conclusion

This workflow provides a complete end-to-end business account creation system that allows members to:
- Create a business profile
- Manage multiple companies
- Track activities and analytics
- Discover other businesses
- Manage products and services

The architecture is scalable, maintainable, and provides excellent user experience with real-time updates and smart caching.
