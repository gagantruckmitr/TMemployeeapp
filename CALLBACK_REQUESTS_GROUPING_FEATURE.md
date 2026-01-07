# Callback Requests - User Grouping Feature

## Date: 6 December 2024

## Feature Overview
Implemented grouping of callback requests by user to avoid duplicate cards. When the same user (driver/transporter) has multiple callback requests, only ONE card is shown with a "History" button to view all their requests.

## Problem Solved
**Before**: If a transporter applied 5 times, there were 5 separate cards cluttering the screen.  
**After**: Only 1 card is shown with a button: "View 5 Callback Requests"

## Implementation

### 1. API Changes (`api/callback_requests_api.php`)

**Modified**: `getCallbackRequests()` function

**What it does**:
- Fetches all callback requests as before
- Groups them by `unique_id` (user identifier)
- For each user, keeps only the LATEST request as the main card
- Stores ALL requests in a `callback_history` array
- Adds `callback_requests_count` field

**Code Logic**:
```php
// Group by unique_id to avoid duplicate cards
$groupedData = [];

foreach ($allRequests as $row) {
    $uniqueId = $row['unique_id'];
    
    if (!isset($groupedData[$uniqueId])) {
        // First request - use as main card
        $enriched = enrichRequestData($conn, $row);
        $enriched['callback_history'] = [];
        $groupedData[$uniqueId] = $enriched;
    }
    
    // Add to history
    $groupedData[$uniqueId]['callback_history'][] = [
        'id' => $row['id'],
        'contact_reason' => $row['contact_reason'],
        'request_date_time' => $row['request_date_time'],
        'status' => $row['status'],
        'notes' => $row['notes'],
        'created_at' => $row['created_at'],
        'updated_at' => $row['updated_at']
    ];
}

// Add count
foreach ($data as &$item) {
    $item['callback_requests_count'] = count($item['callback_history']);
}
```

### 2. Model Changes (`lib/models/database_models.dart`)

**Added to CallbackRequest model**:
```dart
final List<dynamic>? callbackHistory; // All callback requests for this user
final int? callbackRequestsCount; // Total count
```

**Parsing**:
```dart
callbackHistory: json['callback_history'] as List<dynamic>?,
callbackRequestsCount: json['callback_requests_count'] as int?,
```

### 3. New Widget (`lib/features/telecaller/widgets/callback_history_modal.dart`)

**Purpose**: Modal bottom sheet to display all callback requests for a user

**Features**:
- Shows all callback requests in chronological order
- Each request displays:
  - Request number (#1, #2, #3...)
  - Date and time
  - Reason (highlighted in amber box)
  - Status (color-coded badge)
  - Notes (if any)
- Draggable sheet (can resize)
- Smooth scrolling
- Color-coded status indicators

**Status Colors**:
- 🟠 Orange: Pending, Callback
- 🟢 Green: Contacted, Resolved, Interested
- 🔴 Red: Not Interested
- ⚪ Grey: Ringing/Busy, Disconnected, Switched Off
- 🔵 Blue: Future Prospects

### 4. UI Changes

**Modified**: `lib/features/telecaller/widgets/driver_contact_card.dart`

**What changed**:
- Added `callbackHistory` and `callbackRequestsCount` parameters
- Added `_buildCallbackHistoryButton()` method
- If `callbackRequestsCount > 1`, shows history button INSIDE the card
- Button displays: "View X Callback Requests"
- Clicking button opens the CallbackHistoryModal

**Button Design**:
- Orange background with orange border
- History icon on left, arrow icon on right
- Shows count of requests
- Positioned below "Assigned to" and "Call History" row
- Haptic feedback on tap

**Modified**: `lib/features/telecaller/callback_requests/callback_requests_screen.dart`

**What changed**:
- Passes `callbackHistory` and `callbackRequestsCount` to DriverContactCard
- No external button needed - button is inside the card

## User Experience

### Scenario 1: Single Callback Request
**Display**: 
- Shows 1 card with user info
- No history button (not needed)

### Scenario 2: Multiple Callback Requests (e.g., 3 requests)
**Display**:
- Shows 1 card with user info (latest request)
- Inside card (at bottom): Orange button "View 3 Callback Requests"
- Clicking button opens modal showing all 3 requests with details

### Modal View
```
┌─────────────────────────────────────┐
│  🔵 Callback History                │
│  Rajesh Kumar - 3 requests          │
├─────────────────────────────────────┤
│  Request #1                         │
│  📅 22 Nov 2024, 10:30 AM          │
│  📋 Reason: For Jobs                │
│  🟠 PENDING                         │
├─────────────────────────────────────┤
│  Request #2                         │
│  📅 23 Nov 2024, 02:15 PM          │
│  📋 Reason: Subscription Query      │
│  🟢 CONTACTED                       │
├─────────────────────────────────────┤
│  Request #3                         │
│  📅 24 Nov 2024, 09:45 AM          │
│  📋 Reason: Payment Issue           │
│  🟠 CALLBACK                        │
└─────────────────────────────────────┘
```

## Benefits

### 1. Cleaner UI
- No duplicate cards for same user
- Easier to scan through requests
- Less scrolling required

### 2. Better Context
- See all callback requests for a user in one place
- Understand user's history and patterns
- Track multiple issues/reasons

### 3. Improved Workflow
- Call user once, address all their requests
- No confusion about which request to handle
- Clear visibility of request count

## Technical Details

### Grouping Logic
- **Key**: `unique_id` (user's unique identifier)
- **Main Card**: Latest request (most recent `created_at`)
- **History**: All requests sorted by date (newest first)

### Data Flow
1. API fetches all callback requests
2. Groups by `unique_id`
3. Returns array with one entry per user
4. Each entry contains `callback_history` array
5. Flutter displays one card per user
6. History button shows modal with all requests

## Testing

### Test Case 1: User with 1 Request
1. Open Callback Requests screen
2. Find user with single request
3. Verify: No history button shown
4. Card displays normally

### Test Case 2: User with Multiple Requests
1. Open Callback Requests screen
2. Find user with multiple requests
3. Verify: History button shown below card
4. Button text: "View X Callback Requests" (X = count)
5. Click button
6. Verify: Modal opens with all requests
7. Check: Each request shows reason, time, status
8. Verify: Can scroll through all requests
9. Close modal

### Test Case 3: Different Users
1. Verify: Each user gets their own card
2. Verify: No mixing of requests between users
3. Verify: Counts are accurate per user

## Edge Cases Handled

### Empty History
- If `callback_history` is null/empty, button not shown
- Graceful fallback to single card display

### Single Request
- If `callbackRequestsCount` is 1, no button shown
- No unnecessary UI clutter

### Large Number of Requests
- Modal is scrollable
- Handles 10+ requests smoothly
- Draggable sheet for better UX

## Files Modified

1. **api/callback_requests_api.php**
   - Modified `getCallbackRequests()` to group by user
   - Added `callback_history` and `callback_requests_count` fields

2. **lib/models/database_models.dart**
   - Added `callbackHistory` and `callbackRequestsCount` fields to CallbackRequest model

3. **lib/features/telecaller/widgets/callback_history_modal.dart** (NEW)
   - Created modal widget to display callback history

4. **lib/features/telecaller/callback_requests/callback_requests_screen.dart**
   - Added import for CallbackHistoryModal
   - Modified `_buildRequestsList()` to show history button
   - Added modal trigger on button press

## Future Enhancements

### Possible Improvements:
1. **Bulk Actions**: Handle all requests for a user at once
2. **Quick View**: Show preview of reasons without opening modal
3. **Filters**: Filter history by status, date range
4. **Export**: Export user's callback history
5. **Analytics**: Track patterns in callback reasons

## Summary

✅ **Implemented**: User grouping for callback requests  
✅ **Result**: One card per user, regardless of request count  
✅ **Feature**: History button to view all requests  
✅ **UX**: Cleaner, more organized callback requests screen  
✅ **Benefit**: Easier to manage and track user callbacks  

The feature successfully eliminates duplicate cards while preserving access to all callback request details through an intuitive history modal.
