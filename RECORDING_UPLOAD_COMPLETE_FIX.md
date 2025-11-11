# Call Recording Upload Complete Fix

## Overview
Fixed both transporter and driver call recording uploads to properly save files and URLs to the database.

---

## 1. TRANSPORTER RECORDING UPLOAD

### Problem
- Recordings not stored in correct directory
- URLs not saved to database
- Upload happened before job brief was created

### Solution

#### Database
- **Table**: `job_brief_table`
- **Column**: `call_recording` (already exists)
- Stores URL: `https://truckmitr.com/truckmitr-app/Match-making_call_recording/transporter/{filename}`

#### Files Changed

**Backend (PHP)**:
1. `api/phase2_job_brief_api.php`
   - Added `call_recording` field to INSERT/UPDATE queries
   - Added `callRecording` to response formatting

2. `api/phase2_upload_transporter_recording_api.php`
   - Simplified to only upload file and return URL
   - Removed database update (now handled by job brief save)

**Frontend (Flutter)**:
1. `Phase_2-/lib/features/jobs/widgets/job_brief_feedback_modal.dart`
   - Changed flow: Upload recording FIRST, then save job brief with URL
   - Removed separate "Upload Recording" button
   - Recording uploads automatically on form submit
   - Added proper JSON response parsing

2. `Phase_2-/lib/core/services/phase2_api_service.dart`
   - Added `callRecording` parameter to `saveJobBrief()`
   - Added `callRecording` parameter to `updateJobBrief()`

#### New Flow
1. User selects recording file (optional)
2. User fills job brief form
3. User clicks "Submit Feedback"
4. **IF recording selected**: Upload to server → Get URL
5. Save job brief with all data INCLUDING recording URL
6. Success!

---

## 2. DRIVER RECORDING UPLOAD

### Problem
- Using debug API instead of production API
- No proper JSON response parsing
- Unclear feedback on database save status

### Solution

#### Database
- **Table**: `call_logs_match_making`
- **Column**: `call_recording` (already exists)
- Stores URL: `https://truckmitr.com/truckmitr-app/Match-making_call_recording/driver/{filename}`

#### Files Changed

**Backend (PHP)**:
- `api/phase2_upload_driver_recording_api.php` (already working correctly)
  - Uploads file to `/Match-making_call_recording/driver/`
  - Updates or inserts record in `call_logs_match_making` table
  - Returns success with database update status

**Frontend (Flutter)**:
1. `Phase_2-/lib/features/calls/widgets/call_feedback_modal.dart`
   - Changed API endpoint from debug to production
   - Added `dart:convert` import for JSON parsing
   - Improved response handling with proper JSON parsing
   - Shows database save status in success message

#### Flow
1. User opens call feedback modal for driver
2. User selects recording file (optional)
3. User clicks "Upload Recording"
4. File uploads to server
5. API saves URL to `call_logs_match_making` table
6. Success message shows if database was updated

---

## Directory Structure

```
/truckmitr-app/Match-making_call_recording/
├── transporter/          # Transporter call recordings
│   └── {jobId}_{callerId}_{datetime}.{ext}
└── driver/              # Driver call recordings
    └── {jobId}_{callerId}_{datetime}.{ext}
```

**Permissions**: 0755 (directories must be writable)

---

## Database Schema

### job_brief_table (Transporter)
```sql
ALTER TABLE job_brief_table 
ADD COLUMN call_recording VARCHAR(500) NULL;
```

### call_logs_match_making (Driver)
```sql
-- Column already exists
call_recording VARCHAR(500) NULL
```

---

## API Endpoints

### Transporter Recording Upload
**URL**: `https://truckmitr.com/truckmitr-app/api/phase2_upload_transporter_recording_api.php`

**Method**: POST (multipart/form-data)

**Parameters**:
- `recording` (file): Audio file
- `job_id` (string): Job ID
- `caller_id` (int): Telecaller ID
- `transporter_tmid` (string): Transporter TMID

**Response**:
```json
{
  "success": true,
  "message": "Recording uploaded successfully",
  "data": {
    "filename": "JOB123_45_20241108123456.mp3",
    "url": "https://truckmitr.com/truckmitr-app/Match-making_call_recording/transporter/JOB123_45_20241108123456.mp3",
    "size": 1234567,
    "upload_path": "/path/to/file"
  }
}
```

### Driver Recording Upload
**URL**: `https://truckmitr.com/truckmitr-app/api/phase2_upload_driver_recording_api.php`

**Method**: POST (multipart/form-data)

**Parameters**:
- `recording` (file): Audio file
- `job_id` (string): Job ID
- `caller_id` (int): Telecaller ID
- `driver_tmid` (string): Driver TMID

**Response**:
```json
{
  "success": true,
  "message": "Recording uploaded successfully",
  "data": {
    "filename": "JOB123_45_20241108123456.mp3",
    "url": "https://truckmitr.com/truckmitr-app/Match-making_call_recording/driver/JOB123_45_20241108123456.mp3",
    "size": 1234567,
    "upload_path": "/path/to/file",
    "database_updated": true,
    "rows_affected": 1
  }
}
```

---

## Testing Checklist

### Transporter Recording
- [ ] Open job brief feedback form
- [ ] Select audio file
- [ ] Fill form fields
- [ ] Submit form
- [ ] Verify file in `/Match-making_call_recording/transporter/`
- [ ] Verify URL in `job_brief_table.call_recording`
- [ ] Check success message

### Driver Recording
- [ ] Open driver call feedback modal
- [ ] Select audio file
- [ ] Click "Upload Recording"
- [ ] Verify file in `/Match-making_call_recording/driver/`
- [ ] Verify URL in `call_logs_match_making.call_recording`
- [ ] Check success message shows database status

---

## Deployment Steps

1. **Upload PHP files** (if not already done):
   - `api/phase2_job_brief_api.php`
   - `api/phase2_upload_transporter_recording_api.php`
   - `api/phase2_upload_driver_recording_api.php`

2. **Verify directories exist**:
   ```bash
   mkdir -p /truckmitr-app/Match-making_call_recording/transporter
   mkdir -p /truckmitr-app/Match-making_call_recording/driver
   chmod 755 /truckmitr-app/Match-making_call_recording/transporter
   chmod 755 /truckmitr-app/Match-making_call_recording/driver
   ```

3. **Verify database columns**:
   - `job_brief_table.call_recording` ✓ (already exists)
   - `call_logs_match_making.call_recording` ✓ (already exists)

4. **Deploy Flutter app** with updated code

---

## Files Modified Summary

### Backend (PHP)
- ✅ `api/phase2_job_brief_api.php` - Added call_recording support
- ✅ `api/phase2_upload_transporter_recording_api.php` - Simplified upload
- ✅ `api/phase2_upload_driver_recording_api.php` - Already working

### Frontend (Flutter)
- ✅ `Phase_2-/lib/features/jobs/widgets/job_brief_feedback_modal.dart` - Fixed transporter upload flow
- ✅ `Phase_2-/lib/core/services/phase2_api_service.dart` - Added callRecording parameter
- ✅ `Phase_2-/lib/features/calls/widgets/call_feedback_modal.dart` - Fixed driver upload API and parsing

---

## Benefits

✅ **Transporter Recordings**:
- Files stored in correct directory
- URLs saved in database
- Simplified UX (no separate upload button)
- Atomic operation (recording + job brief together)

✅ **Driver Recordings**:
- Using production API (not debug)
- Proper JSON response parsing
- Clear database save status feedback
- Files and URLs properly saved

✅ **Both**:
- Consistent file naming: `{jobId}_{callerId}_{datetime}.{ext}`
- Proper error handling
- Better user feedback
- Database integrity maintained
