# Backlog Screen Debug Guide

## Issue Fixed
The backlog screen was showing "No Backlog" even though the API was returning data.

### Root Cause
The code was checking for `data['success']` but the API returns `data['status']`.

### Changes Made

1. **Fixed API Response Check** (`lib/features/telecaller/screens/backlog_screen.dart`)
   ```dart
   // BEFORE (Wrong)
   if (data['success'] == true) { ... }
   
   // AFTER (Correct)
   if (data['status'] == true) { ... }
   ```

2. **Added Debug Logging**
   - User info logging
   - Token availability check
   - API request URL
   - Response status and body length
   - Parsed data keys
   - Number of leads found

3. **Improved Error Handling**
   - Better error messages
   - Stack trace logging
   - Retry button in error snackbar
   - Network error detection

## How to Debug

### Check Console Logs
When the backlog screen loads, you should see:
```
🔍 Loading backlog leads...
👤 Current user: [Name] (ID: [ID])
🔑 Token available: Yes
📞 Caller ID: [ID]
🌐 Calling API: https://truckmitr.com/api/telehead/backlog-leads
📡 Response status: 200
📦 Response body length: [X] characters
📊 Parsed data keys: [status, mode, total_backlog, current_page, last_page, data]
📋 Backlog API Response: [X] leads found
✅ Backlog leads loaded: [X] leads
```

### Common Issues

1. **"User not logged in"**
   - User needs to login first
   - Token might have expired

2. **"No internet connection"**
   - Check device network
   - Check API server status

3. **"Connection timeout"**
   - Slow network
   - Server taking too long to respond

4. **Empty data array**
   - No backlog leads assigned to this telecaller
   - All leads have been called

## API Response Structure

```json
{
  "status": true,
  "mode": "rolling_backlog",
  "total_backlog": 251,
  "current_page": 1,
  "last_page": 13,
  "data": [
    {
      "id": 20630,
      "unique_id": "TM2512ODTR20378",
      "name": "Bijaya kumar sahoo",
      "name_eng": "Bijaya Kumar Sahoo",
      "mobile": "9937718127",
      "role": "transporter",
      "states": "Odisha",
      "admins": "Pooja Pal",
      "profileCompletion": 27,
      "assigned_to": 3,
      "Created_at": "2025-12-06T07:59:24.000000Z",
      ...
    }
  ]
}
```

## Testing Steps

1. **Login as telecaller**
   - Use valid credentials
   - Verify token is saved

2. **Navigate to Dashboard**
   - Check Backlog KPI shows count

3. **Tap Backlog KPI**
   - Should open backlog screen
   - Should show loading indicator

4. **View Backlog Leads**
   - Cards should display with all details
   - Profile completion avatar
   - Name, TMID, mobile
   - State, role badge
   - Assigned telecaller

5. **Test Call Functionality**
   - Tap call button
   - Select call type (Manual/IVR)
   - Complete call
   - Submit feedback
   - Lead should be removed from list

## Production Ready Checklist

✅ API integration working
✅ Bearer token authentication
✅ Data parsing correct
✅ UI displaying properly
✅ Error handling implemented
✅ Loading states
✅ Empty states
✅ Pull to refresh
✅ Call integration
✅ Feedback modal
✅ Debug logging (can be removed for production)

## Remove Debug Logs for Production

Before deploying, remove or comment out print statements:
- Lines with `print('🔍 ...')`
- Lines with `print('👤 ...')`
- Lines with `print('🔑 ...')`
- Lines with `print('📞 ...')`
- Lines with `print('🌐 ...')`
- Lines with `print('📡 ...')`
- Lines with `print('📦 ...')`
- Lines with `print('📊 ...')`
- Lines with `print('📋 ...')`
- Lines with `print('✅ ...')`
- Lines with `print('❌ ...')`
