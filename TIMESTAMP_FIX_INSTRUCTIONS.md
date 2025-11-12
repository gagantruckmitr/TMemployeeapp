# Timestamp and Driver Card Issues - Fix Instructions

## Issues Identified

### 1. Future Timestamps Issue
**Problem:** Driver application times show future timestamps (e.g., 4:47 AM when current time is 12:14 AM)

**Root Cause:** Timezone mismatch between PHP, MySQL, and the database records. The timestamps in the `applyjobs` table may have been inserted with incorrect timezone offsets.

**Solution:**

#### Step 1: Diagnose the Problem
1. Open your browser and navigate to:
   ```
   https://truckmitr.com/truckmitr-app/api/diagnose_timestamps.php
   ```

2. This will show you:
   - PHP timezone configuration
   - MySQL timezone configuration
   - Any future timestamps in the database
   - Recent application timestamps

#### Step 2: Fix Future Timestamps
1. After reviewing the diagnostic report, navigate to:
   ```
   https://truckmitr.com/truckmitr-app/api/fix_future_timestamps.php
   ```

2. This will show you all records with future timestamps in DRY RUN mode (no changes made)

3. To actually fix the timestamps, add `?fix=yes` to the URL:
   ```
   https://truckmitr.com/truckmitr-app/api/fix_future_timestamps.php?fix=yes
   ```

4. The script will automatically correct all future timestamps by subtracting the time difference

#### Step 3: Verify the Fix
1. Go back to the diagnostic page to confirm no future timestamps remain
2. Check the app to see if times are now displaying correctly

### 2. Driver Cards "Disappearing" After Feedback
**Problem:** After submitting call feedback, driver cards seem to disappear from the job applicants screen

**Root Cause:** The cards weren't actually disappearing - they were being sorted to the bottom of the list. However, the feedback data wasn't being fetched from the database, so the app couldn't properly display the feedback status.

**Solution:** 
The API has been updated to:
1. Fetch call feedback data from `call_logs_match_making` table
2. Include `callFeedback`, `matchStatus`, and `feedbackNotes` in the response
3. The Flutter app already has logic to display this data with color-coded cards

**What Changed:**
- `api/phase2_job_applicants_api.php` now joins with `call_logs_match_making` table
- Returns the most recent feedback for each driver-job combination
- Cards with feedback will now show the feedback status and be color-coded

## Files Modified

### 1. `api/phase2_job_applicants_api.php`
- Added JOIN with `call_logs_match_making` table to fetch feedback data
- Added `callFeedback`, `matchStatus`, `feedbackNotes` to response
- Added detailed timestamp debugging logs

### 2. `api/config.php`
- Added timezone logging for debugging

### 3. New Files Created
- `api/diagnose_timestamps.php` - Diagnostic tool for timezone issues
- `api/fix_future_timestamps.php` - Automated fix for future timestamps

## Testing Steps

### Test 1: Verify Timestamps
1. Open the job applicants screen in the app
2. Check that all "Applied" times are in the past
3. Verify times match the actual application time

### Test 2: Verify Feedback Display
1. Open a job with applicants
2. Call a driver and submit feedback
3. Verify the driver card:
   - Shows the feedback status
   - Has a colored background/border based on feedback type
   - Is sorted to the bottom but still visible
4. Pull to refresh and verify feedback persists

### Test 3: Verify Feedback Colors
The app should show different colors for different feedback types:
- **Green**: Interview done, Interview fixed, Ready for interview, Match making done
- **Yellow**: Ringing, Call busy, Switched off, Not reachable, Disconnected
- **Blue**: Busy right now, Call tomorrow morning, Call in evening, Call after 2 days
- **Red**: Not selected, Not interested

## Monitoring

### Check Logs
The API now logs detailed information about timestamps. Check the PHP error log for entries like:
```
=== TIMESTAMP DEBUG ===
Raw applied_at from DB: 2025-11-12 04:47:00
PHP timezone: Asia/Kolkata
Current PHP time: 2025-11-12 00:14:23
MySQL timezone should be: +05:30
```

If you see "WARNING: Future timestamp detected!" in the logs, run the fix script again.

### Ongoing Prevention
The timezone settings in `config.php` should prevent future issues:
- PHP timezone: `Asia/Kolkata`
- MySQL timezone: `+05:30` (IST)

Both are set automatically when the API loads.

## Troubleshooting

### If timestamps are still wrong:
1. Check if your server's system timezone is correct
2. Verify MySQL global timezone: `SELECT @@global.time_zone;`
3. Check if there's a cron job or script inserting data with wrong timezone

### If feedback still doesn't show:
1. Check if `call_logs_match_making` table exists
2. Verify feedback is being saved: Check the table directly
3. Look for errors in `api/feedback_debug.log`

### If cards still "disappear":
1. They're not disappearing - scroll down to see them at the bottom
2. The sorting logic puts cards with feedback at the bottom
3. This is intentional to prioritize drivers who haven't been called yet

## Need Help?
If issues persist, check:
1. PHP error logs
2. MySQL error logs  
3. `api/feedback_debug.log` for call feedback issues
4. Browser console for Flutter app errors
