# Company Member Separation - Testing Guide

## 🎯 Purpose
This guide helps you verify that the company-member separation issue has been fixed.

## 🔧 Fixes Implemented

### 1. **Enhanced Logout** (`lib/services/auth_service.dart`)
- ✅ Now clears `current_company_id` from SharedPreferences
- ✅ Clears `active_company` from SharedPreferences
- ✅ Prevents company data from persisting across user sessions

### 2. **Active Company Validation** (`businessaccount_dashboard_screen.dart`)
- ✅ Validates that active company belongs to current user
- ✅ Automatically switches to user's first company if invalid company detected
- ✅ Enhanced logging to track which user's data is loaded

### 3. **Enhanced Debug Logging** (All business screens)
- ✅ Logs user's full name, email, phone on data load
- ✅ Logs memberId being used for API calls
- ✅ Tracks company creation with user details

---

## 🧪 Test Cases

### Test Case 1: Fresh Login with Different Users

**Steps:**
1. If logged in, logout completely
2. Login as **Tamilarasan** (thamizhlogesh2020@gmail.com)
3. Go to Business Dashboard
4. Go to "My Companies"
5. **Expected Result**: Should see only "Tamil enterprises"
6. Logout
7. Login as **raja** (raja@gmail.com)
8. Go to Business Dashboard
9. Go to "My Companies"
10. **Expected Result**: Should see raja's 5 companies (grocery x3, chai, cgai)

**Pass Criteria:**
- ✅ Each user sees only their own companies
- ✅ No companies from Tamilarasan appear for raja
- ✅ Console logs show correct user name and memberId

---

### Test Case 2: Company Creation

**Steps:**
1. Login as a new user (or existing user with few companies)
2. Navigate to "My Companies"
3. Click "Create Company"
4. Fill in company details:
   - Name: "Test Company [YourName]"
   - Industry: Any
   - Location: Any
5. Save the company
6. **Check Console Logs**: Should show your memberId and user details
7. Verify company appears in "My Companies"
8. Logout
9. Login as a different user
10. Navigate to "My Companies"
11. **Expected Result**: The test company from step 5 should NOT appear

**Pass Criteria:**
- ✅ Company is created with correct memberId (check console)
- ✅ Company appears for creator
- ✅ Company does NOT appear for other users

---

### Test Case 3: Logout Data Clearing

**Steps:**
1. Login as User A
2. Open "My Companies" - note the companies shown
3. Select a company as active (if multiple exist)
4. Logout
5. **Check Console**: Should see "🔓 Logout: Cleared all user data including company selections"
6. Login as User B
7. Navigate to Business Dashboard
8. **Expected Result**: Should NOT see User A's active company
9. Should see User B's companies only

**Pass Criteria:**
- ✅ Logout logs confirm data clearing
- ✅ User B sees only their own companies
- ✅ No cached company data from User A

---

### Test Case 4: Company Switching Prevention

**Steps:**
1. Login as User A who has multiple companies
2. Go to Business Dashboard
3. Switch between companies using Company Switcher
4. Note the active company
5. Logout
6. Login as User B
7. Navigate to Business Dashboard
8. **Check Console**: Should see validation messages
9. **Expected Result**: Should NOT see User A's active company
10. Should automatically select User B's first company (if any)

**Pass Criteria:**
- ✅ Console shows: "⚠️ Active company from provider doesn't belong to this member"
- ✅ Console shows: "✅ Reset to first company: [User B's company]"
- ✅ Dashboard displays User B's company data only

---

## 📋 Console Output to Watch For

### ✅ Good Signs:

```
🔓 Logout: Cleared all user data including company selections
```

```
====================================================
📊 LOADING BUSINESS DASHBOARD
====================================================
👤 Member ID: 6933eaa6828756fd6cdd5734
👤 Full Name: Tamilarasan
📧 Email: thamizhlogesh2020@gmail.com
📱 Phone: 6379048464
====================================================
```

```
🔍 Loading companies for memberId: 6933eaa6828756fd6cdd5734
👤 User: Tamilarasan
📧 Email: thamizhlogesh2020@gmail.com
📱 Phone: 6379048464
✅ Loaded 1 companies
   - Tamil enterprises (6933ece1ba0dfe9366c3e68d)
```

### ⚠️ Warning Signs (Should trigger automatic fix):

```
⚠️ Active company "diffuse ai" does not belong to current user!
⚠️ Current user has 1 companies
⚠️ Clearing invalid active company and using first company
✅ Active company set to: Tamil enterprises
```

### ❌ Bad Signs (Indicates issue):

```
✅ Loaded 4 companies
   - Sairam Enterprises (different user's company)
   - diffuse ai (different user's company)
   - [current user should not see these]
```

---

## 🔍 Backend Verification

### Check Companies in Database:

```bash
cd activ-backend
node check-companies.js
```

**Expected Output:**
- Shows all companies with their memberId
- Each company has ONE memberId
- MemberId matches the user who created it

### Check Specific User's Companies:

Create a test script or use MongoDB:

```javascript
// In MongoDB Compass or script
db.companies.find({ memberId: ObjectId("6933eaa6828756fd6cdd5734") })
```

**For Tamilarasan (6933eaa6828756fd6cdd5734):**
- Should return only "Tamil enterprises"

**For raja (69332097fc0f19bb3c130b73):**
- Should return: grocery (x3), chai, cgai

---

## 🎭 User Test Matrix

| User | Member ID | Expected Companies | Email |
|------|-----------|-------------------|-------|
| sairam | 692e685ce47750d07c018b50 | Sairam Enterprises, diffuse ai, raja enter prices, aciv enterprices | sairam12@gmail.com |
| raja | 69332097fc0f19bb3c130b73 | grocery (x3), chai, cgai | raja@gmail.com |
| babu | 69332cd67b5d2870ae861450 | sairammmmm enter, ghbf | babu@gmail.com |
| Tamilarasan | 6933eaa6828756fd6cdd5734 | Tamil enterprises | thamizhlogesh2020@gmail.com |

---

## 🛠️ Troubleshooting

### Issue: Still seeing wrong companies

**Check:**
1. Did you logout and login again after the fix?
2. Check console logs - which memberId is being used?
3. Check console logs - which user name/email is shown?
4. Clear app data:
   ```dart
   // In Flutter
   SharedPreferences prefs = await SharedPreferences.getInstance();
   await prefs.clear();
   ```

### Issue: No companies showing

**Check:**
1. User exists in database? (run check-members-detailed.js)
2. User has created companies? (run check-companies.js)
3. API returning data? (check console logs for API responses)
4. memberId correct? (compare console log with database)

### Issue: Validation warnings in console

**This is GOOD!** The validation is working:
```
⚠️ Active company from provider doesn't belong to this member
✅ Reset to first company: [correct company]
```

This means:
- The system detected a mismatch
- Automatically corrected it
- User sees correct companies

---

## 📊 Success Metrics

### 100% Pass Criteria:
- ✅ Each user sees only their own companies
- ✅ No company data persists across logout/login
- ✅ Active company validation catches mismatches
- ✅ Console logs show correct user information
- ✅ Backend query uses correct memberId

### Database Verification:
```bash
# Count companies per member
db.companies.aggregate([
  { $group: { _id: "$memberId", count: { $sum: 1 } } }
])
```

**Expected:**
- Each memberId has correct count
- No null memberIds
- All memberIds are valid ObjectIds

---

## 🚀 Next Steps After Testing

1. ✅ Verify all test cases pass
2. ✅ Check console logs are clean
3. ✅ Confirm no cross-user data leakage
4. 🔄 If issues found:
   - Check which test case failed
   - Review console logs
   - Verify userData is correct
   - Check SharedPreferences cleared on logout

---

## 📞 Need Help?

If you encounter issues:

1. **Capture Console Logs**: Save the full console output
2. **Note the Test Case**: Which test failed?
3. **User Details**: Which users were involved?
4. **Expected vs Actual**: What did you expect vs what happened?

**Key Debug Commands:**
```bash
# Backend - Check database state
cd activ-backend
node check-companies.js
node check-members-detailed.js

# Flutter - Clear app data and test fresh
flutter clean
flutter pub get
flutter run
```

---

## ✅ Final Verification Checklist

- [ ] Logout clears all user data (check console)
- [ ] Each user sees only their companies
- [ ] Company creation logs show correct memberId
- [ ] Active company validation working
- [ ] No cross-user data leakage
- [ ] Console logs show correct user info
- [ ] Backend API returns correct data
- [ ] Database has proper memberId associations

**If all items checked: Issue is FIXED! 🎉**
