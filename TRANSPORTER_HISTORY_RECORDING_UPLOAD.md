# Transporter History Recording Upload Feature

## Summary
Added recording upload functionality to the transporter history section's feedback edit form. Telecallers can now upload call recordings when editing transporter job briefs in the call history hub.

## Changes Made

### 1. Call History Screen (`call_history_screen.dart`)
- Added recording upload support to the edit feedback modal
- Created new `_EditCallFeedbackModal` widget with file picker integration
- Supports both driver and transporter recording uploads
- Updated `_showEditFeedbackModal` to use the new modal

### 2. Call Feedback Modal (`call_feedback_modal.dart`)
- Extended recording upload to support both drivers AND transporters
- Modified `_submitFeedback` to handle transporter recordings
- Changed condition from `if (widget.userType == 'driver' && widget.jobId != null)` to `if (widget.jobId != null)` to allow all user types

### 3. API Service (`phase2_api_service.dart`)
- Updated `updateCallLog` method to support recording file uploads
- Added `uploadTransporterCallRecording` method
- Added generic `uploadCallRecording` method that supports both drivers and transporters
- Enhanced `updateCallLog` to upload recording before updating the log

### 4. Transporter Call History Screen (`transporter_call_history_screen.dart`)
- Replaced simple `_EditCallRecordDialog` with comprehensive `_EditJobBriefModal`
- Added full job brief form with all fields (salary, benefits, vehicle details, etc.)
- Integrated recording upload functionality
- Added file picker for selecting audio files
- Supports multiple audio formats (MP3, WAV, M4A, AAC, OGG, FLAC, WMA, AMR, OPUS, 3GP)

### 5. Backend API (`phase2_upload_driver_recording_api.php`)
- Updated to support both driver and transporter recordings
- Added `transporter_tmid` parameter support
- Modified validation to accept either `driver_tmid` OR `transporter_tmid`
- Automatically determines user type based on provided TMID

## Features

### Recording Upload
- **File Selection**: Telecallers can select audio files from device storage
- **Multiple Formats**: Supports all common audio formats
- **Optional Upload**: Recording upload is optional when editing
- **Visual Feedback**: Shows selected file name and upload status
- **Error Handling**: Gracefully handles upload failures

### Job Brief Edit Form
- **Comprehensive Fields**: All job brief fields are editable
- **Pre-filled Data**: Existing data is automatically loaded
- **Validation**: Required fields are validated
- **Organized Sections**: Fields grouped into logical sections:
  - Basic Information
  - Vehicle & License
  - Salary Details
  - Benefits & Allowances
  - Other Details
  - Call Recording

### User Experience
- **Bottom Sheet Modal**: Modern, user-friendly interface
- **Scrollable Form**: Easy navigation through all fields
- **Loading States**: Clear feedback during submission
- **Success Messages**: Confirmation when updates are saved
- **Error Messages**: Clear error reporting

## Usage

1. Navigate to Call History Hub → Transporters tab
2. Select a transporter to view their call history
3. Click the edit icon on any call record
4. The comprehensive job brief edit form opens
5. Update any fields as needed
6. Optionally select a call recording file
7. Click "Update & Upload Recording" or "Update Job Brief"
8. Recording is uploaded (if selected) and job brief is updated

## Technical Details

### API Endpoints Used
- `phase2_upload_driver_recording_api.php` - Handles both driver and transporter recordings
- `phase2_job_brief_api.php?action=update` - Updates job brief data

### Data Flow
1. User selects recording file (optional)
2. If recording selected, upload to server first
3. Get recording URL from upload response
4. Update job brief with new data and recording URL
5. Refresh call history list

### Recording URL Storage
- Recordings are stored in: `/truckmitr-app/Match-making_call_recording/driver/`
- URL format: `https://truckmitr.com/truckmitr-app/Match-making_call_recording/driver/{filename}`
- Filename format: `{jobId}_{callerId}_{timestamp}.{extension}`

## Benefits

1. **Complete Functionality**: Telecallers can now upload recordings for transporter calls
2. **Consistent Experience**: Same recording upload feature across driver and transporter calls
3. **Better Documentation**: All call details and recordings in one place
4. **Improved Tracking**: Full audit trail of transporter interactions
5. **Enhanced Reporting**: Recording URLs stored in database for playback

## Future Enhancements

- Add recording playback directly in the edit form
- Support recording replacement (delete old, upload new)
- Add recording duration display
- Implement recording compression before upload
- Add recording quality indicators
