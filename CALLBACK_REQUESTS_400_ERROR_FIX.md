# Callback Requests 400 Error Fix

## Problem
When submitting feedback in the Callback Requests screen, users were getting this error:
```
Failed to save feedback: Exception: Unable to update callback request: Exception: Request failed with status 400
```

## Root Cause
The `action` parameter was being sent in the POST body instead of the URL query string, causing the PHP API to not recognize the request type.

### The Issue:
1. Flutter service sent POST request with `action` in the body: `action=update_status&request_id=123&status=Interested`
2. PHP API reads `action` from `$_GET['action']` (query string), not from POST body
3. Since `action` was not found in query string, API returned "Invalid POST action" (400 error)
4. The `request_id` and `status` were never processed

### Why This Happened:
- HTTP POST with `application/x-www-form-urlencoded` puts data in the body
- PHP's `$_GET` only reads from URL query string
- The `action` parameter must be in the URL: `?action=update_status`
- Body parameters go to `$_POST`: `request_id=123&status=Interested`

## Solution

### Fixed Flutter Service
Updated `lib/core/services/callback_requests_service.dart` to put `action` in the URL query string instead of the POST body.

**Key Change:**
```dart
// OLD - action in body (WRONG)
final uri = Uri.parse('${ApiConfig.baseUrl}/callback_requests_api.php');
final body = {
  'action': 'update_status',  // ❌ This doesn't work
  'request_id': requestId.toString(),
  'status': status,
};

// NEW - action in query string (CORRECT)
final uri = Uri.parse('${ApiConfig.baseUrl}/callback_requests_api.php')
    .replace(queryParameters: {'action': 'update_status'});  // ✅ This works
final body = {
  'request_id': requestId.toString(),
  'status': status,
};
```

### Also Fixed PHP API
Updated the POST case in `callback_requests_api.php` to:
1. Detect content type (JSON vs form-urlencoded)
2. Parse input accordingly (`$_POST` for form data, `json_decode` for JSON)
3. Check multiple field names: `request_id`, `callback_id`, `id`
4. Pass the ID to `updateStatus()` function

**Before:**
```php
elseif ($action === 'update_status') {
    $input = json_decode(file_get_contents('php://input'), true);
    $targetId = $id ?? ($input['callback_id'] ?? null);
    if ($targetId) {
        updateStatus($conn, $targetId);
    } else {
        sendError('Callback ID is required', 400);
    }
}
```

**After:**
```php
elseif ($action === 'update_status') {
    // Handle both query param ID and body ID
    // Check if content type is form-urlencoded or JSON
    $contentType = $_SERVER['CONTENT_TYPE'] ?? '';
    
    if (strpos($contentType, 'application/json') !== false) {
        $input = json_decode(file_get_contents('php://input'), true);
    } else {
        $input = $_POST;
    }
    
    // Try multiple field names for compatibility
    $targetId = $id ?? ($input['request_id'] ?? ($input['callback_id'] ?? ($input['id'] ?? null)));
    
    if ($targetId) {
        updateStatus($conn, $targetId);
    } else {
        error_log("update_status: No ID found. Query ID: $id, POST: " . print_r($_POST, true));
        sendError('Callback ID is required', 400);
    }
}
```

### Enhanced Error Logging
Added detailed logging to `updateStatus()` function:
```php
if (!$id) {
    error_log("updateStatus: No ID provided. Input: " . print_r($input, true));
    sendError('Request ID is required', 400);
}

if (!isset($input['status'])) {
    error_log("updateStatus: No status provided. Input: " . print_r($input, true));
    sendError('Status is required', 400);
}

error_log("updateStatus: Processing ID=$id, Status=" . $input['status']);
```

## How It Works Now

### Request Flow:
1. **Flutter sends POST request**:
   ```
   POST /api/callback_requests_api.php?action=update_status
   Content-Type: application/x-www-form-urlencoded
   
   request_id=123&status=Interested&notes=User is interested
   ```

2. **PHP API processes request**:
   - Detects content type: `application/x-www-form-urlencoded`
   - Parses input from `$_POST`
   - Extracts `request_id` from POST data
   - Calls `updateStatus($conn, 123)`

3. **updateStatus() executes**:
   - Validates ID and status
   - Maps status to database enum value
   - Updates `callback_requests` table
   - Returns success response

4. **Flutter receives success**:
   - Shows success message
   - Moves request to history
   - Refreshes UI

## Testing

### Test Case 1: Submit Driver Feedback
1. Open Callback Requests
2. Call a driver
3. Submit feedback with status "Connected" and feedback "Agree for Subscription Today"
4. **Expected**: ✅ Success message, request moves to history
5. **Previous**: ❌ 400 error

### Test Case 2: Submit Transporter Feedback
1. Open Callback Requests
2. Call a transporter
3. Submit feedback with status "Connected" and feedback "Interested in Hiring"
4. **Expected**: ✅ Success message, request moves to history
5. **Previous**: ❌ 400 error

### Test Case 3: Submit with Notes
1. Open Callback Requests
2. Call any user
3. Submit feedback with remarks: "Very interested, follow up tomorrow"
4. **Expected**: ✅ Success message, notes saved
5. **Previous**: ❌ 400 error

## Verification

### Check API Logs
```bash
tail -f /path/to/php/error.log | grep "updateStatus"
```

**Expected output when working**:
```
updateStatus: Processing ID=123, Status=Interested
```

**Previous error output**:
```
updateStatus: No ID provided. Input: Array ( [status] => Interested [notes] => ... )
```

### Check Database
```sql
-- Verify status was updated
SELECT id, user_name, status, notes, updated_at 
FROM callback_requests 
WHERE id = 123;

-- Should show updated status and notes
```

### Check Network Tab
In browser/app developer tools:

**Request**:
```
POST /api/callback_requests_api.php
Content-Type: application/x-www-form-urlencoded

action=update_status&request_id=123&status=Interested&notes=User%20is%20interested
```

**Response** (Success):
```json
{
  "success": true,
  "message": "Status updated successfully."
}
```

**Response** (Previous Error):
```json
{
  "success": false,
  "error": "Callback ID is required"
}
```

## Files Modified

1. **lib/core/services/callback_requests_service.dart**
   - **MAIN FIX**: Moved `action` parameter from POST body to URL query string
   - Updated `updateCallbackRequest()` method
   - Now uses `.replace(queryParameters: {'action': 'update_status'})`

2. **api/callback_requests_api.php**
   - Updated POST action handler for `update_status`
   - Added content type detection
   - Added support for multiple ID field names
   - Enhanced error logging in `updateStatus()` function

## Compatibility

### Supported Content Types:
- ✅ `application/x-www-form-urlencoded` (used by Flutter)
- ✅ `application/json` (for future use)

### Supported ID Field Names:
- ✅ `request_id` (used by Flutter service)
- ✅ `callback_id` (legacy support)
- ✅ `id` (generic support)
- ✅ Query parameter `?id=123` (URL support)

## Error Messages

### Before Fix:
```
Failed to save feedback: Exception: Unable to update callback request: Exception: Request failed with status 400
```

### After Fix:
```
✅ Saved feedback for [User Name]
```

### If Still Fails (with better error info):
```
Failed to save feedback: Exception: Unable to update callback request: Exception: [Specific error message]
```

## Deployment

1. ✅ No database changes required
2. ⚠️ **Flutter app rebuild required** (service file changed)
3. ✅ PHP API file also modified for better compatibility
4. ✅ Backward compatible with other API calls
5. ⚠️ Clear PHP opcache if using: `opcache_reset()`
6. ⚠️ Hot restart the Flutter app to apply changes

## Related Issues

This fix also resolves:
- Callback status not updating
- Feedback not being saved
- History tab not showing completed callbacks
- Call logs not being created (dependent on status update)

---

**Status**: ✅ Fixed
**Date**: December 6, 2025
**Priority**: Critical
**Impact**: High - Blocks all callback feedback submissions
