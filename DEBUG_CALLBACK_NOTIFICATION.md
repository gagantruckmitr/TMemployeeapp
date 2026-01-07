# Debug Callback Notification - Troubleshooting Guide

## Issue: Notification not appearing at 4:58 PM

### Debug Steps:

1. **Check if notification was saved:**
   - Look for this in console logs:
   ```
   💾 Adding notification: [Contact Name]
      Scheduled for: 2024-XX-XX 16:58:00
      TMID: [TMID]
   ✅ Notification saved. Total: 1
   ```

2. **Check if service initialized:**
   - Look for:
   ```
   🚀 Initializing CallbackNotificationService
   📱 Loaded X notifications
      - [Contact Name]: 2024-XX-XX 16:58:00 (dismissed: false)
   ```

3. **Check if monitoring started:**
   - Look for:
   ```
   🔄 Starting callback monitoring (every 10 seconds)
   ⏱️ Timer tick - checking callbacks...
   ```

4. **Check callback detection:**
   - At 4:53 PM (5 minutes before), look for:
   ```
   🔍 Checking callbacks at 2024-XX-XX 16:53:XX
   📋 Total active notifications: 1
      - [Contact Name]: scheduled at 16:58:00, diff: 4m XXs
   ✅ Found upcoming callback: [Contact Name]
   🎯 Showing notification for: [Contact Name]
   ⏰ Countdown started: XXX seconds
   ```

## Quick Test (Right Now):

### Option 1: Set callback for 2 minutes from now
```dart
// In call_feedback_modal.dart, temporarily change:
difference.inMinutes < 5  →  difference.inMinutes < 60

// This makes it show 1 hour before instead of 5 minutes
// Easier to test!
```

### Option 2: Use Debug Screen
1. Navigate to the debug screen (if added to router)
2. See all active notifications
3. Check their status and timing
4. Verify they're being detected

## Common Issues:

### 1. Notification saved but not showing
**Cause:** Time difference calculation issue
**Fix:** Check console for "Found upcoming callback" message

### 2. No console logs at all
**Cause:** Service not initialized
**Fix:** Check app.dart - ensure `_initializeNotificationService()` is called

### 3. Timer not running
**Cause:** Widget not mounted or disposed early
**Fix:** Check "Starting callback monitoring" message appears

### 4. Shows for wrong time
**Cause:** Timezone or time calculation issue
**Fix:** Verify scheduled time matches your local time

## Manual Test Commands:

### Check SharedPreferences:
```dart
// Add this temporarily in any screen:
final prefs = await SharedPreferences.getInstance();
final data = prefs.getString('callback_notifications');
print('Stored notifications: $data');
```

### Force Check:
```dart
// In overlay widget, add a button:
FloatingActionButton(
  onPressed: () {
    _checkForUpcomingCallback();
  },
  child: Icon(Icons.refresh),
)
```

## Expected Console Output (Full Flow):

```
📞 Creating callback notification:
   Name: Rajesh Kumar
   Phone: 9876543210
   Scheduled: 2024-12-07 16:58:00.000
   Current time: 2024-12-07 16:50:00.000
   Minutes until callback: 8

💾 Adding notification: Rajesh Kumar
   Scheduled for: 2024-12-07 16:58:00.000
   TMID: TM12345
✅ Notification saved. Total: 1

🚀 Initializing CallbackNotificationService
📱 Loaded 1 notifications
   - Rajesh Kumar: 2024-12-07 16:58:00.000 (dismissed: false)

🔄 Starting callback monitoring (every 10 seconds)

⏱️ Timer tick - checking callbacks...
🔍 Checking callbacks at 2024-12-07 16:50:10.000
📋 Total active notifications: 1
   - Rajesh Kumar: scheduled at 16:58:00, diff: 7m 50s
❌ No upcoming callbacks within 5 minutes

... (wait until 16:53) ...

⏱️ Timer tick - checking callbacks...
🔍 Checking callbacks at 2024-12-07 16:53:00.000
📋 Total active notifications: 1
   - Rajesh Kumar: scheduled at 16:58:00, diff: 4m 60s
✅ Found upcoming callback: Rajesh Kumar
🎯 Showing notification for: Rajesh Kumar
⏰ Countdown started: 300 seconds
```

## If Still Not Working:

1. **Restart the app completely**
   - Hot reload might not work for timers
   - Do a full restart

2. **Check the time calculation:**
   ```dart
   // Add this in _checkForUpcomingCallback:
   debugPrint('Current time: ${now.toString()}');
   debugPrint('Scheduled time: ${n.scheduledTime.toString()}');
   debugPrint('Difference in seconds: ${difference.inSeconds}');
   debugPrint('Difference in minutes: ${difference.inMinutes}');
   debugPrint('Is within 5 min? ${difference.inSeconds > 0 && difference.inMinutes < 5}');
   ```

3. **Verify widget is in tree:**
   ```dart
   // In overlay initState:
   debugPrint('🎨 CallbackNotificationOverlay mounted');
   ```

4. **Check for errors:**
   - Look for any red error messages in console
   - Check if SharedPreferences is working
   - Verify JSON serialization is correct

## Quick Fix: Change to 1 Hour Window

If you want to test immediately, change this line in `callback_notification_overlay.dart`:

```dart
// Line ~75, change from:
return difference.inSeconds > 0 && difference.inMinutes < 5;

// To:
return difference.inSeconds > 0 && difference.inMinutes < 60;
```

Now it will show 1 hour before the callback time, making it much easier to test!

## Contact for Support:

If none of this works, share:
1. Full console output
2. Time you set the callback
3. Current time when you expected it to show
4. Any error messages
