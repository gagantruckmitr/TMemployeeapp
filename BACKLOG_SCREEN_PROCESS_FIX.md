# Backlog Screen Process Parameter Fix

## Problem
In `lib/features/telecaller/screens/backlog_screen.dart`, the process parameter was not being set correctly when making EasyGo IVR calls:
- All calls were using the default process (or no process)
- Transporter calls should use 'Transporter Onboarding'
- Driver calls should use 'Driver Onboarding'

## Root Cause
The `_handleIVRCall` method was passing `contactType: lead.role ?? 'driver'` but was NOT passing the `process` parameter to the `initiateEasyGoIVR` method.

## Solution Implemented

### 1. Updated `_handleIVRCall()` Method
**Changes:**
- Added role detection and process determination
- Dynamically sets process based on contact role
- Passes correct process parameter to EasyGo IVR service

**Before:**
```dart
final result = await SmartCallingService.instance.initiateEasyGoIVR(
  telecallerPhone: telecallerPhone,
  clientPhone: cleanMobile,
  callerId: callerId.toString(),
  contactId: lead.id,
  tmid: lead.tmid,
  contactType: lead.role ?? 'driver', // No process parameter!
);
```

**After:**
```dart
// Determine process based on contact role
final contactType = lead.role ?? 'driver';
final process = contactType == 'transporter' 
    ? 'Transporter Onboarding' 
    : 'Driver Onboarding';

print('📞 Backlog IVR - Contact: ${lead.name}, Role: ${lead.role}, Type: $contactType, Process: $process');

final result = await SmartCallingService.instance.initiateEasyGoIVR(
  telecallerPhone: telecallerPhone,
  clientPhone: cleanMobile,
  callerId: callerId.toString(),
  contactId: lead.id,
  tmid: lead.tmid,
  contactType: contactType,
  process: process, // Dynamic process based on role!
  driverName: lead.name,
);
```

### 2. Updated `_handleManualCall()` Method
**Changes:**
- Added contactType parameter based on lead role
- Passes correct contact type to manual call service

**Before:**
```dart
final result = await SmartCallingService.instance.initiateManualCall(
  driverMobile: cleanMobile,
  callerId: callerId,
  driverId: lead.id,
);
```

**After:**
```dart
final contactType = lead.role ?? 'driver';

print('📱 Backlog Manual Call - Contact: ${lead.name}, Role: ${lead.role}, Type: $contactType');

final result = await SmartCallingService.instance.initiateManualCall(
  driverMobile: cleanMobile,
  callerId: callerId,
  driverId: lead.id,
  contactType: contactType, // Pass correct contact type
);
```

## Impact

### Driver Backlog Leads
✅ EasyGo IVR calls use `process: 'Driver Onboarding'`
✅ Manual calls log `contactType: 'driver'`
✅ Correct routing in backend systems

### Transporter Backlog Leads
✅ EasyGo IVR calls use `process: 'Transporter Onboarding'`
✅ Manual calls log `contactType: 'transporter'`
✅ Correct routing in backend systems

## Testing Checklist
- [ ] Open Backlog screen
- [ ] Make EasyGo IVR call to a driver from backlog
  - Verify process is 'Driver Onboarding' in logs
  - Check backend receives correct process
- [ ] Make EasyGo IVR call to a transporter from backlog
  - Verify process is 'Transporter Onboarding' in logs
  - Check backend receives correct process
- [ ] Make manual call to driver from backlog
  - Verify contactType is 'driver' in logs
- [ ] Make manual call to transporter from backlog
  - Verify contactType is 'transporter' in logs
- [ ] Verify feedback submission works correctly for both types

## Files Modified
1. `lib/features/telecaller/screens/backlog_screen.dart`
   - Modified `_handleIVRCall()` method (added process parameter)
   - Modified `_handleManualCall()` method (added contactType parameter)

## Related Fixes
- `lib/features/telecaller/smart_calling_page.dart` - Same fix applied
- Both screens now consistently use role-based process routing

## Log Output Example
```
📞 Backlog IVR - Contact: John Doe, Role: driver, Type: driver, Process: Driver Onboarding
📞 Backlog IVR - Contact: ABC Transport, Role: transporter, Type: transporter, Process: Transporter Onboarding
📱 Backlog Manual Call - Contact: John Doe, Role: driver, Type: driver
📱 Backlog Manual Call - Contact: ABC Transport, Role: transporter, Type: transporter
```

## Notes
- The fix ensures correct process routing for all backlog calls
- Role detection uses fallback to 'driver' if role is null
- Process parameter is now consistently passed to EasyGo IVR
- Manual calls also log correct contact type for analytics

## Deployment
✅ Code compiles without errors
✅ No breaking changes
✅ Backward compatible (defaults to 'driver' if role is null)
✅ Ready for testing and deployment

## Expected Behavior After Fix

### Backlog Screen - Driver Calls
- EasyGo IVR uses `process: 'Driver Onboarding'`
- Manual calls log `contactType: 'driver'`
- Feedback routes to driver onboarding process

### Backlog Screen - Transporter Calls
- EasyGo IVR uses `process: 'Transporter Onboarding'`
- Manual calls log `contactType: 'transporter'`
- Feedback routes to transporter onboarding process
