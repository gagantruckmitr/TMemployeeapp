# Call Recording Playback Feature

## Overview
Telecallers can now listen to call recordings directly from the call history screen. A play button appears on call history cards when a recording is available.

## Features

### 1. Recording Availability Indicator
- Play button only shows when recording exists
- Supports both IVR recordings and manually uploaded recordings
- Priority: Manual recordings shown first, then IVR recordings

### 2. Audio Playback Controls
- **Play/Pause Button**: Toggle playback with a single tap
- **Loading State**: Shows spinner while loading audio
- **Visual Feedback**: Icon changes between play and pause states
- **Error Handling**: Shows error message if playback fails

### 3. Recording Sources
The system checks for recordings in this order:
1. **Manual Call Recording** (`manual_call_recording_url`) - User uploaded
2. **IVR Recording** (`recording_url`) - System generated

## Implementation Details

### Frontend Changes

#### 1. Call History Screen (`lib/features/telecaller/screens/call_history_screen.dart`)

**Added Audio Player**:
```dart
import 'package:audioplayers/audioplayers.dart';

class _CallHistoryCardState extends State<_CallHistoryCard> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  bool _isLoading = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  
  // Audio player listeners and controls
}
```

**CallHistoryEntry Model Updated**:
```dart
class CallHistoryEntry {
  final String? recordingUrl;
  final String? manualCallRecordingUrl;
  
  // Helper methods
  String? get anyRecordingUrl => manualCallRecordingUrl ?? recordingUrl;
  bool get hasRecording => anyRecordingUrl != null && anyRecordingUrl!.isNotEmpty;
}
```

**Play Button UI**:
- Appears as a purple circular icon button
- Shows play icon when stopped
- Shows pause icon when playing
- Shows loading spinner when buffering

#### 2. Dependencies (`pubspec.yaml`)
Added audio player package:
```yaml
dependencies:
  audioplayers: ^6.0.0
```

### Backend Changes

#### Call History API (`api/call_history_api.php`)
Updated to return recording URLs:
```php
SELECT 
  cl.recording_url,
  cl.manual_call_recording_url,
  // ... other fields
FROM call_logs cl
```

Response includes:
```json
{
  "recording_url": "https://myoperator.com/recordings/call_123.mp3",
  "manual_call_recording_url": "https://truckmitr.com/truckmitr-app/voice-recording/TM123_5_20241101143025.mp3"
}
```

## User Interface

### Call History Card Layout
```
┌─────────────────────────────────────────┐
│ [Icon] Driver Name                      │
│        Phone Number                     │
│                                         │
│ Status Badge    Duration    Time Ago   │
│                                         │
│ Feedback: [Details]                    │
│ Remarks: [Details]                     │
│                                         │
│ [Call] [Update] [▶ Play]              │
└─────────────────────────────────────────┘
```

### Play Button States

**1. No Recording Available**:
- Button hidden
- Only Call and Update buttons visible

**2. Recording Available (Stopped)**:
- Purple play circle icon (▶)
- Tooltip: "Play Recording"

**3. Recording Playing**:
- Purple pause circle icon (⏸)
- Tooltip: "Pause Recording"

**4. Loading**:
- Small circular progress indicator
- Button disabled

## Usage Flow

### For Telecallers

1. **View Call History**:
   - Navigate to Call History screen
   - See list of past calls

2. **Identify Recordings**:
   - Look for play button on call cards
   - Play button only appears if recording exists

3. **Play Recording**:
   - Tap play button (▶)
   - Audio starts playing
   - Icon changes to pause (⏸)

4. **Pause Recording**:
   - Tap pause button (⏸)
   - Audio pauses
   - Icon changes back to play (▶)

5. **Continue Other Actions**:
   - Can still make calls
   - Can still update feedback
   - Audio plays in background

## Technical Details

### Audio Player Features
- **Streaming**: Plays directly from URL (no download needed)
- **Background Play**: Continues playing while using other features
- **Auto-cleanup**: Properly disposed when card is removed
- **Error Handling**: Shows user-friendly error messages

### Performance
- **Lazy Loading**: Audio only loads when play is pressed
- **Memory Efficient**: One player instance per card
- **Network Efficient**: Streams audio, doesn't download entire file

### Supported Audio Formats
- MP3
- WAV
- M4A
- AAC
- OGG

## Error Handling

### Common Errors

**1. Network Error**:
```
"Failed to play recording: Network error"
```
- Check internet connection
- Verify recording URL is accessible

**2. File Not Found**:
```
"Failed to play recording: File not found"
```
- Recording may have been deleted
- URL may be incorrect

**3. Unsupported Format**:
```
"Failed to play recording: Unsupported format"
```
- File format not supported by audio player
- Convert to supported format

## Database Schema

### call_logs Table
```sql
CREATE TABLE call_logs (
  id INT PRIMARY KEY AUTO_INCREMENT,
  -- ... other fields
  
  -- IVR/MyOperator automatic recording
  recording_url VARCHAR(500) NULL,
  
  -- Manually uploaded recording
  manual_call_recording_url VARCHAR(500) NULL,
  
  -- ... other fields
);
```

## Testing

### Test Cases

1. ✅ **Play Recording**:
   - Tap play button
   - Audio should start playing
   - Icon should change to pause

2. ✅ **Pause Recording**:
   - While playing, tap pause
   - Audio should pause
   - Icon should change to play

3. ✅ **No Recording**:
   - View call without recording
   - Play button should not appear

4. ✅ **Manual Recording Priority**:
   - Call has both recordings
   - Should play manual recording first

5. ✅ **Error Handling**:
   - Invalid URL
   - Should show error message

6. ✅ **Multiple Cards**:
   - Play recording on one card
   - Other cards should not be affected

## Future Enhancements

Potential improvements:
- Progress bar showing playback position
- Playback speed control (0.5x, 1x, 1.5x, 2x)
- Download recording option
- Share recording option
- Waveform visualization
- Timestamp markers for important moments
- Transcription display

## Notes

- Only one recording plays at a time per card
- Audio continues playing when scrolling
- Audio stops when card is disposed
- Works with both WiFi and mobile data
- Minimal battery impact

## Summary

The call recording playback feature provides telecallers with easy access to call recordings directly from the call history screen. With simple play/pause controls and automatic detection of available recordings, telecallers can quickly review past conversations without leaving the app.
