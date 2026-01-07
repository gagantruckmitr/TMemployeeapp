# 🔧 Toll-Free 500 Error - Debugging Guide

## Quick Fix Applied

### Changes Made to `api/toll_free_feedback_api.php`

1. ✅ **Added comprehensive error logging**
2. ✅ **Added try-catch wrapper for fatal errors**
3. ✅ **Added request logging**
4. ✅ **Better error responses with details**

## Debug Steps

### Step 1: Run Debug Script
```
http://localhost/api/debug_toll_free.php
```

This will:
- ✅ Check config.php loads
- ✅ Check PDO connection works
- ✅ Check users table exists
- ✅ Check call_logs table exists
- ✅ Test INSERT directly
- ✅ Test API endpoint

### Step 2: Check Error Logs

**XAMPP:**
```bash
tail -f /Applications/XAMPP/xamppfiles/logs/error_log
```

**Linux/Apache:**
```bash
tail -f /var/log/apache2/error.log
```

**Look for:**
- `=== Toll-Free Feedback API Request ===`
- `FATAL ERROR in toll_free_feedback_api.php`
- `Toll-Free Feedback Error:`

### Step 3: Test from Flutter App

1. Open Flutter app
2. Go to Toll-Free Search
3. Search for a user
4. Make a call
5. Submit feedback
6. Check the console output for:
   - `📞 Submitting toll-free feedback...`
   - `📤 Request body:`
   - `📡 Response status:`
   - `📥 Response body:`

## Common 500 Errors & Solutions

### Error 1: "User not found with ID: X"
**Cause:** The lead_id doesn't exist in users table

**Solution:**
```sql
-- Check if user exists
SELECT id, unique_id, name FROM users WHERE id = X;

-- If not, use a valid user ID from:
SELECT id, unique_id, name FROM users ORDER BY id DESC LIMIT 10;
```

### Error 2: "Database connection failed"
**Cause:** PDO connection issue

**Solution:**
- Check `api/config.php` credentials
- Verify MySQL is running
- Test: `mysql -u truckmitr -p truckmitr`

### Error 3: "Column 'X' doesn't exist"
**Cause:** call_logs table schema mismatch

**Solution:**
```sql
-- Check table structure
DESCRIBE call_logs;

-- Required columns:
-- caller_id, user_id, user_number, driver_name, feedback, remarks,
-- call_status, call_time, tc_for, unique_id_driver, call_source
```

### Error 4: "Invalid JSON"
**Cause:** Flutter app sending malformed JSON

**Solution:**
- Check Flutter console for request body
- Verify Content-Type header is 'application/json'
- Check for special characters in feedback/remarks

### Error 5: "Method not allowed"
**Cause:** Wrong HTTP method or missing action parameter

**Solution:**
- Ensure POST request for submit_feedback
- Ensure GET request for get_history
- Check URL has `?action=submit_feedback`

## Test Files Created

1. **`api/debug_toll_free.php`** - Comprehensive debug script
2. **`api/test_toll_free_direct.php`** - Direct API test with real data
3. **`api/test_toll_free_feedback.php`** - Full test suite

## Verify Fix

### Test 1: Direct Database Insert
```sql
INSERT INTO call_logs (
    caller_id, user_id, user_number, driver_name,
    feedback, remarks, call_status, call_time,
    tc_for, unique_id_driver, call_source
) VALUES (
    3, 100, '9876543210', 'Test User',
    'Connected', 'Test', 'connected', NOW(),
    'toll-free', 'TM000001', 'toll-free'
);
```

### Test 2: API Call
```bash
curl -X POST http://localhost/api/toll_free_feedback_api.php?action=submit_feedback \
  -H "Content-Type: application/json" \
  -d '{
    "caller_id": 3,
    "lead_id": 100,
    "name": "Test User",
    "mobile": "9876543210",
    "feedback": "Connected",
    "remarks": "Test"
  }'
```

### Test 3: Flutter App
1. Login as telecaller
2. Search for user
3. Make call
4. Submit feedback
5. Should see: "✅ Feedback saved for [Name]"

## Error Response Format

The API now returns detailed errors:

```json
{
  "success": false,
  "message": "Failed to save feedback: [error message]",
  "error_details": "[detailed error]",
  "line": 123,
  "file": "toll_free_feedback_api.php"
}
```

## Next Steps

1. ✅ Run `debug_toll_free.php` to identify the exact error
2. ✅ Check error logs for detailed stack trace
3. ✅ Fix the specific issue identified
4. ✅ Test from Flutter app
5. ✅ Verify data in database

## Status

🔧 **DEBUGGING TOOLS READY**

Run the debug script to identify the exact cause of the 500 error!
