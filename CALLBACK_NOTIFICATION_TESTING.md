# Callback Notification - Testing & Debugging Guide

## Current Status: ✅ Code Complete with Debug Logging

All code is implemented with comprehensive debug logging. If the notification isn't showing, follow these steps:

## Step 1: Check Console Logs

After scheduling a callback at 4:58 PM, you should see:

```
📞 Creating callback notification:
   Name: [Contact Name]
   Phone: [Phone Number]
   Scheduled: 2024-12-07 16:58:00.000
   Current time: 2024-12-07 16:50:00.000
   Minutes until callback: 8

💾 Adding notification: [Contact Name]
   Scheduled for: 2024-12-07 16:58:00.000
   TMID: [TMID]
✅ Notification saved. Total: 1
```

**If you DON'T see this:** The notification wasn't saved. Check if you:
- Selected "Call Back Later"
- Picked a date and time
- Entered remarks
- Clicked Submit

## Step 2: Check Service Initialization

On app start, you should see:

```
🚀 Initializing CallbackNotificationService
📱 Loaded 1 notifications
   - [Contact Name]: 2024-12-07 16:58:00.000 (dismissed: false)
```

**If you DON'T see this:** Restart the app completely (not hot reload).

## Step 3: Check Monitoring

You should see this every 10 seconds:

```
⏱️ Timer tick - checking callbacks...
🔍 Checking callbacks at 2024-12-07 16:50:XX.000
📋 Total active notifications: 1
   - [Contact Name]: scheduled at 16:58:00, diff: 7m XXs
❌ No upcoming callbacks within 5 minutes
```

**If you DON'T see this:** The timer isn't running. Restart the app.

## Step 4: Wait for 5 Minutes Before

At 4:53 PM (5 minutes before 4:58 PM), you should see:

```
⏱️ Timer tick - checking callbacks...
🔍 Checking callbacks at 2024-12-07 16:53:XX.000
📋 Total active notifications: 1
   - [Contact Name]: scheduled at 16:58:00, diff: 4m XXs
✅ Found upcoming callback: [Contact Name]
🎯 Showing notification for: [Contact Name]
⏰ Countdown started: 300 seconds
```

**If you see this but NO WIDGET:** There's a rendering issue. Check if the overlay is in the widget tree.

## Quick Test: Change to 1 Hour Window

To test immediately without waiting, make this change:

### File: `lib/widgets/callback_notification_overlay.dart`
### Line: ~75

```dart
// BEFORE (shows 5 minutes before):
return difference.inSeconds > 0 && difference.inMinutes < 5;

// AFTER (shows 1 hour before - for testing):
return difference.inSeconds > 0 && difference.inMinutes < 60;
```

Now schedule a callback for 30 minutes from now, and the widget will appear immediately!

## Add Debug FAB (Recommended)

Add this to any screen to see notification status in real-time:

### Example: Add to Smart Calling Screen

```dart
import '../widgets/callback_debug_fab.dart';

// In your Scaffold:
Scaffold(
  appBar: AppBar(...),
  body: ...,
  floatingActionButton: CallbackDebugFAB(), // Add this
)
```

This shows:
- Current time
- All active notifications
- Time difference for each
- Which ones should be visible
- Refresh button

## Common Issues & Fixes

### Issue 1: "No logs at all"
**Cause:** App not restarted after code changes
**Fix:** Do a full restart (not hot reload)

### Issue 2: "Notification saved but not showing"
**Cause:** Time window is 5 minutes, you might have missed it
**Fix:** Change to 60 minutes (see above) or schedule closer to current time

### Issue 3: "Timer not ticking"
**Cause:** Widget disposed or not mounted
**Fix:** Check if CallbackNotificationOverlay is in widget tree

### Issue 4: "Shows 'No upcoming callbacks' even at 4:53 PM"
**Cause:** Time calculation issue or timezone problem
**Fix:** Check the console output for exact time differences

## Manual Verification Steps

### 1. Verify Notification is Saved

Add this code temporarily to any screen:

```dart
import 'package:shared_preferences/shared_preferences.dart';

// In a button onPressed:
final prefs = await SharedPreferences.getInstance();
final data = prefs.getString('callback_notifications');
print('Stored: $data');
```

You should see JSON data with your notification.

### 2. Force Check Immediately

Add this button temporarily:

```dart
FloatingActionButton(
  onPressed: () {
    // Access the overlay state and call:
    _checkForUpcomingCallback();
  },
  child: Icon(Icons.refresh),
)
```

### 3. Check Widget Tree

Add this in CallbackNotificationOverlay initState:

```dart
debugPrint('🎨 Overlay Widget Mounted!');
debugPrint('🎨 Context: ${context.toString()}');
```

## Expected Timeline

For a callback scheduled at **4:58 PM**:

| Time | What Should Happen |
|------|-------------------|
| 4:50 PM | Notification saved, monitoring started |
| 4:51 PM | Timer checks, says "7m remaining, not within 5 min" |
| 4:52 PM | Timer checks, says "6m remaining, not within 5 min" |
| **4:53 PM** | **Timer checks, says "4m remaining, WITHIN 5 MIN!"** |
| **4:53 PM** | **🎉 WIDGET APPEARS!** |
| 4:54 PM | Widget shows "04:00" countdown |
| 4:55 PM | Widget shows "03:00" countdown |
| 4:56 PM | Widget shows "02:00" countdown |
| 4:57 PM | Widget shows "01:00" countdown |
| 4:58 PM | Widget shows "00:00" countdown |

## If Still Not Working

### Last Resort: Add Visual Debug

Add this to the overlay widget to see if it's even trying to show:

```dart
@override
Widget build(BuildContext context) {
  debugPrint('🎨 Building overlay, active notification: ${_activeNotification?.contactName ?? "none"}');
  
  return Stack(
    children: [
      widget.child,
      // Add this test widget to see if Stack is working:
      Positioned(
        top: 50,
        right: 20,
        child: Container(
          padding: EdgeInsets.all(8),
          color: Colors.red,
          child: Text('TEST', style: TextStyle(color: Colors.white)),
        ),
      ),
      if (_activeNotification != null)
        Positioned(
          left: _position.dx,
          top: _position.dy,
          child: _buildFloatingWidget(),
        ),
    ],
  );
}
```

If you see "TEST" but not the notification widget, there's an issue with the notification widget itself.

## Success Checklist

- [ ] Console shows "Creating callback notification"
- [ ] Console shows "Notification saved"
- [ ] Console shows "Initializing CallbackNotificationService"
- [ ] Console shows "Loaded X notifications"
- [ ] Console shows "Starting callback monitoring"
- [ ] Console shows "Timer tick" every 10 seconds
- [ ] At 5 min before: Console shows "Found upcoming callback"
- [ ] At 5 min before: Console shows "Showing notification"
- [ ] At 5 min before: Widget appears on screen
- [ ] Widget shows countdown timer
- [ ] Widget is draggable
- [ ] Tapping widget navigates to call history

## Need Help?

Share these details:
1. Full console output from scheduling to expected show time
2. Time you scheduled the callback
3. Current time when you expected it to show
4. Screenshot of console logs
5. Any error messages (red text)

---

**Remember:** The widget only shows **5 minutes before** the scheduled time. If you scheduled for 4:58 PM, it will appear at 4:53 PM, not immediately!
