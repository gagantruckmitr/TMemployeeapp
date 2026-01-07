# Callback Feedback Display Fix

## Problems Fixed

1. ✅ Call logs were being created but feedback field was empty
2. ✅ History section in callback requests didn't show feedback on cards

## Root Causes

### Problem 1: Feedback Not Showing in call_logs
The feedback WAS being saved correctly to `call_logs.feedback` field, but the history API wasn't fetching it.

### Problem 2: History Cards Not Showing Feedback
The `getCallbackHistory()` API was only fetching from `callback_requests` table without joining with `call_logs` to get the feedback information.

## Solutions Implemented

### 1. Updated API to Join with call_logs

**File**: `api/callback_requests_api.php`

Modified `getCallbackHistory()` function to:
- Join with `call_logs` table
- Get the latest call log for each callback request
- Include feedback, remarks, and call time from call_logs

**SQL Query**:
```sql
SELECT 
    cr.*,
    cl.feedback as call_feedback,
    cl.remarks as call_remarks,
    cl.call_time as last_call_time
FROM callback_requests cr
LEFT JOIN (
    SELECT 
        user_id,
        feedback,
        remarks,
        call_time,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY call_time DESC) as rn
    FROM call_logs
    WHERE call_source = 'callback_requests'
) cl ON cl.user_id = cr.id AND cl.rn = 1
WHERE cr.status IN ('Contacted', 'Resolved', 'Interested', 'Not Interested')
ORDER BY cr.updated_at DESC
```

**Key Features**:
- Uses `ROW_NUMBER()` to get only the latest call log per user
- Filters by `call_source = 'callback_requests'` to get only callback-related calls
- Returns `call_feedback`, `call_remarks`, and `last_call_time`

### 2. Updated CallbackRequest Model

**File**: `lib/models/database_models.dart`

Added three new fields to `CallbackRequest` class:
```dart
final String? callFeedback;    // Feedback from call_logs
final String? callRemarks;     // Remarks from call_logs
final DateTime? lastCallTime;  // When the call was made
```

Updated `fromJson()` to parse these fields:
```dart
callFeedback: json['call_feedback'] as String?,
callRemarks: json['call_remarks'] as String?,
lastCallTime: json['last_call_time'] != null
    ? DateTime.parse(json['last_call_time'])
    : null,
```

### 3. Updated Contact Mapping

**File**: `lib/features/telecaller/callback_requests/callback_requests_screen.dart`

Updated `_mapRequestToDriverContact()` and `_mapRequestToTransporterContact()`:

**Before**:
```dart
lastFeedback: null,
lastCallTime: request.requestDateTime,
remarks: request.notes,
```

**After**:
```dart
lastFeedback: request.callFeedback,  // ✅ Now shows actual feedback
lastCallTime: request.lastCallTime ?? request.requestDateTime,
remarks: request.callRemarks ?? request.notes,
```

### 4. Updated Optimistic UI Update

When feedback is submitted, the optimistic update now includes:
```dart
callFeedback: feedbackText,      // The feedback text
callRemarks: feedback.remarks,   // User's remarks
lastCallTime: DateTime.now(),    // Current time
```

This ensures the feedback shows immediately in the UI without waiting for refresh.

## Data Flow

### When Feedback is Submitted:

1. **Save to call_logs**:
   ```json
   {
     "user_id": 123,
     "caller_id": 1,
     "call_status": "connected",
     "feedback": "Agree for Subscription Today",
     "remarks": "User is very interested",
     "call_source": "callback_requests"
   }
   ```

2. **Update callback_requests**:
   ```json
   {
     "status": "Interested",
     "notes": "User is very interested"
   }
   ```

3. **Optimistic UI Update**:
   - Moves request to history
   - Shows feedback immediately
   - Shows remarks immediately

4. **On Refresh**:
   - API joins with call_logs
   - Returns latest feedback
   - UI displays feedback on card

### History Card Display:

The `DriverContactCard` widget now shows:
- **Last Feedback**: "Agree for Subscription Today" (from `call_logs.feedback`)
- **Remarks**: "User is very interested" (from `call_logs.remarks`)
- **Last Call Time**: "2 hours ago" (from `call_logs.call_time`)

## Database Tables

### call_logs Table
```sql
CREATE TABLE call_logs (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT,
  caller_id INT,
  call_status VARCHAR(50),
  feedback TEXT,           -- ✅ Stores detailed feedback
  remarks TEXT,            -- ✅ Stores user remarks
  call_source VARCHAR(50), -- ✅ Set to 'callback_requests'
  call_time DATETIME,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

### callback_requests Table
```sql
CREATE TABLE callback_requests (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_name VARCHAR(255),
  mobile_number VARCHAR(20),
  status ENUM('Pending', 'Contacted', 'Resolved', 'Interested', 'Not Interested'),
  notes TEXT,              -- ✅ Stores general notes
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

## API Response Example

### Before Fix:
```json
{
  "success": true,
  "data": [
    {
      "id": 123,
      "user_name": "John Doe",
      "status": "Interested",
      "notes": "User is very interested"
      // ❌ No feedback information
    }
  ]
}
```

### After Fix:
```json
{
  "success": true,
  "data": [
    {
      "id": 123,
      "user_name": "John Doe",
      "status": "Interested",
      "notes": "User is very interested",
      "call_feedback": "Agree for Subscription Today",  // ✅ Added
      "call_remarks": "User is very interested",        // ✅ Added
      "last_call_time": "2025-12-06 10:30:00"          // ✅ Added
    }
  ]
}
```

## UI Display

### History Card Shows:

```
┌─────────────────────────────────────┐
│ 👤 John Doe                    📞  │
│ TM2511JHDR18770                    │
│                                     │
│ 📋 Last Feedback:                  │
│ "Agree for Subscription Today"     │
│                                     │
│ 💬 Remarks:                        │
│ "User is very interested"          │
│                                     │
│ 🕐 Last Call: 2 hours ago          │
│                                     │
│ [Call Again] [View Details]        │
└─────────────────────────────────────┘
```

## Testing

### Test Case 1: Submit New Feedback
1. Open Callback Requests
2. Call a user
3. Submit feedback: "Agree for Subscription Today"
4. Add remarks: "Very interested in premium plan"
5. **Expected**: 
   - ✅ Request moves to History tab
   - ✅ Card shows feedback immediately
   - ✅ Card shows remarks immediately

### Test Case 2: Refresh History
1. Go to History tab
2. Pull to refresh
3. **Expected**:
   - ✅ All cards show feedback
   - ✅ All cards show remarks
   - ✅ All cards show last call time

### Test Case 3: Multiple Calls
1. Call same user multiple times
2. Submit different feedback each time
3. **Expected**:
   - ✅ Card shows LATEST feedback only
   - ✅ Multiple entries in call_logs
   - ✅ History shows most recent call

### Test Case 4: Database Verification
```sql
-- Check call_logs has feedback
SELECT 
    cl.id,
    cl.user_id,
    cl.feedback,
    cl.remarks,
    cl.call_source,
    cl.call_time
FROM call_logs cl
WHERE cl.call_source = 'callback_requests'
ORDER BY cl.created_at DESC
LIMIT 10;

-- Should show feedback and remarks populated
```

## Files Modified

1. **api/callback_requests_api.php**
   - Updated `getCallbackHistory()` function
   - Added JOIN with call_logs table
   - Returns feedback, remarks, and call time

2. **lib/models/database_models.dart**
   - Added `callFeedback` field
   - Added `callRemarks` field
   - Added `lastCallTime` field
   - Updated `fromJson()` and `toJson()`

3. **lib/features/telecaller/callback_requests/callback_requests_screen.dart**
   - Updated `_mapRequestToDriverContact()`
   - Updated `_mapRequestToTransporterContact()`
   - Updated optimistic UI update
   - Now passes feedback to contact cards

## Benefits

1. **Complete Call History** - See what was discussed in each call
2. **Better Follow-ups** - Know exactly what was said last time
3. **Performance Tracking** - Analyze feedback patterns
4. **User Experience** - Telecallers can see full context
5. **Data Consistency** - Feedback stored in proper table (call_logs)

## Deployment

1. ✅ No database migrations required
2. ⚠️ **Flutter app rebuild required** (model changed)
3. ✅ PHP API updated (backward compatible)
4. ⚠️ Hot restart the Flutter app
5. ⚠️ Clear PHP opcache if using

---

**Status**: ✅ Complete
**Date**: December 6, 2025
**Impact**: High - Enables proper feedback tracking and display
**Related**: CALLBACK_REQUESTS_FEEDBACK_TO_CALL_LOGS_FIX.md
