# Transporter Call Recording Upload Feature - Complete

## Overview
Added call recording upload functionality for transporter calls in the Job Brief Feedback modal.

## Implementation Details

### 1. Upload API
**File:** `api/phase2_upload_transporter_recording_api.php`
- Handles transporter call recording uploads
- Saves files to: `/truckmitr-app/Match-making_call_recording/transporter/`
- Filename format: `{job_id}_{caller_id}_{datetime}.{extension}`
- Updates `job_brief` table with recording URL
- Supports all audio formats (mp3, wav, m4a, aac, ogg, flac, wma, amr, opus, 3gp)

### 2. Database Column
**Table:** `job_brief_table`
**Column:** `call_recording` (VARCHAR 500)
- Stores the full URL to the uploaded recording
- Example: `https://truckmitr.com/truckmitr-app/Match-making_call_recording/transporter/TMJB00424_3_20251105141836.opus`

### 3. Flutter UI Updates
**File:** `Phase_2-/lib/features/jobs/widgets/job_brief_feedback_modal.dart`

Added recording upload section with:
- File picker for selecting audio files
- Upload button with progress indicator
- File name display
- Remove file option
- Success/error feedback

### 4. Setup Scripts

#### Add Database Column
```
https://truckmitr.com/truckmitr-app/api/add_job_brief_recording_column.php
```
This script:
- Adds `call_recording` column to `job_brief_table`
- Creates the transporter recording directory
- Shows table structure
- Verifies directory permissions

## User Flow

1. **Telecaller calls transporter** from job card
2. **Selects "Connected: Details Received"** in call feedback
3. **Job Brief Feedback modal opens** with detailed form
4. **Fills in job details** (salary, benefits, route, etc.)
5. **Optionally uploads call recording:**
   - Click "Select Recording File"
   - Choose audio file from device
   - Click "Upload Recording"
   - Wait for success message
6. **Submits the form**
7. **Recording URL saved** in `job_brief_table`

## File Storage Structure

```
/truckmitr-app/Match-making_call_recording/
├── driver/          (Driver call recordings)
│   └── TMJB00424_3_20251105141836.opus
└── transporter/     (Transporter call recordings)
    └── TMJB00424_3_20251105150230.mp3
```

## API Endpoints

### Upload Transporter Recording
**URL:** `https://truckmitr.com/truckmitr-app/api/phase2_upload_transporter_recording_api.php`
**Method:** POST (multipart/form-data)

**Parameters:**
- `recording` (file) - Audio file
- `job_id` (string) - Job ID (e.g., TMJB00424)
- `caller_id` (int) - Telecaller ID
- `transporter_tmid` (string) - Transporter TMID

**Response:**
```json
{
  "success": true,
  "message": "Recording uploaded and database updated successfully",
  "data": {
    "filename": "TMJB00424_3_20251105150230.mp3",
    "url": "https://truckmitr.com/truckmitr-app/Match-making_call_recording/transporter/TMJB00424_3_20251105150230.mp3",
    "size": 820541,
    "upload_path": "/var/www/vhosts/truckmitr.com/httpdocs/truckmitr-app/Match-making_call_recording/transporter/TMJB00424_3_20251105150230.mp3",
    "rows_updated": 1
  }
}
```

## Database Schema

### job_brief_table
```sql
ALTER TABLE job_brief_table 
ADD COLUMN call_recording VARCHAR(500) NULL 
AFTER call_status_feedback;
```

## Features

✅ **File Upload**
- Select audio files from device storage
- Support for all common audio formats
- File size validation
- Progress indicator during upload

✅ **Database Integration**
- Automatic URL storage in job_brief_table
- Links recording to specific job and transporter
- Updates most recent job brief entry

✅ **Error Handling**
- File selection errors
- Upload failures
- Network issues
- Database update failures

✅ **User Feedback**
- Success messages
- Error messages with details
- Upload progress indication
- File name display

## Testing

1. Run setup script: `add_job_brief_recording_column.php`
2. Open Phase 2 app
3. Navigate to Jobs screen
4. Call a transporter
5. Select "Connected: Details Received"
6. Fill job brief form
7. Upload a recording file
8. Submit form
9. Verify recording URL in database

## Notes

- Recording upload is **optional** - form can be submitted without it
- Upload happens **before** form submission
- Multiple uploads will overwrite previous recording for same job brief
- Files are stored with unique timestamps to prevent conflicts
- Directory is created automatically if it doesn't exist
- Permissions are set to 0755 for proper access

## Related Files

- `api/phase2_upload_transporter_recording_api.php` - Upload API
- `api/add_job_brief_recording_column.php` - Setup script
- `Phase_2-/lib/features/jobs/widgets/job_brief_feedback_modal.dart` - UI
- `Phase_2-/lib/core/services/phase2_api_service.dart` - API service

## Deployment Checklist

- [ ] Upload `phase2_upload_transporter_recording_api.php` to server
- [ ] Run `add_job_brief_recording_column.php` to setup database
- [ ] Verify directory permissions (0755)
- [ ] Test file upload from app
- [ ] Verify URL saved in database
- [ ] Check file accessible via URL
- [ ] Test with different audio formats

---

**Status:** ✅ Complete and Ready for Testing
**Date:** November 5, 2025
