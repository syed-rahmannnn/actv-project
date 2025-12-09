# Application Status Screen - Complete Integration Guide

This document explains the complete integration of the Application Status screen, including frontend implementation, backend API endpoints, database collections, and data flow.

---

## Table of Contents

1. [Overview](#overview)
2. [Frontend Implementation](#frontend-implementation)
3. [Backend API Endpoints](#backend-api-endpoints)
4. [Database Collections](#database-collections)
5. [Data Flow Diagram](#data-flow-diagram)
6. [API Request/Response Examples](#api-requestresponse-examples)
7. [Database Query Examples](#database-query-examples)
8. [Error Handling](#error-handling)

---

## Overview

The Application Status screen provides real-time tracking of membership applications through a multi-stage approval workflow:

**Approval Stages**:
1. **Block Admin Review** - Initial verification at block level
2. **District Admin Review** - District-level verification
3. **State Admin Review** - State-level final verification
4. **Payment Ready** - Application approved, ready for payment

**Key Features**:
- Dynamic progress visualization
- Admin assignment tracking
- Review timestamps and messages
- Rejection handling with reasons
- Payment registration when fully approved

---

## Frontend Implementation

### 1. Component Structure

```
ApplicationStatusScreen.tsx
├── State Management (React hooks)
│   ├── applicationData (ApplicationData)
│   ├── isLoading (boolean)
│   ├── errorMessage (string | null)
│   └── stages (ApplicationStage[])
│
├── API Integration
│   └── fetchApplicationStatus()
│
├── Stage Building Logic
│   ├── buildStagesFromData()
│   ├── getStageStatus()
│   ├── getStageColor()
│   ├── getStageIcon()
│   └── getStageMessage()
│
└── UI Rendering
    ├── Progress Section
    ├── Stage Cards
    ├── Waiting/Rejection Sections
    └── Payment Button
```

### 2. TypeScript Interfaces

```typescript
// Frontend Types (ApplicationStatusScreen.tsx)

interface AdminData {
  id: string;
  fullName: string;
  email: string;
}

interface ReviewedBy {
  blockAdmin?: string;
  districtAdmin?: string;
  stateAdmin?: string;
}

interface ApplicationData {
  id: string;                    // Application document _id
  userId: string;                // References MemberDetails._id
  fullName: string;
  email: string;
  phone: string;
  state: string;
  district: string;
  block: string;
  formData: Record<string, any>; // Aggregated form data
  status: 'Pending-Block' | 'Pending-District' | 'Pending-State' | 'Approved' | 'Rejected';
  
  // Admin Assignments (populated from Admin collection)
  assignedBlockAdmin?: AdminData;
  assignedDistrictAdmin?: AdminData;
  assignedStateAdmin?: AdminData;
  
  // Approval Tracking
  rejectionReason?: string;
  blockApprovedAt?: Date;
  districtApprovedAt?: Date;
  stateApprovedAt?: Date;
  reviewedBy?: ReviewedBy;
  
  createdAt: Date;
  updatedAt: Date;
  
  // Helper flags (computed on frontend)
  isBlockApproved: boolean;
  isDistrictApproved: boolean;
  isStateApproved: boolean;
  isRejected: boolean;
}

interface ApplicationStage {
  name: string;              // 'block_admin', 'district_admin', 'state_admin', 'payment'
  displayName: string;       // Human-readable name
  status: 'pending' | 'in_progress' | 'approved' | 'rejected';
  reviewer?: string;         // Admin name
  reviewDate?: Date;         // Approval timestamp
  message?: string;          // Status message
  statusColor: string;       // Hex color for UI
  icon: string;              // Icon/emoji for stage
  isCompleted: boolean;
  isActive: boolean;
}
```

### 3. API Service Layer

```typescript
// services/ApplicationStatusService.ts

import { ApiService } from './ApiService';

export class ApplicationStatusService {
  static async fetchApplicationStatus(): Promise<ApplicationStatusResponse> {
    // Step 1: Get user data from local storage/session
    const userData = await ApiService.getUserData();
    if (!userData) {
      throw new Error('User not logged in');
    }

    // Step 2: Extract user ID (memberId)
    const userId = userData.id || userData.memberId || userData._id;
    if (!userId) {
      throw new Error('User ID not found');
    }

    // Step 3: Make API request to backend
    const response = await ApiService.get<ApplicationStatusResponse>(
      `/applications/user/${userId}`
    );

    // Step 4: Transform response with helper flags
    response.applications = response.applications.map((app) => ({
      ...app,
      isBlockApproved: !!app.blockApprovedAt,
      isDistrictApproved: !!app.districtApprovedAt,
      isStateApproved: !!app.stateApprovedAt,
      isRejected: app.status === 'Rejected',
    }));

    return response;
  }
}
```

### 4. Component Lifecycle

```
Component Mount
    ↓
useEffect Hook Triggered
    ↓
fetchApplicationStatus() Called
    ↓
┌─────────────────────────────────────┐
│ Get User Data from Local Storage    │
│ (email, memberId, token)             │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ API Request:                         │
│ GET /api/v1/applications/user/:id   │
│ Headers: Authorization Bearer token  │
└─────────────────────────────────────┘
    ↓
Backend Processing (see below)
    ↓
┌─────────────────────────────────────┐
│ Receive Response                     │
│ {                                    │
│   success: true,                     │
│   applications: [...],               │
│   count: 1                           │
│ }                                    │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ Transform Data:                      │
│ - Add isBlockApproved flag           │
│ - Add isDistrictApproved flag        │
│ - Add isStateApproved flag           │
│ - Add isRejected flag                │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ Build Stages:                        │
│ - buildStagesFromData()              │
│ - Create 4 stage objects             │
│ - Calculate status, colors, icons    │
└─────────────────────────────────────┘
    ↓
┌─────────────────────────────────────┐
│ Update Component State:              │
│ - setApplicationData(app)            │
│ - setStages(stages)                  │
│ - setIsLoading(false)                │
└─────────────────────────────────────┘
    ↓
UI Renders with Data
```

---

## Backend API Endpoints

### 1. Get Applications by User ID

**Endpoint**: `GET /api/v1/applications/user/:userId`

**Purpose**: Fetch all applications submitted by a specific user (member)

**Authentication**: Required (JWT Bearer token)

**Route Handler** (Express.js):

```javascript
// routes/applicationRoutes.js

const express = require('express');
const router = express.Router();
const { authenticateToken } = require('../middleware/auth');
const Application = require('../models/Application');

/**
 * @route   GET /api/v1/applications/user/:userId
 * @desc    Get all applications for a specific user
 * @access  Private (requires authentication)
 */
router.get('/user/:userId', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;

    console.log(`📋 Fetching applications for user: ${userId}`);

    // Step 1: Find all applications for this user
    const applications = await Application.find({ userId: userId })
      .populate('assignedBlockAdmin', 'fullName email')     // Populate block admin details
      .populate('assignedDistrictAdmin', 'fullName email')  // Populate district admin details
      .populate('assignedStateAdmin', 'fullName email')     // Populate state admin details
      .sort({ createdAt: -1 })                              // Sort by newest first
      .lean();                                              // Convert to plain JavaScript objects

    console.log(`✅ Found ${applications.length} application(s)`);

    // Step 2: Return response
    return res.status(200).json({
      success: true,
      applications: applications,
      count: applications.length,
    });

  } catch (error) {
    console.error('❌ Error fetching applications:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch applications',
      error: error.message,
    });
  }
});

module.exports = router;
```

### 2. Application Submission Endpoint

**Endpoint**: `POST /api/v1/applications/submit`

**Purpose**: Create a new application after completing all 4 registration steps

**Route Handler**:

```javascript
// routes/applicationRoutes.js

/**
 * @route   POST /api/v1/applications/submit
 * @desc    Submit a new membership application
 * @access  Private
 */
router.post('/submit', authenticateToken, async (req, res) => {
  try {
    const { userId, formData } = req.body;

    // Step 1: Get member details
    const member = await MemberDetails.findById(userId);
    if (!member) {
      return res.status(404).json({
        success: false,
        message: 'Member not found',
      });
    }

    // Step 2: Get business info (if exists)
    const businessInfo = await MemberBusinessInfo.findOne({ memberId: userId });
    const financialInfo = await MemberFinancialInfo.findOne({ memberId: userId });
    const declaration = await MemberDeclaration.findOne({ memberId: userId });

    // Step 3: Find assigned admins based on member's location
    const blockAdmin = await Admin.findOne({
      block: member.block,
      level: 'block',
      isActive: true,
    });

    const districtAdmin = await Admin.findOne({
      district: member.district,
      level: 'district',
      isActive: true,
    });

    const stateAdmin = await Admin.findOne({
      state: member.state,
      level: 'state',
      isActive: true,
    });

    // Step 4: Create application document
    const application = new Application({
      userId: userId,
      fullName: member.fullName,
      email: member.email,
      phone: member.phoneNumber,
      state: member.state,
      district: member.district,
      block: member.block,
      
      // Aggregate form data from all collections
      formData: {
        personalDetails: {
          fullName: member.fullName,
          aadhaarNumber: member.aadhaarNumber,
          streetName: member.streetName,
          educationalQualification: member.educationalQualification,
          religion: member.religion,
          socialCategory: member.socialCategory,
        },
        businessInfo: businessInfo ? {
          doingBusiness: businessInfo.doingBusiness,
          organizationName: businessInfo.organizationName,
          constitutionType: businessInfo.constitutionType,
          businessType: businessInfo.businessType,
          businessActivities: businessInfo.businessActivities,
          numberOfEmployees: businessInfo.numberOfEmployees,
        } : null,
        financialInfo: financialInfo ? {
          panNumber: financialInfo.panNumber,
          gstNumber: financialInfo.gstNumber,
          filedITR: financialInfo.filedITR,
          itrYears: financialInfo.itrYears,
          turnoverRange: financialInfo.turnoverRange,
        } : null,
        declaration: declaration ? {
          sisterConcerns: declaration.sisterConcerns,
          companyNames: declaration.companyNames,
          agreeToDeclaration: declaration.agreeToDeclaration,
        } : null,
      },

      // Set initial status and admin assignments
      status: 'Pending-Block',
      assignedBlockAdmin: blockAdmin?._id,
      assignedDistrictAdmin: districtAdmin?._id,
      assignedStateAdmin: stateAdmin?._id,
    });

    // Step 5: Save application to database
    await application.save();

    console.log(`✅ Application created: ${application._id}`);

    // Step 6: Update member's profileCompleted flag
    member.profileCompleted = true;
    await member.save();

    // Step 7: Return response
    return res.status(201).json({
      success: true,
      message: 'Application submitted successfully',
      application: application,
    });

  } catch (error) {
    console.error('❌ Error submitting application:', error);
    return res.status(500).json({
      success: false,
      message: 'Failed to submit application',
      error: error.message,
    });
  }
});
```

---

## Database Collections

### 1. Application Collection

**Collection Name**: `applications`

**Purpose**: Store membership application submissions and track approval workflow

**Schema** (MongoDB/Mongoose):

```javascript
// models/Application.js

const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const ApplicationSchema = new Schema(
  {
    // User Reference
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'MemberDetails',
      required: true,
      index: true,
    },

    // Basic Information (denormalized for quick access)
    fullName: {
      type: String,
      required: true,
    },
    email: {
      type: String,
      required: true,
      lowercase: true,
    },
    phone: {
      type: String,
      required: true,
    },
    state: {
      type: String,
      required: true,
    },
    district: {
      type: String,
      required: true,
    },
    block: {
      type: String,
      required: true,
    },

    // Aggregated Form Data (from all 4 steps)
    formData: {
      type: Object,
      default: {},
    },

    // Approval Workflow Status
    status: {
      type: String,
      enum: [
        'PENDING',           // Initial state
        'Pending-Block',     // Waiting for block admin
        'Pending-District',  // Waiting for district admin
        'Pending-State',     // Waiting for state admin
        'Approved',          // All stages approved
        'Rejected',          // Rejected at any stage
      ],
      default: 'Pending-Block',
      index: true,
    },

    // Admin Assignments (ObjectId references)
    assignedBlockAdmin: {
      type: Schema.Types.ObjectId,
      ref: 'Admin',
      default: null,
    },
    assignedDistrictAdmin: {
      type: Schema.Types.ObjectId,
      ref: 'Admin',
      default: null,
    },
    assignedStateAdmin: {
      type: Schema.Types.ObjectId,
      ref: 'Admin',
      default: null,
    },

    // Approval Timestamps
    blockApprovedAt: {
      type: Date,
      default: null,
    },
    districtApprovedAt: {
      type: Date,
      default: null,
    },
    stateApprovedAt: {
      type: Date,
      default: null,
    },

    // Reviewed By (admin IDs who reviewed)
    reviewedBy: {
      blockAdmin: {
        type: Schema.Types.ObjectId,
        ref: 'Admin',
        default: null,
      },
      districtAdmin: {
        type: Schema.Types.ObjectId,
        ref: 'Admin',
        default: null,
      },
      stateAdmin: {
        type: Schema.Types.ObjectId,
        ref: 'Admin',
        default: null,
      },
    },

    // Rejection Information
    rejectionReason: {
      type: String,
      default: null,
    },
    rejectedAt: {
      type: Date,
      default: null,
    },
    rejectedBy: {
      type: Schema.Types.ObjectId,
      ref: 'Admin',
      default: null,
    },

    // Admin Notes
    blockAdminNotes: String,
    districtAdminNotes: String,
    stateAdminNotes: String,
  },
  {
    timestamps: true, // Adds createdAt and updatedAt
  }
);

// Indexes for performance
ApplicationSchema.index({ userId: 1, createdAt: -1 });
ApplicationSchema.index({ status: 1, createdAt: -1 });
ApplicationSchema.index({ assignedBlockAdmin: 1 });
ApplicationSchema.index({ assignedDistrictAdmin: 1 });
ApplicationSchema.index({ assignedStateAdmin: 1 });

module.exports = mongoose.model('Application', ApplicationSchema);
```

### 2. Admin Collection

**Collection Name**: `admins`

**Purpose**: Store admin users who review and approve applications

**Schema**:

```javascript
// models/Admin.js

const mongoose = require('mongoose');
const Schema = mongoose.Schema;

const AdminSchema = new Schema(
  {
    fullName: {
      type: String,
      required: true,
    },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
    },
    password: {
      type: String,
      required: true,
    },
    
    // Admin Level
    level: {
      type: String,
      enum: ['block', 'district', 'state', 'super'],
      required: true,
      index: true,
    },

    // Location Assignment
    state: {
      type: String,
      default: null,
    },
    district: {
      type: String,
      default: null,
    },
    block: {
      type: String,
      default: null,
    },

    // Status
    isActive: {
      type: Boolean,
      default: true,
      index: true,
    },

    // Permissions
    permissions: {
      type: [String],
      default: [],
    },

    // Last Login
    lastLogin: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

// Compound indexes for location-based queries
AdminSchema.index({ level: 1, block: 1, isActive: 1 });
AdminSchema.index({ level: 1, district: 1, isActive: 1 });
AdminSchema.index({ level: 1, state: 1, isActive: 1 });

module.exports = mongoose.model('Admin', AdminSchema);
```

### 3. Related Collections

The application data aggregates information from these collections:

```javascript
// MemberDetails - Personal information
{
  _id: ObjectId("..."),        // This is the userId in Application
  fullName: "John Doe",
  email: "user@example.com",
  phoneNumber: "+919876543210",
  state: "Kerala",
  district: "Ernakulam",
  block: "Kochi",
  city: "Kochi",
  aadhaarNumber: "123456789012",
  streetName: "MG Road",
  educationalQualification: "B.Tech",
  religion: "Christian",
  socialCategory: "Christian SC",
  profileCompleted: true,      // Set to true when application submitted
  membershipStatus: "pending",
}

// MemberBusinessInfo - Business information (if Company member)
{
  _id: ObjectId("..."),
  memberId: ObjectId("..."),   // References MemberDetails._id
  doingBusiness: true,
  organizationName: "ABC Traders",
  constitutionType: "OPC",
  businessType: "Trader",
  businessActivities: "Import and export",
  numberOfEmployees: "15",
}

// MemberFinancialInfo - Financial compliance (if Company member)
{
  _id: ObjectId("..."),
  memberId: ObjectId("..."),
  panNumber: "ABCDE1234F",
  gstNumber: "22ABCDE1234F1Z5",
  filedITR: true,
  itrYears: "5",
  turnoverRange: "1 Crore - 5 Crores",
}

// MemberDeclaration - Final declaration (if Company member)
{
  _id: ObjectId("..."),
  memberId: ObjectId("..."),
  sisterConcerns: 2,
  companyNames: ["XYZ Enterprises", "DEF Trading Co."],
  agreeToDeclaration: true,
  profileCompleted: true,
}
```

---

## Data Flow Diagram

### Complete Application Status Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                          FRONTEND                                    │
│  ApplicationStatusScreen.tsx                                         │
└─────────────────────────────────────────────────────────────────────┘
                            ↓
                    Component Mounted
                            ↓
                 useEffect Hook Triggered
                            ↓
                            ↓
┌─────────────────────────────────────────────────────────────────────┐
│  Step 1: Get User Data from Local Storage                           │
│  ────────────────────────────────────────                           │
│  const userData = await ApiService.getUserData();                   │
│  → { id: "674d1a2b...", email: "user@example.com", token: "..." }  │
└─────────────────────────────────────────────────────────────────────┘
                            ↓
                            ↓
┌─────────────────────────────────────────────────────────────────────┐
│  Step 2: Extract User ID (memberId)                                 │
│  ────────────────────────────────                                   │
│  const userId = userData.id || userData.memberId || userData._id;   │
│  → userId = "674d1a2b3c4d5e6f7a8b9c0d"                             │
└─────────────────────────────────────────────────────────────────────┘
                            ↓
                            ↓
┌─────────────────────────────────────────────────────────────────────┐
│  Step 3: API Request to Backend                                     │
│  ───────────────────────────────────                                │
│  GET /api/v1/applications/user/674d1a2b3c4d5e6f7a8b9c0d            │
│  Headers:                                                            │
│    Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...    │
│    Content-Type: application/json                                   │
└─────────────────────────────────────────────────────────────────────┘
                            ↓
                            ↓
┌─────────────────────────────────────────────────────────────────────┐
│                          BACKEND                                     │
│  routes/applicationRoutes.js                                         │
└─────────────────────────────────────────────────────────────────────┘
                            ↓
          Middleware: authenticateToken()
                  ↓
        Verify JWT Token
                  ↓
        Extract userId from req.params
                            ↓
                            ↓
┌─────────────────────────────────────────────────────────────────────┐
│  Step 4: Database Query (MongoDB)                                   │
│  ──────────────────────────────────                                 │
│  Application.find({ userId: "674d1a2b..." })                        │
│    .populate('assignedBlockAdmin', 'fullName email')                │
│    .populate('assignedDistrictAdmin', 'fullName email')             │
│    .populate('assignedStateAdmin', 'fullName email')                │
│    .sort({ createdAt: -1 })                                         │
│    .lean()                                                           │
└─────────────────────────────────────────────────────────────────────┘
                            ↓
                            ↓
┌─────────────────────────────────────────────────────────────────────┐
│  Database Operation:                                                 │
│  ───────────────────                                                │
│                                                                      │
│  1. Find in 'applications' collection:                               │
│     db.applications.find({ userId: ObjectId("674d1a2b...") })       │
│                                                                      │
│  2. Populate 'assignedBlockAdmin':                                   │
│     db.admins.findOne({ _id: ObjectId("...") })                     │
│     → { fullName: "Block Admin Name", email: "block@activ.com" }   │
│                                                                      │
│  3. Populate 'assignedDistrictAdmin':                                │
│     db.admins.findOne({ _id: ObjectId("...") })                     │
│     → { fullName: "District Admin Name", email: "dist@activ.com" } │
│                                                                      │
│  4. Populate 'assignedStateAdmin':                                   │
│     db.admins.findOne({ _id: ObjectId("...") })                     │
│     → { fullName: "State Admin Name", email: "state@activ.com" }   │
│                                                                      │
│  5. Sort by createdAt descending (newest first)                      │
│                                                                      │
│  6. Convert to plain JavaScript object (.lean())                     │
└─────────────────────────────────────────────────────────────────────┘
                            ↓
                            ↓
┌─────────────────────────────────────────────────────────────────────┐
│  Step 5: Backend Returns Response                                   │
│  ─────────────────────────────────────                              │
│  {                                                                   │
│    success: true,                                                    │
│    applications: [                                                   │
│      {                                                               │
│        _id: "674e5f6a7b8c9d0e1f2a3b4c",                            │
│        userId: "674d1a2b3c4d5e6f7a8b9c0d",                          │
│        fullName: "John Doe",                                         │
│        email: "user@example.com",                                    │
│        phone: "+919876543210",                                       │
│        state: "Kerala",                                              │
│        district: "Ernakulam",                                        │
│        block: "Kochi",                                               │
│        status: "Pending-District",                                   │
│        assignedBlockAdmin: {                                         │
│          _id: "674c1a2b...",                                        │
│          fullName: "Rajesh Kumar",                                   │
│          email: "rajesh@activ.com"                                   │
│        },                                                            │
│        assignedDistrictAdmin: {                                      │
│          _id: "674c2b3c...",                                        │
│          fullName: "Priya Singh",                                    │
│          email: "priya@activ.com"                                    │
│        },                                                            │
│        assignedStateAdmin: {                                         │
│          _id: "674c3c4d...",                                        │
│          fullName: "Amit Sharma",                                    │
│          email: "amit@activ.com"                                     │
│        },                                                            │
│        blockApprovedAt: "2025-12-02T10:30:00.000Z",                 │
│        districtApprovedAt: null,                                     │
│        stateApprovedAt: null,                                        │
│        rejectionReason: null,                                        │
│        createdAt: "2025-12-01T08:25:00.000Z",                       │
│        updatedAt: "2025-12-02T10:30:00.000Z"                        │
│      }                                                               │
│    ],                                                                │
│    count: 1                                                          │
│  }                                                                   │
└─────────────────────────────────────────────────────────────────────┘
                            ↓
                            ↓
┌─────────────────────────────────────────────────────────────────────┐
│  Step 6: Frontend Receives Response                                 │
│  ───────────────────────────────────────                            │
│  ApplicationStatusService.fetchApplicationStatus()                  │
└─────────────────────────────────────────────────────────────────────┘
                            ↓
                            ↓
┌─────────────────────────────────────────────────────────────────────┐
│  Step 7: Transform Data (Add Helper Flags)                          │
│  ───────────────────────────────────────────                        │
│  response.applications = response.applications.map((app) => ({      │
│    ...app,                                                           │
│    isBlockApproved: !!app.blockApprovedAt,        → true            │
│    isDistrictApproved: !!app.districtApprovedAt,  → false           │
│    isStateApproved: !!app.stateApprovedAt,        → false           │
│    isRejected: app.status === 'Rejected',         → false           │
│  }));                                                                │
└─────────────────────────────────────────────────────────────────────┘
                            ↓
                            ↓
┌─────────────────────────────────────────────────────────────────────┐
│  Step 8: Build Stages Array                                         │
│  ────────────────────────                                           │
│  buildStagesFromData(applicationData)                               │
│                                                                      │
│  stages = [                                                          │
│    {                                                                 │
│      name: 'block_admin',                                            │
│      displayName: 'Block Admin Review',                             │
│      status: 'approved',              ← blockApprovedAt exists      │
│      reviewer: 'Rajesh Kumar',                                       │
│      reviewDate: 2025-12-02T10:30:00Z,                              │
│      message: 'All documents verified. Profile looks good.',        │
│      statusColor: '#4CAF50',          ← Green                       │
│      icon: '✓',                                                      │
│      isCompleted: true,                                              │
│      isActive: false                                                 │
│    },                                                                │
│    {                                                                 │
│      name: 'district_admin',                                         │
│      displayName: 'District Admin Review',                          │
│      status: 'in_progress',           ← status = 'Pending-District' │
│      reviewer: 'Priya Singh',                                        │
│      reviewDate: null,                                               │
│      message: 'Your application is currently being reviewed...',    │
│      statusColor: '#2196F3',          ← Blue                        │
│      icon: '⏳',                                                      │
│      isCompleted: false,                                             │
│      isActive: true                                                  │
│    },                                                                │
│    {                                                                 │
│      name: 'state_admin',                                            │
│      displayName: 'State Admin Review',                             │
│      status: 'pending',                                              │
│      reviewer: 'Amit Sharma',                                        │
│      reviewDate: null,                                               │
│      message: '',                                                    │
│      statusColor: '#90CAF9',          ← Light blue                  │
│      icon: '○',                                                      │
│      isCompleted: false,                                             │
│      isActive: false                                                 │
│    },                                                                │
│    {                                                                 │
│      name: 'payment',                                                │
│      displayName: 'Ready for Payment',                              │
│      status: 'pending',                                              │
│      reviewer: 'ACTIV Super Admin',                                 │
│      reviewDate: null,                                               │
│      message: '',                                                    │
│      statusColor: '#90CAF9',                                         │
│      icon: '💳',                                                      │
│      isCompleted: false,                                             │
│      isActive: false                                                 │
│    }                                                                 │
│  ]                                                                   │
└─────────────────────────────────────────────────────────────────────┘
                            ↓
                            ↓
┌─────────────────────────────────────────────────────────────────────┐
│  Step 9: Update Component State                                     │
│  ────────────────────────────────                                   │
│  setApplicationData(app)                                             │
│  setStages(stages)                                                   │
│  setIsLoading(false)                                                 │
└─────────────────────────────────────────────────────────────────────┘
                            ↓
                            ↓
┌─────────────────────────────────────────────────────────────────────┐
│  Step 10: Component Re-renders                                      │
│  ──────────────────────────────────                                 │
│                                                                      │
│  UI Displays:                                                        │
│  ───────────                                                         │
│                                                                      │
│  ┌──────────────────────────────────────────────────┐              │
│  │  Overall Progress: 1 of 4 stages completed       │              │
│  │  [████████▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓] 25%         │              │
│  │  [✓] Block  [⏳] District  [○] State  [○] Payment│              │
│  └──────────────────────────────────────────────────┘              │
│                                                                      │
│  ┌──────────────────────────────────────────────────┐              │
│  │  Block Admin Review            [Approved]         │              │
│  │  Rajesh Kumar                                     │              │
│  │  Review Date: 2/12/2025                          │              │
│  │  ┌────────────────────────────────────────┐     │              │
│  │  │ ✓ All documents verified. Profile      │     │              │
│  │  │   looks good.                          │     │              │
│  │  └────────────────────────────────────────┘     │              │
│  └──────────────────────────────────────────────────┘              │
│                                                                      │
│  ┌──────────────────────────────────────────────────┐              │
│  │  District Admin Review         [In Progress]      │              │
│  │  Priya Singh                                      │              │
│  │  ┌────────────────────────────────────────┐     │              │
│  │  │ ⏳ Your application is currently being  │     │              │
│  │  │   reviewed...                          │     │              │
│  │  └────────────────────────────────────────┘     │              │
│  └──────────────────────────────────────────────────┘              │
│                                                                      │
│  [Back to Dashboard]                                                │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## API Request/Response Examples

### Example 1: Successful Request

**Request**:
```http
GET /api/v1/applications/user/674d1a2b3c4d5e6f7a8b9c0d HTTP/1.1
Host: api.activ.com
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiI2NzRkMWEyYjNjNGQ1ZTZmN2E4YjljMGQiLCJlbWFpbCI6InVzZXJAZXhhbXBsZS5jb20iLCJpYXQiOjE3MzM3NDU2MDAsImV4cCI6MTczMzgzMjAwMH0.abc123def456
Content-Type: application/json
```

**Response** (Status: Pending-Block):
```json
{
  "success": true,
  "applications": [
    {
      "_id": "674e5f6a7b8c9d0e1f2a3b4c",
      "userId": "674d1a2b3c4d5e6f7a8b9c0d",
      "fullName": "John Doe",
      "email": "user@example.com",
      "phone": "+919876543210",
      "state": "Kerala",
      "district": "Ernakulam",
      "block": "Kochi",
      "formData": {
        "personalDetails": {
          "fullName": "John Doe",
          "aadhaarNumber": "123456789012",
          "streetName": "MG Road",
          "educationalQualification": "B.Tech",
          "religion": "Christian",
          "socialCategory": "Christian SC"
        },
        "businessInfo": {
          "doingBusiness": true,
          "organizationName": "ABC Traders",
          "constitutionType": "OPC",
          "businessType": "Trader"
        }
      },
      "status": "Pending-Block",
      "assignedBlockAdmin": {
        "_id": "674c1a2b3c4d5e6f7a8b9c0e",
        "fullName": "Rajesh Kumar",
        "email": "rajesh@activ.com"
      },
      "assignedDistrictAdmin": {
        "_id": "674c2b3c4d5e6f7a8b9c0f",
        "fullName": "Priya Singh",
        "email": "priya@activ.com"
      },
      "assignedStateAdmin": {
        "_id": "674c3c4d5e6f7a8b9c10",
        "fullName": "Amit Sharma",
        "email": "amit@activ.com"
      },
      "blockApprovedAt": null,
      "districtApprovedAt": null,
      "stateApprovedAt": null,
      "rejectionReason": null,
      "reviewedBy": {},
      "createdAt": "2025-12-01T08:25:00.000Z",
      "updatedAt": "2025-12-01T08:25:00.000Z"
    }
  ],
  "count": 1
}
```

**Response** (Status: Pending-District):
```json
{
  "success": true,
  "applications": [
    {
      "_id": "674e5f6a7b8c9d0e1f2a3b4c",
      "userId": "674d1a2b3c4d5e6f7a8b9c0d",
      "fullName": "John Doe",
      "email": "user@example.com",
      "phone": "+919876543210",
      "state": "Kerala",
      "district": "Ernakulam",
      "block": "Kochi",
      "status": "Pending-District",
      "assignedBlockAdmin": {
        "_id": "674c1a2b3c4d5e6f7a8b9c0e",
        "fullName": "Rajesh Kumar",
        "email": "rajesh@activ.com"
      },
      "assignedDistrictAdmin": {
        "_id": "674c2b3c4d5e6f7a8b9c0f",
        "fullName": "Priya Singh",
        "email": "priya@activ.com"
      },
      "assignedStateAdmin": {
        "_id": "674c3c4d5e6f7a8b9c10",
        "fullName": "Amit Sharma",
        "email": "amit@activ.com"
      },
      "blockApprovedAt": "2025-12-02T10:30:00.000Z",
      "districtApprovedAt": null,
      "stateApprovedAt": null,
      "rejectionReason": null,
      "reviewedBy": {
        "blockAdmin": "674c1a2b3c4d5e6f7a8b9c0e"
      },
      "createdAt": "2025-12-01T08:25:00.000Z",
      "updatedAt": "2025-12-02T10:30:00.000Z"
    }
  ],
  "count": 1
}
```

**Response** (Status: Approved):
```json
{
  "success": true,
  "applications": [
    {
      "_id": "674e5f6a7b8c9d0e1f2a3b4c",
      "userId": "674d1a2b3c4d5e6f7a8b9c0d",
      "fullName": "John Doe",
      "email": "user@example.com",
      "phone": "+919876543210",
      "state": "Kerala",
      "district": "Ernakulam",
      "block": "Kochi",
      "status": "Approved",
      "assignedBlockAdmin": {
        "_id": "674c1a2b3c4d5e6f7a8b9c0e",
        "fullName": "Rajesh Kumar",
        "email": "rajesh@activ.com"
      },
      "assignedDistrictAdmin": {
        "_id": "674c2b3c4d5e6f7a8b9c0f",
        "fullName": "Priya Singh",
        "email": "priya@activ.com"
      },
      "assignedStateAdmin": {
        "_id": "674c3c4d5e6f7a8b9c10",
        "fullName": "Amit Sharma",
        "email": "amit@activ.com"
      },
      "blockApprovedAt": "2025-12-02T10:30:00.000Z",
      "districtApprovedAt": "2025-12-03T14:15:00.000Z",
      "stateApprovedAt": "2025-12-04T09:45:00.000Z",
      "rejectionReason": null,
      "reviewedBy": {
        "blockAdmin": "674c1a2b3c4d5e6f7a8b9c0e",
        "districtAdmin": "674c2b3c4d5e6f7a8b9c0f",
        "stateAdmin": "674c3c4d5e6f7a8b9c10"
      },
      "createdAt": "2025-12-01T08:25:00.000Z",
      "updatedAt": "2025-12-04T09:45:00.000Z"
    }
  ],
  "count": 1
}
```

**Response** (Status: Rejected):
```json
{
  "success": true,
  "applications": [
    {
      "_id": "674e5f6a7b8c9d0e1f2a3b4c",
      "userId": "674d1a2b3c4d5e6f7a8b9c0d",
      "fullName": "John Doe",
      "email": "user@example.com",
      "phone": "+919876543210",
      "state": "Kerala",
      "district": "Ernakulam",
      "block": "Kochi",
      "status": "Rejected",
      "assignedBlockAdmin": {
        "_id": "674c1a2b3c4d5e6f7a8b9c0e",
        "fullName": "Rajesh Kumar",
        "email": "rajesh@activ.com"
      },
      "assignedDistrictAdmin": {
        "_id": "674c2b3c4d5e6f7a8b9c0f",
        "fullName": "Priya Singh",
        "email": "priya@activ.com"
      },
      "assignedStateAdmin": null,
      "blockApprovedAt": "2025-12-02T10:30:00.000Z",
      "districtApprovedAt": null,
      "stateApprovedAt": null,
      "rejectionReason": "Incomplete business documentation. Please upload GST certificate and PAN card copies.",
      "rejectedAt": "2025-12-03T11:20:00.000Z",
      "rejectedBy": "674c2b3c4d5e6f7a8b9c0f",
      "reviewedBy": {
        "blockAdmin": "674c1a2b3c4d5e6f7a8b9c0e",
        "districtAdmin": "674c2b3c4d5e6f7a8b9c0f"
      },
      "createdAt": "2025-12-01T08:25:00.000Z",
      "updatedAt": "2025-12-03T11:20:00.000Z"
    }
  ],
  "count": 1
}
```

### Example 2: Error Responses

**401 Unauthorized** (Invalid or missing token):
```json
{
  "success": false,
  "message": "Authentication token is required",
  "error": "Unauthorized"
}
```

**404 Not Found** (No applications found):
```json
{
  "success": true,
  "applications": [],
  "count": 0
}
```

**500 Internal Server Error**:
```json
{
  "success": false,
  "message": "Failed to fetch applications",
  "error": "Database connection timeout"
}
```

---

## Database Query Examples

### Query 1: Find Applications by User ID

```javascript
// MongoDB Shell
db.applications.find({
  userId: ObjectId("674d1a2b3c4d5e6f7a8b9c0d")
}).sort({ createdAt: -1 })

// Mongoose
Application.find({ userId: "674d1a2b3c4d5e6f7a8b9c0d" })
  .populate('assignedBlockAdmin', 'fullName email')
  .populate('assignedDistrictAdmin', 'fullName email')
  .populate('assignedStateAdmin', 'fullName email')
  .sort({ createdAt: -1 })
  .lean()
```

### Query 2: Find Pending Applications for Block Admin

```javascript
// Find all applications assigned to specific block admin
db.applications.find({
  assignedBlockAdmin: ObjectId("674c1a2b3c4d5e6f7a8b9c0e"),
  status: "Pending-Block"
})

// Mongoose
Application.find({
  assignedBlockAdmin: "674c1a2b3c4d5e6f7a8b9c0e",
  status: "Pending-Block"
})
  .populate('userId', 'fullName email phoneNumber')
  .sort({ createdAt: 1 })
```

### Query 3: Count Applications by Status

```javascript
// MongoDB Aggregation
db.applications.aggregate([
  {
    $group: {
      _id: "$status",
      count: { $sum: 1 }
    }
  }
])

// Result:
// [
//   { _id: "Pending-Block", count: 45 },
//   { _id: "Pending-District", count: 23 },
//   { _id: "Pending-State", count: 12 },
//   { _id: "Approved", count: 156 },
//   { _id: "Rejected", count: 8 }
// ]
```

### Query 4: Find Applications by Location

```javascript
// Find all applications from specific state
db.applications.find({
  state: "Kerala",
  status: { $in: ["Pending-Block", "Pending-District", "Pending-State"] }
})

// Find applications from specific district
db.applications.find({
  state: "Kerala",
  district: "Ernakulam",
  status: "Pending-District"
})
```

### Query 5: Update Application Status (Admin Approval)

```javascript
// Block Admin approves application
db.applications.updateOne(
  { _id: ObjectId("674e5f6a7b8c9d0e1f2a3b4c") },
  {
    $set: {
      status: "Pending-District",
      blockApprovedAt: new Date(),
      "reviewedBy.blockAdmin": ObjectId("674c1a2b3c4d5e6f7a8b9c0e"),
      updatedAt: new Date()
    }
  }
)

// District Admin approves application
db.applications.updateOne(
  { _id: ObjectId("674e5f6a7b8c9d0e1f2a3b4c") },
  {
    $set: {
      status: "Pending-State",
      districtApprovedAt: new Date(),
      "reviewedBy.districtAdmin": ObjectId("674c2b3c4d5e6f7a8b9c0f"),
      updatedAt: new Date()
    }
  }
)

// State Admin approves application (final approval)
db.applications.updateOne(
  { _id: ObjectId("674e5f6a7b8c9d0e1f2a3b4c") },
  {
    $set: {
      status: "Approved",
      stateApprovedAt: new Date(),
      "reviewedBy.stateAdmin": ObjectId("674c3c4d5e6f7a8b9c10"),
      updatedAt: new Date()
    }
  }
)
```

### Query 6: Reject Application

```javascript
// Admin rejects application
db.applications.updateOne(
  { _id: ObjectId("674e5f6a7b8c9d0e1f2a3b4c") },
  {
    $set: {
      status: "Rejected",
      rejectionReason: "Incomplete documentation",
      rejectedAt: new Date(),
      rejectedBy: ObjectId("674c2b3c4d5e6f7a8b9c0f"),
      updatedAt: new Date()
    }
  }
)
```

---

## Error Handling

### Frontend Error Handling

```typescript
// ApplicationStatusScreen.tsx

const fetchApplicationStatus = async () => {
  try {
    setIsLoading(true);
    setErrorMessage(null);

    // Get user data
    const userData = await ApiService.getUserData();
    if (!userData) {
      throw new Error('User not logged in');
    }

    // Extract user ID
    const userId = userData.id || userData.memberId || userData._id;
    if (!userId) {
      throw new Error('User ID not found');
    }

    // Make API request
    const response = await ApiService.get(`/applications/user/${userId}`);

    // Handle empty results
    if (!response.applications || response.applications.length === 0) {
      setErrorMessage('No application found');
      setIsLoading(false);
      return;
    }

    // Success - update state
    setApplicationData(response.applications[0]);
    setStages(buildStagesFromData(response.applications[0]));

  } catch (error: any) {
    // Handle different error types
    if (error.response) {
      // Server responded with error status
      switch (error.response.status) {
        case 401:
          setErrorMessage('Authentication failed. Please login again.');
          // Redirect to login
          navigate('/login');
          break;
        case 404:
          setErrorMessage('Application not found');
          break;
        case 500:
          setErrorMessage('Server error. Please try again later.');
          break;
        default:
          setErrorMessage(`Error: ${error.response.data.message}`);
      }
    } else if (error.request) {
      // Request made but no response received
      setErrorMessage('Network error. Please check your connection.');
    } else {
      // Other errors
      setErrorMessage(error.message || 'An unexpected error occurred');
    }

    console.error('Error fetching application status:', error);
  } finally {
    setIsLoading(false);
  }
};
```

### Backend Error Handling

```javascript
// routes/applicationRoutes.js

router.get('/user/:userId', authenticateToken, async (req, res) => {
  try {
    const { userId } = req.params;

    // Validate userId format
    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid user ID format',
      });
    }

    // Query database
    const applications = await Application.find({ userId })
      .populate('assignedBlockAdmin', 'fullName email')
      .populate('assignedDistrictAdmin', 'fullName email')
      .populate('assignedStateAdmin', 'fullName email')
      .sort({ createdAt: -1 })
      .lean();

    // Return results (even if empty)
    return res.status(200).json({
      success: true,
      applications: applications,
      count: applications.length,
    });

  } catch (error) {
    console.error('Error fetching applications:', error);

    // Database connection error
    if (error.name === 'MongoNetworkError') {
      return res.status(503).json({
        success: false,
        message: 'Database connection error',
        error: 'Service temporarily unavailable',
      });
    }

    // Generic error
    return res.status(500).json({
      success: false,
      message: 'Failed to fetch applications',
      error: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error',
    });
  }
});
```

---

## Summary

This document provides a complete understanding of:

1. **Frontend Architecture**: React component with TypeScript, state management, and API integration
2. **Backend API**: Express.js routes with MongoDB queries and population
3. **Database Schema**: Application and Admin collections with proper indexing
4. **Data Flow**: Step-by-step visualization from user interaction to UI rendering
5. **API Examples**: Request/response formats for all approval stages
6. **Database Queries**: MongoDB operations for CRUD and status updates
7. **Error Handling**: Comprehensive error management on both frontend and backend

The Application Status screen successfully tracks multi-stage approval workflows with real-time updates and admin assignment tracking.
