# Transporter Feedback Save Fix

## Issue
Transporter feedback from dynamic job cards was not being saved to the database. When telecallers called transporters from job postings and submitted feedback through the call feedback modal, the data was not persisting.

## Root Cause
In `lib/features/jobs/widgets/modern_job_card.dart`, the `_showTransporterCallFeedbackAfterIVR()` method was calling `Phase2ApiService.saveJobBrief()` but:

1. **Missing Notes**: The `notes` parameter from the feedback modal was not being passed to the API
2. **Missing Recording Upload**: The `recordingFile` was not being uploaded before saving the feedback
3. **Incomplete Data**: Only `callStatusFeedback` was being sent, without the caller information and other context

## Solution

### Changes Made

#### 1. Updated `modern_job_card.dart`
Modified the `_showTransporterCallFeedbackAfterIVR()` method to:

- **Get caller information**: Retrieve the current user's ID to include as `callerId`
- **Upload recording file**: If a recording file is provided, upload it first using `Phase2ApiService.uploadTransporterCallRecording()`
- **Include notes in feedback**: Append notes to the call status feedback string
- **Pass complete data**: Send all required fields including `callerId`, `name`, `callStatusFeedback`, and `callRecording`

```dart
// Get current user for caller_id
final user = await Phase2AuthService.getCurrentUser();
final callerId = user?.id ?? 0;

// Upload recording file if provided
String? recordingUrl;
if (recordingFile != null) {
  try {
    final uploadResult = await Phase2ApiService.uploadTransporterCallRecording(
      filePath: recordingFile.path,
      jobId: widget.job.jobId,
      callerId: callerId,
      transporterTmid: widget.job.transporterTmid,
    );
    recordingUrl = uploadResult['recording_url'];
  } catch (e) {
    print('Recording upload failed: $e');
    // Continue with feedback submission even if recording fails
  }
}

// Build the complete feedback string with notes if provided
String completeFeedback = callStatus;
if (notes != null && notes.isNotEmpty) {
  completeFeedback = '$callStatus - Notes: $notes';
}

// Save job brief with feedback, notes, and recording
await Phase2ApiService.saveJobBrief(
  uniqueId: widget.job.transporterTmid,
  jobId: widget.job.jobId,
  callerId: callerId,
  name: widget.job.transporterName,
  callStatusFeedback: completeFeedback,
  callRecording: recordingUrl,
);
```

## Database Schema

The feedback is saved to the `job_brief_table` with the following key fields:

- `unique_id`: Transporter TMID
- `job_id`: Job posting ID
- `caller_id`: Telecaller user ID
- `name`: Transporter name
- `call_status_feedback`: Call status with notes (e.g., "Connected: Call Back Later - Notes: Will call tomorrow")
- `call_recording`: URL to uploaded recording file (if provided)
- `closed_job`: Auto-set to 1 for certain feedback types (Not a Transporter, Close Job, etc.)
- `created_at`: Timestamp of first save
- `updated_at`: Timestamp of last update

## API Behavior

The `phase2_job_brief_api.php` API:

1. **Upsert Logic**: Checks if a record exists for the `unique_id` + `job_id` combination
   - If exists: Updates the existing record
   - If not: Inserts a new record

2. **Auto-Close Jobs**: Automatically sets `closed_job = 1` when feedback contains:
   - "Not a Transporter"
   - "He is Driver, mistakenly registered as Transporter"
   - "Close Job"

3. **Caller Filtering**: Each telecaller only sees their own call history (filtered by `caller_id`)

## Testing

### Manual Testing Steps

1. Open the app and navigate to Job Postings
2. Find a job assigned to you
3. Click the call button on a job card
4. Select call type (Manual or EasyGo IVR)
5. After the call, the feedback modal should appear
6. Select a call status (e.g., "Connected: Call Back Later")
7. Add optional notes (e.g., "Will call back tomorrow at 10 AM")
8. Optionally upload a call recording
9. Submit the feedback
10. Verify in the database that the record was saved in `job_brief_table`

### Automated Testing

**Step 1: Check if the table exists**

```bash
# Via browser
https://truckmitr.com/truckmitr-app/api/check_job_brief_table.php
```

This will show:
- If the table exists
- Table structure
- Sample data
- Record counts

**Step 2: Run the direct database test**

```bash
# Via browser
https://truckmitr.com/truckmitr-app/api/test_transporter_feedback_direct.php
```

The test verifies:
- Database connection is working
- Records can be inserted with feedback and notes
- Records can be updated
- All fields are saved correctly
- Call recordings can be attached

### Database Verification

```sql
-- Check recent feedback entries
SELECT 
    id,
    unique_id,
    job_id,
    caller_id,
    name,
    call_status_feedback,
    call_recording,
    closed_job,
    created_at,
    updated_at
FROM job_brief_table
ORDER BY created_at DESC
LIMIT 10;

-- Check feedback for a specific transporter
SELECT * FROM job_brief_table 
WHERE unique_id = 'TM12345'
ORDER BY created_at DESC;

-- Check feedback for a specific job
SELECT * FROM job_brief_table 
WHERE job_id = 'JOB001'
ORDER BY created_at DESC;
```

## Files Modified

1. `lib/features/jobs/widgets/modern_job_card.dart` - Fixed feedback submission logic
2. `api/test_transporter_feedback_save.php` - Created test file for verification

## Files Referenced (No Changes)

- `lib/features/jobs/widgets/transporter_call_feedback_modal.dart` - Feedback modal UI
- `lib/features/jobs/widgets/show_transporter_call_feedback.dart` - Helper function
- `lib/core/services/phase2_api_service.dart` - API service methods
- `api/phase2_job_brief_api.php` - Backend API endpoint

## Impact

- ✅ Transporter feedback is now properly saved to the database
- ✅ Notes from telecallers are preserved
- ✅ Call recordings can be uploaded and linked to feedback
- ✅ Caller information is tracked for each feedback entry
- ✅ Job closure logic works correctly for specific feedback types
- ✅ Each telecaller can see their own call history

## Future Enhancements

1. Add feedback history view in the app to show previous calls to the same transporter
2. Add analytics dashboard for transporter feedback trends
3. Add notification system for follow-up calls (e.g., "Call Back Later" reminders)
4. Add bulk feedback export functionality
5. Add feedback templates for common scenarios

## Related Documentation

- `api/JOB_BRIEF_API_DOCUMENTATION.md` - Complete API documentation
- `TELECALLER_SCREENS_IVR_COMPLETE_FIX.md` - IVR integration documentation
- `TRANSPORTER_SMART_CALLING_IMPLEMENTATION.md` - Smart calling feature documentation
