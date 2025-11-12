# Call Feedback and Recording Upload Fix

## Issues Fixed

### 1. **All Fields Not Saving Properly in call_logs_match_making**
   - **Problem**: When telecaller submitted feedback, some fields were not being saved correctly
   - **Root Cause**: The feedback submission and recording upload were happening independently without proper coordination
   - **Solution**: 
     - Modified `phase2_call_feedback_direct.php` to check for recent call logs (within 5 minutes) and update them instead of always inserting new records
     - This prevents duplicate entries and ensures all fields are properly populated

### 2. **All Telecallers Showing Same Job**
   - **Problem**: Job ID was not being properly passed or stored in the database
   - **Root Cause**: Missing transporter TMID in the job applicants data, causing incomplete feedback records
   - **Solution**:
     - Updated `phase2_job_applicants_api.php` to include transporter TMID and name in the query
     - Modified `DriverApplicant` model to include `transporterTmid` and `transporterName` fields
     - Updated `job_applicants_screen.dart` to pass transporter information when submitting feedback

### 3. **Recording Upload Not Linking to Feedback**
   - **Problem**: Recording uploads were creating separate entries or not linking properly to feedback submissions
   - **Root Cause**: The recording upload API was searching for records incorrectly and not considering job_id
   - **Solution**:
     - Enhanced `phase2_upload_driver_recording_api.php` to:
       - Support both driver and transporter recordings
       - Search for recent call logs (within 10 minutes) using proper criteria
       - Include job_id in the search to ensure correct record matching
       - Update existing records instead of creating duplicates

### 4. **Feedback Submission Order**
   - **Problem**: Recording was being uploaded before feedback was saved, causing timing issues
   - **Root Cause**: Async operations were not properly sequenced
   - **Solution**:
     - Modified `call_feedback_modal.dart` to:
       - Submit feedback first to create/update the call log entry
       - Wait 500ms for the feedback to be saved
       - Then upload the recording which will find and update the existing record
       - Show proper success/error messages for both operations

## Files Modified

### Backend (PHP)
1. **api/phase2_call_feedback_direct.php**
   - Added logic to check for recent call logs and update instead of always inserting
   - Prevents duplicate entries within 5-minute window

2. **api/phase2_upload_driver_recording_api.php**
   - Enhanced search logic to find correct call log records
   - Added support for both driver and transporter recordings
   - Improved matching criteria including job_id
   - Extended search window to 10 minutes

3. **api/phase2_job_applicants_api.php**
   - Added transporter TMID and name to the query
   - Joined with users table to get transporter information

### Frontend (Flutter)
1. **Phase_2-/lib/models/driver_applicant_model.dart**
   - Added `transporterTmid` field
   - Added `transporterName` field
   - Updated fromJson constructor

2. **Phase_2-/lib/features/jobs/job_applicants_screen.dart**
   - Updated `_showCallFeedbackModal` to pass transporter TMID and name
   - Updated state management to include new fields

3. **Phase_2-/lib/features/calls/widgets/call_feedback_modal.dart**
   - Changed submission order: feedback first, then recording
   - Added delay between operations for proper sequencing
   - Improved error handling and user feedback

## Testing Checklist

- [ ] Submit feedback without recording - should save all fields correctly
- [ ] Submit feedback with recording - both should be saved and linked
- [ ] Multiple telecallers calling different drivers for different jobs - each should have correct job_id
- [ ] Recording upload should update the correct call log entry
- [ ] No duplicate entries should be created
- [ ] All fields in call_logs_match_making should be populated:
  - caller_id
  - unique_id_transporter
  - unique_id_driver
  - driver_name
  - transporter_name
  - feedback
  - match_status
  - remark
  - job_id
  - call_recording (if uploaded)

## Database Schema Reference

Table: `call_logs_match_making`
- id (primary key)
- caller_id (telecaller ID)
- unique_id_transporter (transporter TMID)
- unique_id_driver (driver TMID)
- driver_name
- transporter_name
- feedback
- match_status
- call_recording (URL)
- remark (notes)
- job_id
- created_at
- updated_at

## Fixing Existing Blank Fields

### Admin Tool (Recommended - Easy to Use)
Open the admin cleanup tool in your browser:
```
https://truckmitr.com/truckmitr-app/api/admin_cleanup_call_logs.html
```

This provides a user-friendly interface with two options:
1. **One-Time Fix** - Fixes blank fields only
2. **Full Cleanup** - Fixes blank fields + removes duplicates

The tool shows real-time progress and detailed statistics.

### Direct API Call
To fix existing records with blank fields programmatically:
```
https://truckmitr.com/truckmitr-app/api/fix_blank_call_logs.php
```

This script will:
- Fill in missing driver names by looking up from users table
- Fill in missing transporter names by looking up from users table
- Fill in missing job_ids by finding the most recent job application for each driver-transporter pair
- Provide detailed statistics of what was fixed

### Automated Cleanup (Recommended)
For ongoing maintenance, set up a cron job to run periodically:

**Option 1: Via URL (with secret key)**
```bash
# Add to crontab to run every hour
0 * * * * curl "https://truckmitr.com/truckmitr-app/api/cleanup_call_logs_cron.php?key=truckmitr_cleanup_2024"
```

**Option 2: Via PHP CLI**
```bash
# Add to crontab to run every hour
0 * * * * /usr/bin/php /path/to/api/cleanup_call_logs_cron.php
```

The automated cleanup script will:
- Fix blank driver/transporter names
- Fill in missing job_ids
- Remove duplicate entries (same caller, driver, transporter within same minute)
- Log all operations to `cleanup_logs.txt`

### Manual Database Query (Alternative)
If you prefer to run SQL directly:

```sql
-- Fix driver names
UPDATE call_logs_match_making clm
INNER JOIN users u ON clm.unique_id_driver = u.unique_id AND u.role = 'driver'
SET clm.driver_name = u.name
WHERE (clm.driver_name IS NULL OR clm.driver_name = '')
AND clm.unique_id_driver != '';

-- Fix transporter names
UPDATE call_logs_match_making clm
INNER JOIN users u ON clm.unique_id_transporter = u.unique_id AND u.role = 'transporter'
SET clm.transporter_name = u.name
WHERE (clm.transporter_name IS NULL OR clm.transporter_name = '')
AND clm.unique_id_transporter != '';
```

## Notes

- The 5-minute window for feedback updates prevents duplicate entries when telecallers quickly resubmit
- The 10-minute window for recording uploads allows for slower upload times
- Both windows can be adjusted if needed based on real-world usage patterns
- The system now properly handles both driver and transporter recordings
- Run the cleanup script immediately after deployment to fix existing blank fields
- Set up the cron job for ongoing maintenance to keep data clean
