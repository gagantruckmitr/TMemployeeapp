# Quick Test Guide - Transporter Feedback Fix

## What Was Fixed

Transporter feedback from dynamic job cards was not saving to the database. The issue was in `lib/features/jobs/widgets/modern_job_card.dart` where:

1. **Notes were not being passed** to the API
2. **Recording files were not being uploaded** before saving
3. **Caller ID was missing** from the request

## Testing Steps

### 1. Check Database Table

Open in browser:
```
https://truckmitr.com/truckmitr-app/api/check_job_brief_table.php
```

This will show:
- ✓ If `job_brief_table` exists
- ✓ Table structure and columns
- ✓ Current record count
- ✓ Sample data

### 2. Test Direct Database Insert

Open in browser:
```
https://truckmitr.com/truckmitr-app/api/test_transporter_feedback_direct.php
```

This will:
- ✓ Insert a test record with feedback and notes
- ✓ Verify all fields are saved correctly
- ✓ Update the record
- ✓ Clean up test data

### 3. Test in the App

1. Open the Flutter app
2. Navigate to **Job Postings**
3. Find a job assigned to you
4. Click the **call button** (green phone icon)
5. Select call type (Manual or EasyGo IVR)
6. After the call ends, the feedback modal appears
7. Select a status like **"Connected: Call Back Later"**
8. Add notes: **"Will call back tomorrow at 10 AM"**
9. (Optional) Upload a call recording
10. Click **Submit Feedback**
11. You should see: **"Feedback saved successfully"** (green message)

### 4. Verify in Database

Run this SQL query:

```sql
SELECT 
    id,
    unique_id,
    job_id,
    caller_id,
    name,
    call_status_feedback,
    call_recording,
    created_at
FROM job_brief_table
ORDER BY created_at DESC
LIMIT 10;
```

You should see your feedback with:
- ✓ Transporter TMID in `unique_id`
- ✓ Job ID in `job_id`
- ✓ Your user ID in `caller_id`
- ✓ Transporter name in `name`
- ✓ Full feedback with notes in `call_status_feedback`
- ✓ Recording URL in `call_recording` (if uploaded)

## Expected Results

### Before Fix ❌
- Feedback modal appeared but data was not saved
- Database had no new records
- Notes were lost
- Recordings were not uploaded

### After Fix ✅
- Feedback is saved to `job_brief_table`
- Notes are included in `call_status_feedback` field
- Recordings are uploaded and URL is saved
- Caller ID is tracked
- Success message appears in app

## Troubleshooting

### If table doesn't exist:
The `check_job_brief_table.php` script will show the CREATE TABLE SQL. Run it in your database.

### If test fails:
1. Check database connection in `api/config.php`
2. Verify table permissions
3. Check PHP error logs

### If app doesn't save:
1. Check network connectivity
2. Verify API URL in `lib/core/services/phase2_api_service.dart`
3. Check Flutter console for errors
4. Verify user is logged in

## Files Changed

- ✅ `lib/features/jobs/widgets/modern_job_card.dart` - Fixed feedback submission

## Files Created

- ✅ `api/check_job_brief_table.php` - Table verification script
- ✅ `api/test_transporter_feedback_direct.php` - Direct database test
- ✅ `TRANSPORTER_FEEDBACK_FIX.md` - Complete documentation
- ✅ `TRANSPORTER_FEEDBACK_QUICK_TEST.md` - This file

## Quick Verification Command

```sql
-- Check if feedback is being saved
SELECT COUNT(*) as total_feedback 
FROM job_brief_table 
WHERE call_status_feedback IS NOT NULL 
AND created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR);
```

If this returns > 0, feedback is being saved! 🎉
