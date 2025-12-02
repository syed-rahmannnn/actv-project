# Business Profile Dashboard - Live Data Integration

## Overview

The Business Profile dashboard has been fully integrated with the backend API to display live business data instead of hardcoded dummy text. The dashboard now dynamically fetches and displays business profile information, metrics, and associations from the backend.

## Changes Made

### 1. **New Models** (`lib/models/business_profile_model.dart`)

Created three data models to match the backend API schema:

- **`BusinessProfile`**: Represents the business profile data
  - Maps backend fields like `organizationName` → `name`, `businessType` → `industry`
  - Includes helper methods: `displayIndustryLocation`, `statusDisplay`
  - Handles status mapping (UNDER_REVIEW → "Under Review", ACTIVE → "Active")

- **`BusinessMetrics`**: Represents business analytics
  - Profile views count and percentage change
  - Products count and featured products count
  - Helper methods for formatted display strings

- **`BusinessAssociation`**: Represents company connections
  - Association name, role, location, and optional logo

### 2. **Business Profile Service** (`lib/services/business_profile_service.dart`)

Created a dedicated service for business profile API calls:

- **`getBusinessProfile(memberId)`**: Fetches business profile from backend
- **`getBusinessMetrics(businessId)`**: Retrieves profile analytics
- **`getBusinessAssociations(businessId)`**: Gets company associations
- **`saveBusinessProfile(...)`**: Creates new business profile
- **`updateBusinessProfile(...)`**: Updates existing profile
- **`getCompleteMemberProfile(memberId)`**: Fetches complete member data

All methods include:
- Proper error handling
- Timeout configuration for Render deployment
- Fallback to defaults when API fails

### 3. **Business Dashboard Screen Updates** (`lib/screens/Bussiness account/businessaccount _dashboard_screen.dart`)

Transformed from static to dynamic data:

**State Management:**
- Added `_businessProfile`, `_businessMetrics`, `_associations` state variables
- Added `_isLoading` and `_errorMessage` for loading states
- Added `_loadBusinessData()` method to fetch all data in parallel

**Loading & Empty States:**
- `_buildLoadingState()`: Shows spinner while fetching data
- `_buildEmptyState()`: Displays message when no profile exists, with CTA to create one

**Data Binding:**
- **Business Card**: Displays actual business name, industry, location, description, status
- **Status Pill**: Color-coded based on actual status (green for active, orange for under review, red for rejected)
- **Metrics**: Shows real profile views, products count, featured products
- **Associations**: Renders actual company connections from API
- **Refresh**: Added refresh button to reload data

**Key Features:**
- No hardcoded strings - all data comes from API responses
- Graceful degradation - hides sections if no data available
- Pull-to-refresh capability
- Auto-refresh after editing profile

### 4. **Business Profile Screen Updates** (`lib/screens/Bussiness account/business_profile_screen.dart`)

Integrated with backend API:

- **Save to Backend**: `_saveProfile()` now calls `BusinessProfileService.saveBusinessProfile()`
- **Proper Error Handling**: Shows success/error messages based on API response
- **Member ID Extraction**: Safely extracts member ID from userData
- **Navigation**: Navigates to dashboard after successful save

### 5. **Business Profile Edit Screen Updates** (`lib/screens/Bussiness account/business_profile_edit_screen.dart`)

Enhanced with data loading and updates:

- **Load Existing Data**: `_loadExistingProfile()` fetches current profile on init
- **Field Population**: `_populateFields()` fills form with existing data
- **Update vs Create**: Intelligently calls update or create based on existing profile
- **Loading State**: Shows spinner while fetching existing data
- **Proper Updates**: Maps form fields to backend schema correctly

### 6. **Backend Routes** (`activ-backend/routes/business.js`)

Created new business routes for the dashboard:

- **`GET /api/business/metrics`**: Returns business analytics
  - Query param: `businessId`
  - Returns: profileViews, profileViewsChangePercent, productsCount, featuredProductsCount

- **`GET /api/business/associations`**: Returns company connections
  - Query param: `businessId`
  - Returns: Array of association objects

- **`POST /api/business/profile`**: Creates/updates business profile
  - Body: businessId, memberId, name, tagline, description, industry, city, location, logoUrl, website
  - Maps frontend fields to backend schema

**Note**: Metrics and associations currently return default/empty data. These will be populated as you implement product listings and company association features.

### 7. **Server Configuration** (`activ-backend/server.js`)

Added business routes to the Express app:
```javascript
app.use('/api/business', businessRoutes);
```

## API Endpoints Used

### Frontend → Backend Mapping

| Frontend Service Method | Backend Endpoint | Purpose |
|------------------------|------------------|---------|
| `getBusinessProfile()` | `GET /api/profile/business-info/:memberId` | Fetch business profile |
| `getBusinessMetrics()` | `GET /api/business/metrics?businessId={id}` | Fetch analytics |
| `getBusinessAssociations()` | `GET /api/business/associations?businessId={id}` | Fetch connections |
| `saveBusinessProfile()` | `POST /api/profile/business-info` | Create profile |
| `updateBusinessProfile()` | `POST /api/profile/business-info` | Update profile |

## Data Flow

### 1. **Onboarding Flow** (Creating Business Profile)
```
User fills form in BusinessProfileScreen
  ↓
Taps "Save Profile"
  ↓
BusinessProfileService.saveBusinessProfile()
  ↓
POST /api/profile/business-info
  ↓
Backend creates/updates MemberBusinessInfo document
  ↓
Success response → Navigate to BusinessDashboardScreen
```

### 2. **Dashboard Load Flow**
```
BusinessDashboardScreen.initState()
  ↓
_loadBusinessData()
  ↓
Fetch in parallel:
  - BusinessProfileService.getBusinessProfile(memberId)
  - BusinessProfileService.getBusinessMetrics(businessId)
  - BusinessProfileService.getBusinessAssociations(businessId)
  ↓
Update state with API responses
  ↓
Render UI with live data
```

### 3. **Edit Profile Flow**
```
User taps "Edit Profile"
  ↓
BusinessProfileEditScreen loads
  ↓
_loadExistingProfile() fetches current data
  ↓
_populateFields() fills form
  ↓
User edits and saves
  ↓
BusinessProfileService.updateBusinessProfile()
  ↓
POST /api/profile/business-info (with updates)
  ↓
Success → Navigate back to dashboard
  ↓
Dashboard auto-refreshes with new data
```

## UI States

### 1. **Loading State**
- Displays circular progress indicator
- Shows "Loading business profile..." message
- Appears when fetching data from backend

### 2. **Empty State**
- Shows when no business profile exists
- Displays icon, message, and "Create Business Profile" button
- Guides user to complete onboarding

### 3. **Data State**
- Full dashboard with:
  - Business profile card (name, industry, location, status, description)
  - Metrics (profile views, products count)
  - Associations (if any)
  - Recent activity

### 4. **Error State**
- Shows error message if API fails
- Allows retry via refresh button

## Key Features Implemented

✅ **No Hardcoded Data**: All text, numbers, and statuses come from API  
✅ **Loading States**: Proper UX during data fetching  
✅ **Empty States**: Helpful messages when no data exists  
✅ **Status Mapping**: Color-coded status pills based on backend values  
✅ **Dynamic Fields**: Industry/location display adapts to available data  
✅ **Refresh Capability**: Manual refresh button in header  
✅ **Auto-refresh**: Dashboard reloads after profile edits  
✅ **Error Handling**: Graceful fallbacks when API fails  
✅ **Parallel Loading**: Fetches profile, metrics, and associations simultaneously  

## Backend Schema Mapping

### Frontend Model → Backend Database

| Frontend Field | Backend Field (MemberBusinessInfo) |
|----------------|-----------------------------------|
| `name` | `organizationName` |
| `description` | `businessDescription` |
| `industry` | `businessType` |
| `location` | `location` |
| `area` | `area` |
| `mobile` | `mobile` |
| `website` | `businessWebsite` |
| `logoUrl` | `logoUrl` |
| `businessId` | `_id` or `memberId` |

## Testing the Implementation

### 1. **Test Profile Creation**
```
1. Navigate to Business Profile screen
2. Fill in business details
3. Tap "Save Profile"
4. Verify data is saved to backend
5. Check dashboard displays correct data
```

### 2. **Test Profile Loading**
```
1. Open dashboard with existing profile
2. Verify loading state appears briefly
3. Confirm all fields display backend data
4. Check status pill color matches status
```

### 3. **Test Profile Editing**
```
1. Tap "Edit Profile" on dashboard
2. Verify form is pre-filled with current data
3. Modify some fields
4. Save and return to dashboard
5. Confirm changes are reflected
```

### 4. **Test Empty State**
```
1. Access dashboard with new account (no profile)
2. Verify empty state message appears
3. Tap "Create Business Profile"
4. Complete form and save
5. Verify dashboard now shows data
```

## Future Enhancements

### 1. **Metrics Implementation**
Currently returns default values. To implement:
- Add `BusinessMetrics` collection to track views
- Implement view counting logic
- Link products collection for accurate counts

### 2. **Associations Implementation**
Currently returns empty array. To implement:
- Add `BusinessAssociation` collection
- Create association management UI
- Implement add/remove association endpoints

### 3. **Logo Upload**
TODO in save methods. To implement:
- Add file upload service
- Integrate with cloud storage (S3, Cloudinary, etc.)
- Update logo URL in profile

### 4. **Status Workflow**
Implement status change logic:
- Admin approval process
- Status transition notifications
- Status history tracking

## Configuration

### Backend URL
Set in `lib/services/api_service.dart`:
- Production: `https://actv-project.onrender.com/api`
- Development: Configurable via environment variables

### Timeout Settings
Configured in `business_profile_service.dart`:
- Render (production): 75 seconds (handles cold starts)
- Local development: 12 seconds

## Error Handling

All API calls include:
- Try-catch blocks
- Timeout handling
- Null safety checks
- User-friendly error messages
- Fallback to defaults when appropriate

## Summary

The Business Profile dashboard is now fully dynamic and connected to your backend. It fetches live data, handles loading and error states, and provides a seamless user experience. All hardcoded values have been removed and replaced with API-driven data.

The implementation follows Flutter best practices with proper state management, error handling, and user feedback. The backend routes are in place to support metrics and associations in the future.
