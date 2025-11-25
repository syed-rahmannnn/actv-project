# Payment Integration Guide - ACTIV App

## ✅ Completed Setup

### Backend Webhook (Working!)
- ✅ Webhook endpoint: `/api/webhook`
- ✅ MAC signature verification implemented
- ✅ Server running on port 3000
- ✅ ngrok tunnel active
- ✅ **Status: 200 OK from Instamojo** 

### Frontend Flutter App
- ✅ Payment screen with 3 membership options
- ✅ Instamojo API integration
- ✅ WebView for payment page
- ✅ Payment verification service
- ✅ Environment variables configured

---

## 🚀 How the Payment Flow Works

### 1. User Selects Membership Plan
```
User opens Payment Screen → Selects plan:
- Annual Membership (₹500/year)
- Lifetime Membership (₹2500)
- Support ACTIV (custom amount)
```

### 2. User Initiates Payment
```dart
// When user taps "Pay ₹xxx"
1. App calls PaymentService.createPaymentRequest()
2. Instamojo API creates payment request
3. Returns payment URL (longurl)
4. App navigates to PaymentWebViewScreen
```

### 3. Payment in WebView
```
User completes payment in WebView →
Instamojo redirects to: https://activ-app.com/payment/success
```

### 4. Payment Verification (Two Methods)

#### Method A: Redirect URL (Immediate)
```dart
// WebView detects redirect URL
→ Parses payment_id and payment_request_id
→ Calls PaymentService.getPaymentStatus()
→ Verifies payment status
→ Shows success/failure dialog
```

#### Method B: Webhook (Reliable) ✅
```
Instamojo sends webhook to backend →
POST https://237a577e5e34.ngrok-free.app/api/webhook

Backend verifies MAC signature →
Updates database (activates membership) →
User membership status updated
```

---

## 📱 Testing the Complete Flow

### Step 1: Ensure Backend is Running
```bash
# Server should be running on port 3000
# Check PowerShell window - should show:
Server is running on port 3000
Environment: development
Connected to MongoDB
```

### Step 2: Ensure ngrok is Running
```bash
# Check ngrok PowerShell window
# Current URL: https://237a577e5e34.ngrok-free.app
Forwarding: https://237a577e5e34.ngrok-free.app -> http://localhost:3000
```

### Step 3: Configure Instamojo Webhook
1. Go to Instamojo Dashboard
2. Navigate to: API & Plugins → Webhooks
3. Set webhook URL: `https://237a577e5e34.ngrok-free.app/api/webhook`
4. Save

### Step 4: Run Flutter App
```bash
flutter run
```

### Step 5: Test Payment
1. **Navigate to Payment Screen** from your app
2. **Select a membership plan**:
   - Annual (₹500)
   - Lifetime (₹2500)
   - Or enter custom amount for Support ACTIV

3. **Tap "Pay ₹xxx"**
   - Loading dialog appears
   - Payment URL is created
   - WebView opens with Instamojo payment page

4. **Complete Test Payment** (Instamojo Test Mode):
   - Use test card: `4242 4242 4242 4242`
   - Any future expiry date
   - Any CVV

5. **Payment Success**:
   - User redirected to success URL
   - App verifies payment status
   - Success dialog appears
   - Webhook sent to backend (check server logs!)

### Step 6: Verify Backend Received Webhook
Check the server PowerShell window. You should see:
```
========================================
📥 Webhook received at: 2025-11-18T...
========================================
📋 Request headers: { ... }
📦 Request body: {
  "amount": "500.00",
  "buyer": "user@email.com",
  "status": "Credit",
  ...
}
🔐 Verification string: ...
🔑 Received MAC: ...
🔑 Calculated MAC: ...
✅ Signature verified successfully
💳 Payment details: ...
🎉 Payment successful! Activating membership...
📤 Sending success response to Instamojo
```

---

## 🔧 Implementation Details

### Frontend Files
```
lib/
├── screens/Payment/
│   ├── payment_screen.dart           # Main payment UI
│   └── payment_webview_screen.dart   # WebView for Instamojo
├── services/
│   ├── payment_service.dart          # Instamojo API calls
│   └── payment_verification_service.dart # Payment verification
└── config/
    └── instamojo_config.dart         # Configuration
```

### Backend Files
```
activ-backend/
├── server.js                         # Express server
├── routes/
│   └── webhook.js                    # Webhook handler
└── config.env                        # Environment variables
```

### Key Functions

#### 1. Create Payment Request
```dart
final result = await PaymentService.createPaymentRequest(
  amount: 500.00,
  purpose: 'Annual Membership',
  buyerName: 'John Doe',
  email: 'john@example.com',
  phone: '+919876543210',
  redirectUrl: 'https://activ-app.com/payment/success',
);
// Returns: { success: true, payment_url: '...', payment_request_id: '...' }
```

#### 2. Verify Payment Status
```dart
final result = await PaymentService.getPaymentStatus(paymentRequestId);
// Returns payment status and list of completed payments
```

#### 3. Backend Webhook Handler
```javascript
// Receives webhook from Instamojo
// Verifies MAC signature
// Updates database
// Activates user membership
```

---

## 🎯 Next Steps

### 1. Implement Database Update Logic
In `activ-backend/routes/webhook.js`, update the `activateMembership()` function:

```javascript
async function activateMembership(paymentData) {
  const Member = require('../models/MemberDetails');
  
  await Member.findOneAndUpdate(
    { email: paymentData.email },
    {
      membershipStatus: 'active',
      membershipType: paymentData.amount >= 2500 ? 'lifetime' : 'annual',
      membershipActivatedAt: new Date(),
      paymentId: paymentData.paymentId,
      paymentAmount: paymentData.amount,
      lastPaymentDate: new Date(),
    }
  );
  
  console.log('✅ Membership activated for:', paymentData.email);
}
```

### 2. Add Membership Status Check
Add endpoint to check user's membership status:

```javascript
// In backend server.js or new route file
app.get('/api/membership/status/:email', async (req, res) => {
  const member = await Member.findOne({ email: req.params.email });
  res.json({
    isMember: member?.membershipStatus === 'active',
    membershipType: member?.membershipType,
    activatedAt: member?.membershipActivatedAt,
  });
});
```

### 3. Update Frontend to Check Membership
After successful payment, check membership status:

```dart
// In your app, after payment success
final membershipStatus = await checkMembershipStatus(userEmail);
if (membershipStatus['isMember']) {
  // Navigate to member-only features
  // Update UI to show membership badge
}
```

### 4. Handle Payment Failures
Add retry logic and better error handling in payment screen.

### 5. Production Deployment

#### Update Backend
1. Deploy backend to production server (e.g., Render, Railway, Heroku)
2. Get production URL (e.g., `https://activ-backend.onrender.com`)
3. Update Instamojo webhook to production URL

#### Update Frontend
1. Update `.env` with production Instamojo credentials
2. Update redirect URL to your actual domain
3. Build and release app

---

## 🐛 Troubleshooting

### Webhook Not Received (404 Error)
✅ **SOLVED** - Current status: 200 OK
- Ensure server is running
- Ensure ngrok is active
- Verify webhook URL in Instamojo dashboard matches ngrok URL

### Payment Status Not Updating
- Check backend logs for webhook data
- Verify MAC signature matches
- Check database connection
- Implement `activateMembership()` function

### WebView Not Redirecting
- Check redirect URL in payment creation
- Verify WebView navigation delegate
- Check console logs for detected URLs

### Amount Mismatch
- Ensure amount is passed as string in API call
- Verify decimal format (e.g., "500.00" not "500")

---

## 📞 Support

### Instamojo Dashboard
- URL: https://www.instamojo.com/
- API Docs: https://docs.instamojo.com/

### Your Backend (Development)
- Server: http://localhost:3000
- Webhook: https://237a577e5e34.ngrok-free.app/api/webhook
- Health Check: http://localhost:3000/api/health

### Important Notes
1. **ngrok URL changes** every time you restart ngrok
2. Update webhook URL in Instamojo when ngrok restarts
3. For production, use permanent webhook URL
4. Always test in **Instamojo Test Mode** before going live

---

## ✨ Summary

**Current Status**: 
- ✅ Webhook working (200 OK)
- ✅ Frontend payment flow complete
- ✅ MAC verification implemented
- ⏳ Database update logic pending

**Ready to Test**: Yes! 
Follow the testing steps above to complete an end-to-end payment flow.

**Next Priority**: 
Implement the `activateMembership()` function to update user's membership status in the database when payment is successful.
