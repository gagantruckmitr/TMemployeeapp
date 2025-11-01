# Call Recording Upload Feature - Complete Implementation

## Overview
Call recording upload functionality has been successfully implemented for the call feedback modal. Recordings are uploaded to the server with a specific naming format and the URL is stored in the database.

## Implementation Details

### 1. File Upload Location
- **Server Path**: `https://truckmitr.com/truckmitr-app/voice-recording/`
- **Filename Format**: `TMID_CallerID_DateTime.ext`
  - Example: `TM123456_5_20241101143025.mp3`
- **Database Storage**: URL stored in `call_logs.manual_call_recording_url` column

### 2. Frontend Changes

#### CallFeedbackModal Widget (`lib/features/telecaller/widgets/call_feedback_modal.dart`)
- Added file picker integration using `file_picker` package
- Added recording upload UI section with:
  - Upload button with cloud icon
  - File preview with name and remove option
  - Required/Optional badge based on context
- Added state management for:
  - `_selectedRecording`: File object
  - `_recordingFileName`: Display name
  - `_isPickingFile`: Loading state
- File validation:
  - Audio files only
  - Max size: 50MB
- Recording file passed in `CallFeedback` object

#### CallFeedback Model (`lib/models/smart_calling_models.dart`)
- Added `recordingFile` field (dynamic type to hold File object)
- Field is optional and can be null

#### Call History Screen (`lib/features/telecaller/screens/call_history_screen.dart`)
- Updated `_updateFeedback` method to handle recording upload
- Uploads recording before updating feedback
- Shows error message if upload fails
- Uses current user ID as caller ID
- Uses driver ID as TMID

### 3. Backend API

#### Upload Recording API (`api/upload_recording_api.php`)
- **Endpoint**: `POST /api/upload_recording_api.php`
- **Parameters**:
  - `tmid`: Driver TMID
  - `caller_id`: Telecaller ID
  - `call_log_id`: Call log entry ID (optional)
  - `recording`: Audio file (multipart/form-data)
- **Validations**:
  - File type: Audio files only (mp3, wav, m4a, aac, ogg)
  - File size: Max 50MB
- **Process**:
  1. Validates file type and size
  2. Generates filename: `{TMID}_{CallerID}_{DateTime}.{ext}`
  3. Saves to `/voice-recording/` directory
  4. Updates `call_logs.manual_call_recording_url` if `call_log_id` provided
  5. Returns success with URL
- **Response**:
  ```json
  {
    "success": true,
    "message": "Recording uploaded successfully",
    "filename": "TM123456_5_20241101143025.mp3",
    "url": "https://truckmitr.com/truckmitr-app/voice-recording/TM123456_5_20241101143025.mp3",
    "size": 1234567,
    "timestamp": "2024-11-01 14:30:25"
  }
  ```

### 4. Service Layer

#### ApiService (`lib/core/services/api_service.dart`)
- Added `uploadCallRecording` method
- Uses `http.MultipartRequest` for file upload
- Handles multipart/form-data encoding
- 5-minute timeout for large files
- Returns upload result with URL

#### SmartCallingService (`lib/core/services/smart_calling_service.dart`)
- Added `uploadCallRecording` wrapper method
- Delegates to ApiService
- Handles errors gracefully

## Usage

### In Call Feedback Modal
```dart
CallFeedbackModal(
  contact: driverContact,
  referenceId: callLogId,
  callDuration: duration,
  allowDismiss: true,
  requireRecording: false, // Set to true to make recording mandatory
  onFeedbackSubmitted: (feedback) async {
    // feedback.recordingFile contains the File object if uploaded
    await handleFeedback(feedback);
  },
)
```

### Recording Upload Flow
1. User taps "Upload Call Recording" button
2. File picker opens (audio files only)
3. User selects audio file
4. File is validated (type and size)
5. File preview shown with remove option
6. On submit, recording is uploaded first
7. Then feedback is saved with recording URL

## Database Schema

### call_logs Table
```sql
-- Column for manually uploaded call recordings
ALTER TABLE call_logs 
ADD COLUMN manual_call_recording_url VARCHAR(500) NULL 
AFTER recording_url
COMMENT 'URL of manually uploaded call recording';
```

**Note**: The API automatically creates this column if it doesn't exist.

**Column Purpose**:
- `recording_url` - For IVR/MyOperator automatic recordings
- `manual_call_recording_url` - For manually uploaded recordings via the app

## Features

### User Experience
- ✅ Visual upload button with cloud icon
- ✅ File preview with name and size
- ✅ Remove/replace recording option
- ✅ Required/Optional badge
- ✅ Loading state during file selection
- ✅ Error messages for invalid files
- ✅ Success confirmation after upload

### Validation
- ✅ Audio file type validation
- ✅ 50MB file size limit
- ✅ MIME type checking
- ✅ Graceful error handling

### Integration
- ✅ Works with call history feedback
- ✅ Works with smart calling feedback
- ✅ Optional or required based on context
- ✅ URL stored in database automatically

## Testing

### Test Cases
1. ✅ Upload valid audio file (mp3, wav, m4a)
2. ✅ Reject non-audio files
3. ✅ Reject files over 50MB
4. ✅ Remove selected recording
5. ✅ Submit feedback without recording (when optional)
6. ✅ Submit feedback with recording
7. ✅ Handle upload errors gracefully
8. ✅ Verify URL stored in database

## Notes

- Recording upload is **optional** by default in call history
- Can be made **required** in smart calling by setting `requireRecording: true`
- Filename format ensures uniqueness with timestamp
- Server automatically creates upload directory if missing
- Upload timeout is 5 minutes to handle large files
- Recording URL is immediately available after upload

## Future Enhancements

Potential improvements:
- Audio playback preview before upload
- Recording duration display
- Compression for large files
- Progress indicator during upload
- Retry mechanism for failed uploads
- Recording deletion option
