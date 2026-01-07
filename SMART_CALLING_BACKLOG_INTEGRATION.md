# Smart Calling Backlog Integration

## Overview
Integrated the backlog screen data into the Smart Calling page's backlog tab, so both screens now show the same filtered backlog data.

## Changes Made

### File: `lib/features/telecaller/smart_calling_page.dart`

#### 1. Added Imports
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/config/api_config.dart';
```

#### 2. Updated `_loadBacklogData()` Method
**Before:** Used `SmartCallingService.instance.getDriversByStatus()` which loaded all callback leads without filtering by telecaller.

**After:** Now uses the same API as `backlog_screen.dart`:
- Calls `backlog_by_telecaller.php?caller_id={callerId}`
- Filters backlog leads by the current telecaller
- Uses `DriverContact.fromBacklogJson()` to parse the data
- Shows only leads assigned to or relevant to the current telecaller

## API Endpoint
```
GET /api/backlog_by_telecaller.php?caller_id={callerId}
```

### Response Format
```json
{
  "status": true,
  "data": [
    {
      "id": "123",
      "unique_id": "TM123456",
      "name": "John Doe",
      "mobile": "9876543210",
      "role": "driver",
      "callback_history": [...],
      "callback_requests_count": 2,
      ...
    }
  ],
  "total_backlog": 10,
  "filtered_by_telecaller": 5
}
```

## Benefits

1. **Consistency**: Both backlog_screen.dart and smart_calling_page.dart now show identical data
2. **Filtered Data**: Telecallers only see their assigned backlog leads
3. **Real-time**: Data is fetched from the same live API endpoint
4. **Accurate Counts**: The backlog count in Smart Calling now matches the standalone Backlog screen

## User Experience

### Smart Calling Page - Backlog Tab
- Shows leads with callback scheduled
- Filtered by current telecaller
- Displays callback history and request count
- Same call functionality as other tabs (Manual, IVR, EasyGo)
- Feedback submission works identically to backlog_screen.dart

### Navigation Flow
1. User opens Smart Calling page
2. Switches to "Backlog" tab (3rd tab)
3. Sees their assigned backlog leads
4. Can call and submit feedback
5. Lead is removed from list after feedback submission

## Testing Checklist
- [ ] Open Smart Calling page
- [ ] Switch to Backlog tab
- [ ] Verify leads match standalone Backlog screen
- [ ] Verify count is accurate
- [ ] Call a backlog lead
- [ ] Submit feedback
- [ ] Verify lead is removed from list
- [ ] Verify feedback is saved to database
- [ ] Pull to refresh and verify data updates

## Technical Notes

### Data Flow
```
Smart Calling Page (Backlog Tab)
    ↓
_loadBacklogData()
    ↓
GET /api/backlog_by_telecaller.php?caller_id={id}
    ↓
DriverContact.fromBacklogJson()
    ↓
Display in DriverContactCard
    ↓
Call & Feedback (same as other tabs)
```

### Error Handling
- Handles network errors gracefully
- Shows empty state if no backlog leads
- Logs detailed error messages for debugging
- Falls back to empty list on API failure

## Related Files
- `lib/features/telecaller/screens/backlog_screen.dart` - Standalone backlog screen
- `lib/features/telecaller/smart_calling_page.dart` - Smart calling with integrated backlog
- `api/backlog_by_telecaller.php` - Backend API endpoint
- `lib/models/smart_calling_models.dart` - DriverContact.fromBacklogJson() method
