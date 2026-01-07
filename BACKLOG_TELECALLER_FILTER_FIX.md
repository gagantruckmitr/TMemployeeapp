# Backlog Telecaller Filter Fix

## Problem
1. KPI showed incorrect backlog count (not matching actual leads)
2. Backlog screen showed leads from ALL telecallers instead of only the logged-in telecaller (e.g., Pooja with caller_id=3)

## Root Cause
- Using wrapper API (`telehead_backlog_enhanced.php`) that wasn't filtering properly
- KPI count was fetching from wrong source
- Telecaller assignment filtering was not working correctly

## Solution

### 1. Direct Telehead API Usage
Updated both backlog screen and service to use telehead API directly:
- **Endpoint**: `https://truckmitr.com/api/telehead/backlog-leads`
- **Authentication**: Bearer token (contains caller_id)
- **Filtering**: Telehead API automatically filters by logged-in telecaller

### 2. KPI Count Fix
Updated `TelecallerService._getBacklogCountFromTelehead()`:
```dart
// Now uses total_backlog from telehead API response
return data['total_backlog'] ?? 0;
```

### 3. Backlog Screen Update
Updated `BacklogScreen._loadBacklogLeads()`:
- Changed from wrapper to direct telehead API
- Uses `total_backlog` field for accurate count
- Properly displays pagination info (current_page, last_page)

## Files Modified
1. `lib/core/services/telecaller_service.dart` - Updated backlog count method
2. `lib/features/telecaller/screens/backlog_screen.dart` - Changed to direct API
3. `api/telehead_backlog_enhanced.php` - Fixed column name (assigned_to)

## Testing
```bash
# Test with Pooja's token (caller_id=3)
curl -X GET "https://truckmitr.com/api/telehead/backlog-leads" \
  -H "Authorization: Bearer 84|bkv6gfO9YDW2cOTg3oN3Z0R14LyItZbjxXSgImR099a7ce90" \
  -H "Accept: application/json"
```

## Result
✅ KPI shows exact count from telehead API (total_backlog field)
✅ Backlog screen shows only leads assigned to logged-in telecaller
✅ Count in KPI matches count in backlog screen
✅ Pooja (caller_id=3) only sees her assigned backlog leads

## API Response Structure
```json
{
  "status": true,
  "total_backlog": 148,
  "current_page": 1,
  "last_page": 8,
  "data": [
    {
      "id": 20678,
      "name": "Pritesh",
      "role": "transporter",
      ...
    }
  ]
}
```

## Notes
- Telehead API returns 20 leads per page
- Total count is in `total_backlog` field
- API automatically filters by telecaller based on bearer token
- No need for wrapper API anymore
