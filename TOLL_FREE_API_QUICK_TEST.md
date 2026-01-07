# 🚀 Toll-Free API Quick Test Guide

## Quick Tests (In Order)

### 1. Test API Accessibility
```
http://localhost/api/test_simple.php
```
**Expected:** `{"success":true,"message":"API is accessible!"}`

### 2. Test Full API
```
http://localhost/api/test_toll_free_feedback.php
```
**Expected:** See all 6 tests pass with database connection confirmed

### 3. Test from Command Line
```bash
# Submit feedback
curl -X POST http://localhost/api/toll_free_feedback_api.php?action=submit_feedback \
  -H "Content-Type: application/json" \
  -d '{
    "caller_id": 1,
    "lead_id": 1,
    "name": "Test Driver",
    "mobile": "9876543210",
    "feedback": "Connected - Interested",
    "remarks": "Test from curl"
  }'

# Get history
curl http://localhost/api/toll_free_feedback_api.php?action=get_history&caller_id=1&limit=5
```

## What Was Fixed

### ✅ Issue 1: 500 Internal Server Error
**Cause:** Duplicate PDO connection attempt
**Fix:** Use existing `$pdo` from `config.php`

### ✅ Issue 2: 404 Not Found
**Cause:** Root `.htaccess` redirecting API calls to `index.php`
**Fix:** Created `api/.htaccess` to disable routing in API folder

### ✅ Issue 3: Poor Error Messages
**Cause:** No detailed logging
**Fix:** Added comprehensive error logging at every step

## Files Modified

1. ✅ `api/toll_free_feedback_api.php` - Fixed connection & added logging
2. ✅ `api/.htaccess` - Created to disable Laravel routing
3. ✅ `api/test_toll_free_feedback.php` - Enhanced test suite
4. ✅ `api/test_simple.php` - Simple accessibility test

## Verify in Database

```sql
-- Check recent toll-free calls
SELECT 
    cl.id,
    cl.caller_id,
    t.name as telecaller_name,
    cl.driver_name,
    cl.user_number,
    cl.feedback,
    cl.remarks,
    cl.call_status,
    cl.tc_for,
    cl.call_time
FROM call_logs cl
LEFT JOIN telecallers t ON cl.caller_id = t.id
WHERE cl.tc_for = 'toll-free'
ORDER BY cl.call_time DESC
LIMIT 10;
```

## Test from Flutter App

1. **Login** as telecaller
2. **Navigate** to Toll-Free Search
3. **Search** for a user (TMID or mobile)
4. **Click** the blue call button
5. **Wait** for feedback modal to open
6. **Select** feedback and submit
7. **Check** - Should see success message!

## Troubleshooting

### Still getting 404?
- Clear browser cache
- Restart web server: `sudo service apache2 restart` (or nginx)
- Check file permissions: `chmod 644 api/*.php`

### Still getting 500?
- Check PHP error log: `tail -f /var/log/apache2/error.log`
- Check API logs in the test output
- Verify database credentials in `api/config.php`

### No data in database?
- Check `caller_id` is valid (exists in `telecallers` table)
- Check `lead_id` is valid (exists in `users` table)
- Run the SQL query above to see existing records

## Success Indicators

✅ Test simple returns JSON
✅ Test full shows "Database Connected"
✅ cURL returns `{"success":true}`
✅ Flutter app shows "Feedback saved"
✅ Database has new record with correct `caller_id`

## Status: READY TO USE! 🎉
