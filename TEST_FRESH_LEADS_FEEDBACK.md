# Quick Test Guide: Fresh Leads Feedback

## Quick Test (5 minutes)

### 1. Run Test Script
```bash
php api/test_fresh_leads_feedback.php
```

Expected output:
- ✅ Call_logs record found/created
- ✅ Call_history record found/created
- ✅ Updates successful
- ✅ No duplicate records

### 2. Test in App

**Step 1: Make a call**
1. Open Fresh Leads screen
2. Tap call button on any lead
3. Select "EasyGo IVR" or "Manual Call"
4. Wait for call to connect

**Step 2: Submit feedback**
1. After call, feedback modal appears
2. Select status: "Connected"
3. Select feedback: "Agree For Subscription"
4. Add remarks: "Test feedback submission"
5. Tap "Submit Feedback"

**Step 3: Verify**
1. Check that success message appears
2. Lead should disappear from Fresh Leads list
3. Remaining count should decrease

### 3. Check Database

```sql
-- Find the most recent call_history record
SELECT * FROM call_history 
ORDER BY id DESC LIMIT 1;

-- Should show:
-- call_status: 'connected'
-- call_feedback: 'Agree For Subscription'
-- remarks: 'Test feedback submission'
-- updated_at: recent timestamp
```

### 4. Check Error Logs

Look for these log entries:
```
✅ Inserted into call_history ID: [ID] for user_id: [USER_ID]
✅ Updated call_history ID: [ID] for user_id: [USER_ID], status: connected, feedback: Agree For Subscription
```

## Common Issues & Solutions

### Issue: "No call_history record found"
**Solution**: The call_history record should be created when the call is initiated. Check:
1. Is the call actually being initiated?
2. Check error logs for INSERT failures
3. Verify database permissions

### Issue: "Feedback not updating"
**Solution**: 
1. Check that reference_id is being passed correctly
2. Verify call_logs record exists
3. Check error logs for UPDATE failures

### Issue: "Multiple records created"
**Solution**: This should be fixed now. If still happening:
1. Check for duplicate call initiations
2. Verify the two-step UPDATE logic is working
3. Run the test script to check for duplicates

## Database Queries for Debugging

### Check recent calls for a user
```sql
SELECT 
    ch.id,
    ch.user_id,
    ch.user_name,
    ch.call_status,
    ch.call_feedback,
    ch.remarks,
    ch.created_at,
    ch.updated_at,
    a.name as telecaller_name
FROM call_history ch
LEFT JOIN admins a ON ch.assigned_to = a.id
WHERE ch.user_id = [USER_ID]
ORDER BY ch.id DESC
LIMIT 5;
```

### Check for duplicates
```sql
SELECT 
    user_id, 
    assigned_to, 
    COUNT(*) as count,
    GROUP_CONCAT(id) as record_ids
FROM call_history
GROUP BY user_id, assigned_to
HAVING count > 1
ORDER BY count DESC;
```

### Check call_logs vs call_history sync
```sql
SELECT 
    cl.id as call_log_id,
    cl.reference_id,
    cl.user_id,
    cl.call_status as cl_status,
    cl.feedback as cl_feedback,
    ch.id as history_id,
    ch.call_status as ch_status,
    ch.call_feedback as ch_feedback
FROM call_logs cl
LEFT JOIN call_history ch ON cl.user_id = ch.user_id AND cl.caller_id = ch.assigned_to
WHERE cl.created_at >= DATE_SUB(NOW(), INTERVAL 1 HOUR)
ORDER BY cl.id DESC
LIMIT 10;
```

## Success Criteria
- ✅ Feedback saves to call_history table
- ✅ Remarks are included
- ✅ No duplicate records
- ✅ Fresh leads list updates correctly
- ✅ Error logs show proper tracking
