# 🚀 Quick Reference - Instamojo Webhook

## Your Webhook Endpoint
```
Local:      http://localhost:3000/api/webhook/instamojo
With ngrok: https://YOUR-NGROK-URL.ngrok.io/api/webhook/instamojo
Production: https://your-domain.com/api/webhook/instamojo
```

## Start Testing in 3 Steps

### 1️⃣ Start Server
```bash
cd activ-backend
node server.js
```

### 2️⃣ Test Locally
```bash
node test-webhook.js
```

### 3️⃣ Expose to Internet
```bash
ngrok http 3000
```

## Instamojo Dashboard
1. Go to: https://www.instamojo.com/developers/webhooks/
2. Add webhook URL from ngrok
3. Select "Payment Successful"
4. Save

## Check if Working
- Browser: `http://localhost:3000/api/webhook/instamojo`
- Should return JSON with "success" message

## Server Logs When Working
```
📥 Webhook received
✅ Signature verified
💳 Payment details
🎉 Payment successful
✅ Membership activated
```

## If 404 Error
✅ Fixed! Route is now added to server.js

## Need Help?
Read: `WEBHOOK_COMPLETE.md` for full details
