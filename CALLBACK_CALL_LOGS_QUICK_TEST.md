# Quick Test Guide: Callback Requests Call Logs Fix

## Quick Test (5 minutes)

### 1. Test Database Structure
```bash
curl http://localhost/api/test_callback_call_logs.php | json_pp
```

Expected output:
```json
{
  "summary": {
    "callback_requests_table_exists": true,
    "call_logs_table_exists": true,
    "sample_request_found": true,
    "user_mapping_working": true
  }
}
```

### 2. Test in App

#### Step 1: Open Callback Requests
1. Launch app
2. Navigate to Callback Requests screen
3. You should see pending requests in "Requests" tab

#### Step 2: Make a Call
1. Tap call button on any request
2. Choose "Manual Call" or "IVR Call"
3. Complete the call

#### Step 3: Submit Feedback
1. Feedback modal appears
2. Select feedback (e.g., "Agree for Subscription")
3. Add remarks (optional)
4. Tap "Submit Feedback"

#### Step 4: Verify Results
1. ✅ Request disappears from "Requests" tab
2. ✅ Request appears in "History" tab
3. ✅ History shows feedback and remarks

### 3. Verify Database

```sql
-- Check the latest call log
SELECT 
    cl.id,
    cl.user_id,
    u.unique_id as tmid,
    u.name,
    cl.tc_for,
    cl.feedback,
    cl.remarks,
    cl.created_at
FROM call_logs cl
LEFT JOIN users u ON cl.user_id = u.id
WHERE cl.tc_for = 'callback_requests'
ORDER BY cl.created_at DESC
LIMIT 1;
```

Expected:
- ✅ `user_id` matches users.id (not callback_requests.id)
- ✅ `tc_for` = 'callback_requests'
- ✅ `feedback` contains feedback text
- ✅ `remarks` contains your notes
- ✅ `tmid` shows correct TM ID

### 4. Check Callback Request Status

```sql
-- Check the callback request was updated
SELECT 
    cr.id,
    cr.unique_id,
    cr.user_name,
    cr.status,
    cr.notes,
    cr.updated_at
FROM callback_requests cr
ORDER BY cr.updated_at DESC
LIMIT 1;
```

Expected:
- ✅ `status` changed to 'Contacted', 'Interested', etc.
- ✅ `notes` contains your remarks
- ✅ `updated_at` is recent

## Common Issues & Solutions

### Issue 1: user_id is NULL in call_logs
**Cause**: callback_requests_api.php not returning user_id
**Fix**: Check API logs for user_id mapping errors

### Issue 2: Request not in history
**Cause**: Status not mapped correctly
**Check**: 
```sql
SELECT status FROM callback_requests WHERE id = [request_id];
```
Should be one of: 'Contacted', 'Resolved', 'Interested', 'Not Interested'

### Issue 3: Feedback not showing
**Cause**: call_logs join query issue
**Check**:
```sql
SELECT * FROM call_logs WHERE user_id = [user_id] ORDER BY created_at DESC LIMIT 1;
```

## Debug Logs

### App Logs (Flutter)
```
✅ Feedback saved to call_logs and callback_requests updated
📊 Profile completion for [Name]: 75%
✅ Set user_id=123 for callback request 456
```

### API Logs (PHP)
```
📞 Inserting call log: user_id=123, caller_id=3, tc_for=callback_requests, status=connected, feedback=Agree for Subscription
✅ Set user_id=123 for callback request 456 (unique_id: TM123456)
```

## Success Criteria

- [x] Call logs saved with correct user_id
- [x] tc_for field populated
- [x] Feedback and remarks saved
- [x] Request moves to history
- [x] History displays feedback
- [x] No errors in logs

## Next Steps

If all tests pass:
1. Test with different feedback types
2. Test with multiple requests
3. Verify call history in user profile
4. Check analytics/reports include callback calls

If tests fail:
1. Check error logs
2. Run test_callback_call_logs.php
3. Verify database structure
4. Check API responses
