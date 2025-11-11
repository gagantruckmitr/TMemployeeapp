# Transporter Call Recording Upload Fix

## Problem
When telecallers uploaded call recordings in the job brief feedback form, the recordings were:
1. Not being stored in the correct directory (`https://truckmitr.com/truckmitr-app/Match-making_call_recording/transporter/`)
2. Not saving the URL in the database

## Root Causes
1. **Missing Database Column**: The `job_brief_table` didn't have a `call_recording` column
2. **Wrong Upload Flow**: Recording was uploaded BEFORE the job brief was saved, so there was no database record to update
3. **API Not Handling Recording URL**: The job brief API wasn't accepting or saving the `callRecording` parameter

## Solution

### 1. Database Schema Update
**File**: `api/add_call_recording_column_to_job_brief.php` (NEW)
- Added script to create `call_recording` column in `job_brief_table`
- Run this once on the server to add the column

### 2. Updated Job Brief API
**File**: `api/phase2_job_brief_api.php`
- Added `call_recording` field to INSERT query in `saveJobBrief()`
- Added `call_recording` field to UPDATE query in `updateJobBrief()`
- Added `callRecording` to response in `formatJobBriefRow()`

### 3. Updated Upload API
**File**: `api/phase2_upload_transporter_recording_api.php`
- Removed database update logic (no longer needed)
- Now only uploads file and returns URL
- Database will be updated when job brief is saved

### 4. Updated Flutter App
**File**: `Phase_2-/lib/features/jobs/widgets/job_brief_feedback_modal.dart`
- Changed flow: Upload recording FIRST, then save job brief with URL
- Removed separate "Upload Recording" button
- Recording now uploads automatically when form is submitted
- Added `dart:convert` import for JSON parsing

**File**: `Phase_2-/lib/core/services/phase2_api_service.dart`
- Added `callRecording` parameter to `saveJobBrief()` method
- Added `callRecording` parameter to `updateJobBrief()` method

## New Flow

1. User selects recording file (optional)
2. User fills out job brief form
3. User clicks "Submit Feedback"
4. **IF recording selected**: Upload recording to server, get URL
5. Save job brief with all data INCLUDING recording URL
6. Both file and URL are now properly saved

## Deployment Steps

1. **Upload updated PHP files**:
   - `api/add_call_recording_column_to_job_brief.php`
   - `api/phase2_job_brief_api.php`
   - `api/phase2_upload_transporter_recording_api.php`

2. **Run database migration**:
   ```
   https://truckmitr.com/truckmitr-app/api/add_call_recording_column_to_job_brief.php
   ```

3. **Verify directory exists and is writable**:
   ```
   /truckmitr-app/Match-making_call_recording/transporter/
   ```
   - Permissions: 0755

4. **Deploy Flutter app** with updated code

## Testing

1. Open job brief feedback form
2. Select a call recording file
3. Fill out form fields
4. Submit form
5. Verify:
   - File uploaded to `/Match-making_call_recording/transporter/`
   - URL saved in `job_brief_table.call_recording` column
   - Success message shows "Job brief and recording saved successfully"

## Files Changed

### Backend (PHP)
- `api/add_call_recording_column_to_job_brief.php` (NEW)
- `api/phase2_job_brief_api.php` (MODIFIED)
- `api/phase2_upload_transporter_recording_api.php` (MODIFIED)

### Frontend (Flutter)
- `Phase_2-/lib/features/jobs/widgets/job_brief_feedback_modal.dart` (MODIFIED)
- `Phase_2-/lib/core/services/phase2_api_service.dart` (MODIFIED)

## Benefits

✅ Recording files stored in correct directory
✅ Recording URLs saved in database
✅ Simplified user experience (no separate upload button)
✅ Atomic operation (recording + job brief saved together)
✅ Better error handling
✅ Consistent with driver recording upload flow
