# Job Applicants Call Logs Fix

## Problem
When telecallers make calls from the Job Applicants screen (both IVR and manual calls), the calls were being saved in BOTH:
1. ✅ `call_logs_match_making` table (correct - shown in Call History Hub)
2. ❌ `call_logs` table (incorrect - shown in regular Call History screen with "PENDING" status)

This caused duplicate entries where:
- Call History Hub screen showed the call with proper feedback
- Regular Call History screen showed the same call with "PENDING" status

## Root Cause
When initiating calls from Job Applicants screen:
1. The call initiation APIs (`easygo_ivr_api.php` and `manual_call_api.php`) were inserting into `call_logs` table
2. The feedback submission API (`phase2_call_feedback_direct.php`) was inserting into `call_logs_match_making` table
3. This resulted in the same call appearing in both tables

## Solution
Modified the call initiation APIs to **skip** inserting into `call_logs` table when `call_source = 'job_applicants'`:

### 1. EasyGo IVR API (`api/easygo_ivr_api.php`)
Added check in `logEasyGoCallAsync()` function:
```php
// SKIP logging to call_logs if call is from job_applicants screen
if ($callSource === 'job_applicants') {
    error_log("⏭️ Skipping call_logs insert for job_applicants call");
    return;
}
```

### 2. Manual Call API (`api/manual_call_api.php`)
Added conditional logic in `initiateManualCall()` function:
```php
// SKIP logging to call_logs if call is from job_applicants screen
if ($callSource === 'job_applicants') {
    error_log("⏭️ Skipping call_logs insert for job_applicants call");
    $callLogId = 0; // Dummy ID for response
} else {
    // Normal insert into call_logs
}
```

## Result
Now calls from Job Applicants screen will:
- ✅ Save ONLY to `call_logs_match_making` table
- ✅ Appear ONLY in Call History Hub screen (with tabs)
- ✅ NOT appear in regular Call History screen
- ✅ Show proper feedback status in Call History Hub

## Files Modified
1. `api/easygo_ivr_api.php` - Added skip logic for job_applicants calls
2. `api/manual_call_api.php` - Added skip logic for job_applicants calls

## No Changes Needed
- `api/phase2_call_feedback_direct.php` - Already saving to correct table
- Frontend code - No changes required
- Call history screens - No changes required

## Testing
1. Make an IVR call from Job Applicants screen
2. Submit feedback
3. Check Call History Hub → Should show the call with feedback ✅
4. Check regular Call History screen → Should NOT show the call ✅

5. Make a manual call from Job Applicants screen
6. Submit feedback
7. Check Call History Hub → Should show the call with feedback ✅
8. Check regular Call History screen → Should NOT show the call ✅
