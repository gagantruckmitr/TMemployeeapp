# Driver Call Recording Upload Feature

## Overview
Complete implementation of call recording upload functionality for driver calls in the match-making system.

## Features Implemented

### 1. Backend API (`api/phase2_upload_driver_recording_api.php`)
- Accepts audio file uploads (MP3, WAV, M4A, AAC, OGG)
- Filename format: `{jobId}_{callerId}_{datetime}.{extension}`
- Saves to: `https://truckmitr.com/truckmitr-app/Match-making_call_recording/driver/`
- Updates `call_logs_match_making` table's `call_recording` column
- Returns recording URL on success

### 2. Flutter Dependencies
Added to `pubspec.yaml`:
- `file_picker: ^6.1.1` - For selecting audio files
- `path: ^1.8.3` - For path operations

### 3. API Service Method
Added to `Phase2ApiService`:
```dart
uploadDriverCallRecording({
  required String filePath,
  required String jobId,
  required int callerId,
  required String driverTmid,
})
```

### 4. UI Implementation
Enhanced `CallFeedbackModal` with:
- File picker button for selecting recordings
- Upload progress indicator
- File name display with remove option
- Upload button with loading state
- Only shows for driver calls with jobId

## Usage Flow

1. **Telecaller makes call** to driver from Job Applicants screen
2. **Call feedback modal opens** after call
3. **Telecaller selects feedback** (Connected, Call Back, etc.)
4. **Optional: Upload recording**
   - Click "Select Recording File"
   - Choose audio file from device
   - Click "Upload Recording"
   - Wait for upload confirmation
5. **Submit feedback** - Saves feedback and recording URL to database

## Database Schema
The recording URL is saved in:
- Table: `call_logs_match_making`
- Column: `call_recording`
- Format: Full URL to the uploaded file

## File Storage
- Location: `/truckmitr-app/Match-making_call_recording/driver/`
- Naming: `TMJB00424_123_20250105131400.mp3`
  - Job ID: TMJB00424
  - Caller ID: 123
  - DateTime: 2025-01-05 13:14:00
  - Extension: mp3

## Error Handling
- Invalid file types rejected
- Upload failures show error message
- Network errors handled gracefully
- File size limits enforced by server

## Security
- Only authenticated users can upload
- File type validation on server
- Directory permissions set to 0755
- SQL injection prevention with prepared statements

## Testing Checklist
- [ ] Select audio file from device
- [ ] Upload recording successfully
- [ ] View uploaded recording URL in database
- [ ] Handle upload errors gracefully
- [ ] Test with different audio formats
- [ ] Verify file naming convention
- [ ] Check file permissions on server
- [ ] Test with large files
- [ ] Verify database update

## Future Enhancements
- Audio playback in app
- Recording duration display
- Compression before upload
- Multiple recordings per call
- Recording transcription
