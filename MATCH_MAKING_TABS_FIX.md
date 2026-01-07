# Match-Making Tabs Fix - Driver and Transporter Separation

## Problem
In the Smart Calling screen, when `tc_for = match-making`, both the Drivers tab and Transporters tab were showing the same data (both drivers and transporters mixed together). The tabs were not properly filtering data based on user type.

## Solution Implemented (UPDATED)

### 1. Frontend Changes (Flutter)

#### `lib/features/telecaller/smart_calling_page.dart`
- Added `tcFor` parameter to `SmartCallingPage` widget to identify match-making mode
- Added `TabController` for managing Driver and Transporter tabs
- Added `_currentUserType` state variable to track active tab ('driver' or 'transporter')
- Implemented `_buildTabBar()` widget to display tabs when in match-making mode
- Updated `_loadData()` to pass `userType` parameter to API based on current tab
- Updated header title to show "Match Making" when in match-making mode
- Updated search bar placeholder to reflect current tab

#### `lib/core/services/smart_calling_service.dart`
- Added `userType` parameter to `getDrivers()` method
- Passes `userType` to `ApiService.getFreshLeads()`

#### `lib/core/services/api_service.dart`
- Added `userType` parameter to `getFreshLeads()` method
- Sends `user_type` query parameter to backend API

#### `lib/routes/app_router.dart`
- Updated smart-calling route to accept `tc_for` query parameter
- Passes `tcFor` to `SmartCallingPage` widget

### 2. Backend Changes (PHP)

#### `api/fresh_leads_api.php`
- Added `user_type` parameter support in `getFreshLeads()` function
- Implemented role filtering based on `user_type`:
  - When `user_type = 'driver'`: Only returns users with `role = 'driver'`
  - When `user_type = 'transporter'`: Only returns users with `role = 'transporter'`
  - When `user_type` is null: Returns both drivers and transporters (default behavior)
- Updated `getDriversByStatus()` to also support `user_type` filtering

## How It Works

### Navigation
To access match-making mode with tabs:
```dart
context.go('/dashboard/smart-calling?tc_for=match-making');
```

### Tab Behavior (Toggle-Based)
The screen now uses a toggle button instead of traditional tabs:

1. **Drivers Tab (Default)**
   - Shows only users with `role = 'driver'`
   - Loads driver data from API with `user_type=driver`
   - When switched, clears search and reloads data

2. **Transporters Tab**
   - Shows only users with `role = 'transporter'`
   - Loads transporter data from API with `user_type=transporter`
   - When switched, clears search and reloads data

### Key Difference from Regular Mode
- **Match-Making Mode (`tc_for=match-making`)**: Loads ONLY the selected user type (driver OR transporter) at a time
- **Regular Mode (no parameter)**: Loads BOTH drivers AND transporters, allowing toggle between them without reloading

### Data Flow
```
User switches tab
  ↓
_currentUserType updated ('driver' or 'transporter')
  ↓
_loadData() called
  ↓
SmartCallingService.getDrivers(userType: _currentUserType)
  ↓
ApiService.getFreshLeads(userType: userType)
  ↓
API: fresh_leads_api.php?user_type=driver (or transporter)
  ↓
SQL: WHERE u.role = 'driver' (or 'transporter')
  ↓
Returns filtered data
  ↓
UI displays only relevant contacts
```

## Testing

### Test Match-Making Mode
1. Navigate to smart calling with match-making parameter:
   ```
   /dashboard/smart-calling?tc_for=match-making
   ```

2. Verify tabs are visible:
   - "Drivers" tab with truck icon
   - "Transporters" tab with business icon

3. Test Drivers Tab:
   - Should show only drivers
   - Search should filter drivers only
   - Header should show "Match Making"

4. Test Transporters Tab:
   - Should show only transporters
   - Search should filter transporters only
   - Header should show "Match Making"

### Test Regular Mode
1. Navigate to smart calling without parameter:
   ```
   /dashboard/smart-calling
   ```

2. Verify:
   - No tabs visible
   - Shows all contacts (drivers and transporters)
   - Header shows "Smart Calling"

## API Endpoints

### Get Fresh Leads (Drivers Only)
```
GET /api/fresh_leads_api.php?action=fresh_leads&caller_id=1&user_type=driver
```

### Get Fresh Leads (Transporters Only)
```
GET /api/fresh_leads_api.php?action=fresh_leads&caller_id=1&user_type=transporter
```

### Get Fresh Leads (All - Default)
```
GET /api/fresh_leads_api.php?action=fresh_leads&caller_id=1
```

## Files Modified

### Flutter (Dart)
1. `lib/features/telecaller/smart_calling_page.dart`
2. `lib/core/services/smart_calling_service.dart`
3. `lib/core/services/api_service.dart`
4. `lib/routes/app_router.dart`

### Backend (PHP)
1. `api/fresh_leads_api.php`

## Notes
- The fix maintains backward compatibility - regular smart calling mode still works without tabs
- Tab switching automatically reloads data with appropriate filter
- Search functionality works independently within each tab
- All existing call functionality (IVR, manual calling, feedback) remains unchanged
