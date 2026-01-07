# Smart Calling Role-Based Lead Filtering & Process Fix

## Problems Fixed

### 1. Role-Based Lead Filtering
In `lib/features/telecaller/smart_calling_page.dart`, leads were not being properly filtered by role:
- **Driver tab** was showing both drivers AND transporters
- **Transporter tab** was showing both transporters AND drivers
- This caused confusion and incorrect data display

### 2. Process Parameter in EasyGo IVR Calls
When calling from backlog or other tabs, the process parameter was not being set correctly:
- All calls were using 'Driver Onboarding' regardless of contact type
- Transporter calls should use 'Transporter Onboarding'
- Driver calls should use 'Driver Onboarding'

## Root Causes
1. The `_loadDriversFromLiveAPI()` method was loading ALL leads from the API without filtering by the `role` field
2. The transporter loading was not properly filtering by role
3. The `_startCall` method was hardcoding `contactType: 'driver'` and not checking the contact's role field
4. The `_handleEasyGoIVR` method was always using 'Driver Onboarding' process

## Solution Implemented

### 1. Fixed Driver Loading (`_loadDriversFromLiveAPI()`)
**Changes:**
- Added role filtering: `final driverLeads = leads.where((lead) => lead.role == 'driver').toList();`
- Applied same filter to elechamps leads: `elechampsDrivers = allElechampsLeads.where((lead) => lead.role == 'driver').toList();`
- Updated remaining count to reflect only driver leads

**Before:**
```dart
final leads = await TodayLeadsService.instance.getTodayLeads();
drivers = leads.map((lead) => _convertTodayLeadToDriverContact(lead)).toList();
```

**After:**
```dart
final leads = await TodayLeadsService.instance.getTodayLeads();
// CRITICAL FIX: Filter only drivers (role == 'driver')
final driverLeads = leads.where((lead) => lead.role == 'driver').toList();
drivers = driverLeads.map((lead) => _convertTodayLeadToDriverContact(lead)).toList();
```

### 2. Created New Transporter Loading Method (`_loadTransportersFromLiveAPI()`)
**New method added:**
- Loads leads from TodayLeadsService
- Filters only transporters: `final transporterLeads = leads.where((lead) => lead.role == 'transporter').toList();`
- Converts TodayLead to TransporterContact
- Handles UTC to IST conversion

**Implementation:**
```dart
Future<List<TransporterContact>> _loadTransportersFromLiveAPI() async {
  List<TransporterContact> transporters = [];
  
  try {
    final leads = await TodayLeadsService.instance.getTodayLeads();
    
    // CRITICAL FIX: Filter only transporters (role == 'transporter')
    final transporterLeads = leads.where((lead) => lead.role == 'transporter').toList();
    
    // Convert to TransporterContact...
  } catch (e) {
    print('⚠️ [SmartCalling] Error loading today transporter leads: $e');
  }
  
  return transporters;
}
```

### 3. Updated `_loadData()` Method
**Changes:**
- Replaced `SmartCallingService.instance.getTransporters()` calls with `_loadTransportersFromLiveAPI()`
- Applied to both regular mode and match-making mode
- Ensures consistent role-based filtering across all tabs

**Before:**
```dart
final transporters = await SmartCallingService.instance.getTransporters(userType: 'transporter');
```

**After:**
```dart
final transporters = await _loadTransportersFromLiveAPI();
```

## Impact

### Driver Tab (Tab 0)
✅ Now shows ONLY leads with `role == 'driver'`
✅ Filters both TodayLeads API and Elechamps API results
✅ Accurate remaining count for drivers only

### Transporter Tab (Tab 1)
✅ Now shows ONLY leads with `role == 'transporter'`
✅ Uses same data source as drivers (TodayLeadsService)
✅ Consistent filtering logic

### Backlog Tab (Tab 2)
✅ No changes needed (already working correctly)

## Testing Checklist

### Role Filtering Tests
- [ ] Open Smart Calling page
- [ ] Switch to Driver tab - verify only drivers appear (check TMID starts with DR)
- [ ] Switch to Transporter tab - verify only transporters appear (check TMID starts with TR)
- [ ] Switch to Backlog tab - verify callback leads appear correctly
- [ ] Test in match-making mode (`tcFor: 'match-making'`)
- [ ] Verify counts are accurate for each tab
- [ ] Test search functionality in each tab

### Process Parameter Tests
- [ ] **Driver Tab - EasyGo IVR Call:**
  - Make a call to a driver
  - Verify process is set to 'Driver Onboarding' in logs
  - Check backend receives correct process parameter
  
- [ ] **Transporter Tab - EasyGo IVR Call:**
  - Make a call to a transporter
  - Verify process is set to 'Transporter Onboarding' in logs
  - Check backend receives correct process parameter
  
- [ ] **Backlog Tab - Driver Call:**
  - Make a call to a driver from backlog
  - Verify process is 'Driver Onboarding'
  - Verify contactType is 'driver' in call logs
  
- [ ] **Backlog Tab - Transporter Call:**
  - Make a call to a transporter from backlog
  - Verify process is 'Transporter Onboarding'
  - Verify contactType is 'transporter' in call logs
  
- [ ] **Manual Calls:**
  - Test manual calls for both drivers and transporters
  - Verify correct contactType is logged

## Additional Fixes

### 4. Dynamic Process Parameter Based on Contact Role
**Changes to `_startCall()` method:**
- Added role detection: `final contactType = contact.role == 'transporter' ? 'transporter' : 'driver';`
- Pass contactType to call handlers
- Log correct contact type in call hit

**Before:**
```dart
final logResult = await CallHitService.instance.logCallHit(
  contactId: contact.id,
  contactName: contact.name,
  contactType: 'driver', // Always driver!
  callType: callType,
  sourceScreen: 'smart_calling',
  phoneNumber: contact.phoneNumber,
);
```

**After:**
```dart
final contactType = contact.role == 'transporter' ? 'transporter' : 'driver';
final logResult = await CallHitService.instance.logCallHit(
  contactId: contact.id,
  contactName: contact.name,
  contactType: contactType, // Dynamic based on role!
  callType: callType,
  sourceScreen: 'smart_calling',
  phoneNumber: contact.phoneNumber,
);
```

### 5. Updated `_handleEasyGoIVR()` Method
**Changes:**
- Added optional `contactType` parameter (defaults to 'driver')
- Dynamically determines process: `final process = contactType == 'transporter' ? 'Transporter Onboarding' : 'Driver Onboarding';`
- Passes correct process to EasyGo IVR service

**Implementation:**
```dart
Future<void> _handleEasyGoIVR(
  DriverContact contact,
  int callerId, {
  String contactType = 'driver',
}) async {
  // Determine process based on contact type
  final process = contactType == 'transporter' 
      ? 'Transporter Onboarding' 
      : 'Driver Onboarding';
  
  // Initiate EasyGo IVR with correct process
  final result = await SmartCallingService.instance.initiateEasyGoIVR(
    telecallerPhone: telecallerPhone,
    clientPhone: cleanDriverMobile,
    callerId: callerId.toString(),
    contactId: contact.id,
    tmid: contact.tmid,
    contactType: contactType,
    process: process, // Dynamic!
    driverName: contact.name,
  );
}
```

### 6. Updated `_handleManualCall()` Method
**Changes:**
- Added optional `contactType` parameter (defaults to 'driver')
- Passes correct contact type to manual call service

## Files Modified
1. `lib/features/telecaller/smart_calling_page.dart`
   - Modified `_loadDriversFromLiveAPI()` method (role filtering)
   - Added `_loadTransportersFromLiveAPI()` method (new)
   - Updated `_loadData()` method (2 locations)
   - Modified `_startCall()` method (role detection & contactType passing)
   - Modified `_handleEasyGoIVR()` method (dynamic process parameter)
   - Modified `_handleManualCall()` method (contactType parameter)

## Related Code
- `lib/core/services/today_leads_service.dart` - Source of lead data
- `lib/models/smart_calling_models.dart` - DriverContact and TransporterContact models
- `lib/core/services/smart_calling_service.dart` - Service layer (not modified)

## Key Benefits

### 1. Accurate Lead Segregation
- Drivers only appear in Driver tab
- Transporters only appear in Transporter tab
- No cross-contamination of data

### 2. Correct Process Routing
- Driver calls → 'Driver Onboarding' process
- Transporter calls → 'Transporter Onboarding' process
- Works correctly from all tabs (Driver, Transporter, Backlog)

### 3. Proper Call Logging
- Contact type is correctly identified and logged
- Call history will show accurate contact types
- Analytics will be more precise

### 4. Backward Compatibility
- Default parameters ensure existing code continues to work
- No breaking changes to method signatures
- Graceful fallback to 'driver' if role is not set

## Notes
- The fix ensures data integrity by filtering at the UI layer
- Both tabs now use the same data source (TodayLeadsService) for consistency
- Role filtering is applied BEFORE conversion to contact models
- Elechamps API results are also filtered by role for drivers
- Process parameter is dynamically determined based on contact role
- No changes needed to backend APIs - filtering and routing is done client-side

## Deployment
✅ Code compiles without errors
✅ No breaking changes
✅ Backward compatible with default parameters
✅ Ready for testing and deployment

## Expected Behavior After Fix

### Driver Tab
- Shows only leads with `role == 'driver'`
- EasyGo IVR calls use `process: 'Driver Onboarding'`
- Call logs show `contactType: 'driver'`

### Transporter Tab
- Shows only leads with `role == 'transporter'`
- EasyGo IVR calls use `process: 'Transporter Onboarding'`
- Call logs show `contactType: 'transporter'`

### Backlog Tab
- Shows both drivers and transporters (callback leads)
- Automatically detects role from contact data
- Routes to correct process based on role
- Logs correct contact type
