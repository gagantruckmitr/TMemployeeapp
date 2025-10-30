# Fix: Smart Calling Error - "Column not found"

## Problem
The app is showing this error:
```
Failed to refresh: Exception: Failed to fetch drivers: Exception: Failed to fetch drivers by status: 
SQLSTATE[42S22]: Column not found: 1054 Unknown column 'cl.remarks' in 'field list'
```

This happens when telecallers try to view drivers by status (Connected Calls, Callbacks, etc.).

## Root Cause
The error can be caused by:
1. Missing `remarks` column in `call_logs` table ✅ (Already fixed - column exists)
2. Missing enum values in `call_status` column (likely the actual issue)

Your database shows the `remarks` column exists, so the issue is probably with the `call_status` enum values.

## Solution

### Step 1: Diagnose the Exact Issue (Recommended First)
1. Upload `api/diagnose_smart_calling_error.php` to your Plesk server
2. Visit: `https://yourdomain.com/api/diagnose_smart_calling_error.php`
3. This will show you exactly what's wrong

### Step 2: Fix call_status Enum Values (Most Likely Fix)

**Option A: Run PHP Fix Script (Easiest)**
1. Upload `api/fix_call_status_enum.php` to your Plesk server
2. Visit: `https://yourdomain.com/api/fix_call_status_enum.php`
3. The script will add missing enum values like `not_reachable`, `invalid`, `pending`
4. Refresh your app - error should be gone!

**Option B: Run SQL Script via phpMyAdmin**
1. Log into Plesk → Databases → phpMyAdmin
2. Select your database (truckmitr)
3. Go to SQL tab
4. Copy and paste this SQL:

```sql
ALTER TABLE call_logs 
MODIFY COLUMN call_status ENUM(
    'pending',
    'connected',
    'not_connected',
    'busy',
    'no_answer',
    'callback',
    'callback_later',
    'not_reachable',
    'not_interested',
    'invalid',
    'completed',
    'failed',
    'cancelled'
) DEFAULT 'pending';
```

5. Click "Go" to execute
6. Refresh your app - error should be gone!

## Verification
After applying the fix:
1. Open the Smart Calling page in your app
2. Try clicking on different status tabs (Connected Calls, Callbacks, etc.)
3. The error should be gone and drivers should load properly

## Why This Happened
Your production database's `call_status` enum was created with limited values:
- `connected`, `not_connected`, `busy`, `no_answer`, `callback`, `callback_later`, `not_interested`

But the API code tries to use additional values:
- `not_reachable` (for unreachable numbers)
- `invalid` (for invalid numbers)
- `pending` (for fresh leads)

When the API tries to filter by these missing enum values, MySQL throws an error that gets misreported as a "column not found" error.

## Files Created
- `api/diagnose_smart_calling_error.php` - Diagnostic tool to identify the exact issue
- `api/fix_call_status_enum.php` - Automated fix for enum values
- `fix_call_status_enum.sql` - SQL script for manual fix
- `api/fix_call_logs_complete.php` - Comprehensive table structure fix
- `api/fix_call_logs_remarks.php` - Simple column fix (not needed in your case)
