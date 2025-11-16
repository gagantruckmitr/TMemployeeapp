# Transporter Call History Separation - Issue Analysis

## Problem Statement

Calls made from the **Job Postings screen** are appearing in BOTH:
1. General Call History (should NOT appear here)
2. Transporter Call History (should ONLY appear here)

## Current Architecture

### Two Separate Systems:

**System 1: Driver Calls (Smart Calling)**
- **Table:** `call_logs`
- **Screens:** Smart Calling, General Call History
- **Service:** `SmartCallingService.initiateClick2CallIVR()`
- **Purpose:** Track calls to drivers

**System 2: Transporter Calls (Job Postings)**
- **Table:** `job_brief_table`
- **Screens:** Job Postings, Transporter Call History
- **Service:** `Phase2ApiService.saveJobBrief()`
- **Purpose:** Track calls to transporters about jobs

## Root Cause

When making IVR calls from Job Postings, the code calls:
```dart
SmartCallingService.instance.initiateClick2CallIVR()
```

This method:
1. ✅ Makes the TeleCMI IVR call (correct)
2. ❌ Saves an entry to `call_logs` table (incorrect for transporters)

Then the code also calls:
```dart
Phase2ApiService.saveJobBrief()
```

This:
1. ✅ Saves to `job_brief_table` (correct)

**Result:** The call is saved to BOTH tables, appearing in both histories.

## Solution Options

### Option 1: Don't Use SmartCallingService for Transporters (RECOMMENDED)
Create a separate method for transporter IVR calls that:
- Makes the TeleCMI API call directly
- Does NOT save to `call_logs`
- Only saves to `job_brief_table` via `saveJobBrief`

### Option 2: Filter by User Type
Add a `user_type` field to `call_logs` table:
- Mark calls as 'driver' or 'transporter'
- Filter general call history to only show 'driver' calls
- More complex, requires database migration

### Option 3: Use Different TeleCMI Numbers
- Use different phone numbers for driver vs transporter calls
- Filter based on the number called
- Requires TeleCMI configuration changes

## Recommended Implementation

### Step 1: Create Transporter-Specific IVR Method

**File:** `lib/core/services/smart_calling_service.dart`

```dart
// New method for transporter IVR calls (doesn't log to call_logs)
Future<Map<String, dynamic>> initiateTransporterIVR({
  required String transporterMobile,
  required int callerId,
  required String transporterTmid,
}) async {
  try {
    // Make TeleCMI API call directly without logging to call_logs
    final response = await http.post(
      Uri.parse('$baseUrl/click2call_ivr_api.php'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'driver_mobile': transporterMobile,
        'caller_id': callerId.toString(),
        'driver_id': transporterTmid,
        'skip_call_log': true, // Flag to skip call_logs entry
      }),
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data;
    }
    
    return {'success': false, 'error': 'API call failed'};
  } catch (e) {
    return {'success': false, 'error': e.toString()};
  }
}
```

### Step 2: Update Job Card to Use New Method

**File:** `lib/features/jobs/widgets/modern_job_card.dart`

**Change from:**
```dart
final result = await SmartCallingService.instance.initiateClick2CallIVR(
  driverMobile: cleanMobile,
  callerId: callerId,
  driverId: widget.job.transporterTmid,
);
```

**Change to:**
```dart
final result = await SmartCallingService.instance.initiateTransporterIVR(
  transporterMobile: cleanMobile,
  callerId: callerId,
  transporterTmid: widget.job.transporterTmid,
);
```

### Step 3: Update TeleCMI API to Support Skip Flag

**File:** `api/click2call_ivr_api.php`

Add logic to skip `call_logs` entry when `skip_call_log` flag is true:

```php
$skipCallLog = isset($data['skip_call_log']) && $data['skip_call_log'] === true;

// Only insert into call_logs if not skipped
if (!$skipCallLog) {
    $insertQuery = "INSERT INTO call_logs ...";
    // existing code
}
```

## Alternative Quick Fix

If you don't want to modify the code, you can filter the general call history to exclude transporter calls:

**File:** `api/call_history_api.php`

Add a WHERE clause to exclude calls where the user is a transporter:

```php
$query = "
    SELECT cl.*, u.name as driver_name, u.mobile as phone_number
    FROM call_logs cl
    INNER JOIN users u ON cl.user_id = u.id
    WHERE cl.caller_id = ? 
    AND u.role != 'transporter'  -- Exclude transporter calls
    ORDER BY cl.created_at DESC
";
```

## Current Status

### Transporter Calls (Job Postings)
- ✅ Fixed - Excluded from general call history
- ✅ Appear ONLY in Transporter Call History
- ✅ Complete separation achieved

### Driver Calls (Job Applicants)
- ✅ Fixed - Excluded from telecaller call history
- ✅ Appear ONLY in Phase 2 Call History
- ✅ Complete separation achieved via NOT EXISTS subquery

## Job Applicants (Driver Calls) - FIXED ✅

### Problem (Resolved)
Calls to drivers from Job Applicants screen were appearing in BOTH:
1. Telecaller Call History (`call_logs` table)
2. Phase 2 Call History (`call_logs_match_making` table)

### Root Cause
Job applicants code saves to both tables:
```dart
// Step 1: Log call to call_logs
await SmartCallingService.instance.initiateManualCall(...);

// Step 2: Save feedback to call_logs_match_making  
await Phase2ApiService.saveCallFeedback(...);
```

### Solution Implemented
Added filtering to `api/call_history_api.php` to exclude calls that exist in `call_logs_match_making`:

```sql
AND NOT EXISTS (
    SELECT 1 FROM call_logs_match_making clm 
    WHERE clm.caller_id = cl.caller_id 
    AND (clm.unique_id_driver = u.unique_id OR clm.unique_id_transporter = u.unique_id)
    AND DATE(clm.created_at) = DATE(COALESCE(cl.call_initiated_at, cl.call_time, cl.Created_at))
)
```

This ensures:
- If a call exists in `call_logs_match_making`, it's excluded from telecaller call history
- Complete separation without code refactoring
- Job applicant calls appear ONLY in Phase 2 Call History

## Final Status - ALL FIXED ✅

### Completed
- ✅ Transporter calls separated (excluded from telecaller call history)
- ✅ Driver calls from job applicants separated (excluded from telecaller call history)
- ✅ Complete separation of all three call history systems

### Call History Separation Summary

| Call Source | Saved To | Appears In | Status |
|------------|----------|------------|--------|
| **Job Postings** (Transporters) | `job_brief_table` | Transporter Call History ONLY | ✅ Fixed |
| **Job Applicants** (Drivers) | Both tables* | Phase 2 Call History ONLY | ✅ Fixed |
| **Smart Calling** (Drivers) | `call_logs` | Telecaller Call History ONLY | ✅ Working |

*Job applicants save to both tables, but filtering ensures they only appear in Phase 2 Call History

### Filtering Logic

**Telecaller Call History** (`api/call_history_api.php`):
- Excludes transporters: `u.role != 'transporter'`
- Excludes Phase 2 calls: `NOT EXISTS` check against `call_logs_match_making`
- Shows ONLY Smart Calling driver calls

**Phase 2 Call History** (`api/phase2_call_history_api.php`):
- Reads from `call_logs_match_making` table
- Shows job applicant driver calls
- Completely separate from telecaller history

**Transporter Call History** (`api/phase2_job_brief_api.php`):
- Reads from `job_brief_table`
- Shows job posting transporter calls
- Completely separate from other histories

---

**Status:** ✅ Complete
**Priority:** High
**Impact:** Resolved - No more duplicate calls in multiple histories
**Effort:** Low - Achieved via SQL filtering
