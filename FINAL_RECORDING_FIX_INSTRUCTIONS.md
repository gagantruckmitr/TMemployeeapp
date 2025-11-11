# Final Recording Upload & Playback Fix

## Problem Summary
1. Driver recordings not saving to `/truckmitr-app/Match-making_call_recording/driver/`
2. Recording URLs not saving in database
3. No way to play recordings in history screens

## Complete Solution

---

## Part 1: Test & Diagnose

### Step 1: Run Test Script
Visit: `https://truckmitr.com/truckmitr-app/api/test_driver_recording_upload.php`

This will check:
- ✓ Directory exists and is writable
- ✓ Database table and column exist
- ✓ Recent upload logs
- ✓ PHP upload settings

### Step 2: Check Debug Logs
If uploads are failing, check: `https://truckmitr.com/truckmitr-app/upload_debug.log`

---

## Part 2: Fix Database (If Needed)

### Driver Recordings Table
If `call_logs_match_making.call_recording` column is missing:

```sql
ALTER TABLE call_logs_match_making 
ADD COLUMN call_recording VARCHAR(500) NULL;
```

### Transporter Recordings Table  
Column already exists in `job_brief_table.call_recording` ✓

---

## Part 3: Fix Directory Permissions

### Create Directories (if missing)
```bash
mkdir -p /home/truckmitr/public_html/truckmitr-app/Match-making_call_recording/driver
mkdir -p /home/truckmitr/public_html/truckmitr-app/Match-making_call_recording/transporter
```

### Set Permissions
```bash
chmod 755 /home/truckmitr/public_html/truckmitr-app/Match-making_call_recording/driver
chmod 755 /home/truckmitr/public_html/truckmitr-app/Match-making_call_recording/transporter
```

---

## Part 4: Deploy Updated Files

### Backend (PHP) - Upload to server
1. ✅ `api/phase2_upload_driver_recording_api.php` (already correct)
2. ✅ `api/phase2_upload_transporter_recording_api.php` (updated)
3. ✅ `api/phase2_job_brief_api.php` (updated with call_recording support)
4. ✅ `api/test_driver_recording_upload.php` (NEW - for testing)

### Frontend (Flutter) - Rebuild app
1. ✅ `Phase_2-/lib/features/calls/widgets/call_feedback_modal.dart` (fixed API endpoint)
2. ✅ `Phase_2-/lib/features/jobs/widgets/job_brief_feedback_modal.dart` (fixed upload flow)
3. ✅ `Phase_2-/lib/core/services/phase2_api_service.dart` (added callRecording param)
4. ✅ `Phase_2-/lib/features/calls/call_history_screen.dart` (added audio player)
5. ✅ `Phase_2-/lib/widgets/audio_player_widget.dart` (NEW - audio player widget)
6. ✅ `Phase_2-/lib/models/call_history_model.dart` (already has callRecording field)

---

## Part 5: How It Works Now

### Driver Recording Upload Flow
1. Telecaller opens driver call feedback modal
2. Selects recording file (optional)
3. Clicks "Upload Recording"
4. File uploads to `/Match-making_call_recording/driver/`
5. URL saves to `call_logs_match_making.call_recording`
6. Success message shows database save status

### Transporter Recording Upload Flow
1. Telecaller fills job brief feedback form
2. Selects recording file (optional)
3. Clicks "Submit Feedback"
4. Recording uploads FIRST → gets URL
5. Job brief saves with recording URL
6. Both file and URL saved together

### Recording Playback
- **Driver History**: Call History Screen shows audio player for each call with recording
- **Transporter History**: Job brief history shows audio player (when implemented)
- Tap play button → opens recording in external player/browser

---

## Part 6: Testing Checklist

### Test Driver Recording
- [ ] Open driver call feedback modal
- [ ] Select audio file
- [ ] Click "Upload Recording"
- [ ] Check success message mentions "database"
- [ ] Visit test script - verify file exists
- [ ] Check call history - see audio player
- [ ] Tap play - recording plays

### Test Transporter Recording
- [ ] Open job brief feedback form
- [ ] Select audio file
- [ ] Fill form and submit
- [ ] Check success message
- [ ] Visit test script - verify file in transporter folder
- [ ] Check transporter history - see audio player
- [ ] Tap play - recording plays

---

## Part 7: Troubleshooting

### Recording uploads but URL not in database

**Driver Issue:**
- Check if call log exists BEFORE uploading
- The API tries to find existing call log by driver_tmid + caller_id
- If no match found, it creates new record

**Solution:** Make sure call feedback is saved BEFORE uploading recording

**Transporter Issue:**
- Recording now uploads during job brief submission
- URL is passed to saveJobBrief API
- Should save together atomically

### Directory permission denied

```bash
# Check current permissions
ls -la /home/truckmitr/public_html/truckmitr-app/Match-making_call_recording/

# Fix permissions
chmod 755 /home/truckmitr/public_html/truckmitr-app/Match-making_call_recording/driver
chmod 755 /home/truckmitr/public_html/truckmitr-app/Match-making_call_recording/transporter

# If still failing, try 777 temporarily (NOT recommended for production)
chmod 777 /home/truckmitr/public_html/truckmitr-app/Match-making_call_recording/driver
```

### File uploads but can't access URL

**Check .htaccess:**
Make sure directory allows direct file access:

```apache
# In /truckmitr-app/Match-making_call_recording/.htaccess
<FilesMatch "\.(mp3|wav|m4a|aac|ogg)$">
    Order Allow,Deny
    Allow from all
</FilesMatch>
```

### PHP upload size limits

Edit `php.ini` or `.htaccess`:
```
upload_max_filesize = 50M
post_max_size = 50M
max_execution_time = 300
```

---

## Part 8: API Endpoints Reference

### Driver Recording Upload
**URL:** `https://truckmitr.com/truckmitr-app/api/phase2_upload_driver_recording_api.php`

**Request:**
```
POST multipart/form-data
- recording: (file)
- job_id: (string)
- caller_id: (int)
- driver_tmid: (string)
```

**Response:**
```json
{
  "success": true,
  "message": "Recording uploaded successfully",
  "data": {
    "filename": "JOB123_45_20241108123456.mp3",
    "url": "https://truckmitr.com/truckmitr-app/Match-making_call_recording/driver/JOB123_45_20241108123456.mp3",
    "database_updated": true,
    "rows_affected": 1
  }
}
```

### Transporter Recording Upload
**URL:** `https://truckmitr.com/truckmitr-app/api/phase2_upload_transporter_recording_api.php`

**Request:**
```
POST multipart/form-data
- recording: (file)
- job_id: (string)
- caller_id: (int)
- transporter_tmid: (string)
```

**Response:**
```json
{
  "success": true,
  "message": "Recording uploaded successfully",
  "data": {
    "filename": "JOB123_45_20241108123456.mp3",
    "url": "https://truckmitr.com/truckmitr-app/Match-making_call_recording/transporter/JOB123_45_20241108123456.mp3"
  }
}
```

---

## Part 9: File Structure

```
/truckmitr-app/
├── Match-making_call_recording/
│   ├── driver/
│   │   └── {jobId}_{callerId}_{datetime}.{ext}
│   └── transporter/
│       └── {jobId}_{callerId}_{datetime}.{ext}
├── api/
│   ├── phase2_upload_driver_recording_api.php
│   ├── phase2_upload_transporter_recording_api.php
│   ├── phase2_job_brief_api.php
│   └── test_driver_recording_upload.php
└── upload_debug.log
```

---

## Part 10: Quick Fix Commands

### If everything fails, run these:

```bash
# 1. Create directories
mkdir -p /home/truckmitr/public_html/truckmitr-app/Match-making_call_recording/driver
mkdir -p /home/truckmitr/public_html/truckmitr-app/Match-making_call_recording/transporter

# 2. Set permissions
chmod 755 /home/truckmitr/public_html/truckmitr-app/Match-making_call_recording/driver
chmod 755 /home/truckmitr/public_html/truckmitr-app/Match-making_call_recording/transporter

# 3. Check database
mysql -u username -p database_name -e "SHOW COLUMNS FROM call_logs_match_making LIKE 'call_recording';"

# 4. Add column if missing
mysql -u username -p database_name -e "ALTER TABLE call_logs_match_making ADD COLUMN call_recording VARCHAR(500) NULL;"

# 5. Test upload
curl -X POST https://truckmitr.com/truckmitr-app/api/test_driver_recording_upload.php
```

---

## Summary

✅ **Driver recordings**: Upload separately, save to `call_logs_match_making`
✅ **Transporter recordings**: Upload with job brief, save to `job_brief_table`
✅ **Playback**: Audio player widget in history screens
✅ **Testing**: Test script to diagnose issues
✅ **Debugging**: Detailed logs for troubleshooting

All files are ready. Deploy and test!
