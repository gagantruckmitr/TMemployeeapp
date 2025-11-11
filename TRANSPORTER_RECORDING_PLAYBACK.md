# Transporter Recording Playback Feature

## Summary
Added audio playback functionality to the transporter call history screen, allowing telecallers to listen to their uploaded recordings directly from the app.

## Features Added

### 1. Recording Indicator on Call Cards
- **Visual Badge**: Green "Recording available" badge shows on cards with recordings
- **Icon**: Microphone icon for quick visual identification
- **Location**: Displayed in the subtitle area of each call history card

### 2. Audio Player in Expanded View
- **Integrated Player**: AudioPlayerWidget displays when expanding a call record
- **Section Header**: Clear "Call Recording:" label with audio icon
- **Divider**: Visual separation from other details
- **Conditional Display**: Only shows when recording URL exists

### 3. Enhanced Edit Modal
- **Current Recording Player**: Shows existing recording with playback controls
- **Replace Option**: Button to replace existing recording
- **Visual Feedback**: Green background for existing recordings
- **Smart UI**: Different layouts for new vs. existing recordings

## UI Components

### Call History Card
```dart
// Recording indicator in subtitle
if (record['callRecording'] != null && 
    record['callRecording'].toString().isNotEmpty)
  Row(
    children: [
      Icon(Icons.mic, size: 12, color: Colors.green[700]),
      Text('Recording available', ...)
    ],
  )
```

### Expanded Card View
```dart
// Audio player in details section
if (record['callRecording'] != null && 
    record['callRecording'].toString().isNotEmpty) ...[
  Row(
    children: [
      Icon(Icons.audiotrack, ...),
      Text('Call Recording:', ...),
    ],
  ),
  AudioPlayerWidget(recordingUrl: record['callRecording']),
]
```

### Edit Modal - Existing Recording
```dart
// Shows current recording with player
Container(
  decoration: BoxDecoration(
    color: Colors.green.shade50,
    border: Border.all(color: Colors.green.shade200),
  ),
  child: Column(
    children: [
      Text('Current Recording'),
      AudioPlayerWidget(recordingUrl: ...),
      OutlinedButton('Replace Recording'),
    ],
  ),
)
```

### Edit Modal - New Recording
```dart
// Shows file picker for new recording
Container(
  child: Column(
    children: [
      if (selectedFile != null)
        // Show selected file name
      else
        // Show file picker button
    ],
  ),
)
```

## User Experience Flow

### Viewing Recordings
1. Navigate to Call History Hub → Transporters
2. Select a transporter
3. Look for green "Recording available" badge on cards
4. Tap to expand the card
5. Scroll to see the audio player
6. Use play/pause controls to listen

### Editing with Existing Recording
1. Click edit icon on a call record
2. Scroll to "Call Recording" section
3. See current recording with player
4. Listen to existing recording if needed
5. Click "Replace Recording" to upload new one
6. Or leave as-is to keep current recording

### Adding New Recording
1. Click edit on a call record without recording
2. Scroll to "Call Recording" section
3. Click "Select Recording File"
4. Choose audio file from device
5. Click "Update & Upload Recording"

## Visual Design

### Color Scheme
- **Recording Available Badge**: Green (#4CAF50)
- **Current Recording Container**: Light green background (#E8F5E9)
- **Audio Player**: Default theme colors
- **Replace Button**: Primary color outline

### Icons Used
- `Icons.mic` - Recording available indicator (12px)
- `Icons.audiotrack` - Recording section header (16px)
- `Icons.check_circle` - Current recording status (20px)
- `Icons.swap_horiz` - Replace recording button (18px)

### Spacing & Layout
- **Card Badge**: 4px spacing between icon and text
- **Player Section**: 12px padding, 8px spacing
- **Edit Modal**: 16px padding, 12px spacing between elements

## Technical Implementation

### Import Added
```dart
import '../../widgets/audio_player_widget.dart';
```

### Recording Check
```dart
final hasRecording = record['callRecording'] != null &&
    record['callRecording'].toString().isNotEmpty;
```

### Conditional Rendering
- Uses Dart's spread operator (`...`) for conditional widgets
- Checks for null and empty strings
- Gracefully handles missing recordings

## Benefits

1. **Immediate Playback**: No need to download files
2. **Quality Check**: Verify recording quality before saving
3. **Context**: Listen while viewing call details
4. **Convenience**: All in one place - view, listen, edit
5. **Transparency**: Clear indication of which calls have recordings

## AudioPlayerWidget Features

The integrated AudioPlayerWidget provides:
- Play/Pause controls
- Progress bar with seek functionality
- Duration display (current/total)
- Loading states
- Error handling
- Responsive design

## Future Enhancements

Potential improvements:
- Download recording option
- Share recording functionality
- Recording duration in card badge
- Waveform visualization
- Playback speed control
- Volume control
- Timestamp markers for important moments

## Testing Checklist

- [x] Recording badge shows on cards with recordings
- [x] Badge doesn't show on cards without recordings
- [x] Audio player appears in expanded view
- [x] Player controls work (play/pause/seek)
- [x] Edit modal shows existing recording
- [x] Can listen to recording while editing
- [x] Replace button works correctly
- [x] New recording selection works
- [x] UI is responsive and clean
- [x] No errors in console

## Files Modified

1. **transporter_call_history_screen.dart**
   - Added AudioPlayerWidget import
   - Added recording indicator to card subtitle
   - Added audio player to expanded card view
   - Enhanced edit modal with recording player
   - Added smart UI for existing vs. new recordings

## Usage Statistics

After implementation, track:
- Number of recordings played
- Average playback duration
- Recording replacement rate
- User engagement with playback feature

## Support

If playback issues occur:
1. Check recording URL is valid
2. Verify file format is supported
3. Check network connectivity
4. Ensure AudioPlayerWidget is properly configured
5. Check server CORS settings for audio files
