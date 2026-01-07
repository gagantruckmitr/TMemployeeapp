# Fresh Leads Call Logs Fix

## Problem
When making calls from Fresh Leads screen and submitting feedback:
1. ❌ Calls are not being saved to `call_logs` table with correct fields
2. ❌ Missing `tc_for` and `call_source` fields
3. ❌ Leads not properly tracked as "called"
4. ❌ Stats showing incorrect "remaining_fresh" count

## API Response Analysis
```json
{
  "assigned_to": 8,
  "assigned_name": "Sonam",
  "assigned_role": "telecaller",
  "total_assigned": 9,
  "total_called": 1,
  "remaining_fresh": 8
}
```

This shows:
- 9 total assigned leads
- 1 called (saved in call_logs)
- 8 remaining (not yet called)

## Root Cause
The fresh leads screen uses `SmartCallingService.updateCallFeedback()` which calls the Click2Call IVR API. This API doesn't properly save to `call_logs` with:
- Correct `user_id` (from users table)
- `tc_for` field = 'fresh_leads'
- `call_source` field = 'fresh_leads'

## Solution

### Option 1: Direct call_logs API (Recommended)
Similar to callback requests fix, save directly to `call_logs_api.php`:

```dart
// In fresh_leads_screen.dart
Future<void> _saveToCallLogs({
  required int userId,
  required int callerId,
  required String driverName,
  required String userNumber,
  required String status,
  required String feedback,
  String? remarks,
}) async {
  try {
    final user = RealAuthService.instance.currentUser;
    final callerNumber = user?.mobile ?? '';
    
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/call_logs_api.php?action=insert'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'user_id': userId,
        'caller_id': callerId,
        'driver_name': driverName,
        'user_number': userNumber,
        'caller_number': callerNumber,
        'call_status': status,
        'feedback': feedback,
        'remarks': remarks,
        'notes': remarks,
        'tc_for': 'fresh_leads',
        'call_source': 'fresh_leads',
        'call_time': DateTime.now().toIso8601String(),
        'reference_id': 'FRESH_${DateTime.now().millisecondsSinceEpoch}_${callerId}_$userId',
      }),
    ));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        debugPrint('✅ Call log saved successfully: ${data['id']}');
        return true;
      }
    }
    return false;
  } catch (e) {
    debugPrint('❌ Error saving to call_logs: $e');
    return false;
  }
}
```

### Option 2: Update existing API
Modify the Click2Call IVR API to include `tc_for` and `call_source` fields.

## Implementation Steps

### 1. Update fresh_leads_screen.dart

Add the `_saveToCallLogs` method (same as callback requests):

```dart
Future<void> _saveToCallLogs({
  required int userId,
  required int callerId,
  required String driverName,
  required String userNumber,
  required String status,
  required String feedback,
  String? remarks,
  String? callSource,
}) async {
  // Implementation above
}
```

### 2. Update _updateContactStatus method

```dart
Future<void> _updateContactStatus(
  DriverContact contact,
  TodayLead lead,
  CallFeedback feedback, {
  String? referenceId,
  int? callDuration,
}) async {
  // Get feedback text
  String feedbackText = _getFeedbackText(feedback, lead.role);
  
  try {
    final user = RealAuthService.instance.currentUser;
    if (user == null) throw Exception('User not authenticated');
    
    final callerId = int.parse(user.id);
    final userId = lead.id; // This is users.id
    
    // 1. Save to call_logs table
    await _saveToCallLogs(
      userId: userId,
      callerId: callerId,
      driverName: contact.name,
      userNumber: contact.phoneNumber,
      status: _mapCallStatusToDb(feedback.status),
      feedback: feedbackText,
      remarks: feedback.remarks,
      callSource: 'fresh_leads',
    );
    
    // 2. Update via existing API (optional, for compatibility)
    if (referenceId != null) {
      await SmartCallingService.instance.updateCallFeedback(
        referenceId: referenceId,
        callStatus: _mapCallStatusToDb(feedback.status),
        feedback: feedbackText,
        remarks: feedback.remarks,
        callDuration: callDuration,
        driverName: contact.name,
      );
    }
    
    // 3. Remove from list (lead is now "called")
    setState(() {
      _leads.removeWhere((l) => l.id == lead.id);
    });
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Call completed for ${contact.name}'),
          backgroundColor: AppTheme.primaryBlue,
        ),
      );
    }
  } catch (e) {
    debugPrint('❌ Error saving feedback: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save feedback: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

### 3. Add helper method

```dart
String _getFeedbackText(CallFeedback feedback, String role) {
  if (role == 'transporter') {
    switch (feedback.status) {
      case CallStatus.connected:
        return feedback.transporterConnectedFeedback?.displayName ?? 'Connected';
      case CallStatus.callBack:
        return feedback.callBackReason?.displayName ?? 'Call Back';
      default:
        return 'Unknown';
    }
  } else {
    switch (feedback.status) {
      case CallStatus.connected:
        return feedback.connectedFeedback?.displayName ?? 'Connected';
      case CallStatus.callBack:
        return feedback.callBackReason?.displayName ?? 'Call Back';
      case CallStatus.callBackLater:
        return feedback.callBackTime?.displayName ?? 'Call Back Later';
      case CallStatus.notReachable:
        return 'Not Reachable';
      case CallStatus.notInterested:
        return 'Not Interested';
      case CallStatus.invalid:
        return 'Invalid Number';
      case CallStatus.pending:
        return 'Pending';
    }
  }
}
```

## Database Verification

After implementing, verify with:

```sql
-- Check recent fresh leads call logs
SELECT 
    cl.id,
    cl.user_id,
    u.unique_id as tmid,
    u.name,
    cl.tc_for,
    cl.call_source,
    cl.feedback,
    cl.remarks,
    cl.created_at
FROM call_logs cl
LEFT JOIN users u ON cl.user_id = u.id
WHERE cl.call_source = 'fresh_leads'
ORDER BY cl.created_at DESC
LIMIT 10;
```

Expected:
- ✅ `user_id` is from users table
- ✅ `tc_for` = 'fresh_leads'
- ✅ `call_source` = 'fresh_leads'
- ✅ `feedback` and `remarks` populated

## Testing

1. Open Fresh Leads screen
2. Make a call to a lead
3. Submit feedback with remarks
4. Verify:
   - ✅ Lead disappears from list
   - ✅ Call log created in database
   - ✅ Stats updated (remaining_fresh decreases)

## Benefits

1. ✅ Consistent with callback requests implementation
2. ✅ Proper tracking of fresh leads calls
3. ✅ Correct stats and analytics
4. ✅ All call data in one place (call_logs table)
5. ✅ Easy to query and report on

## Files to Modify

1. `lib/features/telecaller/screens/fresh_leads_screen.dart`
   - Add `_saveToCallLogs` method
   - Update `_updateContactStatus` method
   - Add `_getFeedbackText` helper

## Status

- [ ] Implementation pending
- [ ] Testing pending
- [ ] Database verification pending

## Related Fixes

- ✅ Callback Requests Call Logs Fix (CALLBACK_REQUESTS_CALL_LOGS_FIX.md)
- [ ] Fresh Leads Call Logs Fix (this document)
- [ ] Backlog Call Logs Fix (if needed)
- [ ] Social Media Call Logs Fix (if needed)
