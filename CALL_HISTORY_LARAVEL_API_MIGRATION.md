# Call History Laravel API Migration

## Summary
Updated the Call History Hub screen to use Laravel APIs instead of core PHP API files for both transporter and driver call history.

## Changes Made

### 1. Transporter Call History API Migration

**Old API (Core PHP):**
- List: `phase2_job_brief_api.php?action=transporters_list&caller_id={id}`
- History: `phase2_job_brief_api.php?action=history&unique_id={tmid}&caller_id={id}`

**New API (Laravel):**
- Both endpoints now use: `https://truckmitr.com/api/telehead/jobs/assigned-to/{assigned_to}`
- Uses Bearer token authentication from login

**Updated Methods:**
- `Phase2ApiService.getTransportersWithCallHistory()` - Now fetches from Laravel API and groups jobs by transporter
- `Phase2ApiService.getTransporterCallHistory()` - Now fetches from Laravel API and filters by transporter TMID

### 2. Driver Call History API Migration

**Old API (Core PHP):**
- `phase2_call_history_api.php?action=list&caller_id={id}`

**New API (Laravel):**
- `https://truckmitr.com/api/telehead/jobs/assigned-to/{assigned_to}`
- Uses Bearer token authentication from login
- Returns job brief data with match-making information

**Updated Methods:**
- `Phase2ApiService.fetchCallHistory()` - Now fetches from Laravel API and transforms job data to CallHistoryLog format

**API Response Structure:**
```json
{
  "assigned_to": "3",
  "jobs": [
    {
      "id": 51,
      "unique_id_transporter": "TM2510HRTR12979",
      "unique_id_driver": "TM2511HRDR16442",
      "user_id_transporter": 13007,
      "user_id_driver": 16586,
      "assigned_to": 3,
      "job_id": "TMJB00551",
      "call_status": "callback_later",
      "call_feedback": "Busy Right Now",
      "call_remarks": "testing",
      "call_recording": null,
      "call_duration": null,
      "active_time": "44",
      "match_status": "pending",
      "driver_name": "Vikramjeet",
      "transporter_name": "Dipanshu",
      "created_at": "2025-12-17 11:42:54",
      "updated_at": "2025-12-17 11:43:38"
    }
  ]
}
```

**Data Transformation:**
The Laravel API response is transformed to match the CallHistoryLog model:
- `call_feedback` → `feedback`
- `call_remarks` → `remark`
- `call_recording` → `callRecording`
- `match_status` → `matchStatus`
- `unique_id_driver` → `uniqueIdDriver`
- `unique_id_transporter` → `uniqueIdTransporter`
- `driver_name` → `driverName`
- `transporter_name` → `transporterName`

## Authentication

All API calls now use Bearer token authentication:
```dart
final token = await RealAuthService.instance.getAuthToken();
headers: {
  'Authorization': 'Bearer $token',
  'Content-Type': 'application/json',
  'Accept': 'application/json',
}
```

## Data Processing

### Transporter List
- Fetches all jobs assigned to the telecaller
- Groups jobs by `transporter_tmid`
- Counts total calls per transporter
- Tracks last call date
- Sorts by most recent call first

### Transporter Call History
- Fetches all jobs assigned to the telecaller
- Filters by specific `transporter_tmid`
- Returns all jobs for that transporter

### Driver Call History
- Fetches all jobs assigned to the telecaller (match-making data)
- Transforms job data to CallHistoryLog format
- Applies client-side filtering for:
  - Period (today, week, month, all)
  - Feedback type
  - Search (driver name, driver TMID, transporter name, transporter TMID)
  - Pagination (limit, offset)

## Testing

To test the changes:

1. **Transporter List:**
   - Navigate to Call History → Transporters tab
   - Verify transporters are listed with call counts
   - Check that search works correctly

2. **Transporter Call History:**
   - Tap on any transporter from the list
   - Verify call history is displayed
   - Check that all calls for that transporter are shown

3. **Driver Call History:**
   - Navigate to Call History → My Calls tab
   - Verify call logs are displayed (showing match-making data)
   - Test period filters (Today, Week, Month, All)
   - Test feedback filters
   - Test search functionality

## Files Modified

- `lib/core/services/phase2_api_service.dart`
  - Updated `getTransportersWithCallHistory()` method
  - Updated `getTransporterCallHistory()` method
  - Updated `fetchCallHistory()` method

## Notes

- Both transporter and driver call history now use the same Laravel API endpoint: `https://truckmitr.com/api/telehead/jobs/assigned-to/{assigned_to}`
- The API returns job brief data with match-making information (driver + transporter pairs)
- Client-side filtering and transformation is used to maintain compatibility with existing UI
- Bearer token is automatically retrieved from `RealAuthService` which stores it during login
- All API calls include proper error handling and logging
