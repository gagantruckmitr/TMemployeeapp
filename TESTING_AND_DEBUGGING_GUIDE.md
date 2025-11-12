# Testing and Debugging Guide - Call Feedback System

## Current Issue: Blank Fields in Database

The `driver_name` and `transporter_name` fields are showing as NULL in the `call_logs_match_making` table.

## Debugging Steps

### Step 1: Test the Blank Fields Checker
Run this URL to see what's happening with the blank fields:
```
https://truckmitr.com/truckmitr-app/api/test_blank_fields.php
```

This will show:
- Records with blank driver names and whether they can be looked up
- Records with blank transporter names and whether they can be looked up
- Records with blank job IDs and whether they can be found
- Sample TMIDs to verify they exist in the users table

### Step 2: Check the Debug Logs
After submitting feedback from the app, check these log files on the server:

**Feedback Submission Log:**
```bash
cat /path/to/api/feedback_debug.log
```

This shows:
- What data the API received from the Flutter app
- The final values before inserting into database

**Recording Upload Log:**
```bash
cat /path/to/api/upload_debug.log
```

### Step 3: Test in the Flutter App
1. Clean and rebuild the app:
   ```bash
   cd Phase_2-
   flutter clean
   flutter pub get
   flutter run
   ```

2. Submit feedback for a driver

3. Check the console output for debug messages:
   ```
   === FEEDBACK SUBMISSION DEBUG ===
   Caller ID: ...
   Driver TMID: ...
   Driver Name: ...
   Transporter TMID: ...
   Transporter Name: ...
   Job ID: ...
   ================================
   ```

4. Also check the API request:
   ```
   SENDING TO API: {callerId: ..., uniqueIdDriver: ..., ...}
   ```

### Step 4: Fix Existing Blank Records

**Option A: Use Admin Tool (Easiest)**
```
https://truckmitr.com/truckmitr-app/api/admin_cleanup_call_logs.html
```
Click "Run One-Time Fix" or "Run Full Cleanup"

**Option B: Direct API Call**
```
https://truckmitr.com/truckmitr-app/api/fix_blank_call_logs.php
```

**Option C: Automated Cron Job**
Set up to run every hour:
```bash
0 * * * * curl "https://truckmitr.com/truckmitr-app/api/cleanup_call_logs_cron.php?key=truckmitr_cleanup_2024"
```

## Common Issues and Solutions

### Issue 1: Transporter Name is Empty in Flutter App
**Symptom:** `driver.transporterName` is empty string
**Cause:** API not returning transporter name
**Solution:** 
- Verify `phase2_job_applicants_api.php` includes transporter info in the query
- Check if the JOIN with users table for transporter is working

### Issue 2: Names Not Being Looked Up
**Symptom:** API receives empty names and doesn't look them up
**Cause:** TMID doesn't exist in users table or role mismatch
**Solution:**
- Run test_blank_fields.php to verify TMIDs exist
- Check if role field matches ('driver' or 'transporter')
- The API now tries without role filter as fallback

### Issue 3: Job ID Not Being Saved
**Symptom:** job_id field is NULL
**Cause:** Job ID not being passed from Flutter app
**Solution:**
- Verify `widget.jobId` is not null in the screen
- Check if job_id is being passed to CallFeedbackModal
- Ensure job_id is included in the API request

## Verification Queries

### Check if TMIDs exist in users table:
```sql
SELECT unique_id, name, role 
FROM users 
WHERE unique_id IN (
    SELECT DISTINCT unique_id_driver 
    FROM call_logs_match_making 
    WHERE driver_name IS NULL OR driver_name = ''
    LIMIT 10
);
```

### Check recent call logs:
```sql
SELECT id, caller_id, unique_id_driver, driver_name, 
       unique_id_transporter, transporter_name, 
       job_id, feedback, created_at
FROM call_logs_match_making
ORDER BY created_at DESC
LIMIT 20;
```

### Count blank fields:
```sql
SELECT 
    COUNT(*) as total_records,
    SUM(CASE WHEN driver_name IS NULL OR driver_name = '' THEN 1 ELSE 0 END) as blank_driver_names,
    SUM(CASE WHEN transporter_name IS NULL OR transporter_name = '' THEN 1 ELSE 0 END) as blank_transporter_names,
    SUM(CASE WHEN job_id IS NULL OR job_id = '' THEN 1 ELSE 0 END) as blank_job_ids
FROM call_logs_match_making;
```

## Expected Behavior

### When Feedback is Submitted:
1. Flutter app sends:
   - callerId (telecaller ID)
   - uniqueIdDriver (driver TMID)
   - driverName (driver name)
   - uniqueIdTransporter (transporter TMID)
   - transporterName (transporter name)
   - jobId (job ID like TMJB00437)
   - feedback (e.g., "Interview Done")
   - matchStatus (e.g., "Selected")
   - additionalNotes (optional remarks)

2. API receives the data and:
   - Checks if a recent call log exists (within 5 minutes)
   - If exists: Updates the existing record
   - If not: Creates a new record
   - If names are empty: Looks them up from users table using TMIDs
   - If job_id is empty: Tries to find it from applyjobs table

3. Database should have:
   - All fields populated (no NULLs except optional fields)
   - Correct driver and transporter names
   - Correct job ID
   - Timestamp of when feedback was submitted

## Files Modified

### Backend:
- `api/phase2_call_feedback_direct.php` - Added logging and improved name lookup
- `api/phase2_job_applicants_api.php` - Added transporter info to query
- `api/phase2_upload_driver_recording_api.php` - Improved record matching
- `api/fix_blank_call_logs.php` - One-time fix script
- `api/cleanup_call_logs_cron.php` - Automated cleanup
- `api/test_blank_fields.php` - Debugging tool

### Frontend:
- `Phase_2-/lib/models/driver_applicant_model.dart` - Added transporter fields
- `Phase_2-/lib/features/jobs/job_applicants_screen.dart` - Added debug logging
- `Phase_2-/lib/features/calls/widgets/call_feedback_modal.dart` - Fixed submission order

## Next Steps

1. Run `test_blank_fields.php` to understand the current state
2. Check the debug logs after submitting feedback
3. Run the cleanup script to fix existing records
4. Monitor new submissions to ensure they're working correctly
5. Set up the cron job for ongoing maintenance
