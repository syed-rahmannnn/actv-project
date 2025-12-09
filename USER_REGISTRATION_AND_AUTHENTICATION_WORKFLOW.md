# User Registration & Authentication Workflow

This document explains the complete workflow of user registration, data storage, and authentication in the ACTIV Chamber of Commerce application.

---

## Table of Contents

1. [Overview](#overview)
2. [Database Collections](#database-collections)
3. [Registration Workflow](#registration-workflow)
4. [Authentication Workflow](#authentication-workflow)
5. [Data Retrieval Flow](#data-retrieval-flow)
6. [Multi-Step Form Data Storage](#multi-step-form-data-storage)
7. [Application Approval Workflow](#application-approval-workflow)
8. [Payment & Membership Activation](#payment--membership-activation)
9. [Database Relationships](#database-relationships)
10. [Security Features](#security-features)

---

## Overview

The ACTIV application uses a **distributed data model** where user information is stored across multiple MongoDB collections:

- **MemberAuth**: Stores email and hashed password for authentication
- **MemberDetails**: Stores personal and location information
- **MemberBusinessInfo**: Stores business-related information
- **MemberFinancialInfo**: Stores financial and compliance data
- **MemberDeclaration**: Stores declaration and sister concern details
- **Application**: Stores application submission for approval workflow

All collections are linked using `memberId` (ObjectId reference).

---

## Database Collections

### 1. MemberAuth Collection

**Purpose**: Stores authentication credentials (email and password)

```javascript
{
  _id: ObjectId("..."),                    // Auto-generated MongoDB ID
  email: "user@example.com",               // Unique, lowercase email
  password: "$2a$10$...",                   // Bcrypt hashed password (cost factor: 10)
  isActive: true,                          // Account active status
  lastLogin: ISODate("2025-12-09T10:30:00Z"), // Last successful login
  createdAt: ISODate("2025-12-01T08:00:00Z"),
  updatedAt: ISODate("2025-12-09T10:30:00Z")
}
```

**Indexes**:
- Compound Index: `{ email: 1, isActive: 1 }` - Optimizes login queries

**Key Features**:
- Password is hashed using bcrypt with cost factor 10 (industry standard)
- Email is stored in lowercase for case-insensitive matching
- `comparePassword()` method for password verification
- `updateLastLogin()` method to track user activity

---

### 2. MemberDetails Collection

**Purpose**: Stores personal information and location data

```javascript
{
  _id: ObjectId("..."),                    // This is the memberId used everywhere
  fullName: "John Doe",                    // User's full name
  email: "user@example.com",               // Unique email (matches MemberAuth)
  phoneNumber: "+919876543210",            // Contact number
  
  // Location Information
  state: "Kerala",
  district: "Ernakulam",
  block: "Kochi",
  city: "Kochi",
  
  // Demographic Details (from Personal Details Form - Step 1)
  aadhaarNumber: "123456789012",           // 12-digit Aadhaar
  streetName: "MG Road",
  educationalQualification: "B.Tech",
  religion: "Christian",
  socialCategory: "Christian SC",          // Enum: ['Christian SC', 'ST', 'Christian ST', 'Other']
  
  // Profile Status
  profileCompleted: false,                 // true after all 4 steps completed
  
  // Approval Information (set by admins)
  approvedBy: "admin@activ.com",
  approvedBlock: "Kochi",
  approvedAt: ISODate("2025-12-05T12:00:00Z"),
  
  // Membership Information (set after payment)
  membershipStatus: "pending",             // Enum: ['pending', 'active', 'expired', 'cancelled']
  membershipType: "none",                  // Enum: ['annual', 'lifetime', 'none']
  membershipActivatedAt: null,
  membershipExpiresAt: null,
  
  // Payment Information
  paymentId: "pay_abc123",                 // Razorpay payment ID
  paymentAmount: 3000,                     // Amount paid (in rupees)
  lastPaymentDate: ISODate("2025-12-06T09:00:00Z"),
  
  createdAt: ISODate("2025-12-01T08:00:00Z"),
  updatedAt: ISODate("2025-12-09T10:30:00Z")
}
```

**Indexes**:
- Unique Index: `email` (automatically created)
- Index: `phoneNumber`

**Key Features**:
- This is the **main collection** - its `_id` is used as `memberId` everywhere
- Contains demographic data from Step 1 (Personal Details Form)
- Tracks approval workflow and admin actions
- Manages membership lifecycle and payment tracking

---

### 3. MemberBusinessInfo Collection

**Purpose**: Stores business-related information (from Step 2)

```javascript
{
  _id: ObjectId("..."),
  memberId: ObjectId("..."),               // References MemberDetails._id
  
  // Required duplicate fields for data integrity
  fullName: "John Doe",
  email: "user@example.com",
  
  // Business Information (from Business Information Form - Step 2)
  doingBusiness: true,                     // false for Aspirants (students/non-business)
  organizationName: "ABC Traders",
  constitutionType: "OPC",                 // Enum: ['OPC', 'TRUST', 'SOCIETY']
  businessType: "Trader",                  // Enum: ['Manufacturing', 'Trader', 'Service Provider', 'Others']
  businessActivities: "Import and export of textiles",
  businessCommencementYear: "2020",
  numberOfEmployees: "15",
  
  // Chamber Membership
  memberOfOtherChamber: false,
  otherChamber: "",
  
  // Government Registration
  registeredWithGovtOrganization: ["MSME", "KVIC"], // Array of enums
  
  // Additional Business Profile Fields
  mobile: "+919876543210",
  area: "Edappally",
  location: "Kochi, Kerala",
  businessDescription: "Leading textile trader",
  businessWebsite: "https://abctraders.com",
  logoUrl: "https://...",
  
  // Status
  status: "UNDER_REVIEW",                  // Enum: ['UNDER_REVIEW', 'APPROVED', 'ACTIVE', 'REJECTED', 'PENDING']
  
  createdAt: ISODate("2025-12-01T08:15:00Z"),
  updatedAt: ISODate("2025-12-01T08:15:00Z")
}
```

**Indexes**:
- Index: `memberId`

**Key Features**:
- Linked to MemberDetails via `memberId`
- Contains all business-related fields from Step 2
- **Aspirant members** (students/non-business) have `doingBusiness: false`
- Aspirants skip Steps 3 & 4 and submit directly after Step 2

---

### 4. MemberFinancialInfo Collection

**Purpose**: Stores financial and compliance information (from Step 3)

```javascript
{
  _id: ObjectId("..."),
  memberId: ObjectId("..."),               // References MemberDetails._id
  
  // Required duplicate fields
  fullName: "John Doe",
  email: "user@example.com",
  
  // Tax & Compliance (from Financial Compliance Form - Step 3)
  panNumber: "ABCDE1234F",                 // 10-char alphanumeric (validated)
  gstNumber: "22ABCDE1234F1Z5",            // 15-char GST format (validated)
  udyamNumber: "UDYAM-KL-00-1234567",
  
  // ITR Filing
  filedITR: true,
  itrYears: "5",                           // Only if filedITR = true
  
  // Turnover Information
  turnoverRange: "1 Crore - 5 Crores",     // Dropdown selection
  fy2021: "4500000",                       // FY 2021-22 turnover
  fy2020: "4000000",                       // FY 2020-21 turnover
  fy2019: "3500000",                       // FY 2019-20 turnover
  
  // Government Schemes
  govtSchemeBenefit: true,
  scheme1: "PMEGP",                        // Only if govtSchemeBenefit = true
  scheme2: "Credit Linked Capital Subsidy",
  scheme3: "Stand-Up India",
  
  createdAt: ISODate("2025-12-01T08:20:00Z"),
  updatedAt: ISODate("2025-12-01T08:20:00Z")
}
```

**Indexes**:
- Index: `memberId`

**Key Features**:
- Conditional fields based on `filedITR` and `govtSchemeBenefit`
- PAN and GST validation at application level
- Only for Company members (Aspirants skip this step)

---

### 5. MemberDeclaration Collection

**Purpose**: Stores declaration and final submission data (from Step 4)

```javascript
{
  _id: ObjectId("..."),
  memberId: ObjectId("..."),               // References MemberDetails._id
  
  // Required duplicate fields
  fullName: "John Doe",
  email: "user@example.com",
  
  // Sister Concerns (from Declaration Form - Step 4)
  sisterConcerns: 2,                       // Number of sister companies
  companyNames: [                          // Array of company names
    "XYZ Enterprises",
    "DEF Trading Co."
  ],
  showOneFieldPerName: true,
  
  // Declaration Agreement
  agreeToDeclaration: true,                // Required: Must be true to submit
  profileCompleted: true,                  // Set to true after Step 4
  submissionDate: ISODate("2025-12-01T08:25:00Z"),
  
  // Review Status
  status: "pending",                       // Enum: ['pending', 'under_review', 'approved', 'rejected']
  reviewNotes: "",
  reviewedBy: null,
  reviewedAt: null,
  
  createdAt: ISODate("2025-12-01T08:25:00Z"),
  updatedAt: ISODate("2025-12-01T08:25:00Z")
}
```

**Indexes**:
- Index: `memberId`
- Index: `status`

**Key Features**:
- Final step of registration (Step 4)
- Declaration agreement is **mandatory**
- Sets `profileCompleted: true` in MemberDetails
- Only for Company members (Aspirants skip this step)

---

### 6. Application Collection

**Purpose**: Manages the approval workflow (Block → District → State admins)

```javascript
{
  _id: ObjectId("..."),
  userId: ObjectId("..."),                 // Same as MemberDetails._id
  
  // User Information
  fullName: "John Doe",
  email: "user@example.com",
  phone: "+919876543210",
  state: "Kerala",
  district: "Ernakulam",
  block: "Kochi",
  
  // Form Data (aggregated from all 4 steps)
  formData: {
    // Step 1: Personal Details
    personalDetails: {
      fullName: "John Doe",
      aadhaarNumber: "123456789012",
      streetName: "MG Road",
      educationalQualification: "B.Tech",
      religion: "Christian",
      socialCategory: "Christian SC"
    },
    // Step 2: Business Information
    businessInfo: {
      doingBusiness: true,
      organizationName: "ABC Traders",
      constitutionType: "OPC",
      businessTypes: ["Trader"],
      businessActivities: "Import/export of textiles",
      numberOfEmployees: "15"
    },
    // Step 3: Financial Compliance
    financialInfo: {
      panNumber: "ABCDE1234F",
      gstNumber: "22ABCDE1234F1Z5",
      filedITR: true,
      itrYears: "5",
      turnoverRange: "1 Crore - 5 Crores"
    },
    // Step 4: Declaration
    declaration: {
      sisterConcerns: 2,
      companyNames: ["XYZ Enterprises", "DEF Trading Co."],
      agreeToDeclaration: true
    }
  },
  
  // Approval Workflow
  status: "Pending-Block",                 // Enum: ['PENDING', 'Pending-Block', 'Pending-District', 'Pending-State', 'Approved', 'Rejected']
  
  // Admin Assignments
  assignedBlockAdmin: ObjectId("..."),
  assignedDistrictAdmin: ObjectId("..."),
  assignedStateAdmin: ObjectId("..."),
  
  // Approval Tracking
  blockApprovedAt: ISODate("2025-12-02T10:00:00Z"),
  districtApprovedAt: ISODate("2025-12-03T11:00:00Z"),
  stateApprovedAt: ISODate("2025-12-04T14:00:00Z"),
  
  // Reviewed By
  reviewedBy: {
    blockAdmin: ObjectId("..."),
    districtAdmin: ObjectId("..."),
    stateAdmin: ObjectId("...")
  },
  
  // Rejection (if applicable)
  rejectionReason: null,
  
  createdAt: ISODate("2025-12-01T08:25:00Z"),
  updatedAt: ISODate("2025-12-04T14:00:00Z")
}
```

**Indexes**:
- Index: `userId`
- Compound Indexes:
  - `{ assignedBlockAdmin: 1, status: 1 }`
  - `{ assignedDistrictAdmin: 1, status: 1 }`
  - `{ assignedStateAdmin: 1, status: 1 }`
- Index: `status`

**Key Features**:
- Contains **all form data** from Steps 1-4
- 3-tier approval workflow (Block → District → State)
- Auto-assigned to admins based on location
- Tracks approval timestamps and reviewing admins

---

## Registration Workflow

### Step-by-Step Process

```
┌─────────────────────────────────────────────────────────────────────┐
│                        1. USER REGISTRATION                          │
└─────────────────────────────────────────────────────────────────────┘

User opens app → Registration Screen

┌──────────────────────────────────────────┐
│  Registration Form (Initial)             │
│  ─────────────────────────────────       │
│  • Full Name                             │
│  • Email                                 │
│  • Phone Number                          │
│  • Password                              │
│  • State                                 │
│  • District                              │
│  • Block                                 │
│  • City                                  │
│                                          │
│  [Register Button]                       │
└──────────────────────────────────────────┘
            ↓
            ↓ POST /api/auth/register
            ↓
┌──────────────────────────────────────────────────────────────────┐
│  Backend Processing                                               │
│  ───────────────────                                             │
│                                                                   │
│  1. Check if email already exists in MemberDetails               │
│     → If exists: Return 409 error "Email already exists"         │
│                                                                   │
│  2. Create MemberDetails document                                │
│     Collection: memberdetails                                    │
│     ┌────────────────────────────────────────┐                  │
│     │ _id: ObjectId("674d1a2b...")           │                  │
│     │ fullName: "John Doe"                   │                  │
│     │ email: "user@example.com"              │                  │
│     │ phoneNumber: "+919876543210"           │                  │
│     │ state: "Kerala"                        │                  │
│     │ district: "Ernakulam"                  │                  │
│     │ block: "Kochi"                         │                  │
│     │ city: "Kochi"                          │                  │
│     │ profileCompleted: false                │                  │
│     │ membershipStatus: "pending"            │                  │
│     │ createdAt: ISODate(...)                │                  │
│     └────────────────────────────────────────┘                  │
│                                                                   │
│  3. Create MemberAuth document (if password provided)            │
│     Collection: memberauths                                      │
│     ┌────────────────────────────────────────┐                  │
│     │ _id: ObjectId("674d1a2c...")           │                  │
│     │ email: "user@example.com"              │                  │
│     │ password: "$2a$10$..." (hashed)        │                  │
│     │ isActive: true                         │                  │
│     │ lastLogin: null                        │                  │
│     │ createdAt: ISODate(...)                │                  │
│     └────────────────────────────────────────┘                  │
│                                                                   │
│  4. Generate JWT Token                                           │
│     Payload: { userId: memberId, email: email }                 │
│     Secret: process.env.JWTSECRET                               │
│     Expiry: 24 hours                                             │
│                                                                   │
│  5. Return Response                                              │
│     {                                                            │
│       success: true,                                             │
│       message: "Registration successful",                        │
│       data: {                                                    │
│         token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",       │
│         member: {                                                │
│           id: "674d1a2b...",                                     │
│           memberId: "674d1a2b...",                               │
│           fullName: "John Doe",                                  │
│           email: "user@example.com",                             │
│           phoneNumber: "+919876543210",                          │
│           state: "Kerala",                                       │
│           district: "Ernakulam",                                 │
│           block: "Kochi",                                        │
│           city: "Kochi",                                         │
│           profileCompleted: false                                │
│         }                                                        │
│       }                                                          │
│     }                                                            │
└──────────────────────────────────────────────────────────────────┘
            ↓
            ↓ Return to App
            ↓
┌──────────────────────────────────────────┐
│  App receives response                   │
│  • Store JWT token in secure storage     │
│  • Store user data in local state        │
│  • Navigate to Additional Details Form   │
└──────────────────────────────────────────┘
```

---

## Authentication Workflow

### Login Process

```
┌─────────────────────────────────────────────────────────────────────┐
│                        2. USER LOGIN                                 │
└─────────────────────────────────────────────────────────────────────┘

User opens app → Login Screen

┌──────────────────────────────────────────┐
│  Login Form                              │
│  ──────────                              │
│  • Email: user@example.com               │
│  • Password: ••••••••                    │
│                                          │
│  [Login Button]                          │
└──────────────────────────────────────────┘
            ↓
            ↓ POST /api/auth/login
            ↓
┌──────────────────────────────────────────────────────────────────┐
│  Backend Processing                                               │
│  ───────────────────                                             │
│                                                                   │
│  1. Validate Input                                               │
│     • Email is provided and valid                                │
│     • Password is provided                                       │
│                                                                   │
│  2. Normalize Email                                              │
│     email = "user@example.com".toLowerCase()                     │
│     → "user@example.com"                                         │
│                                                                   │
│  3. PARALLEL DATABASE QUERIES (Optimized)                        │
│     Execute simultaneously:                                      │
│                                                                   │
│     Query 1: Find MemberDetails                                  │
│     ┌─────────────────────────────────────────┐                 │
│     │ MemberDetails.findOne({                 │                 │
│     │   email: "user@example.com"             │                 │
│     │ })                                      │                 │
│     │ .select('_id fullName email             │                 │
│     │          phoneNumber state district     │                 │
│     │          block city profileCompleted')  │                 │
│     │ .lean()                                 │                 │
│     └─────────────────────────────────────────┘                 │
│                                                                   │
│     Query 2: Find MemberAuth                                     │
│     ┌─────────────────────────────────────────┐                 │
│     │ MemberAuth.findOne({                    │                 │
│     │   email: "user@example.com"             │                 │
│     │ })                                      │                 │
│     │ .select('email password isActive')      │                 │
│     └─────────────────────────────────────────┘                 │
│                                                                   │
│  4. Check Member Exists                                          │
│     If NOT found in MemberDetails:                               │
│     → Return 404 "Member not found"                              │
│                                                                   │
│  5. Check Auth Record                                            │
│     If NOT found in MemberAuth OR isActive = false:              │
│     → Return 403 "Account is inactive or not found"              │
│                                                                   │
│  6. Verify Password                                              │
│     ┌─────────────────────────────────────────┐                 │
│     │ memberAuth.comparePassword(password)    │                 │
│     │ → bcrypt.compare(plaintext, hashed)     │                 │
│     └─────────────────────────────────────────┘                 │
│                                                                   │
│     If password doesn't match:                                   │
│     → Return 401 "Invalid password"                              │
│                                                                   │
│  7. Generate JWT Token                                           │
│     ┌─────────────────────────────────────────┐                 │
│     │ jwt.sign({                              │                 │
│     │   userId: member._id,                   │                 │
│     │   email: member.email                   │                 │
│     │ }, process.env.JWTSECRET, {             │                 │
│     │   expiresIn: '24h'                      │                 │
│     │ })                                      │                 │
│     └─────────────────────────────────────────┘                 │
│                                                                   │
│  8. Update Last Login (Asynchronously)                           │
│     memberAuth.lastLogin = new Date()                            │
│     memberAuth.save()                                            │
│                                                                   │
│  9. Return Success Response                                      │
│     {                                                            │
│       success: true,                                             │
│       message: "Login successful",                               │
│       data: {                                                    │
│         token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",       │
│         member: {                                                │
│           id: "674d1a2b...",                                     │
│           memberId: "674d1a2b...",                               │
│           fullName: "John Doe",                                  │
│           email: "user@example.com",                             │
│           phoneNumber: "+919876543210",                          │
│           state: "Kerala",                                       │
│           district: "Ernakulam",                                 │
│           block: "Kochi",                                        │
│           city: "Kochi",                                         │
│           profileCompleted: false                                │
│         }                                                        │
│       }                                                          │
│     }                                                            │
└──────────────────────────────────────────────────────────────────┘
            ↓
            ↓ Return to App
            ↓
┌──────────────────────────────────────────┐
│  App receives response                   │
│  • Store JWT token in secure storage     │
│  • Store user data in local state        │
│  • Check profileCompleted status         │
│    → If false: Navigate to Form Step 1   │
│    → If true: Navigate to Dashboard      │
└──────────────────────────────────────────┘
```

### Performance Optimization

The login API is optimized for speed:

1. **Parallel Queries**: MemberDetails and MemberAuth are fetched simultaneously
2. **Field Selection**: Only required fields are retrieved (`.select()`)
3. **Lean Queries**: For read-only data, `.lean()` returns plain JavaScript objects
4. **Async Last Login Update**: Non-blocking operation
5. **Bcrypt Cost Factor 10**: Industry standard, 75% faster than cost 12
6. **Compound Index**: `{ email: 1, isActive: 1 }` on MemberAuth

**Typical Response Time**: 50-150ms

---

## Data Retrieval Flow

### How Email & Password Fetch User Data

When a user logs in with email and password, here's how all their data is retrieved:

```
┌─────────────────────────────────────────────────────────────────────┐
│              DATA RETRIEVAL AFTER SUCCESSFUL LOGIN                   │
└─────────────────────────────────────────────────────────────────────┘

Login returns: memberId (e.g., "674d1a2b...")

┌──────────────────────────────────────────────────────────────────┐
│  Using memberId to fetch all related data                         │
│  ─────────────────────────────────────                           │
│                                                                   │
│  1. MemberDetails (Already fetched during login)                 │
│     GET /api/auth/member/:memberId                               │
│     ↓                                                             │
│     Returns: Personal info, location, membership status          │
│                                                                   │
│  2. MemberBusinessInfo (if exists)                               │
│     GET /api/business/:memberId                                  │
│     ↓                                                             │
│     ┌─────────────────────────────────────────┐                 │
│     │ MemberBusinessInfo.findOne({            │                 │
│     │   memberId: "674d1a2b..."               │                 │
│     │ })                                      │                 │
│     └─────────────────────────────────────────┘                 │
│     ↓                                                             │
│     Returns: Business details from Step 2                        │
│                                                                   │
│  3. MemberFinancialInfo (if exists)                              │
│     GET /api/financial/:memberId                                 │
│     ↓                                                             │
│     ┌─────────────────────────────────────────┐                 │
│     │ MemberFinancialInfo.findOne({           │                 │
│     │   memberId: "674d1a2b..."               │                 │
│     │ })                                      │                 │
│     └─────────────────────────────────────────┘                 │
│     ↓                                                             │
│     Returns: Financial info from Step 3                          │
│                                                                   │
│  4. MemberDeclaration (if exists)                                │
│     GET /api/declaration/:memberId                               │
│     ↓                                                             │
│     ┌─────────────────────────────────────────┐                 │
│     │ MemberDeclaration.findOne({             │                 │
│     │   memberId: "674d1a2b..."               │                 │
│     │ })                                      │                 │
│     └─────────────────────────────────────────┘                 │
│     ↓                                                             │
│     Returns: Declaration from Step 4                             │
│                                                                   │
│  5. Application (if submitted)                                   │
│     GET /api/applications/user/:memberId                         │
│     ↓                                                             │
│     ┌─────────────────────────────────────────┐                 │
│     │ Application.findOne({                   │                 │
│     │   userId: "674d1a2b..."                 │                 │
│     │ })                                      │                 │
│     └─────────────────────────────────────────┘                 │
│     ↓                                                             │
│     Returns: Application status and approval details             │
│                                                                   │
└──────────────────────────────────────────────────────────────────┘

All data is linked through memberId (MemberDetails._id)
```

### Alternative Retrieval: By Email

```javascript
// Get member by email
GET /api/auth/member-by-email/:email

// Backend Query
const member = await MemberDetails.findOne({ 
  email: email.toLowerCase() 
});

// Then use member._id as memberId to fetch related data
const businessInfo = await MemberBusinessInfo.findOne({ 
  memberId: member._id 
});
const financialInfo = await MemberFinancialInfo.findOne({ 
  memberId: member._id 
});
const declaration = await MemberDeclaration.findOne({ 
  memberId: member._id 
});
const application = await Application.findOne({ 
  userId: member._id 
});
```

---

## Multi-Step Form Data Storage

### Complete Form Submission Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                  MULTI-STEP FORM DATA STORAGE                        │
└─────────────────────────────────────────────────────────────────────┘

User completes registration → Navigates to Additional Details Forms

┌───────────────────────────────────────────────────────────────────┐
│  STEP 1: Personal Details Form                                     │
│  ──────────────────────────                                       │
│  • Aadhaar Number                                                  │
│  • Street Name                                                     │
│  • Educational Qualification                                       │
│  • Religion                                                        │
│  • Social Category                                                 │
│  • Password Change (optional)                                      │
│                                                                     │
│  [Next Button]                                                     │
└───────────────────────────────────────────────────────────────────┘
            ↓
            ↓ PUT /api/members/:memberId (auto-save every 2 seconds)
            ↓
┌───────────────────────────────────────────────────────────────────┐
│  Updates MemberDetails Collection                                  │
│  ─────────────────────────────────                                │
│  • aadhaarNumber: "123456789012"                                   │
│  • streetName: "MG Road"                                           │
│  • educationalQualification: "B.Tech"                              │
│  • religion: "Christian"                                           │
│  • socialCategory: "Christian SC"                                  │
│                                                                     │
│  If password provided:                                             │
│  Updates MemberAuth Collection                                     │
│  • password: (new hashed password)                                 │
│  • updatedAt: current timestamp                                    │
└───────────────────────────────────────────────────────────────────┘
            ↓
            ↓ Navigate to Step 2
            ↓
┌───────────────────────────────────────────────────────────────────┐
│  STEP 2: Business Information Form                                 │
│  ─────────────────────────────────                                │
│  • Doing Business? (Yes/No)                                        │
│                                                                     │
│  If YES (Company Member):                                          │
│    • Organization Name                                             │
│    • Constitution Type                                             │
│    • Business Types (multi-select)                                 │
│    • Business Activities                                           │
│    • Number of Employees                                           │
│    • Member of Other Chamber                                       │
│    • Government Organizations                                      │
│    [Next Button] → Proceed to Step 3                               │
│                                                                     │
│  If NO (Aspirant - Student/Non-Business):                          │
│    [Submit Button] → Skip Steps 3 & 4, submit directly             │
└───────────────────────────────────────────────────────────────────┘
            ↓
            ↓ POST /api/business/:memberId (auto-save every 2 seconds)
            ↓
┌───────────────────────────────────────────────────────────────────┐
│  Creates/Updates MemberBusinessInfo Collection                     │
│  ──────────────────────────────────────────                       │
│  • memberId: "674d1a2b..."                                         │
│  • fullName: "John Doe"                                            │
│  • email: "user@example.com"                                       │
│  • doingBusiness: true                                             │
│  • organizationName: "ABC Traders"                                 │
│  • constitutionType: "OPC"                                         │
│  • businessType: "Trader"                                          │
│  • businessActivities: "Import/export"                             │
│  • numberOfEmployees: "15"                                         │
│  • registeredWithGovtOrganization: ["MSME"]                        │
└───────────────────────────────────────────────────────────────────┘
            ↓
            ↓ If doingBusiness = true → Navigate to Step 3
            ↓ If doingBusiness = false → Submit Application
            ↓
┌───────────────────────────────────────────────────────────────────┐
│  STEP 3: Financial Compliance Form (Company Members Only)          │
│  ───────────────────────────────────────────────                  │
│  • PAN Number                                                      │
│  • GST Number                                                      │
│  • Udyam Number                                                    │
│  • Filed ITR? (Yes/No)                                             │
│    → If Yes: ITR Years                                             │
│  • Turnover Range                                                  │
│  • FY 2021-22, 2020-21, 2019-20 Turnover                           │
│  • Government Scheme Benefit? (Yes/No)                             │
│    → If Yes: Scheme 1, Scheme 2, Scheme 3                          │
│                                                                     │
│  [Next Button]                                                     │
└───────────────────────────────────────────────────────────────────┘
            ↓
            ↓ POST /api/financial/:memberId (auto-save every 2 seconds)
            ↓
┌───────────────────────────────────────────────────────────────────┐
│  Creates/Updates MemberFinancialInfo Collection                    │
│  ───────────────────────────────────────────                      │
│  • memberId: "674d1a2b..."                                         │
│  • fullName: "John Doe"                                            │
│  • email: "user@example.com"                                       │
│  • panNumber: "ABCDE1234F"                                         │
│  • gstNumber: "22ABCDE1234F1Z5"                                    │
│  • filedITR: true                                                  │
│  • itrYears: "5"                                                   │
│  • turnoverRange: "1 Crore - 5 Crores"                             │
│  • fy2021: "4500000"                                               │
│  • govtSchemeBenefit: true                                         │
│  • scheme1: "PMEGP"                                                │
└───────────────────────────────────────────────────────────────────┘
            ↓
            ↓ Navigate to Step 4
            ↓
┌───────────────────────────────────────────────────────────────────┐
│  STEP 4: Declaration Form (Company Members Only)                   │
│  ──────────────────────────────                                   │
│  • No. of Sister Concerns                                          │
│  • Company Names (multi-line)                                      │
│  • [Add Another Company Button]                                    │
│  • Show one field per name (checkbox)                              │
│  • Declaration Agreement (checkbox - REQUIRED)                     │
│                                                                     │
│  [Submit Application Button]                                       │
└───────────────────────────────────────────────────────────────────┘
            ↓
            ↓ POST /api/declaration/:memberId
            ↓ POST /api/applications/submit
            ↓
┌───────────────────────────────────────────────────────────────────┐
│  1. Creates/Updates MemberDeclaration Collection                   │
│     ─────────────────────────────────────────                     │
│     • memberId: "674d1a2b..."                                      │
│     • fullName: "John Doe"                                         │
│     • email: "user@example.com"                                    │
│     • sisterConcerns: 2                                            │
│     • companyNames: ["XYZ Enterprises", "DEF Trading"]             │
│     • agreeToDeclaration: true                                     │
│     • profileCompleted: true                                       │
│     • submissionDate: ISODate(...)                                 │
│                                                                     │
│  2. Updates MemberDetails                                          │
│     ─────────────────────                                         │
│     • profileCompleted: true                                       │
│                                                                     │
│  3. Creates Application Document                                   │
│     ────────────────────────────                                  │
│     • userId: "674d1a2b..."                                        │
│     • fullName: "John Doe"                                         │
│     • email: "user@example.com"                                    │
│     • state: "Kerala"                                              │
│     • district: "Ernakulam"                                        │
│     • block: "Kochi"                                               │
│     • formData: {                                                  │
│         personalDetails: {...},                                    │
│         businessInfo: {...},                                       │
│         financialInfo: {...},                                      │
│         declaration: {...}                                         │
│       }                                                            │
│     • status: "Pending-Block"                                      │
│     • assignedBlockAdmin: (auto-assigned)                          │
│                                                                     │
│  4. Auto-assign to Block Admin                                     │
│     Based on member's block location                               │
└───────────────────────────────────────────────────────────────────┘
            ↓
            ↓ Navigate to Application Submitted Screen
            ↓
┌───────────────────────────────────────────────────────────────────┐
│  Application Submitted Successfully!                               │
│  ───────────────────────────────────                              │
│  Your application is under review.                                 │
│  Current Status: Pending Block Approval                            │
│                                                                     │
│  You will be notified once approved.                               │
└───────────────────────────────────────────────────────────────────┘
```

### Auto-Save Feature

Each form implements **auto-save with 2-second debounce**:

```typescript
// Auto-save implementation
const autoSaveData = debounce(async () => {
  if (isSaving) return;
  
  setIsSaving(true);
  
  try {
    // Get memberId from userData or fetch from backend
    let memberId = userData.memberId;
    
    if (!memberId) {
      const response = await ApiService.getMemberByEmail(email);
      memberId = response.data.memberId;
    }
    
    // Save to respective collection
    await ApiService.updateMemberDetails(memberId, formData);
    
    console.log('✓ Auto-saved');
  } catch (error) {
    console.error('Auto-save failed:', error);
  } finally {
    setIsSaving(false);
  }
}, 2000); // 2-second debounce

// Trigger on field change
useEffect(() => {
  autoSaveData();
}, [formData]);
```

---

## Application Approval Workflow

### 3-Tier Approval System

```
┌─────────────────────────────────────────────────────────────────────┐
│                   APPLICATION APPROVAL WORKFLOW                      │
└─────────────────────────────────────────────────────────────────────┘

Application Submitted → status: "Pending-Block"

┌───────────────────────────────────────────────────────────────────┐
│  TIER 1: Block Admin Approval                                      │
│  ──────────────────────────                                       │
│  • Application auto-assigned to Block Admin (based on location)    │
│  • Block Admin reviews application                                 │
│  • Block Admin can:                                                 │
│    ✓ APPROVE → Move to District Admin                              │
│    ✗ REJECT → Application rejected (with reason)                   │
│                                                                     │
│  If Approved:                                                       │
│  • status: "Pending-Block" → "Pending-District"                    │
│  • blockApprovedAt: current timestamp                              │
│  • reviewedBy.blockAdmin: blockAdminId                             │
│  • Auto-assign to District Admin                                   │
└───────────────────────────────────────────────────────────────────┘
            ↓
            ↓ Application moves to District Admin
            ↓
┌───────────────────────────────────────────────────────────────────┐
│  TIER 2: District Admin Approval                                   │
│  ─────────────────────────────                                    │
│  • Application auto-assigned to District Admin                     │
│  • District Admin reviews application                              │
│  • District Admin can:                                             │
│    ✓ APPROVE → Move to State Admin                                 │
│    ✗ REJECT → Application rejected (with reason)                   │
│                                                                     │
│  If Approved:                                                       │
│  • status: "Pending-District" → "Pending-State"                    │
│  • districtApprovedAt: current timestamp                           │
│  • reviewedBy.districtAdmin: districtAdminId                       │
│  • Auto-assign to State Admin                                      │
└───────────────────────────────────────────────────────────────────┘
            ↓
            ↓ Application moves to State Admin
            ↓
┌───────────────────────────────────────────────────────────────────┐
│  TIER 3: State Admin Approval (Final)                              │
│  ──────────────────────────────────                               │
│  • Application auto-assigned to State Admin                        │
│  • State Admin reviews application                                 │
│  • State Admin can:                                                 │
│    ✓ APPROVE → Application approved (final)                        │
│    ✗ REJECT → Application rejected (with reason)                   │
│                                                                     │
│  If Approved:                                                       │
│  • status: "Pending-State" → "Approved"                            │
│  • stateApprovedAt: current timestamp                              │
│  • reviewedBy.stateAdmin: stateAdminId                             │
│  • Update MemberDetails:                                           │
│    - approvedBy: stateAdmin email                                  │
│    - approvedBlock: member's block                                 │
│    - approvedAt: current timestamp                                 │
│  • Member notified of approval                                     │
│  • Member can now proceed to payment                               │
└───────────────────────────────────────────────────────────────────┘
            ↓
            ↓ Application approved
            ↓
┌───────────────────────────────────────────────────────────────────┐
│  Member Dashboard                                                  │
│  ────────────────                                                 │
│  Status: Approved ✓                                                │
│  Approved on: Dec 4, 2025                                          │
│                                                                     │
│  Next Step: Make Payment                                           │
│  • Annual Membership: ₹3,000                                       │
│  • Lifetime Membership: ₹15,000                                    │
│                                                                     │
│  [Proceed to Payment]                                              │
└───────────────────────────────────────────────────────────────────┘
```

### Rejection Workflow

```
If any admin REJECTS the application:

┌───────────────────────────────────────────────────────────────────┐
│  Application Rejected                                              │
│  ──────────────────                                               │
│  • status: (current) → "Rejected"                                  │
│  • rejectionReason: "Incomplete business documents"                │
│  • Member notified via email/notification                          │
│  • Member can view rejection reason in dashboard                   │
│  • Member may need to resubmit with corrections                    │
└───────────────────────────────────────────────────────────────────┘
```

---

## Payment & Membership Activation

### Payment Integration (Razorpay)

```
┌─────────────────────────────────────────────────────────────────────┐
│                    PAYMENT & MEMBERSHIP ACTIVATION                   │
└─────────────────────────────────────────────────────────────────────┘

Application Approved → Member proceeds to payment

┌───────────────────────────────────────────────────────────────────┐
│  Payment Screen                                                    │
│  ──────────────                                                   │
│  Select Membership Plan:                                           │
│  ○ Annual (₹3,000) - Valid for 1 year                             │
│  ● Lifetime (₹15,000) - Valid forever                             │
│                                                                     │
│  [Pay with Razorpay]                                               │
└───────────────────────────────────────────────────────────────────┘
            ↓
            ↓ Initiate Razorpay payment
            ↓
┌───────────────────────────────────────────────────────────────────┐
│  Razorpay Payment Gateway                                          │
│  ────────────────────────                                         │
│  • User enters card/UPI details                                    │
│  • Payment processed                                               │
│  • Razorpay returns payment_id                                     │
└───────────────────────────────────────────────────────────────────┘
            ↓
            ↓ POST /api/webhook/payment (Razorpay webhook)
            ↓
┌───────────────────────────────────────────────────────────────────┐
│  Payment Verification & Membership Activation                      │
│  ───────────────────────────────────────────                      │
│  1. Verify payment with Razorpay                                   │
│     • Check payment_id signature                                   │
│     • Verify payment status = "captured"                           │
│                                                                     │
│  2. Update MemberDetails                                           │
│     ┌─────────────────────────────────────────┐                  │
│     │ • paymentId: "pay_abc123"               │                  │
│     │ • paymentAmount: 15000                  │                  │
│     │ • lastPaymentDate: ISODate(...)         │                  │
│     │ • membershipStatus: "active"            │                  │
│     │ • membershipType: "lifetime"            │                  │
│     │ • membershipActivatedAt: ISODate(...)   │                  │
│     │ • membershipExpiresAt: null (lifetime)  │                  │
│     └─────────────────────────────────────────┘                  │
│                                                                     │
│  3. Generate Membership ID                                         │
│     Format: ACTV-KL-EKM-2025-0001                                 │
│     (State-District-Year-Sequence)                                 │
│                                                                     │
│  4. Send Confirmation Email                                        │
│     • Membership certificate                                       │
│     • Payment receipt                                              │
│     • Welcome message                                              │
│                                                                     │
│  5. Send Push Notification                                         │
│     "Congratulations! Your membership is now active."              │
└───────────────────────────────────────────────────────────────────┘
            ↓
            ↓ Return to App
            ↓
┌───────────────────────────────────────────────────────────────────┐
│  Member Dashboard - ACTIVE MEMBER                                  │
│  ──────────────────────────────                                   │
│  Status: ACTIVE ✓                                                  │
│  Membership ID: ACTV-KL-EKM-2025-0001                             │
│  Type: Lifetime                                                    │
│  Activated: Dec 6, 2025                                            │
│                                                                     │
│  Access to:                                                        │
│  • Browse Members                                                  │
│  • Discover Activities                                             │
│  • View Products                                                   │
│  • Notifications                                                   │
│  • Business Profile                                                │
└───────────────────────────────────────────────────────────────────┘
```

### Membership Expiry (Annual Members)

```
For Annual Members:
┌───────────────────────────────────────────────────────────────────┐
│  Membership Expiry Check (Daily Cron Job)                          │
│  ──────────────────────────────────────                           │
│  • Check all members with membershipType = "annual"                │
│  • If membershipExpiresAt < current date:                          │
│    - membershipStatus: "active" → "expired"                        │
│    - Send renewal notification                                     │
│    - Restrict access to member features                            │
│                                                                     │
│  Member must renew:                                                │
│  • Pay ₹3,000 for annual renewal                                   │
│  • Or upgrade to lifetime (₹12,000 difference)                     │
└───────────────────────────────────────────────────────────────────┘
```

---

## Database Relationships

### Entity Relationship Diagram

```
┌─────────────────────┐
│   MemberAuth        │
│ ─────────────────── │
│ _id (PK)            │
│ email (UNIQUE)      │◄──────────┐
│ password (hashed)   │           │
│ isActive            │           │
│ lastLogin           │           │
└─────────────────────┘           │
                                  │
                                  │ (email match)
                                  │
┌─────────────────────┐           │
│  MemberDetails      │           │
│ ─────────────────── │           │
│ _id (PK) ◄──────────┼───────────┼─── This is the memberId
│ email (UNIQUE)      │───────────┘
│ fullName            │
│ phoneNumber         │
│ state, district     │
│ block, city         │
│ aadhaarNumber       │
│ profileCompleted    │
│ membershipStatus    │
└─────────────────────┘
         │
         │ memberId (FK)
         │
         ├──────────────────┬──────────────────┬──────────────────┐
         │                  │                  │                  │
         ▼                  ▼                  ▼                  ▼
┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐
│ MemberBusinessInfo│ │MemberFinancialInfo│ │ MemberDeclaration│ │   Application    │
│ ────────────────│ │ ────────────────│ │ ────────────────│ │ ────────────────│
│ _id (PK)         │ │ _id (PK)         │ │ _id (PK)         │ │ _id (PK)         │
│ memberId (FK)    │ │ memberId (FK)    │ │ memberId (FK)    │ │ userId (FK)      │
│ fullName         │ │ fullName         │ │ fullName         │ │ fullName         │
│ email            │ │ email            │ │ email            │ │ email            │
│ doingBusiness    │ │ panNumber        │ │ sisterConcerns   │ │ formData         │
│ organizationName │ │ gstNumber        │ │ companyNames     │ │ status           │
│ businessType     │ │ filedITR         │ │ agreeToDeclaration│ │ assignedBlockAdmin│
│ ...              │ │ turnoverRange    │ │ ...              │ │ assignedDistrictAdmin│
└──────────────────┘ │ ...              │ └──────────────────┘ │ assignedStateAdmin│
                     └──────────────────┘                      │ ...              │
                                                               └──────────────────┘

All collections are linked via memberId (which is MemberDetails._id)
```

### Data Consistency

To maintain data consistency across collections:

1. **Duplicate Fields**: Each related collection stores `fullName` and `email` for data integrity
2. **Single Source of Truth**: `MemberDetails._id` is the memberId used everywhere
3. **Referential Integrity**: All collections reference `memberId` with `ref: 'MemberDetails'`
4. **Indexed Foreign Keys**: All `memberId` fields are indexed for fast lookups

---

## Security Features

### 1. Password Security

```javascript
// Bcrypt hashing with cost factor 10
const hashedPassword = await bcrypt.hash(password, 10);

// Cost factor comparison:
// Cost 10: ~50ms (Industry standard, recommended)
// Cost 12: ~200ms (More secure but slower)
// Cost 8: ~12ms (Faster but less secure)
```

### 2. JWT Token Security

```javascript
// Token generation
const token = jwt.sign(
  { userId: memberId, email: email },
  process.env.JWTSECRET,
  { expiresIn: '24h' }
);

// Token verification (middleware)
const decoded = jwt.verify(token, process.env.JWTSECRET);
```

**Token Structure**:
```
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2NzRkMWEyYi4uLiIsImVtYWlsIjoidXNlckBleGFtcGxlLmNvbSIsImlhdCI6MTcwMjEyMzQ1NiwiZXhwIjoxNzAyMjA5ODU2fQ.signature
```

**Payload**:
```json
{
  "userId": "674d1a2b...",
  "email": "user@example.com",
  "iat": 1702123456,
  "exp": 1702209856
}
```

### 3. Input Validation

- Email: Regex validation + lowercase normalization
- Password: Minimum 8 characters (can be customized)
- PAN: Format validation `ABCDE1234F`
- GST: Format validation `22ABCDE1234F1Z5`
- Aadhaar: 12-digit numeric validation

### 4. Database Security

- **Indexes**: Optimized for query performance
- **Sparse Indexes**: On optional fields to save space
- **Unique Constraints**: On email fields to prevent duplicates
- **Enum Validation**: Restricts values to predefined options
- **Timestamps**: Automatic `createdAt` and `updatedAt` tracking

### 5. API Security

- JWT authentication required for protected routes
- Token expiry: 24 hours
- Email normalization (lowercase)
- Parallel queries for performance
- Async operations for non-blocking updates

---

## Summary

### Complete User Journey

1. **Registration** → Creates `MemberAuth` + `MemberDetails`
2. **Login** → Verifies email/password, returns JWT token
3. **Step 1** → Updates `MemberDetails` with personal info
4. **Step 2** → Creates `MemberBusinessInfo`
   - If Aspirant (doingBusiness = false) → Submit directly
   - If Company → Continue to Step 3
5. **Step 3** → Creates `MemberFinancialInfo` (Company only)
6. **Step 4** → Creates `MemberDeclaration` + `Application` (Company only)
7. **Approval** → 3-tier admin approval (Block → District → State)
8. **Payment** → Razorpay integration, membership activation
9. **Active Member** → Full access to platform features

### Database Collections Summary

| Collection | Purpose | Key Fields | Linked By |
|-----------|---------|-----------|-----------|
| **MemberAuth** | Authentication | email, password (hashed) | email |
| **MemberDetails** | Personal info | fullName, email, location, membershipStatus | _id (memberId) |
| **MemberBusinessInfo** | Business details | organizationName, businessType | memberId |
| **MemberFinancialInfo** | Financial data | PAN, GST, turnover | memberId |
| **MemberDeclaration** | Declaration | sisterConcerns, companies | memberId |
| **Application** | Approval workflow | status, formData, admins | userId (memberId) |

### Key Design Principles

1. ✅ **Distributed Data Model**: Information split across specialized collections
2. ✅ **Single Source of Truth**: `MemberDetails._id` is the memberId everywhere
3. ✅ **Data Integrity**: Duplicate `fullName` and `email` in related collections
4. ✅ **Performance**: Indexed foreign keys, parallel queries, lean operations
5. ✅ **Security**: Bcrypt hashing, JWT tokens, input validation
6. ✅ **Scalability**: Normalized design allows independent scaling
7. ✅ **Flexibility**: Optional fields, conditional forms (Aspirant vs Company)
8. ✅ **Audit Trail**: Timestamps, approval tracking, payment history

---

**Last Updated**: December 9, 2025  
**Version**: 1.0
