# Network Connectivity Troubleshooting Guide

## Problem
The Browse Members screen shows "No members found" and the app logs show timeout errors:
```
⏱️ Request timeout on attempt 1
TimeoutException: Request timed out after 30 seconds
```

## Root Cause
The Flutter app on your mobile device **cannot reach** the backend server at `http://10.201.103.174:3000`

## Solutions (Try in order)

### Solution 1: Ensure Device is on Same WiFi Network ✅ **MOST LIKELY FIX**

**Your mobile device must be connected to the SAME WiFi network as your development PC**

1. On your mobile device:
   - Open Settings → WiFi
   - Make sure you're connected to the SAME WiFi network as your PC
   - Check the IP address - it should start with `10.201.x.x`

2. To find your PC's network:
   - PC IP: `10.201.103.174`
   - Your phone must also have IP like `10.201.103.xxx`

3. **If your phone is on a different WiFi or mobile data:**
   - Connect it to the same WiFi as your PC
   - Restart the Flutter app

---

### Solution 2: Use USB Debugging with Port Forwarding

If you can't connect both devices to same WiFi, use ADB port forwarding:

```powershell
# Connect phone via USB
# Enable USB debugging on phone

# Forward port from phone to PC
adb reverse tcp:3000 tcp:3000

# Update baseUrl in Flutter app to use localhost
```

Then change the API URL in `lib/services/browse_members_service.dart`:
```dart
static const String baseUrl = 'http://10.0.2.2:3000/api/browse-members';  // For Android emulator
// OR
static const String baseUrl = 'http://localhost:3000/api/browse-members';  // For USB with ADB reverse
```

---

### Solution 3: Check Windows Firewall

Windows might be blocking incoming connections:

```powershell
# Run as Administrator in PowerShell
netsh advfirewall firewall add rule name="Node.js Server" dir=in action=allow protocol=TCP localport=3000

# OR temporarily disable Windows Firewall (not recommended)
# Settings → Windows Security → Firewall & network protection → Turn off
```

---

### Solution 4: Verify Backend Server is Running

1. Check if server is running:
```powershell
cd activ-backend
node server.js
```

Should see:
```
✅ MongoDB Connected
✅ Server running on port 3000
```

2. Test server from browser on **same PC**:
- Open: `http://localhost:3000/api/browse-members`
- Should see JSON with 4 members

3. Test server from browser on **mobile device**:
- Open: `http://10.201.103.174:3000/api/browse-members`
- Should see same JSON
- **If this fails**, it's a network/firewall issue

---

### Solution 5: Use ngrok for Remote Access (Last Resort)

If nothing else works, expose your local server to internet:

```powershell
# Install ngrok: https://ngrok.com/
ngrok http 3000
```

Copy the HTTPS URL (e.g., `https://abc123.ngrok.io`) and update Flutter:
```dart
static const String baseUrl = 'https://abc123.ngrok.io/api/browse-members';
```

---

## Quick Test Command

Run this from Flutter app to test connectivity:
```powershell
cd c:\actv-project
dart test_network_connectivity.dart
```

This will show:
- ✅ DNS working
- ✅ Internet working
- ✅/❌ Backend server reachable
- Device IP address (must be 10.201.x.x)

---

## What We Already Fixed

✅ Database has 4 approved members with active payment
✅ Backend API is working correctly (tested locally)
✅ Backend query filters properly (approvedBy, membershipStatus, profileCompleted)
✅ Flutter service has correct API endpoint
✅ Reduced timeout from 30s to 10s for faster feedback

## The Only Remaining Issue

🔴 **Network connectivity between mobile device and PC backend server**

The most likely solution is **Solution 1** - make sure your phone is on the same WiFi as your PC!

---

## Testing After Fix

1. Restart Flutter app
2. Navigate to Browse Members
3. Pull down to refresh
4. Should see 4 members:
   - Syed Rahman (Saveetha)
   - Israr Shaik (Saveetha)
   - tharun (diffuse ai)
   - mani

## Still Not Working?

1. Run network test: `dart test_network_connectivity.dart`
2. Check console logs for specific error
3. Verify phone IP starts with `10.201.`
4. Try opening `http://10.201.103.174:3000/api/browse-members` in phone browser
5. If browser works but app doesn't, it's an app configuration issue
6. If browser also fails, it's a network/firewall issue
