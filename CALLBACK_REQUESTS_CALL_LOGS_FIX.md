# Callback Requests Call Logs Fix

## Problem
When making calls from the Callback Requests screen and submitting feedback:
1. ❌ Calls were being saved to `call_logs` table with incorrect `user_id` (using callback_request.id instead of users.id)
2. ❌ The `tc_for` field was not being populated
3. ❌ After submitting feedback, leads were not moving to history section properly
4. ❌ Call logs were not showing correct user information

## Root Cause
The `callback_requests` table has its own `id` field, but the `call_logs` table needs the actual `user_id` from the `users` table. The code was using `request.id` (callback_request ID) instead of `request.userId` (actual user ID from users table).

## Solution

### 1. Database Structure
```sql
-- callback_requests table
CREATE TABLE callback_requests (
  id INT PRIMARY KEY AUTO_INCREMENT,
  unique_id VARCHAR(255),  -- Links to users.unique_id
  user_name VARCHAR(255),
  mobile_number VARCHAR(20),
  ...
);

-- users table
CREATE TABLE users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  unique_id VARCHAR(255),  -- TM ID (e.g., TM123456)
  name VARCHAR(255),
  mobile VARCHAR(20),
  ...
);

-- call_logs table
CREATE TABLE call_logs (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT,          -- Must be users.id (NOT callback_requests.id)
  caller_id BIGINT,        -- Telecaller ID from admins table
  tc_for VARCHAR(100),     -- Source: 'callback_requests', 'fresh_leads', etc.
  call_status ENUM(...),
  feedback TEXT,
  remarks TEXT,
  ...
);
```

### 2. Code Changes

#### A. Flutter App (callback_requests_screen.dart)
```dart
// BEFORE (WRONG):
await _saveToCallLogs(
  userId: request.id,  // ❌ This is callback_request.id
  ...
);

// AFTER (CORRECT):
final actualUserId = request.userId ?? request.id;
await _saveToCallLogs(
  userId: actualUserId,  // ✅ This is users.id
  callerId: int.parse(user.id),
  driverName: request.userName,
  userNumber: request.mobileNumber,
  callerNumber: user.mobile,
  status: _mapCallStatusToString(feedback.status),
  feedback: feedbackText,
  remarks: feedback.remarks,
  callSource: 'callback_requests',
  tmid: request.uniqueId,
);
```

#### B. API (callback_requests_api.php)
```php
// Ensure user_id is always returned
if (isset($relatedUser['id'])) {
    $row['user_id'] = (int)$relatedUser['id'];
    error_log("✅ Set user_id={$relatedUser['id']} for callback request");
}
```

#### C. API (call_logs_api.php)
```php
// Use call_source as tc_for if not provided
$tcFor = $input['tc_for'] ?? $input['call_source'] ?? null;

// Log for debugging
error_log("📞 Inserting call log: user_id=$userId, caller_id=$callerId, tc_for=$tcFor");
```

### 3. Data Flow

```
User makes call from Callback Requests screen
    ↓
Feedback submitted
    ↓
1. Save to call_logs table:
   - user_id: users.id (from callback_request.userId)
   - caller_id: telecaller's admin.id
   - tc_for: 'callback_requests'
   - feedback: Selected feedback text
   - remarks: Telecaller notes
   - call_status: Mapped from feedback status
   - reference_id: CALLBACK_{timestamp}_{caller_id}_{user_id}
    ↓
2. Update callback_requests status:
   - status: Mapped from feedback (e.g., 'Contacted', 'Interested')
   - notes: Telecaller remarks
    ↓
3. Move to history:
   - Requests with status 'Contacted', 'Resolved', 'Interested', 'Not Interested'
   - Show in History tab with latest call feedback
```

### 4. Status Mapping

#### Feedback to Callback Status
```dart
CallStatus.connected → CallbackStatus.contacted/interested
CallStatus.callBack → CallbackStatus.callback
CallStatus.notReachable → CallbackStatus.switchedOff
CallStatus.notInterested → CallbackStatus.notInterested
CallStatus.invalid → CallbackStatus.disconnected
```

#### Callback Status to History
```php
// Requests Tab (Pending)
'Pending', 'Callback', 'Ringing / Call Busy', 
'Disconnected', 'Swtiched Off / Out of Service or Network', 
'Future Prospects'

// History Tab (Completed)
'Contacted', 'Resolved', 'Interested', 'Not Interested'
```

### 5. Testing

#### Test Script
```bash
# Run test script to verify database structure and mappings
curl http://localhost/api/test_callback_call_logs.php
```

#### Manual Testing Steps
1. Open Callback Requests screen
2. Select a pending callback request
3. Make a call (Manual or IVR)
4. Submit feedback with remarks
5. Verify:
   - ✅ Call appears in call_logs table with correct user_id
   - ✅ tc_for field is set to 'callback_requests'
   - ✅ Feedback and remarks are saved
   - ✅ Request moves to History tab
   - ✅ History shows the feedback and remarks

#### Database Verification
```sql
-- Check recent callback call logs
SELECT 
    cl.id,
    cl.user_id,
    u.unique_id as tmid,
    u.name as user_name,
    cl.caller_id,
    a.name as telecaller_name,
    cl.tc_for,
    cl.call_status,
    cl.feedback,
    cl.remarks,
    cl.created_at
FROM call_logs cl
LEFT JOIN users u ON cl.user_id = u.id
LEFT JOIN admins a ON cl.caller_id = a.id
WHERE cl.tc_for = 'callback_requests'
ORDER BY cl.created_at DESC
LIMIT 10;

-- Check callback requests with user mapping
SELECT 
    cr.id as callback_id,
    cr.unique_id,
    cr.user_name,
    cr.status,
    u.id as user_id,
    u.name as user_name_from_users
FROM callback_requests cr
LEFT JOIN users u ON cr.unique_id = u.unique_id
LIMIT 10;
```

## Files Modified

1. **lib/features/telecaller/callback_requests/callback_requests_screen.dart**
   - Fixed user_id mapping in _saveToCallLogs
   - Added caller_number and reference_id
   - Added tmid parameter

2. **api/call_logs_api.php**
   - Added tc_for fallback to call_source
   - Added debug logging

3. **api/callback_requests_api.php**
   - Enhanced user_id mapping with logging
   - Ensured user_id is always returned as integer

4. **api/test_callback_call_logs.php** (NEW)
   - Test script to verify database structure
   - Check user_id mappings
   - Verify call logs

## Expected Behavior After Fix

### Before Feedback
- Request appears in "Requests" tab
- Shows pending status
- Can make call

### After Feedback Submission
1. Call log created in `call_logs` table with:
   - Correct `user_id` (from users table)
   - `tc_for` = 'callback_requests'
   - Feedback text
   - Telecaller remarks
   - Call status

2. Callback request updated:
   - Status changed based on feedback
   - Notes updated with remarks

3. UI updated:
   - Request removed from "Requests" tab
   - Request appears in "History" tab
   - History shows feedback and remarks

## Troubleshooting

### Issue: user_id is null in call_logs
**Solution**: Check that callback_requests_api.php is returning user_id field

### Issue: Request not moving to history
**Solution**: Verify status mapping is correct and status is in history list

### Issue: Feedback not showing in history
**Solution**: Check that call_logs join query is working correctly

## Notes

- The `userId` field in CallbackRequest model is populated by the API from the users table
- The callback_requests table links to users via `unique_id` (TM ID)
- The call_logs table uses numeric `user_id` from users.id
- Always use `request.userId` for call_logs, never `request.id`
