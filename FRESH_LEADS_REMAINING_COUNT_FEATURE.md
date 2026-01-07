# Fresh Leads Remaining Count Feature - COMPLETE FIX

## Overview
Implemented a feature to display and track the `remaining_fresh` count from the API, which shows only uncalled leads and decreases after each call is completed and feedback is submitted.

## Problem Fixed
- **Before**: Screen showed 9 leads but only 7 were remaining (2 already called)
- **After**: Screen now shows only the 7 uncalled leads, matching the `remaining_fresh` count

## API Response Structure
The API endpoint `https://truckmitr.com/api/telehead/today-leads` returns:
```json
{
  "status": true,
  "assigned_count": [
    {
      "assigned_to": 8,
      "assigned_name": "Sonam",
      "total_assigned": 9,
      "total_called": 2,
      "remaining_fresh": 7
    }
  ],
  "data": [
    {
      "id": 20830,
      "assigned_to": 8,
      "name": "Sonu",
      "call_logs": [...]  // Has call logs = already called
    },
    {
      "id": 20837,
      "assigned_to": 8,
      "name": "Karan",
      "call_logs": []  // No call logs = fresh lead
    }
  ]
}
```

## Changes Made

### 1. TodayLeadsService (`lib/core/services/today_leads_service.dart`)
- Added `_remainingFreshLeads` private variable to store the count
- Added `remainingFreshLeads` getter to access the count
- Modified `getTodayLeads()` to extract `remaining_fresh` from the `assigned_count` array
- **KEY FIX**: Added `callLogs` field to `TodayLead` model
- **KEY FIX**: Added `hasBeenCalled` getter that checks if `callLogs` is not empty
- **KEY FIX**: Filter leads to exclude those with `hasBeenCalled = true`
- Now only returns uncalled leads (matching the `remaining_fresh` count)

### 2. FreshLeadsScreen (`lib/features/telecaller/screens/fresh_leads_screen.dart`)
- Added `_remainingFreshLeads` state variable
- Updated `_loadLeads()` to fetch and store the remaining count from the service
- Modified the stats header to display the remaining fresh leads count with a badge
- Updated `_updateContactStatus()` to reload leads after successful feedback submission
- The snackbar now shows the updated remaining count after call completion

### 3. Dashboard API (`api/telecaller_dashboard_stats.php`)
- Updated to use `remaining_fresh` from the `assigned_count` array
- Fallback logic to count uncalled leads from data array (excluding those with call_logs)
- Now shows accurate fresh leads count on dashboard KPI

## UI Changes
The Fresh Leads screen now displays:
- **Left side**: Uncalled leads count (e.g., "7 Leads")
- **Right side**: Remaining fresh leads badge (e.g., "Remaining: 7")
- **Both numbers match** because we filter out called leads

The badge has:
- Blue background with opacity
- Phone callback icon
- Bold text showing the count

## Behavior
1. When the screen loads:
   - Fetches all leads from API
   - Filters out leads with `call_logs` (already called)
   - Shows only uncalled leads
   - Displays `remaining_fresh` count in badge

2. After a call is completed and feedback is submitted:
   - The API is called again to refresh the data
   - The lead that was just called now has `call_logs`
   - It gets filtered out from the list
   - The `remaining_fresh` count decreases by 1
   - UI updates to show new count
   - Snackbar shows: "Call completed for [Name] • Remaining: X"

3. Dashboard KPI:
   - Shows the same `remaining_fresh` count
   - Updates automatically when leads are called

## Testing
To test:
1. Open Fresh Leads screen
2. Verify only uncalled leads appear (no leads with existing call logs)
3. Verify the "Remaining: X" badge matches the lead count
4. Make a call and submit feedback
5. Verify the lead disappears from the list
6. Verify the count decreases by 1
7. Check dashboard - fresh leads count should also decrease

## Technical Details

### Lead Filtering Logic
```dart
// Only show leads that:
// 1. Are assigned to current user
// 2. Have NOT been called (call_logs is empty)
userLeads = allLeads
    .where((lead) => lead.assignedTo == currentUserId && !lead.hasBeenCalled)
    .toList();
```

### Call Logs Detection
```dart
bool get hasBeenCalled => callLogs.isNotEmpty;
```

A lead is considered "called" if it has any entries in the `call_logs` array from the API.

## Notes
- The count is fetched from the API's `assigned_count` array
- Leads are filtered by checking the `call_logs` field
- Both the list count and badge count now match
- Dashboard KPI also uses the same logic
- If the API doesn't return the count, it defaults to 0
