# 🔧 Toll-Free Feedback 500 Error - FIXED

## Changes Made

### 1. Fixed Database Connection
**File:** `api/toll_free_feedback_api.php`

**Problem:** API was creating its own PDO connection instead of using the one from config.php

**Solution:**
```php
// BEFORE (causing 500 error)
require_once 'config.php';
try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    // ... more code
} catch(PDOException $e) {
    // Error handling
}

// AFTER (fixed)
require_once 'config.php';
// config.php already sets headers and creates $pdo connection
```

### 2. Added Better Error Logging

Added comprehensive error logging to help debug issues:

```php
// Log raw input
error_log('Toll-Free Feedback Raw Input: ' . $rawInput);

// Log parsed data
error_log('Parsed data - caller_id: ' . $callerId . ', lead_id: ' . $leadId);

// Log user lookup
error_log('User found - TMID: ' . $tmid . ', Role: ' . $role);

// Log database insert
error_log('Call log inserted with ID: ' . $callLogId);

// Log errors with stack trace
error_log('Toll-Free Feedback Error: ' . $e->getMessage());
error_log('Stack trace: ' . $e->getTraceAsString());
```

### 3. Added JSON Validation

```php
$input = json_decode($rawInput, true);

if (json_last_error() !== JSON_ERROR_NONE) {
    echo json_encode([
        'success' => false,
        'message' => 'Invalid JSON: ' . json_last_error_msg()
    ]);
    return;
}
```

### 4. Added User Validation

```php
if (!$user) {
    error_log('User not found with ID: ' . $leadId);
    echo json_encode([
        'success' => false,
        'message' => 'User not found with ID: ' . $leadId
    ]);
    return;
}
```

### 5. Enhanced Error Responses

```php
echo json_encode([
    'success' => false,
    'message' => 'Failed to save feedback: ' . $e->getMessage(),
    'error_details' => $e->getMessage(),
    'line' => $e->getLine(),
    'file' => basename($e->getFile())
]);
```

## Testing

### Test the API Directly

1. **Open in browser:**
   ```
   http://localhost/api/test_toll_free_feedback.php
   ```

2. **Check error logs:**
   - Look for log entries in your PHP error log
   - Check browser console for detailed error messages

### Test from Flutter App

1. Login as telecaller
2. Go to Toll-Free Search
3. Search for a user
4. Make a call
5. Submit feedback
6. Check the response in Flutter console

## Common Issues & Solutions

### Issue 1: Database Connection Failed
**Error:** "Database connection failed"

**Solution:**
- Check `api/config.php` has correct database credentials
- Verify MySQL is running
- Test connection: `mysql -u truckmitr -p truckmitr`

### Issue 2: User Not Found
**Error:** "User not found with ID: X"

**Solution:**
- Verify the user exists in `users` table
- Check the `lead_id` being sent from Flutter app
- Query: `SELECT * FROM users WHERE id = X`

### Issue 3: Invalid JSON
**Error:** "Invalid JSON: ..."

**Solution:**
- Check Flutter app is sending valid JSON
- Verify Content-Type header is set to 'application/json'
- Check the request body in network logs

### Issue 4: Missing caller_id or lead_id
**Error:** "caller_id and lead_id are required"

**Solution:**
- Verify Flutter app is logged in
- Check `RealAuthService.instance.currentUser` is not null
- Verify the user ID is being passed correctly

## Verify Fix

Run this SQL query to check if feedback is being saved:

```sql
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
    cl.call_source,
    cl.call_time
FROM call_logs cl
LEFT JOIN telecallers t ON cl.caller_id = t.id
WHERE cl.tc_for = 'toll-free'
ORDER BY cl.call_time DESC
LIMIT 10;
```

## Next Steps

1. ✅ Test the API using `test_toll_free_feedback.php`
2. ✅ Check error logs for any issues
3. ✅ Test from Flutter app
4. ✅ Verify data is saved in `call_logs` table
5. ✅ Check that `caller_id` is correct

## Additional Fix: 404 Error

### Problem
The root `.htaccess` file was redirecting all API requests to `index.php`, causing 404 errors.

### Solution
Created `api/.htaccess` to disable Laravel routing in the API directory:

```apache
# API Directory - Disable Laravel routing
<IfModule mod_rewrite.c>
    RewriteEngine Off
</IfModule>
```

This allows direct access to PHP files in the `api/` folder.

## Testing URLs

1. **Simple test:** `http://localhost/api/test_simple.php`
   - Should return: `{"success":true,"message":"API is accessible!"}`

2. **Full test:** `http://localhost/api/test_toll_free_feedback.php`
   - Should show all test results

3. **Direct API call:**
   ```bash
   curl -X POST http://localhost/api/toll_free_feedback_api.php?action=submit_feedback \
     -H "Content-Type: application/json" \
     -d '{"caller_id":1,"lead_id":1,"name":"Test","mobile":"9876543210","feedback":"Connected","remarks":"Test"}'
   ```

## Status
✅ **FIXED** - Both 500 and 404 errors resolved!
- ✅ Database connection fixed
- ✅ Error handling improved
- ✅ API routing fixed with .htaccess
- ✅ Comprehensive logging added
