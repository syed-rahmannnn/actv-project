# Flutter App Audit Document
## ACTIV Portal - Complete System Blueprint

**Document Version:** 1.0  
**Date:** December 8, 2025  
**Total Screens:** 54+  
**Platform:** Flutter 3.9+  
**State Management:** Provider Pattern  

---

## Executive Summary

The ACTIV Portal is a comprehensive Flutter application designed for member management, business profile creation, and multi-level administrative approval workflows. The app serves multiple user roles including Members, Block Admins, District Admins, State Admins, and Super Admins.

**Key Statistics:**
- **Total Screens:** 54+ screens
- **API Endpoints:** 40+ endpoints
- **User Roles:** 5 distinct roles
- **Reusable Components:** 15+ widgets
- **Services:** 16 service classes
- **Providers:** 5 state management providers

---

## 1. Screen Inventory

### 1.1 Authentication & Onboarding

#### 1.1.1 Onboarding Screen
- **File:** `lib/screens/onboarding_screen.dart`
- **Purpose:** First-time user introduction and app overview
- **Navigation:** Entry point → Login Screen
- **Components:** 
  - PageView for slides
  - Smooth page indicators
  - Skip button
- **APIs:** None
- **Transitions:** PageView animation with custom page indicators

#### 1.1.2 Login Screen
- **File:** `lib/screens/Login/login_screen.dart`
- **Purpose:** User authentication for all roles
- **APIs:**
  - `POST /api/auth/login` - User login with email/password
- **Navigation:** 
  - Success → Dashboard (role-based routing)
  - New User → Registration Step 1
- **Components:**
  - TextField (email, password)
  - ElevatedButton
  - Form validation
- **Validation:**
  - Email: Required, valid email format
  - Password: Required, min 6 characters
- **State Management:** AuthService for token storage

---

### 1.2 Member Registration Flow

#### 1.2.1 Registration Step 1
- **File:** `lib/screens/Member Registration/registration_step1_screen.dart`
- **Purpose:** Basic member information collection
- **APIs:**
  - `POST /api/auth/register` - Create new member account
- **Navigation:** Step 1 → Step 2 (on success)
- **Form Fields:**
  - Full Name (required)
  - Email (required, email validation)
  - Phone Number (required, 10 digits)
  - Password (required, min 6 chars)
  - Confirm Password (required, must match)
- **Validation:**
  - Email regex: `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
  - Phone: Numeric, 10 digits
  - Password match validation
- **Components:** Form, TextFormField, Custom validator functions

#### 1.2.2 Registration Step 2
- **File:** `lib/screens/Member Registration/registration_step2_screen.dart`
- **Purpose:** Location and additional details
- **APIs:**
  - `PUT /api/members/:id` - Update member profile
- **Navigation:** Step 2 → Dashboard (on completion)
- **Form Fields:**
  - State (dropdown, required)
  - District (dropdown, required)
  - Block (dropdown, required)
  - City (text input, required)
- **Dependencies:** Location data cascading dropdowns

---

### 1.3 Member Dashboard & Navigation

#### 1.3.1 Dashboard Screen (Main)
- **File:** `lib/screens/Member Bottom Navigation/dashboard_screen.dart`
- **Purpose:** Member home screen with overview cards
- **APIs:**
  - `GET /api/members/:id/status` - Profile completion, application status
  - `GET /api/members/:email/details` - Member details
  - `GET /api/business-profiles/:memberId` - Business profile status
- **Navigation:**
  - Bottom Navigation Bar (Home, Explore, Notifications)
  - → Personal Details Form
  - → Application Status Screen
  - → Business Profile Screen
  - → Complete Membership Screen
- **Components:**
  - Profile completion card
  - Application status card (conditional)
  - Business account card
  - Profile statistics
  - Recent activities list
- **Dynamic UI:**
  - Shows "Complete Profile" when `hasApplication = false`
  - Shows "View Status" when `hasApplication = true`
  - Business account card always visible
- **State Variables:**
  - `_profileCompletion` (percentage)
  - `_hasApplication` (boolean)
  - `_hasBusinessProfile` (boolean)
  - `_applicationStatus` (string)
- **Providers:** UserProfileProvider, CompanySelectionProvider

#### 1.3.2 Browse Members Screen
- **File:** `lib/screens/Member Bottom Navigation/browse_members_screen.dart`
- **Purpose:** Discover and connect with other members
- **APIs:**
  - `GET /api/browse-members` - Fetch members list with filters
  - `GET /api/browse-members/search?query=` - Search members
- **Navigation:** Bottom Nav → Member Profile Details
- **Components:**
  - Search bar with debounce
  - Filter chips (location, business type)
  - ListView.builder for members
  - Pagination support
- **Features:**
  - Real-time search
  - Location-based filtering
  - Business category filtering
  - Member profile cards

#### 1.3.3 Notification Screen
- **File:** `lib/screens/Member Bottom Navigation/notification_screen.dart`
- **Purpose:** Display system and application notifications
- **APIs:**
  - `GET /api/notifications/:userId` - Fetch user notifications
  - `PUT /api/notifications/:id/read` - Mark as read
- **Navigation:** Bottom Nav → Notification Details
- **Components:**
  - ListView of notification cards
  - Unread badge indicator
  - Swipe to dismiss
  - Pull to refresh

---

### 1.4 Member Profile Management

#### 1.4.1 Profile Screen
- **File:** `lib/screens/Member Profile/profile_screen.dart`
- **Purpose:** View and edit member profile
- **APIs:**
  - `GET /api/members/:id` - Fetch profile data
  - `PUT /api/members/:id` - Update profile
  - `POST /api/members/:id/photo` - Upload profile photo
- **Navigation:** Dashboard → Profile → Edit Profile
- **Components:**
  - CircleAvatar with image picker
  - Profile info cards
  - Edit button
  - Logout button
- **Form Fields:**
  - Profile photo
  - Full name
  - Email (readonly)
  - Phone number
  - Location (state, district, block, city)

#### 1.4.2 Profile Detail Screen
- **File:** `lib/screens/Member Profile/profile_detail_screen.dart`
- **Purpose:** View detailed member information
- **APIs:**
  - `GET /api/members/:id/details` - Complete profile details
- **Navigation:** Browse Members → Profile Detail
- **Components:**
  - Detailed info sections
  - Business information (if applicable)
  - Contact actions (call, email)

---

### 1.5 Member Additional Details

#### 1.5.1 Personal Details Form
- **File:** `lib/screens/Member Addtional Details/personal_details_form.dart`
- **Purpose:** Comprehensive personal information collection
- **APIs:**
  - `PUT /api/members/:id` - Save personal details
- **Navigation:** Dashboard → Personal Details → Submit
- **Form Sections:**
  1. **Personal Information**
     - Aadhaar Number (12 digits, required)
     - Educational Qualification (dropdown)
     - Religion (dropdown)
     - Social Category (dropdown)
  
  2. **Business Information** (conditional)
     - Doing Business (checkbox)
     - Business Name
     - Business Type
     - Years in Business
  
  3. **Address Details**
     - Street Name
     - Landmark
     - Pincode (6 digits)
- **Validation:**
  - Aadhaar: 12 digits numeric
  - Pincode: 6 digits numeric
  - Required fields based on business selection
- **State Management:** Form state with TextEditingControllers

#### 1.5.2 Business Details Form
- **File:** `lib/screens/Member Addtional Details/business_details_form.dart`
- **Purpose:** Detailed business information for company members
- **APIs:**
  - `POST /api/business-info` - Create business profile
  - `PUT /api/business-info/:id` - Update business profile
- **Form Fields:**
  - Company Name
  - Business Type
  - Registration Number
  - GST Number (optional)
  - Annual Turnover
  - Number of Employees
- **Validation:**
  - GST: 15 characters alphanumeric (if provided)
  - Registration Number: Required

#### 1.5.3 Financial Details Form
- **File:** `lib/screens/Member Addtional Details/financial_details_form.dart`
- **Purpose:** Financial information for membership application
- **APIs:**
  - `POST /api/financial-info` - Submit financial details
- **Form Fields:**
  - Annual Income Range
  - Bank Account Holder Name
  - Account Number
  - IFSC Code
- **Validation:**
  - IFSC: 11 characters, alphanumeric
  - Account Number: 9-18 digits

---

### 1.6 Application Status & Submission

#### 1.6.1 Application Status Screen
- **File:** `lib/screens/Application Status/application_status_screen.dart`
- **Purpose:** Track membership application progress
- **APIs:**
  - `GET /api/applications/:userId` - Fetch application status
  - `GET /api/applications/:id/timeline` - Approval timeline
- **Navigation:** Dashboard → Application Status
- **Components:**
  - Stepper widget showing approval stages
  - Status indicators (Pending, Approved, Rejected)
  - Timeline view
  - Comments from admins
- **Status Flow:**
  - Pending-Block → Pending-District → Pending-State → Approved
- **Features:**
  - Real-time status updates
  - Admin comments display
  - Rejection reason display

#### 1.6.2 Application Submitted Screen
- **File:** `lib/screens/Application Status/application_submitted_screen.dart`
- **Purpose:** Confirmation screen after application submission
- **APIs:** None (static confirmation)
- **Navigation:** Form Submission → Confirmation → Dashboard
- **Components:**
  - Success icon/animation
  - Application reference number
  - Next steps information
  - Navigate to Dashboard button

---

### 1.7 Business Account Management

#### 1.7.1 Business Profile Screen
- **File:** `lib/screens/Bussiness account/business_profile_screen.dart`
- **Purpose:** Create and manage business profile
- **APIs:**
  - `POST /api/business-profiles` - Create business profile
  - `GET /api/business-profiles/:memberId` - Fetch business profile
  - `PUT /api/business-profiles/:id` - Update profile
- **Navigation:** Dashboard → Business Profile → Company Management
- **Form Sections:**
  1. Business Basic Info
  2. Contact Details
  3. Social Media Links
  4. Business Description
- **Components:**
  - Multi-step form wizard
  - Image upload for logo
  - Rich text editor for description

#### 1.7.2 Manage Companies Screen
- **File:** `lib/screens/Bussiness account/manage_companies_screen.dart`
- **Purpose:** Manage multiple companies under one account
- **APIs:**
  - `GET /api/companies?memberId=` - List companies
  - `POST /api/companies` - Create new company
  - `PUT /api/companies/:id` - Update company
  - `DELETE /api/companies/:id` - Delete company
- **Navigation:** Business Dashboard → Manage Companies → Add/Edit Company
- **Components:**
  - Company list with cards
  - Add company FAB (Floating Action Button)
  - Edit/Delete actions
  - Company switcher dropdown
- **Features:**
  - Multiple company management
  - Active company selection
  - Company-specific products

#### 1.7.3 Business Dashboard Screen
- **File:** `lib/screens/Bussiness account/business_dashboard_screen.dart`
- **Purpose:** Overview of business metrics and activities
- **APIs:**
  - `GET /api/business/stats/:companyId` - Business statistics
  - `GET /api/business/activities/:companyId` - Recent activities
- **Navigation:** Dashboard → Business Dashboard
- **Components:**
  - Metrics cards (views, products, orders)
  - Chart widgets (trend lines)
  - Recent activities list
  - Quick action buttons
- **Metrics Displayed:**
  - Profile views (with % change)
  - Total products
  - Total orders
  - Revenue (if applicable)

#### 1.7.4 Complete Membership Screen
- **File:** `lib/screens/Bussiness account/complete_membership_screen.dart`
- **Purpose:** Select and purchase membership plan
- **APIs:**
  - `GET /api/membership/plans` - Fetch available plans
  - `POST /api/payment/create-order` - Initiate payment
- **Navigation:** Dashboard → Membership Plans → Payment
- **Components:**
  - Plan cards (Aspirant, Company)
  - Feature comparison table
  - Price display
  - Payment button
- **Features:**
  - Role-based plan locking (Aspirant vs Company)
  - Plan comparison
  - Razorpay integration
- **Business Logic:**
  - Auto-detects member type from `personalDetails.doingBusiness`
  - Locks to Aspirant plan if student
  - Locks to Company plan if business owner
  - Hides toggle button when locked

#### 1.7.5 Add/Edit Product Screen
- **File:** `lib/screens/Bussiness account/add_product_screen.dart`
- **Purpose:** Create and edit business products
- **APIs:**
  - `POST /api/products` - Create product
  - `PUT /api/products/:id` - Update product
  - `POST /api/products/:id/images` - Upload product images
- **Form Fields:**
  - Product name
  - Description
  - Category
  - Price
  - Stock quantity
  - Images (multiple)
- **Validation:**
  - Name: Required, 3-100 chars
  - Price: Numeric, >= 0
  - Stock: Integer, >= 0
- **Components:**
  - Image picker (multiple images)
  - Category dropdown
  - Rich text editor for description

---

### 1.8 Payment Processing

#### 1.8.1 Payment WebView Screen
- **File:** `lib/screens/Payment/payment_webview_screen.dart`
- **Purpose:** Handle Razorpay payment gateway
- **APIs:**
  - Razorpay Checkout SDK
  - `POST /api/payment/verify` - Verify payment signature
- **Navigation:** Membership Screen → Payment → Success/Failure
- **Components:**
  - WebView for Razorpay
  - Loading indicator
  - Error handling
- **Payment Flow:**
  1. Create order on backend
  2. Open Razorpay checkout
  3. User completes payment
  4. Verify signature
  5. Update membership status
- **Callbacks:**
  - onPaymentSuccess
  - onPaymentError
  - onPaymentCancel

#### 1.8.2 Payment Success Screen
- **File:** `lib/screens/Payment/payment_success_screen.dart`
- **Purpose:** Payment confirmation and receipt
- **APIs:**
  - `GET /api/payment/:orderId` - Fetch payment details
- **Navigation:** Payment → Success → Dashboard
- **Components:**
  - Success animation (Lottie)
  - Payment details card
  - Transaction ID
  - Download receipt button
  - Navigate to Dashboard button

---

### 1.9 Admin Screens - Block Level

#### 1.9.1 Block Admin Dashboard
- **File:** `lib/screens/Block Admin/blockadmin_dashboard.dart`
- **Purpose:** Block admin overview and pending applications
- **APIs:**
  - `GET /api/admin/block/dashboard` - Dashboard stats
  - `GET /api/admin/block/pending-applications` - Pending count
- **Navigation:** Login (Block Admin) → Dashboard → Approval Queue
- **Components:**
  - Stats cards (pending, approved, rejected)
  - Quick action buttons
  - Recent applications list
- **Metrics:**
  - Total pending applications
  - Today's approvals
  - Pending reviews

#### 1.9.2 Block Admin Approval Page
- **File:** `lib/screens/Block Admin/blockadmin_approval_page.dart`
- **Purpose:** Review and approve/reject member applications
- **APIs:**
  - `GET /api/applications?block=&status=Pending-Block` - Fetch applications
  - `PUT /api/applications/:id/approve` - Approve application
  - `PUT /api/applications/:id/reject` - Reject with reason
- **Navigation:** Dashboard → Application List → Application Detail
- **Components:**
  - Application cards with member info
  - Filter chips (All, Pending, Approved, Rejected)
  - Search bar
  - Detail modal with approve/reject buttons
- **Actions:**
  - View application details
  - Approve (forward to district)
  - Reject (with mandatory reason)
  - Add comments
- **Validation:**
  - Rejection reason: Required, min 10 characters

#### 1.9.3 Block Admin Member List
- **File:** `lib/screens/Block Admin/blockadmin_member_list.dart`
- **Purpose:** View all members in block jurisdiction
- **APIs:**
  - `GET /api/admin/block/members` - List members
  - `GET /api/members/:id` - Member details
- **Navigation:** Dashboard → Member List → Member Profile
- **Components:**
  - DataTable with sorting
  - Search and filters
  - Export to CSV button
- **Features:**
  - Pagination
  - Column sorting
  - Location filtering

#### 1.9.4 Block Admin Settings
- **File:** `lib/screens/Block Admin/blockadmin_settings.dart`
- **Purpose:** Admin account settings and configuration
- **APIs:**
  - `GET /api/admin/:id` - Admin profile
  - `PUT /api/admin/:id` - Update profile
  - `PUT /api/admin/:id/password` - Change password
- **Navigation:** Dashboard → Settings
- **Form Fields:**
  - Name
  - Email
  - Phone
  - Current password
  - New password
  - Confirm password
- **Features:**
  - Profile update
  - Password change
  - Notification preferences
  - Logout

---

### 1.10 Admin Screens - District Level

#### 1.10.1 District Admin Dashboard
- **File:** `lib/screens/District Admin/districtadmin_dashboard.dart`
- **Purpose:** District-level application overview
- **APIs:**
  - `GET /api/admin/district/dashboard` - Stats
  - `GET /api/admin/district/pending` - Pending applications
- **Navigation:** Login → Dashboard → Approval Queue
- **Components:**
  - District-wide statistics
  - Block-wise breakdown
  - Pending applications list
- **Metrics:**
  - Total applications in district
  - Block-wise distribution
  - Approval rate

#### 1.10.2 District Admin Approval Page
- **File:** `lib/screens/District Admin/districtadmin_approval_page.dart`
- **Purpose:** Review block-approved applications
- **APIs:**
  - `GET /api/applications?district=&status=Pending-District`
  - `PUT /api/applications/:id/district-approve`
  - `PUT /api/applications/:id/district-reject`
- **Navigation:** Dashboard → Applications → Detail
- **Components:**
  - Application list with block info
  - Block admin's comments display
  - Approve/Reject actions
  - District admin comments field
- **Workflow:**
  - Reviews applications approved by block admins
  - Can approve (forward to state) or reject (back to block)
  - Must review block admin comments

---

### 1.11 Admin Screens - State Level

#### 1.11.1 State Admin Dashboard
- **File:** `lib/screens/State Admin/stateadmin_dashboard.dart`
- **Purpose:** State-level oversight of all applications
- **APIs:**
  - `GET /api/admin/state/dashboard` - State statistics
  - `GET /api/admin/state/pending` - Pending state approval
- **Navigation:** Login → Dashboard → Applications
- **Components:**
  - State-wide metrics
  - District-wise breakdown
  - Trend charts
- **Metrics:**
  - Total state applications
  - District performance
  - Approval timeline averages

#### 1.11.2 State Admin Approval Page
- **File:** `lib/screens/State Admin/stateadmin_approval_page.dart`
- **Purpose:** Final approval authority for memberships
- **APIs:**
  - `GET /api/applications?state=&status=Pending-State`
  - `PUT /api/applications/:id/state-approve` - Final approval
  - `PUT /api/applications/:id/state-reject` - Final rejection
- **Navigation:** Dashboard → Applications → Final Decision
- **Components:**
  - Complete application history
  - All admin comments timeline
  - Final approval button
  - Rejection with state-level reason
- **Workflow:**
  - Reviews district-approved applications
  - Final approval grants full membership
  - Can reject with state-level concerns
  - Rejection requires detailed reasoning

---

### 1.12 Super Admin

#### 1.12.1 Super Admin Dashboard
- **File:** `lib/screens/Super Admin/superadmin_dashboard.dart`
- **Purpose:** System-wide administration and analytics
- **APIs:**
  - `GET /api/admin/super/dashboard` - System stats
  - `GET /api/admin/super/users` - All users
  - `GET /api/admin/super/analytics` - Platform analytics
- **Navigation:** Login → Super Dashboard → Management Screens
- **Components:**
  - System health metrics
  - User growth charts
  - Admin activity logs
  - Quick management actions
- **Features:**
  - User management (create/edit/delete admins)
  - System configuration
  - Platform analytics
  - Audit logs
  - Emergency controls

---

## 2. Navigation Flow

### 2.1 Authentication Flow
```
App Launch
    ↓
[AuthWrapper checks session]
    ↓
Has Valid Session? 
    ├─ Yes → Role-Based Dashboard
    │         ├─ Member → Member Dashboard
    │         ├─ Block Admin → Block Admin Dashboard
    │         ├─ District Admin → District Admin Dashboard
    │         ├─ State Admin → State Admin Dashboard
    │         └─ Super Admin → Super Admin Dashboard
    │
    └─ No → Onboarding Screen
              ↓
          Login Screen
              ↓
          Login Success → Role-Based Dashboard
```

### 2.2 Member Registration Flow
```
Login Screen (New User)
    ↓
Registration Step 1 (Basic Info)
    ↓
API: POST /api/auth/register
    ↓
Registration Step 2 (Location)
    ↓
API: PUT /api/members/:id
    ↓
Member Dashboard
```

### 2.3 Member Application Flow
```
Member Dashboard
    ↓
Personal Details Form
    ↓
API: PUT /api/members/:id (personal details)
    ↓
Business Details Form (if business owner)
    ↓
API: POST /api/business-info
    ↓
Financial Details Form
    ↓
API: POST /api/financial-info
    ↓
Review & Submit
    ↓
API: POST /api/applications
    ↓
Application Submitted Screen
    ↓
Dashboard (shows Application Status card)
```

### 2.4 Admin Approval Workflow
```
Member Submits Application
    ↓
Status: Pending-Block
    ↓
Block Admin Reviews
    ├─ Approve → Status: Pending-District
    │               ↓
    │           District Admin Reviews
    │               ├─ Approve → Status: Pending-State
    │               │               ↓
    │               │           State Admin Reviews
    │               │               ├─ Approve → Status: Approved (Final)
    │               │               └─ Reject → Status: Rejected (Final)
    │               │
    │               └─ Reject → Status: Rejected
    │
    └─ Reject → Status: Rejected
```

### 2.5 Business Profile Flow
```
Member Dashboard
    ↓
Create Business Account
    ↓
Business Profile Screen
    ↓
API: POST /api/business-profiles
    ↓
Business Dashboard
    ↓
Manage Companies
    ├─ Add Company
    │   ↓
    │   API: POST /api/companies
    │
    ├─ Add Products
    │   ↓
    │   API: POST /api/products
    │
    └─ View Analytics
        ↓
        API: GET /api/business/stats
```

### 2.6 Payment Flow
```
Member Dashboard
    ↓
Complete Membership
    ↓
Select Plan (Aspirant/Company)
    ↓
API: POST /api/payment/create-order
    ↓
Payment WebView (Razorpay)
    ├─ Success
    │   ↓
    │   API: POST /api/payment/verify
    │   ↓
    │   Payment Success Screen
    │   ↓
    │   Dashboard (Membership Active)
    │
    └─ Failure → Payment Failed Screen → Retry
```

### 2.7 Bottom Navigation Flow (Member)
```
Member Dashboard
    │
    ├─ [Home Tab] → Dashboard Screen
    │
    ├─ [Explore Tab] → Browse Members Screen
    │                      ↓
    │                  Member Profile Detail
    │
    └─ [Notifications Tab] → Notification Screen
                                  ↓
                              Notification Detail
```

---

## 3. Reusable Components

### 3.1 Widgets

#### 3.1.1 Company Switcher Widget
- **File:** `lib/widgets/company_switcher_widget.dart`
- **Purpose:** Dropdown to switch between multiple companies
- **Parameters:**
  - `companies`: List<Company>
  - `selectedCompanyId`: String
  - `onCompanyChanged`: Function(String)
- **Used In:**
  - Business Dashboard
  - Manage Companies Screen
  - Add Product Screen
- **Features:**
  - Dynamic company list
  - Persist selection using Provider
  - Company-specific context switching

#### 3.1.2 Custom Buttons
- **Location:** Throughout app (inline)
- **Types:**
  - Primary Button (elevated, blue)
  - Secondary Button (outlined)
  - Text Button (flat)
- **Common Parameters:**
  - `text`: String
  - `onPressed`: VoidCallback
  - `isLoading`: bool (shows spinner)
  - `width`: double?

#### 3.1.3 Form Field Widgets
- **TextFormField with Validation**
  - Custom validators
  - Error message display
  - Input formatting
- **DropdownFormField**
  - Searchable dropdown
  - Cascading selections (state → district → block)
- **ImagePickerWidget**
  - Single/multiple image selection
  - Camera/gallery options
  - Image preview
  - Crop functionality

#### 3.1.4 Status Badge Widget
- **Purpose:** Display application/membership status
- **Parameters:**
  - `status`: String
  - `size`: BadgeSize
- **Status Colors:**
  - Pending: Yellow
  - Approved: Green
  - Rejected: Red
  - Active: Blue
- **Used In:**
  - Dashboard cards
  - Application list
  - Admin approval screens

#### 3.1.5 Profile Card Widget
- **Purpose:** Display member profile summary
- **Parameters:**
  - `member`: Member object
  - `onTap`: VoidCallback
- **Components:**
  - Profile photo
  - Name and location
  - Business type (if applicable)
  - Quick actions (call, message)
- **Used In:**
  - Browse Members
  - Admin member lists
  - Search results

---

### 3.2 Utility Classes

#### 3.2.1 Validators
- **File:** `lib/utils/validators.dart` (implied)
- **Functions:**
  - `validateEmail(String)` - Email regex validation
  - `validatePhone(String)` - 10-digit phone validation
  - `validateAadhaar(String)` - 12-digit Aadhaar validation
  - `validateGST(String)` - 15-char GST validation
  - `validateIFSC(String)` - IFSC code format
  - `validatePassword(String)` - Min length, complexity
  - `validateRequired(String)` - Non-empty check

#### 3.2.2 Cache Manager
- **File:** `lib/utils/cache_manager.dart`
- **Purpose:** Fast in-memory caching for API responses
- **Methods:**
  - `get(String key)` - Retrieve cached data
  - `set(String key, dynamic value, Duration ttl)` - Store with TTL
  - `remove(String key)` - Invalidate cache
  - `clear()` - Clear all cache
- **Used For:**
  - Member list caching
  - Profile data caching
  - Reduce API calls

#### 3.2.3 Date Formatters
- **Purpose:** Consistent date/time formatting
- **Functions:**
  - `formatDate(DateTime)` - "Dec 8, 2025"
  - `formatDateTime(DateTime)` - "Dec 8, 2025 10:30 AM"
  - `formatRelativeTime(DateTime)` - "2 hours ago"
- **Used In:** Notifications, application timeline, activity logs

---

### 3.3 Common UI Patterns

#### 3.3.1 Loading States
- **Pattern:** CircularProgressIndicator centered
- **Implementation:**
  ```dart
  isLoading 
    ? Center(child: CircularProgressIndicator())
    : ContentWidget()
  ```
- **Used:** All API-dependent screens

#### 3.3.2 Empty States
- **Pattern:** Icon + Message + Action button
- **Components:**
  - Empty state icon
  - Descriptive message
  - Call-to-action button
- **Examples:**
  - "No notifications yet"
  - "No applications pending"
  - "No companies created"

#### 3.3.3 Error Handling
- **Pattern:** SnackBar for errors
- **Implementation:**
  ```dart
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error message'))
  );
  ```
- **Used:** API failures, validation errors

#### 3.3.4 Pull to Refresh
- **Widget:** RefreshIndicator
- **Used In:**
  - Dashboard
  - Application lists
  - Member lists
  - Notifications

---

## 4. Animations and Transitions

### 4.1 Page Transitions

#### 4.1.1 Default Navigation
- **Type:** MaterialPageRoute with default slide animation
- **Direction:** Right to left (push), left to right (pop)
- **Duration:** ~300ms
- **Used:** All standard navigation

#### 4.1.2 Hero Animations
- **Used For:** Profile photo transitions
- **Implementation:**
  - Wrap source image in Hero widget with tag
  - Destination screen uses same tag
- **Screens:**
  - Member list → Member detail
  - Profile card → Full profile

#### 4.1.3 Fade Transitions
- **Type:** FadeTransition
- **Used For:**
  - Modal dialogs
  - Bottom sheets
  - Overlay widgets
- **Duration:** 200ms

### 4.2 UI Animations

#### 4.2.1 Loading Animations
- **Type:** Circular progress indicator (rotating)
- **Used:** Button loading states, page loading

#### 4.2.2 Success Animations
- **Type:** Lottie animations
- **Files:** 
  - `assets/animations/success.json`
  - `assets/animations/checkmark.json`
- **Used In:**
  - Payment success
  - Application submitted
  - Profile updated

#### 4.2.3 Expand/Collapse Animations
- **Type:** AnimatedSize or ExpansionTile
- **Used For:**
  - Accordion lists
  - Detail expansion
  - Filter panels
- **Duration:** 300ms

#### 4.2.4 List Animations
- **Type:** AnimatedList / ListView.builder with animation
- **Used For:**
  - Notifications appearing
  - Application list updates
  - Member search results

### 4.3 Micro-interactions

#### 4.3.1 Button Press Animation
- **Type:** Scale animation (99% → 100%)
- **Duration:** 100ms
- **Used:** All interactive buttons

#### 4.3.2 Card Tap Ripple
- **Type:** InkWell ripple effect
- **Used:** All tappable cards

#### 4.3.3 Badge Pulse Animation
- **Type:** Scale pulse (for unread counts)
- **Used:** Notification badge, pending application count

---

## 5. Forms and Validations

### 5.1 Form Summary Table

| Form Screen | Fields Count | Validation Types | Submission API |
|-------------|--------------|------------------|----------------|
| Login | 2 | Email, Password | POST /api/auth/login |
| Registration Step 1 | 5 | Email, Phone, Password Match | POST /api/auth/register |
| Registration Step 2 | 4 | Required, Dropdown | PUT /api/members/:id |
| Personal Details | 15+ | Aadhaar, Required, Dropdown | PUT /api/members/:id |
| Business Details | 8 | GST, Registration No | POST /api/business-info |
| Financial Details | 4 | IFSC, Account No | POST /api/financial-info |
| Business Profile | 12 | URL, Email, Phone | POST /api/business-profiles |
| Add Product | 6 | Price, Stock, Required | POST /api/products |
| Admin Rejection | 1 | Min 10 chars | PUT /api/applications/:id/reject |

### 5.2 Detailed Form Validations

#### 5.2.1 Login Form
- **Email Field:**
  - Type: TextFormField
  - Validation: Required, Email format
  - Regex: `^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$`
  - Error: "Please enter a valid email"
  
- **Password Field:**
  - Type: TextFormField (obscureText: true)
  - Validation: Required, Min 6 characters
  - Error: "Password must be at least 6 characters"

#### 5.2.2 Personal Details Form
- **Aadhaar Number:**
  - Type: TextFormField
  - Validation: Required, Exactly 12 digits
  - Regex: `^[0-9]{12}$`
  - Error: "Aadhaar must be 12 digits"
  
- **Educational Qualification:**
  - Type: DropdownButtonFormField
  - Options: [Below 10th, 10th Pass, 12th Pass, Graduate, Post Graduate, PhD]
  - Validation: Required
  
- **Pincode:**
  - Type: TextFormField
  - Validation: Required, 6 digits
  - Regex: `^[0-9]{6}$`
  - Error: "Pincode must be 6 digits"

#### 5.2.3 Business Details Form
- **GST Number:**
  - Type: TextFormField
  - Validation: Optional, If provided must be 15 chars
  - Regex: `^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$`
  - Error: "Invalid GST format"

- **Business Registration Number:**
  - Type: TextFormField
  - Validation: Required for companies
  - Min Length: 5 characters

#### 5.2.4 Financial Details Form
- **IFSC Code:**
  - Type: TextFormField
  - Validation: Required, 11 characters
  - Regex: `^[A-Z]{4}0[A-Z0-9]{6}$`
  - Error: "Invalid IFSC code"

- **Account Number:**
  - Type: TextFormField
  - Validation: Required, 9-18 digits
  - Regex: `^[0-9]{9,18}$`
  - Error: "Invalid account number"

#### 5.2.5 Admin Rejection Form
- **Rejection Reason:**
  - Type: TextFormField (multiline)
  - Validation: Required, Min 10 characters
  - Max Length: 500 characters
  - Error: "Please provide detailed reason (min 10 characters)"

### 5.3 Form State Management

#### 5.3.1 Form Controllers
- **TextEditingController:** Used for all text fields
- **Lifecycle:** 
  - initState() → Initialize controllers
  - dispose() → Dispose controllers
- **Example:**
  ```dart
  final _emailController = TextEditingController();
  
  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
  ```

#### 5.3.2 Form Validation
- **GlobalKey<FormState>:** Form validation key
- **Validation Trigger:** Manual (on submit button press)
- **Implementation:**
  ```dart
  final _formKey = GlobalKey<FormState>();
  
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Submit to API
    }
  }
  ```

#### 5.3.3 Loading States
- **Pattern:** Disable submit button during API call
- **Implementation:**
  ```dart
  bool _isSubmitting = false;
  
  ElevatedButton(
    onPressed: _isSubmitting ? null : _submitForm,
    child: _isSubmitting 
      ? CircularProgressIndicator()
      : Text('Submit')
  )
  ```

---

## 6. API Mapping

### 6.1 API Base Configuration
- **Base URL:** 
  - Development: `http://10.42.208.174:3000/api`
  - Production: `https://actv-project.onrender.com/api`
- **Request Timeout:** 
  - Local: 12 seconds
  - Production (Render): 75 seconds (cold start handling)
- **Authentication:** Bearer token in Authorization header
- **Content-Type:** application/json

### 6.2 Authentication APIs

| Endpoint | Method | Request Body | Response | Used In |
|----------|--------|--------------|----------|---------|
| `/auth/register` | POST | `{ email, password, fullName, phoneNumber }` | `{ success, token, user }` | Registration Step 1 |
| `/auth/login` | POST | `{ email, password }` | `{ success, token, user, role }` | Login Screen |
| `/auth/logout` | POST | - | `{ success }` | Profile Settings |
| `/auth/validate-token` | GET | - | `{ valid, user }` | AuthWrapper |

### 6.3 Member APIs

| Endpoint | Method | Request Body | Response | Used In |
|----------|--------|--------------|----------|---------|
| `/members/:id` | GET | - | `{ member details }` | Profile Screen |
| `/members/:id` | PUT | `{ updates }` | `{ success, member }` | Edit Profile, Forms |
| `/members/:id/status` | GET | - | `{ profileCompletion, hasApplication, applicationStatus, hasBusinessProfile }` | Dashboard |
| `/members/:email/details` | GET | - | `{ member details }` | Dashboard |
| `/members/:id/photo` | POST | FormData (image) | `{ photoUrl }` | Profile Photo Upload |

### 6.4 Application APIs

| Endpoint | Method | Request Body | Response | Used In |
|----------|--------|--------------|----------|---------|
| `/applications` | POST | `{ userId, formData, memberType }` | `{ success, applicationId }` | Application Submission |
| `/applications/:userId` | GET | - | `{ application }` | Application Status |
| `/applications/:id/timeline` | GET | - | `{ timeline[] }` | Application Status |
| `/applications?block=&status=` | GET | Query params | `{ applications[] }` | Block Admin |
| `/applications?district=&status=` | GET | Query params | `{ applications[] }` | District Admin |
| `/applications?state=&status=` | GET | Query params | `{ applications[] }` | State Admin |
| `/applications/:id/approve` | PUT | `{ comments }` | `{ success }` | Block Admin Approval |
| `/applications/:id/reject` | PUT | `{ reason }` | `{ success }` | Admin Rejection |
| `/applications/:id/district-approve` | PUT | `{ comments }` | `{ success }` | District Admin |
| `/applications/:id/state-approve` | PUT | `{ comments }` | `{ success, membership }` | State Admin Final |

### 6.5 Business Profile APIs

| Endpoint | Method | Request Body | Response | Used In |
|----------|--------|--------------|----------|---------|
| `/business-profiles` | POST | `{ memberId, businessData }` | `{ success, profileId }` | Business Profile Creation |
| `/business-profiles/:memberId` | GET | - | `{ businessProfile }` | Business Dashboard |
| `/business-profiles/:id` | PUT | `{ updates }` | `{ success }` | Edit Business Profile |
| `/business-info` | POST | `{ memberId, businessInfo }` | `{ success }` | Business Details Form |
| `/financial-info` | POST | `{ memberId, financialInfo }` | `{ success }` | Financial Details Form |

### 6.6 Company Management APIs

| Endpoint | Method | Request Body | Response | Used In |
|----------|--------|--------------|----------|---------|
| `/companies?memberId=` | GET | Query param | `{ companies[] }` | Manage Companies |
| `/companies` | POST | `{ memberId, companyName, details }` | `{ success, companyId }` | Add Company |
| `/companies/:id` | PUT | `{ updates }` | `{ success }` | Edit Company |
| `/companies/:id` | DELETE | - | `{ success }` | Delete Company |
| `/business/stats/:companyId` | GET | - | `{ views, products, orders }` | Business Dashboard |
| `/business/activities/:companyId` | GET | - | `{ activities[] }` | Business Dashboard |

### 6.7 Product APIs

| Endpoint | Method | Request Body | Response | Used In |
|----------|--------|--------------|----------|---------|
| `/products` | POST | `{ companyId, productData }` | `{ success, productId }` | Add Product |
| `/products/:id` | PUT | `{ updates }` | `{ success }` | Edit Product |
| `/products/:id` | DELETE | - | `{ success }` | Delete Product |
| `/products/:id/images` | POST | FormData (images) | `{ imageUrls[] }` | Product Images Upload |
| `/products?companyId=` | GET | Query param | `{ products[] }` | Product List |

### 6.8 Browse Members APIs

| Endpoint | Method | Request Body | Response | Used In |
|----------|--------|--------------|----------|---------|
| `/browse-members` | GET | Query params (filters) | `{ members[], total }` | Browse Members |
| `/browse-members/search?query=` | GET | Query param | `{ members[] }` | Member Search |
| `/browse-members/:id` | GET | - | `{ member details }` | Member Profile Detail |

### 6.9 Payment APIs

| Endpoint | Method | Request Body | Response | Used In |
|----------|--------|--------------|----------|---------|
| `/payment/create-order` | POST | `{ amount, planType, userId }` | `{ orderId, razorpayKey }` | Membership Payment |
| `/payment/verify` | POST | `{ orderId, paymentId, signature }` | `{ success, membership }` | Payment Verification |
| `/membership/plans` | GET | - | `{ plans[] }` | Complete Membership |
| `/payment/:orderId` | GET | - | `{ payment details }` | Payment Success |

### 6.10 Notification APIs

| Endpoint | Method | Request Body | Response | Used In |
|----------|--------|--------------|----------|---------|
| `/notifications/:userId` | GET | - | `{ notifications[] }` | Notification Screen |
| `/notifications/:id/read` | PUT | - | `{ success }` | Mark as Read |
| `/notifications/unread-count/:userId` | GET | - | `{ count }` | Badge Count |

### 6.11 Admin Dashboard APIs

| Endpoint | Method | Request Body | Response | Used In |
|----------|--------|--------------|----------|---------|
| `/admin/block/dashboard` | GET | - | `{ stats }` | Block Admin Dashboard |
| `/admin/block/pending-applications` | GET | - | `{ count }` | Block Admin Dashboard |
| `/admin/block/members` | GET | - | `{ members[] }` | Block Member List |
| `/admin/district/dashboard` | GET | - | `{ stats }` | District Dashboard |
| `/admin/state/dashboard` | GET | - | `{ stats }` | State Dashboard |
| `/admin/super/dashboard` | GET | - | `{ systemStats }` | Super Admin Dashboard |
| `/admin/:id` | GET | - | `{ admin profile }` | Admin Settings |
| `/admin/:id` | PUT | `{ updates }` | `{ success }` | Update Admin Profile |
| `/admin/:id/password` | PUT | `{ currentPassword, newPassword }` | `{ success }` | Change Password |

### 6.12 API Error Handling

#### Common Error Responses
```json
{
  "success": false,
  "message": "Error description",
  "error": "Detailed error (dev mode only)"
}
```

#### HTTP Status Codes Used
- **200:** Success
- **201:** Created
- **400:** Bad Request (validation error)
- **401:** Unauthorized (invalid/missing token)
- **403:** Forbidden (insufficient permissions)
- **404:** Not Found
- **500:** Server Error

#### Error Handling Pattern
```dart
try {
  final response = await http.get(url);
  if (response.statusCode == 200) {
    // Success
  } else if (response.statusCode == 401) {
    // Redirect to login
  } else {
    // Show error message
  }
} catch (e) {
  // Network error
}
```

---

## 7. Summary Overview

### 7.1 Application Statistics

| Metric | Count |
|--------|-------|
| **Total Screens** | 54+ |
| **API Endpoints** | 42+ |
| **Service Classes** | 16 |
| **Reusable Widgets** | 10+ |
| **State Providers** | 5 |
| **Admin Levels** | 4 |
| **Form Validations** | 30+ |
| **User Roles** | 5 |

### 7.2 Technical Stack

#### Frontend
- **Framework:** Flutter 3.9+
- **Language:** Dart 3.0+
- **State Management:** Provider Pattern
- **HTTP Client:** http package
- **Local Storage:** shared_preferences
- **Image Handling:** image_picker
- **Animations:** Lottie
- **Payment Gateway:** Razorpay

#### Backend Integration
- **API Protocol:** REST
- **Authentication:** JWT Bearer tokens
- **Data Format:** JSON
- **File Upload:** Multipart/form-data
- **Caching:** In-memory FastCacheManager

### 7.3 Key Features

#### For Members
1. ✅ Multi-step registration with validation
2. ✅ Personal profile management
3. ✅ Business profile creation
4. ✅ Multi-company management
5. ✅ Application submission and tracking
6. ✅ Membership payment integration
7. ✅ Member discovery and networking
8. ✅ Product listing for businesses
9. ✅ Real-time notifications
10. ✅ Profile completion tracking

#### For Administrators
1. ✅ Multi-level approval workflow (Block → District → State)
2. ✅ Application review and comments
3. ✅ Approval/rejection with reasons
4. ✅ Member management by jurisdiction
5. ✅ Dashboard analytics
6. ✅ Role-based access control
7. ✅ Admin settings and profile management

#### For Super Admin
1. ✅ System-wide oversight
2. ✅ User and admin management
3. ✅ Platform analytics
4. ✅ Audit logs
5. ✅ System configuration

### 7.4 Best Practices Observed

#### Code Organization
✅ **Modular Architecture:** Screens, services, widgets, providers separated  
✅ **Service Layer Pattern:** API calls abstracted into service classes  
✅ **Provider State Management:** Centralized state with ChangeNotifier  
✅ **Reusable Components:** Common widgets extracted and parameterized  

#### Performance Optimizations
✅ **API Caching:** FastCacheManager reduces redundant API calls  
✅ **Lazy Loading:** Lists use ListView.builder for efficient rendering  
✅ **Image Optimization:** Cached network images  
✅ **Conditional Rendering:** Only render visible widgets  

#### User Experience
✅ **Loading States:** All async operations show loading indicators  
✅ **Error Handling:** User-friendly error messages with SnackBars  
✅ **Form Validation:** Real-time validation with clear error messages  
✅ **Offline Support:** Cached data available when offline  
✅ **Pull to Refresh:** Refresh capability on all lists  

#### Security
✅ **JWT Authentication:** Secure token-based auth  
✅ **Role-Based Access:** Different screens/features per role  
✅ **Secure Storage:** Tokens stored in shared_preferences  
✅ **Input Validation:** All forms validated before submission  

### 7.5 Potential Optimizations

#### Performance
🔄 **Pagination:** Implement cursor-based pagination for large lists  
🔄 **Debouncing:** Search inputs should debounce API calls  
🔄 **Image Compression:** Compress images before upload  
🔄 **Code Splitting:** Lazy load admin screens to reduce initial bundle  

#### State Management
🔄 **BLoC Pattern:** Consider migrating to BLoC for complex state  
🔄 **Riverpod:** Modern alternative to Provider with better performance  
🔄 **State Persistence:** Save form state across app restarts  

#### User Experience
🔄 **Offline Queue:** Queue actions when offline, sync when online  
🔄 **Push Notifications:** Firebase Cloud Messaging for real-time alerts  
🔄 **Biometric Auth:** Fingerprint/Face ID for quick login  
🔄 **Dark Mode:** Theme switching support  
🔄 **Internationalization:** Multi-language support  

#### Code Quality
🔄 **Unit Tests:** Add test coverage for services and validators  
🔄 **Widget Tests:** Test critical user flows  
🔄 **Integration Tests:** End-to-end testing  
🔄 **Code Documentation:** Add JSDoc/DartDoc comments  
🔄 **Linting:** Enforce stricter lint rules  

#### Backend Integration
🔄 **GraphQL:** Consider GraphQL for flexible data fetching  
🔄 **WebSocket:** Real-time updates for notifications  
🔄 **API Versioning:** Support multiple API versions  
🔄 **Request Retry:** Automatic retry for failed requests  

---

## 8. Dependencies & Packages

### 8.1 Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  provider: ^6.0.0
  
  # HTTP & Networking
  http: ^0.13.0
  
  # Local Storage
  shared_preferences: ^2.0.0
  
  # UI Components
  flutter_dotenv: ^5.0.0
  
  # Image Handling
  image_picker: ^0.8.0
  
  # Animations
  lottie: ^2.0.0
  
  # Payment
  razorpay_flutter: ^1.3.0
```

### 8.2 Service Dependencies

| Service | Dependencies | Purpose |
|---------|--------------|---------|
| AuthService | shared_preferences, http | Authentication, token management |
| ApiService | http, cache_manager | HTTP requests, caching |
| MemberService | ApiService | Member CRUD operations |
| ApplicationService | ApiService | Application management |
| BusinessProfileService | ApiService | Business profile operations |
| CompanyService | ApiService | Company management |
| ProductService | ApiService | Product CRUD |
| PaymentService | razorpay_flutter, ApiService | Payment processing |
| NotificationService | ApiService | Notifications |

---

## 9. Environment Configuration

### 9.1 Environment Variables (.env)
```
API_BASE_URL=http://10.42.208.174:3000/api
RAZORPAY_KEY=rzp_test_xxxxx
RAZORPAY_SECRET=xxxxx
```

### 9.2 Build Configurations

#### Development
- **API URL:** Local backend (10.42.208.174:3000)
- **Timeout:** 12 seconds
- **Debug Mode:** Enabled
- **Logging:** Verbose

#### Production
- **API URL:** Render deployment (actv-project.onrender.com)
- **Timeout:** 75 seconds (cold start handling)
- **Debug Mode:** Disabled
- **Logging:** Errors only

---

## 10. User Roles & Permissions

### 10.1 Role Matrix

| Feature | Member | Block Admin | District Admin | State Admin | Super Admin |
|---------|--------|-------------|----------------|-------------|-------------|
| Register | ✅ | ❌ | ❌ | ❌ | ❌ |
| Submit Application | ✅ | ❌ | ❌ | ❌ | ❌ |
| Create Business Profile | ✅ | ❌ | ❌ | ❌ | ❌ |
| Browse Members | ✅ | ✅ | ✅ | ✅ | ✅ |
| Approve Block Level | ❌ | ✅ | ❌ | ❌ | ❌ |
| Approve District Level | ❌ | ❌ | ✅ | ❌ | ❌ |
| Approve State Level | ❌ | ❌ | ❌ | ✅ | ❌ |
| Manage System | ❌ | ❌ | ❌ | ❌ | ✅ |
| View Analytics | Own | Block | District | State | System |

### 10.2 Role-Based Navigation

#### Member
- Dashboard
- Browse Members
- Notifications
- Profile
- Business Account (if applicable)
- Application Status

#### Block Admin
- Dashboard
- Application Queue (Block-level)
- Member List (Block)
- Settings

#### District Admin
- Dashboard
- Application Queue (District-level)
- Member List (District)
- Settings

#### State Admin
- Dashboard
- Application Queue (State-level)
- Member List (State)
- Settings

#### Super Admin
- Dashboard
- All Users
- All Applications
- System Settings
- Analytics
- Audit Logs

---

## Conclusion

This audit document provides a comprehensive overview of the ACTIV Portal Flutter application. The app demonstrates solid architectural practices with clear separation of concerns, modular code organization, and comprehensive feature coverage for both members and multi-level administrators.

**Strengths:**
- Well-structured role-based access system
- Comprehensive validation and error handling
- Clean API integration with caching
- Reusable component architecture
- Multi-level approval workflow

**Recommended Next Steps:**
1. Implement suggested performance optimizations
2. Add comprehensive test coverage
3. Enhance offline capabilities
4. Implement push notifications
5. Add analytics tracking for user behavior

---

**Document Prepared By:** GitHub Copilot  
**Review Status:** Initial Audit  
**Last Updated:** December 8, 2025
