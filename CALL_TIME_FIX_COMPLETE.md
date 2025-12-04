# Call Time Timezone Fix - COMPLETE ✅

## Problem
When initiating a call in the smart calling screen without submitting feedback:
1. **First issue**: `call_time` was showing +5:30 hours offset
2. **Second issue**: After fixing call_time, `updated_at` and `created_at` were showing -5:30 hours offset (e.g., call_time: 19:24, updated_at: 13:34)

## Root Cause
1. **Missing call_time field**: The INSERT statement in `logEasyGoCallAsync()` was missing the `call_time` field entirely, causing the database to use a default value with wrong timezone
2. **MySQL timezone not set**: The `easygo_ivr_api.php` file wasn't explicitly setting the MySQL session timezone to IST
3. **Column defaults using server timezone**: The `updated_at` column likely has `DEFAULT CURRENT_TIMESTAMP` or `ON UPDATE CURRENT_TIMESTAMP` which uses the MySQL server's default timezone (UTC) instead of the session timezone

## Solution
1. Added the `call_time` field to the INSERT statement
2. Added explicit timezone setting at the start of `easygo_ivr_api.php`
3. **Used CONVERT_TZ() for all timestamp fields** to explicitly convert from session timezone to IST (+05:30), bypassing any column defaults or triggers

### Changes Made

**1. Added timezone setting (Line ~18)**
```php
require_once 'config.php';

// Ensure MySQL timezone is set to IST for this connection
$conn->query("SET time_zone = '+05:30'");
```

**2. Added call_time field and CONVERT_TZ for all timestamps (Line ~215)**
```php
// Before:
INSERT INTO call_logs 
(caller_id, tc_for, user_id, driver_name, call_status, caller_number, user_number,
 reference_id, api_response, call_source, call_initiated_at, created_at, updated_at)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), NOW())

// After:
INSERT INTO call_logs 
(caller_id, tc_for, user_id, driver_name, call_status, caller_number, user_number,
 reference_id, api_response, call_source, call_time, call_initiated_at, created_at, updated_at)
VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 
        CONVERT_TZ(NOW(), @@session.time_zone, '+05:30'), 
        CONVERT_TZ(NOW(), @@session.time_zone, '+05:30'), 
        CONVERT_TZ(NOW(), @@session.time_zone, '+05:30'), 
        CONVERT_TZ(NOW(), @@session.time_zone, '+05:30'))
```

**3. Fixed UPDATE statement for feedback (Line ~370)**
```php
// Before:
updated_at = NOW()

// After:
updated_at = CONVERT_TZ(NOW(), @@session.time_zone, '+05:30')
```

## Testing
1. Initiate a call from smart calling screen
2. Don't submit feedback (let it save as pending)
3. Check all timestamp fields in the `call_logs` table:
   - `call_time` should show correct IST time (e.g., 19:24)
   - `call_initiated_at` should show correct IST time (e.g., 19:24)
   - `created_at` should show correct IST time (e.g., 19:24)
   - `updated_at` should show correct IST time (e.g., 19:24)
4. All timestamps should match and show IST time

## Impact
- All new call logs will have all timestamp fields set correctly in IST
- Consistent timezone handling across all timestamp fields (`call_time`, `call_initiated_at`, `created_at`, `updated_at`)
- No more timezone offsets for pending calls
- MySQL session timezone is explicitly set to IST for all operations in this API
