# Instamojo Payment Integration - Webhook Setup Guide

## Overview
This guide explains how to set up and verify Instamojo payment webhooks for automated payment confirmation.

## 1. Webhook Configuration in Instamojo Dashboard

### Steps to Configure Webhook:
1. Log in to your **Instamojo Dashboard**
2. Navigate to **Settings** → **Webhooks**
3. Click on **Add Webhook**
4. Enter your webhook URL: `https://yourdomain.com/api/instamojo-webhook`
5. Select events to trigger webhook:
   - ✅ Payment Successful
   - ✅ Payment Failed (optional)
6. Save the configuration

### Important Notes:
- Use HTTPS (not HTTP) for production webhooks
- Your server must be publicly accessible
- Instamojo will send POST requests to this URL

---

## 2. Webhook URL Format

**Development (for testing):**
```
https://your-ngrok-url.ngrok.io/api/instamojo-webhook
```

**Production:**
```
https://yourdomain.com/api/instamojo-webhook
```

---

## 3. Backend Implementation (Node.js)

The webhook handler is already created in:
```
activ-backend/routes/webhook.js
```

### Add to your server.js:
```javascript
const webhookRoutes = require('./routes/webhook');
app.use('/api', webhookRoutes);

// Important: Add body parser for webhooks
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
```

---

## 4. Webhook Data Structure

Instamojo sends the following data to your webhook:

```json
{
  "payment_id": "MOJO5a06005J21512197",
  "payment_request_id": "e3eb155909da4e979a83fa3a3b4a28c3",
  "status": "Credit",
  "amount": "500.00",
  "buyer_email": "user@example.com",
  "buyer_name": "John Doe",
  "buyer_phone": "9876543210",
  "currency": "INR",
  "fees": "11.80",
  "mac": "a5b14cef593e2b77e46843bd0cd612f6",
  "longurl": "https://www.instamojo.com/...",
  "shorturl": "https://imjo.in/..."
}
```

---

## 5. Security: Verifying Webhook Signature

### Why Verification is Important:
- Prevents fake payment notifications
- Ensures data integrity
- Protects against fraud

### How Verification Works:
1. Instamojo sends a `mac` (MD5 hash) with webhook data
2. Your server recreates the hash using your private salt
3. Compare both hashes - if they match, the webhook is authentic

### Verification Process:
```javascript
// 1. Extract MAC from webhook
const receivedMac = webhookData.mac;

// 2. Create message string (sorted keys)
const message = "amount=500.00|buyer_email=user@example.com|...|YOUR_PRIVATE_SALT";

// 3. Calculate MD5 hash
const calculatedMac = crypto.createHash('md5').update(message).digest('hex');

// 4. Verify
if (calculatedMac === receivedMac) {
  // Authentic webhook - process payment
}
```

---

## 6. Database Updates

When a webhook is received and verified, update your database:

```javascript
// Update member status
await Member.findOneAndUpdate(
  { email: buyerEmail },
  {
    membershipStatus: 'active',
    membershipActivatedAt: new Date(),
    paymentId: paymentId,
    paymentAmount: amount,
  }
);

// Send confirmation email
await sendMembershipConfirmationEmail(buyerEmail);

// Generate digital certificate
await generateMembershipCertificate(buyerEmail);
```

---

## 7. Testing Webhooks

### Using ngrok for Local Testing:
1. Install ngrok: `npm install -g ngrok`
2. Start your backend: `node server.js`
3. Start ngrok: `ngrok http 3000`
4. Use the ngrok URL in Instamojo webhook settings
5. Make a test payment
6. Check your server logs for webhook data

### Test Payment:
- Instamojo provides test mode with test credentials
- Use test credit card: 4242 4242 4242 4242
- Use any future expiry date and CVV

---

## 8. Error Handling

### Common Webhook Issues:

**Webhook not received:**
- Check if webhook URL is publicly accessible
- Verify HTTPS is enabled
- Check firewall settings
- Ensure server is running

**Signature verification fails:**
- Verify INSTAMOJO_PRIVATE_SALT is correct
- Check data sorting logic
- Ensure no extra spaces in salt

**Database not updating:**
- Check MongoDB connection
- Verify email matching logic
- Check server logs for errors

---

## 9. Monitoring and Logging

### Important Logs to Track:
```javascript
console.log('Webhook received:', {
  paymentId,
  status,
  amount,
  buyerEmail,
  timestamp: new Date(),
});
```

### Set up alerts for:
- Failed signature verifications
- Failed database updates
- Webhook timeouts

---

## 10. Production Checklist

✅ Webhook URL is HTTPS
✅ Private salt is securely stored in .env
✅ Signature verification is implemented
✅ Database transactions are atomic
✅ Error handling is comprehensive
✅ Email notifications are configured
✅ Logging and monitoring is enabled
✅ Backup webhook handler is ready

---

## 11. Environment Variables Required

Add to your backend `.env` file:
```env
INSTAMOJO_API_KEY=your_api_key
INSTAMOJO_AUTH_TOKEN=your_auth_token
INSTAMOJO_PRIVATE_SALT=your_private_salt
```

---

## Support

For issues:
1. Check Instamojo documentation: https://docs.instamojo.com
2. Review webhook logs in Instamojo dashboard
3. Test with ngrok for debugging
4. Contact Instamojo support if needed

---

## Security Best Practices

1. ✅ Always verify webhook signatures
2. ✅ Use HTTPS for all communications
3. ✅ Store credentials in environment variables
4. ✅ Implement rate limiting on webhook endpoint
5. ✅ Log all webhook events
6. ✅ Handle duplicate webhooks gracefully
7. ✅ Set up monitoring and alerts
