# Callback Requests Refresh Error Fix

## Problem
Getting "Unable to refresh" error when trying to refresh the callback requests screen.

## Root Causes

### 1. MySQL ROW_NUMBER() Compatibility Issue
The `getCallbackHistory()` function was using `ROW_NUMBER() OVER (PARTITION BY ...)` which requires MySQL 8.0+. Many servers still run MySQL 5.7 which doesn't support window functions.

### 2. Training Table Query Error
The `enrichRequestData()` function was querying a `training` table that might not exist, causing the entire API call to fail.

### 3. Missing Error Handling
The enrichment function had no try-catch blocks, so any database error would break the entire API response.

## Solutions Implemented

### 1. Fixed MySQL Compatibility Issue

**File**: `api/callback_requests_api.php` - `getCallbackHistory()` function

**Before (MySQL 8.0+ only)**:
```php
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
```

**After (MySQL 5.7+ compatible)**:
```php
LEFT JOIN call_logs cl ON cl.user_id = cr.id 
    AND cl.call_source = 'callback_requests'
    AND cl.id = (
        SELECT id FROM call_logs 
        WHERE user_id = cr.id 
        AND call_source = 'callback_requests'
        ORDER BY call_time DESC 
        LIMIT 1
    )
```

This approach:
- ✅ Works with MySQL 5.7+
- ✅ Gets the latest call log per user
- ✅ No window functions required
- ✅ Same result, better compatibility

### 2. Added Error Handling for Training Query

**Before**:
```php
$trainingSql = "SELECT COUNT(*) as count FROM training WHERE unique_id = ? AND status = 'completed'";
$tStmt = $conn->prepare($trainingSql);
$tStmt->bind_param("s", $uniqueId);
$tStmt->execute();
// ... would fail if table doesn't exist
```

**After**:
```php
try {
    $trainingSql = "SELECT COUNT(*) as count FROM training WHERE unique_id = ? AND status = 'completed'";
    $tStmt = $conn->prepare($trainingSql);
    if ($tStmt) {
        $tStmt->bind_param("s", $uniqueId);
        $tStmt->execute();
        $trainingResult = $tStmt->get_result()->fetch_assoc();
        if ($trainingResult && $trainingResult['count'] > 0) {
            $trainingStatus = 'Completed';
        } else {
            $trainingStatus = 'Not Completed';
        }
    }
} catch (Exception $e) {
    // Training table might not exist, default to Not Completed
    $trainingStatus = 'Not Completed';
    error_log("Training query error: " . $e->getMessage());
}
```

### 3. Added Global Error Handling

Wrapped the entire enrichment logic in try-catch:

```php
if ($uniqueId) {
    try {
        // All enrichment queries here
        // ...
    } catch (Exception $e) {
        // Log error but don't fail the entire request
        error_log("Error enriching callback request data: " . $e->getMessage());
    }
}
```

This ensures:
- ✅ API doesn't crash if one query fails
- ✅ Errors are logged for debugging
- ✅ Partial data is still returned
- ✅ User sees some data instead of complete failure

## Error Handling Strategy

### Graceful Degradation
Instead of failing completely, the API now:
1. Logs errors to PHP error log
2. Returns default values for failed queries
3. Continues processing other data
4. Returns partial results

### Default Values
If enrichment fails, these defaults are used:
- `profile_completion`: '0%'
- `subscribe_date`: 'N/A'
- `applied_jobs_count`: 0
- `call_history_count`: 0
- `training_status`: 'Not Completed'
- `assigned_telecaller`: 'N/A'

## Testing

### Test Case 1: Refresh Requests Tab
1. Open Callback Requests screen
2. Go to Requests tab
3. Pull down to refresh
4. **Expected**: ✅ Refreshes successfully
5. **Before**: ❌ "Unable to refresh" error

### Test Case 2: Refresh History Tab
1. Go to History tab
2. Pull down to refresh
3. **Expected**: ✅ Refreshes successfully with feedback
4. **Before**: ❌ "Unable to refresh" error

### Test Case 3: Check Error Logs
```bash
# Check PHP error log for any issues
tail -f /path/to/php/error.log | grep "callback"
```

Should see:
- ✅ No critical errors
- ℹ️ Info logs if training table doesn't exist
- ℹ️ Info logs if enrichment has issues

### Test Case 4: Verify Data Still Shows
1. Even if some queries fail
2. **Expected**: ✅ Basic data still displays
3. **Expected**: ✅ Counts might be 0 but no crash

## MySQL Version Compatibility

### Before Fix:
- ❌ Requires MySQL 8.0+
- ❌ Fails on MySQL 5.7
- ❌ Fails on MariaDB < 10.2

### After Fix:
- ✅ Works with MySQL 5.7+
- ✅ Works with MySQL 8.0+
- ✅ Works with MariaDB 10.0+
- ✅ Works with most hosting providers

## Debugging

### If Still Getting Errors:

1. **Check PHP Error Log**:
```bash
tail -f /var/log/php/error.log
```

2. **Test API Directly**:
```bash
curl "https://your-domain.com/api/callback_requests_api.php?action=index&auth_admin_id=1"
```

3. **Use Test Script**:
```bash
curl "https://your-domain.com/api/test_callback_refresh.php"
```

4. **Check MySQL Version**:
```sql
SELECT VERSION();
```

5. **Check Table Existence**:
```sql
SHOW TABLES LIKE 'training';
SHOW TABLES LIKE 'call_logs';
SHOW TABLES LIKE 'applyjobs';
```

## Files Modified

1. **api/callback_requests_api.php**
   - Fixed `getCallbackHistory()` - Removed ROW_NUMBER()
   - Added try-catch to training query
   - Added global try-catch to enrichRequestData()
   - Added error logging

2. **api/test_callback_refresh.php** (NEW)
   - Test script to debug API issues
   - Checks database connectivity
   - Checks table existence
   - Tests API endpoint

## Benefits

1. **Better Compatibility** - Works with older MySQL versions
2. **Graceful Degradation** - Partial data instead of complete failure
3. **Better Debugging** - Error logs help identify issues
4. **More Reliable** - Doesn't crash on missing tables
5. **Production Ready** - Handles edge cases properly

## Deployment

1. ✅ No database changes required
2. ✅ No Flutter changes required
3. ✅ Only PHP API file modified
4. ✅ Backward compatible
5. ⚠️ Clear PHP opcache if using: `opcache_reset()`
6. ⚠️ Check PHP error logs after deployment

---

**Status**: ✅ Fixed
**Date**: December 6, 2025
**Priority**: Critical
**Impact**: High - Blocks all refresh operations
**MySQL Compatibility**: 5.7+ (previously 8.0+ only)
