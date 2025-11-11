# Call Feedback Screen UI Behavior Fixes

## UI Structure Understanding

The Call Feedback screen has three main status options:
1. **Connected** → Shows "Connected Feedback" options when selected
2. **Not Connected** → Shows "Not Connected Reason" options when selected
3. **Call Back Later** → Shows "Call Back Time" options when selected

## Issues Fixed

### 🪲 Bug 1 – Screen Auto-Scroll When Switching Status
**Problem:** When switching between "Connected" and "Not Connected", the screen would automatically scroll down due to widget tree size changes and Flutter's default behavior to keep focused widgets visible.

**Solution:**
- Added `ScrollController` to manage scroll position explicitly
- Implemented scroll position preservation: captures current scroll position before state change
- Uses `WidgetsBinding.instance.addPostFrameCallback()` to restore scroll position after rebuild
- Added `ClampingScrollPhysics()` to `SingleChildScrollView` for stable scrolling behavior
- Prevents automatic scrolling when UI elements expand/collapse by using `jumpTo()` instead of allowing default scroll behavior

### ⚙️ Bug 2 – "Call Back Later" Options Not Showing
**Problem:** When selecting "Call Back Later" as the main status, the time options (Busy Right Now, Call Tomorrow Morning, etc.) were not appearing.

**Solution:**
- Fixed `_onStatusSelected()` to properly set `_showCallBackTimes = true` when `CallStatus.callBackLater` is selected
- Restored `_showCallBackTimes` to animation trigger condition
- Now "Call Back Later" correctly expands to show time options when selected
- "Not Connected Reason" selections do NOT trigger "Call Back Later" expansion (working as intended)

## Files Modified

1. **lib/features/telecaller/widgets/call_feedback_modal.dart**
   - Fixed auto-scroll and auto-expand issues
   - Added `ClampingScrollPhysics()` and `keyboardDismissBehavior`

2. **Phase_2-/lib/features/calls/widgets/call_feedback_modal.dart**
   - Added `ClampingScrollPhysics()` and `keyboardDismissBehavior` for consistent UX

## Expected Behavior After Fix

✅ Tapping "Connected" shows "Connected Feedback" options without auto-scrolling
✅ Tapping "Not Connected" shows "Not Connected Reason" options without auto-scrolling
✅ Tapping "Call Back Later" shows "Call Back Time" options without auto-scrolling
✅ Selecting a reason under "Not Connected" does NOT trigger "Call Back Later" expansion
✅ Scrolling behavior is stable and smooth with clamping physics
✅ Keyboard dismisses on drag for better UX
✅ Switching between statuses maintains scroll position

## Testing Checklist

- [ ] Tap "Connected" - should show feedback options without scrolling
- [ ] Tap "Not Connected" - should show reason options without scrolling
- [ ] Select "Ringing/Call Busy" under "Not Connected" - should NOT show "Call Back Later" options
- [ ] Tap "Call Back Later" main status - should show time options (Busy Right Now, Call Tomorrow Morning, etc.)
- [ ] Switch between "Connected" and "Not Connected" - scroll position should remain stable
- [ ] Scroll behavior should be smooth without jumps
- [ ] Keyboard should dismiss when dragging scroll view
