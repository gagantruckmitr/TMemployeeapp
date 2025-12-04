# Debug Guide - Transporter Feedback Not Saving

## Current Status

The code has been updated with extensive logging on both frontend (Flutter) and backend (PHP API). This will help us identify exactly where the issue is occurring.

## Step 1: Test the API Directly

Visit this URL in your browser:
```
https://truckmitr.com/truckmitr-app/api/test_feedback_with_logging.php
```

This will:
- Send a test request to the API
- Show the response
- Display recent error log entries
- Clean up test data

**Expected Result:** You should see "✓ SUCCESS!" if the API is working.

**If it fails:** Note the error message and check the error logs.

## Step 2: Test from the Flutter App

1. Open the Flutter app
2. Navigate to **Job Postings**
3. Find a job assigned to you
4. Click the **call button** (green phone icon)
5. Make a call (Manual or EasyGo IVR)
6. When the feedback modal appears:
   - Select a status (e.g., "Connected: Call Back Later")
   - Add notes (e.g., "Test feedback")
   - Click **Submit Feedback**

## Step 3: Check Flutter Console Logs

Look for these log messages in your Flutter console:

```
=== SHOWING TRANSPORTER FEEDBACK MODAL ===
Transporter TMID: TM12345
Transporter Name: Test Transporter
Job ID: JOB001

=== FEEDBACK SUBMITTED ===
Call Status: Connected: Call Back Later
Notes: Test feedback
Recording File: null

Saving feedback to database...
Caller ID: 1
User: John Doe

=== CALLING API ===
uniqueId: TM12345
jobId: JOB001
callerId: 1
name: Test Transporter
callStatusFeedback: Connected: Call Back Later - Notes: Test feedback
callRecording: null

=== SAVE JOB BRIEF API CALL ===
uniqueId: TM12345
jobId: JOB001
callerId (input): 1
Request Body: {"uniqueId":"TM12345","jobId":"JOB001","callerId":1,"name":"Test Transporter","callStatusFeedback":"Connected: Call Back Later - Notes: Test feedback"}
API URL: https://truckmitr.com/truckmitr-app/api/phase2_job_brief_api.php
Response Status Code: 200
Response Body: {"success":true,"message":"Job brief saved successfully","data":{"id":123,"uniqueId":"TM12345","jobId":"JOB001","updated":false}}
✓ Job brief saved successfully
```

## Step 4: Check PHP Error Logs

On your server, check the PHP error log for these messages:

```bash
# Common log locations:
tail -f /var/log/php_errors.log
tail -f /var/log/apache2/error.log
tail -f /var/log/nginx/error.log

# Or check the path from php.ini:
php -i | grep error_log
```

Look for:
```
=== SAVE JOB BRIEF API CALLED ===
Request Method: POST
Content Type: application/json
Raw Input: {"uniqueId":"TM12345",...}
Decoded Data: Array(...)
uniqueId: TM12345
jobId: JOB001
callerId: 1
No existing record, inserting new one
Insert Query: INSERT INTO job_brief_table...
✓ Insert successful, ID: 123
```

## Step 5: Check Database

Run this SQL query to see if data is being saved:

```sql
-- Check recent entries
SELECT 
    id,
    unique_id,
    job_id,
    caller_id,
    name,
    call_status_feedback,
    created_at
FROM job_brief_table
ORDER BY created_at DESC
LIMIT 10;

-- Check for entries in the last hour
SELECT COUNT(*) as recent_count
FROM job_brief_table
WHERE created_at > DATE_SUB(NOW(), INTERVAL 1 HOUR);
```

## Common Issues and Solutions

### Issue 1: API Returns 404

**Symptom:** Response Status Code: 404

**Solution:**
- Check if the API file exists at: `api/phase2_job_brief_api.php`
- Verify the URL in `lib/core/services/phase2_api_service.dart`
- Check `.htaccess` rules

### Issue 2: Database Connection Failed

**Symptom:** "Database connection not available"

**Solution:**
- Check `api/config.php` database credentials
- Verify MySQL service is running
- Check database user permissions

### Issue 3: Table Doesn't Exist

**Symptom:** "Table 'job_brief_table' doesn't exist"

**Solution:**
Run this SQL to create the table:

```sql
CREATE TABLE IF NOT EXISTS job_brief_table (
    id INT AUTO_INCREMENT PRIMARY KEY,
    unique_id VARCHAR(50) NOT NULL,
    job_id VARCHAR(50) NOT NULL,
    caller_id INT,
    name VARCHAR(255),
    job_location VARCHAR(255),
    route VARCHAR(255),
    vehicle_type VARCHAR(100),
    license_type VARCHAR(100),
    experience VARCHAR(100),
    salary_fixed DECIMAL(10,2),
    salary_variable DECIMAL(10,2),
    esi_pf VARCHAR(10) DEFAULT 'No',
    food_allowance DECIMAL(10,2),
    trip_incentive DECIMAL(10,2),
    rehne_ki_suvidha VARCHAR(10) DEFAULT 'No',
    mileage VARCHAR(50),
    fast_tag_road_kharcha VARCHAR(50) DEFAULT 'Company',
    call_status_feedback TEXT,
    call_recording VARCHAR(500),
    closed_job TINYINT(1) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_unique_job (unique_id, job_id),
    INDEX idx_caller (caller_id),
    INDEX idx_created (created_at)
);
```

### Issue 4: JSON Parsing Error

**Symptom:** "Invalid JSON data" or "JSON Error: ..."

**Solution:**
- Check if Content-Type header is set to "application/json"
- Verify the request body is valid JSON
- Check for special characters in the data

### Issue 5: Missing Required Fields

**Symptom:** "Transporter ID and Job ID are required"

**Solution:**
- Verify `widget.job.transporterTmid` is not empty
- Verify `widget.job.jobId` is not empty
- Check the JobModel data

### Issue 6: User Not Logged In

**Symptom:** callerId is 0 or null

**Solution:**
- Verify user is logged in
- Check `Phase2AuthService.getCurrentUser()` returns valid user
- Check session/token is valid

## Quick Verification Commands

### Check if API is accessible:
```bash
curl -X POST https://truckmitr.com/truckmitr-app/api/phase2_job_brief_api.php \
  -H "Content-Type: application/json" \
  -d '{"uniqueId":"TEST","jobId":"TEST","callerId":1,"name":"Test","callStatusFeedback":"Test"}'
```

### Check database table:
```bash
mysql -u your_user -p your_database -e "DESCRIBE job_brief_table;"
```

### Check recent entries:
```bash
mysql -u your_user -p your_database -e "SELECT * FROM job_brief_table ORDER BY created_at DESC LIMIT 5;"
```

## Files with Logging

### Frontend (Flutter):
- `lib/features/jobs/widgets/modern_job_card.dart` - Feedback submission
- `lib/core/services/phase2_api_service.dart` - API calls

### Backend (PHP):
- `api/phase2_job_brief_api.php` - API endpoint

## Next Steps

1. Run the test script: `test_feedback_with_logging.php`
2. Test from the app and check Flutter console
3. Check PHP error logs
4. Check database for new entries
5. Report back with the log output from any failing step

## Contact Points

If you see errors at any step, provide:
1. The exact error message
2. The log output from Flutter console
3. The log output from PHP error log
4. The HTTP response code and body
5. Any database errors

This will help identify the exact point of failure.
