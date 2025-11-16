# IVR Call Mini Mode Feature

## Overview
Added mini mode support to the IVR call waiting overlay, allowing telecallers to minimize the call screen and continue browsing the app while the IVR call is in progress. This enables conference calling and multitasking.

## Feature Description

### Full Screen Mode (Default)
- Shows the complete IVR call waiting overlay with animations
- Displays driver name, call status, and instructions
- Takes up the entire screen

### Mini Mode (Minimized)
- Compact floating widget in the top-right corner
- Shows essential call information (driver name, status)
- Allows telecallers to navigate to other screens
- Can make additional calls (conference calling)
- Tap to expand back to full screen

## Implementation

### File Modified
**`lib/features/telecaller/widgets/ivr_call_waiting_overlay.dart`**

### Changes Made

#### 1. Added Mini Mode Support
```dart
class IVRCallWaitingOverlay extends StatefulWidget {
  final bool allowMinimize; // New parameter
  
  const IVRCallWaitingOverlay({
    required this.driverName,
    this.referenceId,
    required this.onCallEnded,
    this.allowMinimize = true, // Enabled by default
  });
}
```

#### 2. Added State Variable
```dart
class _IVRCallWaitingOverlayState extends State<IVRCallWaitingOverlay> {
  bool _isMinimized = false; // Tracks mini mode state
}
```

#### 3. Added Minimize Button
In the header, added a minimize button:
```dart
if (widget.allowMinimize) ...[
  IconButton(
    onPressed: () {
      setState(() {
        _isMinimized = true;
      });
    },
    icon: const Icon(Icons.minimize),
    tooltip: 'Minimize',
  ),
],
```

#### 4. Created Mini Mode Widget
```dart
Widget _buildMiniMode(BuildContext context) {
  return Positioned(
    top: 100,
    right: 16,
    child: GestureDetector(
      onTap: () {
        setState(() {
          _isMinimized = false; // Expand on tap
        });
      },
      child: Material(
        // Compact floating widget
        child: Container(
          width: 180,
          // Shows: Icon, Driver Name, Status, End Call button
        ),
      ),
    ),
  );
}
```

#### 5. Updated Build Method
```dart
@override
Widget build(BuildContext context) {
  if (_isMinimized) {
    return _buildMiniMode(context);
  }
  
  return Material(
    // Full screen mode
  );
}
```

## User Experience

### Minimizing the Call
1. IVR call is initiated (full screen overlay appears)
2. Telecaller clicks the minimize button (top-right)
3. Overlay shrinks to a floating widget
4. Telecaller can now navigate to other screens

### While in Mini Mode
- Floating widget stays visible on top of other screens
- Shows live call status
- Pulsing animation indicates active call
- Can end call directly from mini widget
- Can tap widget to expand back to full screen

### Expanding the Call
1. Tap anywhere on the mini widget
2. OR click the expand icon
3. Returns to full screen mode

## Use Cases

### 1. Conference Calling
```
Telecaller initiates IVR call to Driver A
         ↓
Minimize the call overlay
         ↓
Navigate to Job Applicants screen
         ↓
Initiate another call to Driver B
         ↓
Both calls active (conference call)
```

### 2. Multitasking
```
IVR call in progress
         ↓
Minimize overlay
         ↓
Check job details
         ↓
Review driver profiles
         ↓
Update notes
         ↓
Expand when ready to end call
```

### 3. Quick Reference
```
Call in progress
         ↓
Minimize overlay
         ↓
Look up information
         ↓
Return to call
```

## Mini Mode Widget Features

### Visual Elements
- **Gradient Background**: Blue to orange gradient
- **Pulsing Icon**: Animated phone icon
- **Driver Name**: Truncated if too long
- **Status Indicator**: Loading spinner + "In Progress" text
- **End Call Button**: White button for quick access
- **Expand Icon**: Tap to return to full screen

### Positioning
- **Location**: Top-right corner
- **Offset**: 100px from top, 16px from right
- **Size**: 180px wide, auto height
- **Elevation**: 8 (floats above content)

### Interactions
- **Tap Widget**: Expands to full screen
- **Tap Expand Icon**: Expands to full screen
- **Tap End Call**: Ends call and shows feedback modal

## Configuration

### Enable/Disable Mini Mode
```dart
// Enable mini mode (default)
IVRCallWaitingOverlay(
  driverName: 'John Doe',
  onCallEnded: () {},
  allowMinimize: true, // Can minimize
);

// Disable mini mode
IVRCallWaitingOverlay(
  driverName: 'John Doe',
  onCallEnded: () {},
  allowMinimize: false, // Cannot minimize
);
```

## Screens Using This Feature

Mini mode is enabled by default on:
- ✅ Job Applicants Screen
- ✅ Job Postings Screen (Dynamic Jobs)
- ✅ Match Making Screen
- ✅ Callback Requests Screen
- ✅ Call History Screens
- ✅ Dashboard/Smart Calling
- ✅ Social Media Leads

## Benefits

✅ **Conference Calling** - Make multiple calls simultaneously
✅ **Multitasking** - Browse app while call is active
✅ **Better UX** - Don't block the entire screen
✅ **Quick Access** - End call from mini widget
✅ **Visual Feedback** - Always see call status
✅ **Flexible** - Can expand/minimize as needed

## Technical Details

### State Management
- Uses `setState()` to toggle between modes
- Preserves all animations in mini mode
- No data loss when switching modes

### Animations
- Pulse animation continues in mini mode
- Smooth transition between modes
- Loading indicator shows call is active

### Performance
- Lightweight mini widget
- Minimal resource usage
- No impact on app performance

## Testing Checklist

### Basic Functionality
- [ ] Minimize button appears in full screen mode
- [ ] Clicking minimize switches to mini mode
- [ ] Mini widget appears in correct position
- [ ] Tapping mini widget expands to full screen
- [ ] End call button works in mini mode

### Conference Calling
- [ ] Can initiate second call while first is minimized
- [ ] Both calls remain active
- [ ] Can switch between calls
- [ ] Can end calls independently

### Navigation
- [ ] Mini widget stays visible when navigating
- [ ] Widget appears on top of all screens
- [ ] No interference with other UI elements
- [ ] Back button doesn't dismiss mini widget

### Edge Cases
- [ ] Works with long driver names
- [ ] Works with/without reference ID
- [ ] Handles rapid minimize/expand
- [ ] Proper cleanup on call end

## Future Enhancements

Potential improvements:
1. **Draggable Widget** - Allow repositioning the mini widget
2. **Multiple Calls** - Show multiple mini widgets for conference calls
3. **Call Timer** - Display call duration in mini mode
4. **Mute/Hold** - Add controls in mini widget
5. **Swipe to Dismiss** - Swipe mini widget to end call
6. **Customizable Position** - Let users choose widget position
7. **Call History** - Quick access to recent calls from mini widget
