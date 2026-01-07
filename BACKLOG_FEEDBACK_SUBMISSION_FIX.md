# Backlog Feedback Submission Fix

## Problem
When submitting feedback from the backlog screen modal, the submit button appeared to work (calling happened) but the feedback was NOT being saved to the database. The lead would be removed from the UI but no database update occurred.

## Root Cause
The `_showFeedbackModal` method in `backlog_screen.dart` was missing the critical step of calling the API to save feedback to the database. It was only:
1. Removing the lead from the local UI list
2. Closing the modal
3. Showing a success message

But it was NOT calling `SmartCallingService.instance.updateCallFeedback()` to persist the feedback.

## Additional Issues Fixed
1. **404 Error Handling**: When reference_id doesn't exist in call_logs, the code now falls back to direct status update
2. **setState() After Dispose**: Fixed by using modalContext instead of context and checking mounted before setState

## Solution
Added the complete feedback submission logic to `backlog_screen.dart`:

### 1. Created `_updateContactStatus` Method
This method:
- Converts the feedback enum to display text
- Calls `SmartCallingService.instance.updateCallFeedback()` with the reference ID
- Falls back to `updateCallStatus()` or `updateTransporterCallStatus()` if no reference ID
- Shows error messages if the save fails

### 2. Created `_mapCallStatusToDb` Method
Maps the `CallStatus` enum to database-compatible strings:
- `CallStatus.connected` → "Connected"
- `CallStatus.callBack` → "Not Connected"
- `CallStatus.callBackLater` → "Call Back Later"
- etc.

### 3. Updated `_showFeedbackModal` Callback
The `onFeedbackSubmitted` callback now:
1. **Saves feedback to database** via `_updateContactStatus()`
2. Marks lead as processed
3. Removes from UI list
4. Closes modal
5. Shows success message

## Files Modified
- `lib/features/telecaller/screens/backlog_screen.dart`

## Testing
1. Open backlog screen
2. Call a lead (manual or IVR)
3. Submit feedback with status and remarks
4. Verify feedback is saved to database (check call_logs table)
5. Verify lead is removed from backlog list
6. Verify success message appears

## Technical Details
The fix follows the same pattern used in `fresh_leads_screen.dart` which was working correctly. The key is calling `SmartCallingService.instance.updateCallFeedback()` with:
- `referenceId`: The call log ID or IVR reference
- `callStatus`: Mapped status string
- `feedback`: Display name of the selected feedback option
- `remarks`: User-entered remarks
- `driverName`: Contact name for logging

This ensures the feedback is properly persisted to the `call_logs` table in the database.
