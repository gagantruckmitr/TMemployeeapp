# Quick Test Guide - Callback Requests Feedback Fix

## Quick Test Steps

### Test 1: Driver Callback with Feedback
1. Open Callback Requests screen
2. Find a driver in the Requests tab
3. Tap the call button
4. Select call type (Manual or IVR)
5. After call, **verify Driver Feedback Modal opens** ✅
6. Select status: "Connected"
7. Select feedback: "Agree for Subscription Today"
8. Add remarks: "User is very interested"
9. Submit feedback
10. **Verify**: Request moves to History tab
11. **Check Database**:
    ```sql
    -- Check call_logs table
    SELECT * FROM call_logs 
    WHERE call_source = 'callback_requests' 
    ORDER BY id DESC LIMIT 1;
    
    -- Should show:
    -- call_status: 'connected'
    -- feedback: 'Agree for Subscription Today'
    -- remarks: 'User is very interested'
    ```

### Test 2: Transporter Callback with Feedback
1. Open Callback Requests screen
2. Find a transporter in the Requests tab
3. Tap the call button
4. Select call type (Manual or IVR)
5. After call, **verify Transporter Feedback Modal opens** ✅
6. Select status: "Connected"
7. Select feedback: "Interested in Hiring"
8. Add remarks: "Looking for 5 drivers"
9. Submit feedback
10. **Verify**: Request moves to History tab
11. **Check Database**:
    ```sql
    -- Check call_logs table
    SELECT * FROM call_logs 
    WHERE call_source = 'callback_requests' 
    ORDER BY id DESC LIMIT 1;
    
    -- Should show:
    -- call_status: 'connected'
    -- feedback: 'Interested in Hiring'
    -- remarks: 'Looking for 5 drivers'
    ```

### Test 3: History Tab Functionality
1. Go to History tab in Callback Requests
2. **Verify**: Only completed callbacks shown
3. Tap call button on a history item
4. Make another call
5. Submit new feedback
6. **Verify**: New entry created in call_logs
7. **Check Database**:
    ```sql
    -- Check multiple call logs for same user
    SELECT * FROM call_logs 
    WHERE user_id = [USER_ID] 
    AND call_source = 'callback_requests'
    ORDER BY created_at DESC;
    
    -- Should show multiple entries for same user
    ```

## Quick Database Checks

### 1. Verify Call Logs Created
```sql
SELECT 
    cl.id,
    cl.driver_name,
    cl.call_status,
    cl.feedback,
    cl.remarks,
    cl.call_source,
    cl.created_at
FROM call_logs cl
WHERE cl.call_source = 'callback_requests'
ORDER BY cl.created_at DESC
LIMIT 10;
```

**Expected**: New entries with `call_source = 'callback_requests'`

### 2. Verify Callback Status Updated
```sql
SELECT 
    id,
    user_name,
    status,
    notes,
    updated_at
FROM callback_requests
WHERE status IN ('Contacted', 'Interested', 'Not Interested')
ORDER BY updated_at DESC
LIMIT 10;
```

**Expected**: Status changed from 'Pending' to completed status

### 3. Verify Data Consistency
```sql
SELECT 
    cr.user_name,
    cr.status as callback_status,
    cl.call_status,
    cl.feedback,
    cl.created_at as call_logged_at
FROM callback_requests cr
JOIN call_logs cl ON cl.user_id = cr.id
WHERE cl.call_source = 'callback_requests'
ORDER BY cl.created_at DESC
LIMIT 10;
```

**Expected**: Matching data between both tables

## Common Issues & Solutions

### Issue 1: Wrong Modal Opens
**Problem**: Driver modal opens for transporter or vice versa
**Check**: 
```sql
SELECT id, user_name, app_type FROM callback_requests WHERE id = [ID];
```
**Solution**: Verify `app_type` field is correct in database

### Issue 2: Call Log Not Created
**Problem**: Feedback submitted but no entry in call_logs
**Check**: Browser console for errors
**Solution**: 
- Verify API endpoint is accessible
- Check network tab for failed requests
- Verify user authentication

### Issue 3: Status Not Updated
**Problem**: Call log created but callback status unchanged
**Check**: 
```sql
SELECT * FROM callback_requests WHERE id = [ID];
```
**Solution**: 
- Check API response for errors
- Verify status mapping is correct
- Check database permissions

## Success Indicators

✅ **Driver Modal** opens for drivers
✅ **Transporter Modal** opens for transporters  
✅ **Call logs** created with `call_source = 'callback_requests'`
✅ **Callback status** updated to completed status
✅ **Remarks** saved in both tables
✅ **Request** moves from Requests to History tab
✅ **Multiple calls** can be made to same user (multiple call logs)

## Quick Verification Script

Run this in your database to verify everything is working:

```sql
-- Check last 5 callback-related call logs
SELECT 
    'CALL LOGS' as table_name,
    cl.id,
    cl.driver_name,
    cl.call_status,
    cl.feedback,
    cl.call_source,
    cl.created_at
FROM call_logs cl
WHERE cl.call_source = 'callback_requests'
ORDER BY cl.created_at DESC
LIMIT 5

UNION ALL

-- Check last 5 completed callback requests
SELECT 
    'CALLBACK REQUESTS' as table_name,
    cr.id,
    cr.user_name,
    cr.status,
    cr.notes,
    'N/A' as call_source,
    cr.updated_at
FROM callback_requests cr
WHERE cr.status IN ('Contacted', 'Interested', 'Not Interested')
ORDER BY cr.updated_at DESC
LIMIT 5;
```

---

**Quick Test Time**: ~5 minutes per test
**Total Tests**: 3
**Estimated Time**: 15 minutes
