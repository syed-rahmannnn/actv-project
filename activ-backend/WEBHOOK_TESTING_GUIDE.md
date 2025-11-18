# Testing Webhook Endpoint - Quick Guide

## 1. Verify Server is Running

Start your backend server:
```bash
cd activ-backend
node server.js
```

You should see:
```
Server is running on port 3000
Connected to MongoDB
```

---

## 2. Test Webhook Endpoint (GET Request)

Open browser or use curl to test if endpoint exists:

**URL:** `http://localhost:3000/api/webhook/instamojo`

**Expected Response:**
```json
{
  "status": "success",
  "message": "Instamojo webhook endpoint is active",
  "timestamp": "2025-11-18T..."
}
```

If you get this response, your endpoint is correctly configured! ✅

---

## 3. Test Webhook with curl (POST Request)

```bash
curl -X POST http://localhost:3000/api/webhook/instamojo \
  -H "Content-Type: application/json" \
  -d '{
    "payment_id": "TEST123",
    "payment_request_id": "TEST456",
    "status": "Credit",
    "amount": "500.00",
    "buyer_email": "test@example.com",
    "buyer_name": "Test User",
    "buyer_phone": "9876543210",
    "mac": "test_mac_hash"
  }'
```

**Note:** This will fail signature verification (expected) but confirms endpoint receives POST requests.

---

## 4. For ngrok Testing (Public URL)

### Install ngrok:
```bash
npm install -g ngrok
```

### Start ngrok:
```bash
ngrok http 3000
```

You'll get output like:
```
Forwarding  https://abc123.ngrok.io -> http://localhost:3000
```

### Your webhook URL will be:
```
https://abc123.ngrok.io/api/webhook/instamojo
```

**Use this URL in Instamojo dashboard!**

---

## 5. Check Server Logs

When webhook is received, you'll see detailed logs:
```
📥 Webhook received at: 2025-11-18T...
📋 Request headers: {...}
📦 Request body: {...}
✅ Signature verified successfully
💳 Payment details: {...}
🎉 Payment successful! Activating membership...
✅ Membership activated for: user@example.com
📤 Sending success response to Instamojo
```

---

## 6. Common Issues and Solutions

### 404 Error - Route Not Found
**Problem:** Endpoint doesn't exist
**Solution:** 
- Check server.js has `app.use('/api/webhook', webhookRoutes);`
- Restart server after changes
- Verify URL is exactly: `/api/webhook/instamojo`

### 500 Error - Internal Server Error
**Problem:** Server code has errors
**Solution:**
- Check server console logs
- Verify all dependencies installed: `npm install`
- Check MongoDB connection

### Connection Refused
**Problem:** Server not running
**Solution:**
- Start server: `node server.js`
- Check port 3000 is not in use
- Verify firewall settings

### CORS Error (from browser)
**Problem:** CORS not configured
**Solution:**
- Already configured in server.js
- For testing, webhooks don't need CORS (server-to-server)

---

## 7. Testing Checklist

Before connecting to Instamojo:

- [ ] Server starts without errors
- [ ] GET request to `/api/webhook/instamojo` returns 200
- [ ] MongoDB is connected
- [ ] Environment variables (.env) are loaded
- [ ] ngrok is running (for external testing)
- [ ] Webhook URL is accessible from internet

---

## 8. Instamojo Dashboard Setup

1. Go to: https://www.instamojo.com/developers/webhooks/
2. Click "Add Webhook"
3. Enter webhook URL: `https://your-ngrok-url.ngrok.io/api/webhook/instamojo`
4. Select events: "Payment Successful"
5. Save

---

## 9. Quick Debugging Commands

**Check if port 3000 is in use:**
```bash
netstat -ano | findstr :3000
```

**Kill process on port 3000:**
```bash
taskkill /PID <PID> /F
```

**Test endpoint from command line:**
```bash
curl http://localhost:3000/api/webhook/instamojo
```

**View server logs in real-time:**
```bash
node server.js
# or with nodemon for auto-restart
nodemon server.js
```

---

## 10. Production Deployment

When deploying to production (Render, Heroku, etc.):

1. Ensure environment variables are set
2. Update webhook URL in Instamojo dashboard
3. Use HTTPS (required by Instamojo)
4. Monitor logs for webhook events
5. Set up error alerts

**Production URL format:**
```
https://your-app.render.com/api/webhook/instamojo
```

---

## Need Help?

If webhook still returns 404:
1. Restart server completely
2. Check exact URL path: `/api/webhook/instamojo`
3. Verify webhook.js is in routes folder
4. Check server.js imports webhook routes
5. Test with curl first before Instamojo
