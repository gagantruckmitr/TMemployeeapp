# Transporter Recording Upload Fix

## Issue
Recordings are not being saved to the server when editing transporter call history.

## Root Causes Identified

1. **Database Schema**: The `job_brief_table` may not have the `call_recording` column
2. **API Response Format**: Need to ensure consistent response format
3. **Error Handling**: Need better error logging to identify issues

## Fixes Applied

### 1. Enhanced Error Logging (transporter_call_history_screen.dart)
Added comprehensive debug logging to track the upload process:
- Logs job ID, caller ID, transporter TMID
- Logs file path and request fields
- Logs HTTP response status and body
- Shows user-friendly error messages

### 2. Updated API Response (phase2_upload_driver_recording_api.php)
Enhanced response to include:
- `recording_url` at root level (backward compatibility)
- `data.url` field
- `data.recording_url` field (duplicate for compatibility)
- `user_type` and `user_tmid` for debugging

### 3. Database Schema Migration (add_call_recording_column_to_job_brief.php)
Script to add `call_recording` column to `job_brief_table` if it doesn't exist.

### 4. Test Script (test_transporter_recording_upload.php)
Comprehensive test script to verify:
- Database schema
- Upload directory permissions
- Recent job briefs with recordings
- Testing instructions

## Steps to Fix

### Step 1: Run Database Migration
```bash
# Access the migration script via browser
https://truckmitr.com/truckmitr-app/api/add_call_recording_column_to_job_brief.php
```

This will add the `call_recording` column to `job_brief_table` if it doesn't exist.

### Step 2: Verify Setup
```bash
# Access the test script via browser
https://truckmitr.com/truckmitr-app/api/test_transporter_recording_upload.php
```

This will check:
- ✓ Database column exists
- ✓ Upload directory exists and is writable
- ✓ Recent job briefs

### Step 3: Test Upload
1. Open the Flutter app
2. Navigate to Call History Hub → Transporters
3. Select a transporter
4. Click edit on any call record
5. Select a recording file
6. Click "Update & Upload Recording"
7. Check the console for debug logs

### Step 4: Verify Upload
Check the debug logs in the console:
```
=== Recording Upload Debug ===
Job ID: [job_id]
Caller ID: [caller_id]
Transporter TMID: [tmid]
File path: [path]
Request fields: {job_id: ..., caller_id: ..., transporter_tmid: ...}
Response status: 200
Response body: {"success":true,...}
Response data: {...}
Recording URL: https://truckmitr.com/...
```

### Step 5: Check Database
Refresh the test script to see if the recording URL was saved:
```bash
https://truckmitr.com/truckmitr-app/api/test_transporter_recording_upload.php
```

## Common Issues & Solutions

### Issue 1: Column doesn't exist
**Error**: `Unknown column 'call_recording' in 'field list'`

**Solution**: Run the migration script (Step 1)

### Issue 2: Upload directory not writable
**Error**: `Upload directory not writable`

**Solution**: 
```bash
chmod 755 /path/to/truckmitr-app/Match-making_call_recording/driver/
```

### Issue 3: File upload fails
**Error**: `Failed to save recording file`

**Solution**: 
- Check file size (max 50MB)
- Check file format (MP3, WAV, M4A, etc.)
- Check server upload limits in php.ini

### Issue 4: Recording URL not saved
**Error**: Recording uploads but URL not in database

**Solution**: 
- Verify `call_recording` column exists
- Check `updateJobBrief` API includes `callRecording` field
- Verify the response includes `data.url`

## API Endpoints

### Upload Recording
```
POST https://truckmitr.com/truckmitr-app/api/phase2_upload_driver_recording_api.php

Form Data:
- recording: [file]
- job_id: [string]
- caller_id: [int]
- transporter_tmid: [string]

Response:
{
  "success": true,
  "message": "Recording uploaded successfully",
  "recording_url": "https://...",
  "data": {
    "filename": "...",
    "url": "https://...",
    "recording_url": "https://...",
    "size": 1234567,
    "user_type": "transporter",
    "user_tmid": "..."
  }
}
```

### Update Job Brief
```
POST https://truckmitr.com/truckmitr-app/api/phase2_job_brief_api.php?action=update

JSON Body:
{
  "id": 123,
  "name": "...",
  "jobLocation": "...",
  ...
  "callRecording": "https://..."
}

Response:
{
  "success": true,
  "message": "Job brief updated successfully",
  "data": {
    "id": 123
  }
}
```

## File Structure

```
api/
├── phase2_upload_driver_recording_api.php  (handles both driver & transporter)
├── phase2_job_brief_api.php                (handles job brief CRUD)
├── add_call_recording_column_to_job_brief.php  (migration)
└── test_transporter_recording_upload.php   (test script)

Phase_2-/lib/features/calls/
└── transporter_call_history_screen.dart    (edit modal with recording upload)
```

## Database Schema

### job_brief_table
```sql
CREATE TABLE job_brief_table (
  id INT PRIMARY KEY AUTO_INCREMENT,
  unique_id VARCHAR(50),
  job_id VARCHAR(50),
  caller_id INT,
  name VARCHAR(255),
  job_location VARCHAR(255),
  route TEXT,
  vehicle_type VARCHAR(100),
  license_type VARCHAR(100),
  experience VARCHAR(100),
  salary_fixed DECIMAL(10,2),
  salary_variable DECIMAL(10,2),
  esi_pf VARCHAR(10),
  food_allowance DECIMAL(10,2),
  trip_incentive DECIMAL(10,2),
  rehne_ki_suvidha VARCHAR(10),
  mileage VARCHAR(50),
  fast_tag_road_kharcha VARCHAR(50),
  call_status_feedback VARCHAR(255),
  call_recording VARCHAR(500),  -- THIS COLUMN
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

## Testing Checklist

- [ ] Database column exists
- [ ] Upload directory is writable
- [ ] Can select recording file
- [ ] Upload shows progress
- [ ] Success message appears
- [ ] Recording URL in database
- [ ] Can play recording (if player implemented)
- [ ] Error messages are clear
- [ ] Works for multiple transporters
- [ ] Works with different file formats

## Next Steps

1. Run migration script
2. Run test script to verify setup
3. Test upload in Flutter app
4. Check debug logs
5. Verify in database
6. Test with different file formats
7. Test with large files (near 50MB limit)

## Support

If issues persist:
1. Check server error logs
2. Check upload_debug.log file
3. Verify PHP upload settings (upload_max_filesize, post_max_size)
4. Check database connection
5. Verify file permissions
