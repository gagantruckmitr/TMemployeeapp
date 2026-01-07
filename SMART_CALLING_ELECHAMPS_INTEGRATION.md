# Smart Calling - Elechamps API Integration

## Overview
Integrated the elechamps API endpoint into the Smart Calling screen to fetch additional leads for telecallers.

## Changes Made

### 1. API Service (`lib/core/services/api_service.dart`)
Added new methods to fetch leads from the elechamps API:

- **`getElechampsLeads()`**: Fetches leads from `https://truckmitr.com/api/telehead/elechamps/{adminId}/users`
- **`_mapElechampsJsonToDriverContact()`**: Maps elechamps JSON response to `DriverContact` model

**Features:**
- Handles different response structures (array or object with data/users field)
- Supports limit parameter to control number of results
- Maps various field name variations (name_eng, nameEng, name, etc.)
- Extracts profile completion percentage from multiple possible fields
- Properly handles registration dates and assigned telecaller info

### 2. Smart Calling Service (`lib/core/services/smart_calling_service.dart`)
Enhanced the service to support elechamps leads:

- **Updated `getDrivers()`**: Added `useElechamps` and `adminId` parameters
- **Added `getElechampsLeads()`**: Convenience method to fetch elechamps leads directly
- Merges leads from multiple sources (API, today's leads, elechamps) removing duplicates by ID

### 3. Smart Calling Page (`lib/features/telecaller/smart_calling_page.dart`)
Modified the driver loading logic:

- **Updated `_loadDriversFromLiveAPI()`**: Now fetches from both today's leads API and elechamps API
- Automatically uses current user's admin ID for elechamps API
- Merges results from both sources, avoiding duplicates
- Updates remaining leads count to reflect total from all sources
- Includes error handling for elechamps API failures (won't break if elechamps is down)

## API Endpoint

```
GET https://truckmitr.com/api/elechamps_users_api.php?admin_id={adminId}&per_page=10
```

**Parameters:**
- `admin_id`: The telecaller's admin ID (automatically retrieved from logged-in user)
- `per_page` (optional): Number of results per page (default: 10)
- `page` (optional): Page number for pagination (default: 1)

**Response Format:**
```json
{
  "status": "success",
  "admin_id": 8,
  "admin_name": "Sonam",
  "assigned_user_count": 173,
  "current_page": 12,
  "per_page": 10,
  "last_page": 18,
  "users": [
    {
      "id": 21408,
      "assigned_to": 8,
      "unique_id": "TM2512ANDR21139",
      "role": "driver",
      "name": "Mohit Kumar",
      "name_eng": "Mohit Kumar",
      "mobile": "8815696321",
      "states": "Andaman and Nicobar Islands",
      "Created_at": "2025-12-10 21:00:39",
      "driver_completion": 0,
      "profile_completion": 28,
      ...
    }
  ]
}
```

**Response Fields:**
- `status`: API status (success/error)
- `admin_id`: Admin ID
- `admin_name`: Admin name
- `assigned_user_count`: Total users assigned to this admin
- `current_page`: Current page number
- `per_page`: Results per page
- `last_page`: Total pages
- `users`: Array of user objects

**User Object Fields:**
- `id`: User ID
- `unique_id`: TruckMitr ID (TMID)
- `name_eng`: User name in English (preferred)
- `name`: User name (fallback)
- `mobile`: Contact number
- `role`: User role (driver/transporter)
- `profile_completion`: Profile completion percentage (0-100)
- `driver_completion`: Driver-specific completion (alternative field)
- `Created_at`: Registration date
- `states`: State name
- `assigned_to`: Admin ID assigned to this user

## How It Works

1. When Smart Calling page loads, it fetches leads from:
   - Today's leads API (existing)
   - Elechamps API (new)

2. Both sets of leads are merged, with duplicates removed based on user ID

3. The total count is displayed in the header

4. If elechamps API fails, the page still works with today's leads only

## Benefits

- **More Leads**: Telecallers get access to additional leads from elechamps
- **Unified View**: All leads appear in one list
- **No Duplicates**: Smart merging prevents showing the same lead twice
- **Resilient**: Graceful fallback if elechamps API is unavailable
- **Automatic**: Uses logged-in user's admin ID automatically

## Testing

### 1. Test API Endpoint Directly
Visit the test script to verify the API is working:
```
https://truckmitr.com/api/test_elechamps_api.php?admin_id=8
```

This will show:
- API status
- Admin name
- Total assigned users
- Pagination info
- Sample user data
- Full response

### 2. Test in Flutter App

1. Login as a telecaller
2. Navigate to Smart Calling screen
3. Check console logs for:
   ```
   🔵 [SmartCalling] Fetching elechamps leads for admin: {adminId}
   📊 API Status: success
   📊 Total assigned users: 173
   📊 Page 12 of 18
   ✅ Fetched 10 elechamps leads
   🔵 [SmartCalling] Final count: {total} drivers ({today} from today + {elechamps} from elechamps)
   ```
4. Verify leads are displayed correctly
5. Test calling functionality with elechamps leads
6. Verify profile completion percentage is shown
7. Check that assigned telecaller info is displayed

## Error Handling

- If elechamps API fails, error is logged but doesn't break the page
- Today's leads will still be displayed
- User sees a warning in console but no error message in UI

## Future Enhancements

- Add toggle to enable/disable elechamps leads
- Add separate tab for elechamps leads
- Cache elechamps leads separately
- Add refresh button for elechamps leads only
