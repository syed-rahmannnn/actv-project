# ACTIV Member Registration & Payment Workflow

## Complete User Journey: From Registration to Active Membership

This document describes the end-to-end process of how users register, get approved, and complete payment to become active members of the ACTIV Chamber of Commerce.

---

## Overview Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                    MEMBER REGISTRATION WORKFLOW                      │
└─────────────────────────────────────────────────────────────────────┘

1. USER REGISTRATION
   └─> Email + Password → MemberAuth created
   
2. APPLICATION SUBMISSION
   └─> Complete Form → Application (Pending-Block)
   
3. THREE-TIER APPROVAL PROCESS
   ├─> Block Admin Review → Pending-District
   ├─> District Admin Review → Pending-State
   └─> State Admin Review → Approved
   
4. MEMBER PROFILE CREATION
   └─> 4 Collections Created (Details, Business, Financial, Declaration)
   
5. PAYMENT PROCESSING
   ├─> Select Membership Plan
   ├─> Instamojo Payment Gateway
   └─> Webhook Activation
   
6. ACTIVE MEMBERSHIP
   └─> Access to Platform Features
```

---

## Phase 1: User Registration

### 1.1 Initial Registration (Flutter App)

**Screen**: `RegistrationScreen` / `LoginScreen`

**User Actions**:
- User opens ACTIV app
- Clicks "Register" / "Sign Up"
- Enters email and password
- Agrees to terms & conditions
- Clicks "Register"

**API Call**:
```dart
POST /api/auth/register

Request Body:
{
  "email": "john.doe@example.com",
  "password": "SecurePassword123"
}

Response:
{
  "success": true,
  "message": "Registration successful",
  "userId": "507f1f77bcf86cd799439011",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

**Database Changes**:
- **Collection**: `memberauths`
- **Action**: Create new document
```javascript
{
  _id: "507f1f77bcf86cd799439011",
  email: "john.doe@example.com",
  password: "$2a$10$hashed_password_here", // bcrypt hashed
  isActive: true,
  createdAt: "2025-12-09T10:00:00.000Z",
  updatedAt: "2025-12-09T10:00:00.000Z"
}
```

**User Status**: ✅ Registered (Email + Password created)

---

## Phase 2: Application Submission

### 2.1 Complete Multi-Step Application Form

**Screen**: `DeclarationFormScreen`

**User Actions**:
1. **Personal Details** (Step 1)
   - Full name, phone, email
   - State, District, Block
   - Address, Aadhaar number
   - Education, religion, social category

2. **Business Information** (Step 2)
   - Doing business? (Yes/No)
   - Organization name
   - Constitution type (OPC/TRUST/SOCIETY)
   - Business type (Manufacturing/Trader/Service/Others)
   - Business activities
   - Number of employees
   - Registration (MSME/KVIC/NABARD)

3. **Financial Information** (Step 3)
   - PAN number
   - GST number
   - Udyam number
   - ITR filed (Yes/No)
   - Turnover range
   - FY 2020/2020/2021 figures
   - Government scheme benefits

4. **Declaration** (Step 4)
   - Sister concerns count
   - Company names (if any)
   - Agree to declaration checkbox
   - Submit application

**Member Type Detection**:
```dart
// Determined from form data
if (personalDetails['doingBusiness'] == true) {
  memberType = 'COMPANY';
} else if (personalDetails['memberType'] == 'ASPIRANT') {
  memberType = 'ASPIRANT';
}
```

**API Call**:
```dart
POST /api/applications/submit

Request Body:
{
  "userId": "507f1f77bcf86cd799439011",
  "fullName": "John Doe",
  "email": "john.doe@example.com",
  "phone": "+919876543210",
  "state": "Kerala",
  "district": "Ernakulam",
  "block": "Kochi",
  "formData": {
    "personalDetails": { /* all personal fields */ },
    "businessInfo": { /* all business fields */ },
    "financialInfo": { /* all financial fields */ },
    "declaration": { /* declaration data */ },
    "memberType": "COMPANY" // or "ASPIRANT"
  }
}

Response:
{
  "success": true,
  "message": "Application submitted successfully",
  "application": {
    "_id": "675f1a2b3c4d5e6f7a8b9c0d",
    "status": "Pending-Block",
    "assignedBlockAdmin": "6900c05f611665a07022c860",
    "assignedDistrictAdmin": "6900c05f611665a07022c861",
    "assignedStateAdmin": "6900c05f611665a07022c862"
  }
}
```

**Database Changes**:
- **Collection**: `applications`
- **Action**: Create new application document
```javascript
{
  _id: "675f1a2b3c4d5e6f7a8b9c0d",
  userId: "507f1f77bcf86cd799439011",
  fullName: "John Doe",
  email: "john.doe@example.com",
  phone: "+919876543210",
  state: "Kerala",
  district: "Ernakulam",
  block: "Kochi",
  formData: { /* complete form data */ },
  status: "Pending-Block",
  assignedBlockAdmin: "6900c05f611665a07022c860",
  assignedDistrictAdmin: "6900c05f611665a07022c861",
  assignedStateAdmin: "6900c05f611665a07022c862",
  createdAt: "2025-12-09T10:15:00.000Z",
  updatedAt: "2025-12-09T10:15:00.000Z"
}
```

**User Status**: ⏳ Application Submitted (Waiting for Block Admin Review)

---

## Phase 3: Three-Tier Approval Process

### 3.1 Block Admin Review (Level 1)

**Dashboard**: `BlockAdminDashboard` → Approval Page

**Admin Actions**:
1. Block Admin logs in to admin portal
2. Views pending applications for their block
3. Reviews application details
4. Clicks on application card to view full profile
5. Either:
   - ✅ **Approves** → Application moves to District Admin
   - ❌ **Rejects** → Application is rejected with reason

**API Call (Approval)**:
```javascript
POST /api/applications/block-review/:appId

Request Body:
{
  "action": "approve",
  "adminId": "BA0001"
}

Response:
{
  "success": true,
  "status": "Pending-District",
  "message": "Application approved by Block Admin"
}
```

**Database Changes**:
```javascript
// Application document updated
{
  status: "Pending-Block" → "Pending-District",
  blockApprovedAt: "2025-12-09T11:00:00.000Z",
  reviewedBy: {
    blockAdmin: "6900c05f611665a07022c860"
  }
}
```

**User Status**: ⏳ Approved by Block Admin (Waiting for District Admin)

---

### 3.2 District Admin Review (Level 2)

**Dashboard**: `DistrictAdminDashboard` → Approval Page

**Admin Actions**:
1. District Admin logs in
2. Views applications approved by Block Admins
3. Reviews application details
4. Either:
   - ✅ **Approves** → Application moves to State Admin
   - ❌ **Rejects** → Application is rejected with reason

**API Call (Approval)**:
```javascript
POST /api/applications/district-review/:appId

Request Body:
{
  "action": "approve",
  "adminId": "DA0001"
}

Response:
{
  "success": true,
  "status": "Pending-State",
  "message": "Application approved by District Admin"
}
```

**Database Changes**:
```javascript
// Application document updated
{
  status: "Pending-District" → "Pending-State",
  districtApprovedAt: "2025-12-09T12:00:00.000Z",
  reviewedBy: {
    blockAdmin: "6900c05f611665a07022c860",
    districtAdmin: "6900c05f611665a07022c861"
  }
}
```

**User Status**: ⏳ Approved by District Admin (Waiting for State Admin - Final Level)

---

### 3.3 State Admin Review (Level 3 - Final)

**Dashboard**: `StateAdminDashboard` → Approval Page

**Admin Actions**:
1. State Admin logs in
2. Views applications approved by District Admins
3. Performs final review
4. Either:
   - ✅ **Approves** → Member profile is created
   - ❌ **Rejects** → Application is rejected with reason

**API Call (Approval)**:
```javascript
POST /api/applications/state-review/:appId

Request Body:
{
  "action": "approve",
  "adminId": "SA0001"
}

Response:
{
  "success": true,
  "status": "Approved",
  "message": "Application approved! Member profile created",
  "memberId": "675f1a2b3c4d5e6f7a8b9c0e"
}
```

**Database Changes - Multiple Collections Created**:

1. **Application Updated**:
```javascript
{
  status: "Pending-State" → "Approved",
  stateApprovedAt: "2025-12-09T13:00:00.000Z",
  reviewedBy: {
    blockAdmin: "6900c05f611665a07022c860",
    districtAdmin: "6900c05f611665a07022c861",
    stateAdmin: "6900c05f611665a07022c862"
  }
}
```

2. **MemberDetails Created** (Collection: `memberdetails`):
```javascript
{
  _id: "675f1a2b3c4d5e6f7a8b9c0e",
  fullName: "John Doe",
  email: "john.doe@example.com",
  phoneNumber: "+919876543210",
  state: "Kerala",
  district: "Ernakulam",
  block: "Kochi",
  aadhaarNumber: "123456789012",
  membershipStatus: "pending", // Payment not yet completed
  membershipType: "none",
  approvedBy: "SA0001",
  approvedBlock: "Kochi",
  approvedAt: "2025-12-09T13:00:00.000Z",
  createdAt: "2025-12-09T13:00:00.000Z"
}
```

3. **MemberBusinessInfo Created** (Collection: `memberbusinessinfos`):
```javascript
{
  _id: "675f1a2b3c4d5e6f7a8b9c0f",
  memberId: "675f1a2b3c4d5e6f7a8b9c0e",
  fullName: "John Doe",
  email: "john.doe@example.com",
  organizationName: "Doe Enterprises",
  businessType: "Manufacturing",
  status: "APPROVED",
  // ... other business fields
}
```

4. **MemberFinancialInfo Created** (Collection: `memberfinancialinfos`):
```javascript
{
  _id: "675f1a2b3c4d5e6f7a8b9c10",
  memberId: "675f1a2b3c4d5e6f7a8b9c0e",
  fullName: "John Doe",
  email: "john.doe@example.com",
  panNumber: "ABCDE1234F",
  gstNumber: "27ABCDE1234F1Z5",
  // ... other financial fields
}
```

5. **MemberDeclaration Created** (Collection: `memberdeclarations`):
```javascript
{
  _id: "675f1a2b3c4d5e6f7a8b9c11",
  memberId: "675f1a2b3c4d5e6f7a8b9c0e",
  fullName: "John Doe",
  email: "john.doe@example.com",
  agreeToDeclaration: true,
  status: "approved",
  // ... other declaration fields
}
```

**User Status**: ✅ Approved (Profile Created - Ready for Payment)

---

## Phase 4: Payment Processing

### 4.1 Complete Membership Screen

**Screen**: `CompleteMembershipScreen`

**User Actions**:
1. User logs in after approval
2. App navigates to "Complete Membership" screen
3. User sees two membership categories:
   - **Company Member** (for businesses)
   - **Aspirant Member** (for individuals/students)

**Member Type Lock**:
```dart
// System automatically locks based on application data
if (memberType == 'COMPANY') {
  // Show only Company plans
  _isLockedToCompany = true;
} else if (memberType == 'ASPIRANT') {
  // Show only Aspirant plan
  _isLockedToAspirant = true;
  _selectedPlan = 'Aspirant Plan';
}
```

### 4.2 Company Membership Plans

**Available for**: Users who selected "Doing Business" = Yes

**Plans**:

| Plan | Experience | Duration | Price | Benefits |
|------|-----------|----------|-------|----------|
| **Starter Plan** | 0 – 5 years | 1 Year | ₹500 | Basic membership, Directory listing |
| **Intermediate Plan** | 5 – 10 years | 1 Year | ₹1,000 | All Starter + Priority support |
| **Advanced Plan** | 10 – 15 years | 1 Year | ₹2,000 | All Intermediate + Premium features |
| **Lifetime Membership** | Any | Lifetime | ₹2,500 | All features forever |

**User Selection**:
1. Select experience range (affects default plan)
2. Choose plan (Starter/Intermediate/Advanced/Lifetime)
3. Review payment summary
4. Click "Complete Payment"

### 4.3 Aspirant Membership Plan

**Available for**: Students, individuals without business

**Plan**:
- **Aspirant Plan**: ₹500 (1 Year)
- Access to networking, events, learning resources
- No business profile features

### 4.4 Payment Gateway Integration

**Service**: Instamojo Payment Gateway

**Payment Flow**:

1. **Create Payment Request**:
```dart
// payment_service.dart
final result = await PaymentService.createPaymentRequest(
  amount: selectedAmount, // ₹500 to ₹2,500
  purpose: 'ACTIV Membership - $selectedPlan',
  buyerName: userData['fullName'],
  email: userData['email'],
  phone: userData['phone'],
  redirectUrl: 'https://activ-backend.com/payment-success',
);

// Response
{
  "success": true,
  "payment_url": "https://www.instamojo.com/pay/abc123xyz456/",
  "payment_request_id": "abc123xyz456"
}
```

2. **Open Payment WebView**:
```dart
// Navigate to PaymentWebViewScreen
Navigator.push(context, MaterialPageRoute(
  builder: (context) => PaymentWebViewScreen(
    paymentUrl: result['payment_url'],
    paymentRequestId: result['payment_request_id'],
  ),
));
```

3. **User Completes Payment**:
   - WebView opens Instamojo payment page
   - User enters card/UPI/net banking details
   - Completes payment securely on Instamojo
   - Instamojo redirects to success URL

4. **Payment Success Detection**:
```dart
// PaymentWebViewScreen monitors URL changes
if (currentUrl.contains('payment-success') || 
    currentUrl.contains('payment_id=')) {
  // Payment completed
  Navigator.pushReplacement(context, MaterialPageRoute(
    builder: (context) => PaymentSuccessScreen(
      membershipType: selectedPlan,
      amount: selectedAmount,
      paymentReference: extractedPaymentId,
    ),
  ));
}
```

### 4.5 Webhook Processing (Backend)

**When**: Immediately after payment is completed on Instamojo

**Webhook URL**: `https://activ-backend.com/api/webhook/instamojo`

**Instamojo Sends**:
```javascript
POST /api/webhook/instamojo

Body:
{
  "payment_id": "MOJO5b10N00J13220624",
  "payment_request_id": "abc123xyz456",
  "status": "Credit",
  "amount": "1000.00",
  "buyer": "john.doe@example.com",
  "buyer_name": "John Doe",
  "buyer_phone": "+919876543210",
  "mac": "d4f5a6b7c8d9e0f1a2b3c4d5e6f7a8b9" // Security signature
}
```

**Backend Processing**:

1. **Verify Signature** (Security):
```javascript
// routes/webhook.js
const privateSalt = process.env.INSTAMOJO_PRIVATE_SALT;
const calculatedMac = crypto
  .createHash('md5')
  .update(verificationString + '|' + privateSalt)
  .digest('hex');

if (calculatedMac === receivedMac) {
  // Signature verified - payment is genuine
}
```

2. **Activate Membership**:
```javascript
// Determine membership type from amount
const amount = parseFloat(webhookData.amount);
let membershipType = 'annual';
let expiresAt = null;

if (amount >= 2500) {
  membershipType = 'lifetime';
  expiresAt = null; // Never expires
} else if (amount >= 500) {
  membershipType = 'annual';
  expiresAt = new Date();
  expiresAt.setFullYear(expiresAt.getFullYear() + 1); // 1 year from now
}

// Update member record
await MemberDetails.findOneAndUpdate(
  { email: webhookData.buyer },
  {
    membershipStatus: 'active',
    membershipType: membershipType,
    membershipActivatedAt: new Date(),
    membershipExpiresAt: expiresAt,
    paymentId: webhookData.payment_id,
    paymentAmount: amount,
    lastPaymentDate: new Date()
  }
);
```

**Database Changes**:
```javascript
// MemberDetails updated
{
  membershipStatus: "pending" → "active",
  membershipType: "none" → "annual" (or "lifetime"),
  membershipActivatedAt: "2025-12-09T14:00:00.000Z",
  membershipExpiresAt: "2026-12-09T14:00:00.000Z", // or null for lifetime
  paymentId: "MOJO5b10N00J13220624",
  paymentAmount: 1000,
  lastPaymentDate: "2025-12-09T14:00:00.000Z"
}
```

**User Status**: 🎉 **ACTIVE MEMBER** (Payment Completed & Verified)

---

## Phase 5: Active Membership Features

### 5.1 Member Dashboard Access

**Screen**: `MemberDashboard`

**Available Features**:

1. **Profile Management**
   - View/edit personal details
   - Update business information
   - Upload profile picture
   - Add company logo

2. **Member Directory**
   - Browse all active members
   - Search by name, location, business type
   - Filter by district, block
   - View member profiles
   - Send connection requests

3. **Networking**
   - Connection requests (like LinkedIn)
   - Accept/decline connections
   - View connected members
   - Send messages

4. **Business Profile**
   - Create/manage company profile
   - Add products/services
   - Upload product images
   - Set pricing and categories
   - Feature products (for premium members)

5. **Events & Activities**
   - View upcoming chamber events
   - Register for events
   - View past event photos
   - Activity feed

6. **Notifications**
   - Connection requests
   - Application status updates
   - Event invitations
   - System announcements

7. **Membership Card**
   - Digital membership certificate
   - Download as PDF
   - Share on WhatsApp
   - QR code for verification

### 5.2 API Access (Approved Members Only)

**Browse Members API**:
```javascript
GET /api/browse-members

Query:
{
  membershipStatus: 'active', // Only approved + paid members
  profileCompleted: true,
  approvedBy: { $exists: true }
}

Response:
{
  "success": true,
  "members": [
    {
      "_id": "675f1a2b3c4d5e6f7a8b9c0e",
      "fullName": "John Doe",
      "email": "john.doe@example.com",
      "phoneNumber": "+919876543210",
      "district": "Ernakulam",
      "block": "Kochi",
      "businessInfo": {
        "organizationName": "Doe Enterprises",
        "businessType": "Manufacturing"
      },
      "membershipType": "annual",
      "membershipActivatedAt": "2025-12-09T14:00:00.000Z"
    },
    // ... more members
  ]
}
```

---

## Phase 6: Membership Expiry & Renewal

### 6.1 Annual Membership Expiry

**When**: 1 year after `membershipActivatedAt`

**System Behavior**:
- Automatic email notification 30 days before expiry
- Automatic email notification 7 days before expiry
- On expiry date: `membershipStatus` changes to `expired`
- Member can no longer access premium features
- Profile remains in system but not visible in directory

### 6.2 Membership Renewal

**Process**:
1. User logs in
2. System detects expired membership
3. Redirects to "Renew Membership" screen
4. User selects plan and completes payment
5. Membership reactivated via webhook
6. New expiry date set to 1 year from renewal date

### 6.3 Lifetime Membership

**Benefits**:
- Never expires (`membershipExpiresAt` = null)
- No renewal required
- Permanent access to all features
- One-time payment of ₹2,500

---

## Summary: Complete Timeline

| Step | Action | Duration | Status |
|------|--------|----------|--------|
| 1 | User Registration | 2 minutes | Account created |
| 2 | Application Submission | 15-20 minutes | Form submitted |
| 3 | Block Admin Review | 1-2 days | Level 1 approval |
| 4 | District Admin Review | 1-2 days | Level 2 approval |
| 5 | State Admin Review | 1-3 days | Final approval |
| 6 | Payment Processing | 5 minutes | Membership activated |
| **Total** | **Registration → Active Member** | **3-7 days** | **✅ ACTIVE** |

---

## Payment Plans Summary

### Company Members

| Plan | Experience | Price | Duration | Features |
|------|-----------|-------|----------|----------|
| Starter | 0-5 years | ₹500 | 1 Year | Basic membership, Directory |
| Intermediate | 5-10 years | ₹1,000 | 1 Year | All Starter + Priority support |
| Advanced | 10-15 years | ₹2,000 | 1 Year | All Intermediate + Premium features |
| Lifetime | Any | ₹2,500 | Forever | All features, No renewal |

### Aspirant Members

| Plan | Price | Duration | Features |
|------|-------|----------|----------|
| Aspirant | ₹500 | 1 Year | Networking, Events, Learning |

---

## Security Features

### 1. Authentication Security
- Passwords hashed with bcrypt (cost: 10)
- JWT tokens with 7-day expiration
- Token verification on all protected routes

### 2. Payment Security
- Instamojo PCI-DSS compliant gateway
- Webhook signature verification (MAC)
- SSL/TLS encrypted transactions
- No card details stored on server

### 3. Data Privacy
- Personal information encrypted at rest
- Email/phone used only for verification
- Aadhaar number stored securely
- GDPR-compliant data handling

### 4. Admin Access Control
- Role-based permissions (Block/District/State)
- Admin actions logged for audit
- Cannot approve applications outside jurisdiction
- Requires authentication for all admin APIs

---

## Error Handling

### Common Scenarios

**1. Payment Failed**:
- User shown error message
- Can retry payment immediately
- No membership activation
- No database changes

**2. Webhook Timeout**:
- Backend retries webhook processing
- User notified to contact support
- Manual activation by admin if needed

**3. Duplicate Application**:
- System checks for existing pending application
- Returns error: "You already have a pending application"
- User must wait for approval before resubmitting

**4. Admin Rejection**:
- User notified via email
- Reason provided by admin
- User can edit and resubmit application
- No payment taken if rejected

**5. Network Failure During Payment**:
- Instamojo handles transaction state
- Webhook triggered even if user closes app
- Membership activated automatically
- User can check status in app

---

## API Endpoints Summary

| Endpoint | Method | Purpose | Auth Required |
|----------|--------|---------|---------------|
| `/api/auth/register` | POST | Register new user | No |
| `/api/auth/login` | POST | User login | No |
| `/api/applications/submit` | POST | Submit application | Yes (JWT) |
| `/api/applications/block-review/:id` | POST | Block admin review | Yes (Admin) |
| `/api/applications/district-review/:id` | POST | District admin review | Yes (Admin) |
| `/api/applications/state-review/:id` | POST | State admin review | Yes (Admin) |
| `/api/webhook/instamojo` | POST | Payment webhook | No (Signature) |
| `/api/browse-members` | GET | List active members | Yes (JWT) |
| `/api/members/:id` | GET | Get member details | Yes (JWT) |
| `/api/profile/:id` | PUT | Update profile | Yes (JWT) |

---

## Database Collections Involved

| Collection | Created At | Purpose |
|------------|-----------|---------|
| `memberauths` | Registration | Login credentials |
| `applications` | Form Submission | Application tracking |
| `memberdetails` | State Approval | Core member profile |
| `memberbusinessinfos` | State Approval | Business information |
| `memberfinancialinfos` | State Approval | Financial data |
| `memberdeclarations` | State Approval | Declaration form |
| `notifications` | Various | User notifications |
| `connections` | Active Members | Member networking |
| `activities` | Active Members | Activity logs |
| `products` | Active Members | Product catalog |

---

## Future Enhancements

### Planned Features

1. **Auto-Renewal**
   - Credit card on file
   - Automatic charge before expiry
   - Email notification of renewal

2. **Bulk Payments**
   - Corporate packages (10+ members)
   - Discounted rates for bulk
   - Single invoice for all members

3. **Payment Plans**
   - EMI options for lifetime membership
   - Quarterly/Half-yearly payment options

4. **Referral Program**
   - Refer new members, get discount
   - Referral bonus credits
   - Leaderboard for top referrers

5. **Mobile Payment Integration**
   - Google Pay direct integration
   - PhonePe integration
   - UPI Autopay for renewals

---

## Support & Troubleshooting

### User Support

**Issue**: "Payment completed but membership not activated"
- **Solution**: Check webhook logs, manually activate via admin panel

**Issue**: "Application stuck in pending"
- **Solution**: Contact assigned admin, escalate to higher level if needed

**Issue**: "Cannot access member directory"
- **Solution**: Verify payment status, check membership expiry date

### Admin Support

**Issue**: "Cannot find application to review"
- **Solution**: Check status filters, verify admin jurisdiction

**Issue**: "Application approval failed"
- **Solution**: Check server logs, verify database connection

### Technical Support

**Logs Location**:
- Backend: `activ-backend/logs/pm2-out.log`
- Webhook: `activ-backend/logs/webhook.log`
- Payment: Search for "Payment" in logs

**Database Queries**:
```javascript
// Check member payment status
db.memberdetails.findOne({ email: "user@example.com" })

// Check application status
db.applications.findOne({ userId: "507f1f77bcf86cd799439011" })

// Check recent payments
db.memberdetails.find({ 
  lastPaymentDate: { $gte: new Date('2025-12-09') } 
})
```

---

## Contact Information

**For Users**:
- Email: support@activchamber.com
- Phone: +91-XXXX-XXXXXX
- WhatsApp: +91-XXXX-XXXXXX

**For Admins**:
- Admin Portal: https://admin.activchamber.com
- Email: admin@activchamber.com

**Technical Issues**:
- Developer Email: tech@activchamber.com
- GitHub: https://github.com/activ-chamber

---

**Last Updated**: December 9, 2025  
**Version**: 1.0.0  
**Status**: Production Ready ✅
