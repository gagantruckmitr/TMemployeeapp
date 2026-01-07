# Job Applicants Rejection Feature

## Overview
Added rejection functionality to the Job Applicants screen, allowing telecallers to reject driver applications for specific jobs.

## Changes Made

### 1. UI Changes (lib/features/jobs/job_applicants_screen.dart)
- Added a "Reject" button to each driver card in the job applicants list
- Button appears between "Jobs" info button and "Call" button
- Red-themed button with cancel icon for clear visual indication
- Shows confirmation dialog before rejection with:
  - Driver and job details
  - Multi-line text field for rejection reason (optional)
  - Cancel and Reject action buttons

### 2. Functionality Added
- `_showRejectConfirmation()`: Shows confirmation dialog with:
  - Driver and job details display
  - Multi-line text field for rejection reason
  - Proper controller disposal on cancel/submit
- `_rejectApplicant()`: Handles the rejection process
  - Accepts optional reason parameter
  - Calls API to update database with reason
  - Updates local state with "Not Selected" match status
  - Shows success/error feedback to user

### 3. API Service (lib/core/services/phase2_api_service.dart)
- Added `rejectJobApplicant()` method
- Sends rejection request with:
  - callerId (telecaller ID)
  - driverId (numeric driver ID)
  - jobId (numeric job ID)
  - driverTmid (driver unique ID)
  - jobIdString (job ID string like TMJB00418)
  - reason (optional rejection reason text)

### 4. Backend API (api/phase2_reject_applicant_api.php)
- New endpoint to handle rejection requests
- Accepts and processes rejection reason
- Updates two tables in a transaction:
  1. **applyjobs table**: Sets status to 'Rejected'
  2. **call_logs_match_making table**: 
     - Updates existing record with match_status = 'Not Selected'
     - OR inserts new record if none exists
     - Matches by job_id (string format like TMJB00418)
     - Stores rejection reason in remark field with timestamp
- Ensures data consistency with transaction rollback on error

## Key Features
✅ Matches job_id correctly (uses string format TMJB00418 for call_logs_match_making)
✅ Updates match_status to "Not Selected" 
✅ Updates applyjobs status to "Rejected"
✅ Optional rejection reason field with multi-line input
✅ Reason stored in database with timestamp
✅ Transaction-based updates for data consistency
✅ Confirmation dialog prevents accidental rejections
✅ Visual feedback with color-coded status
✅ Local state updates for immediate UI refresh
✅ Proper text controller disposal to prevent memory leaks

## Database Updates
- **applyjobs.status**: Set to 'Rejected'
- **call_logs_match_making.match_status**: Set to 'Not Selected'
- **call_logs_match_making.feedback**: Set to 'Not Selected'
- **call_logs_match_making.remark**: Stores rejection with timestamp and reason
  - Format: "Rejected by telecaller on YYYY-MM-DD HH:MM:SS. Reason: [reason text]"
  - If no reason provided: "Rejected by telecaller on YYYY-MM-DD HH:MM:SS"

## Testing
1. Open Job Applicants screen for any job
2. Click "Reject" button on a driver card
3. In the rejection dialog:
   - Enter a rejection reason (optional)
   - Click "Reject" to confirm or "Cancel" to abort
4. Verify:
   - Card updates with red "Not Selected" status
   - Database shows status='Rejected' in applyjobs
   - Database shows match_status='Not Selected' in call_logs_match_making
   - Correct job_id is matched (string format)
   - Rejection reason appears in remark field with timestamp
5. Test without reason to ensure it works with empty reason field
