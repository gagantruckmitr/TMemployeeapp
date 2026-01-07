# Rejection Reason Feature Update

## What Changed
Added a **reason text field** to the rejection confirmation dialog in the Job Applicants screen.

## UI Enhancement
The rejection dialog now includes:
- **Driver & Job Info**: Shows who is being rejected and for which job
- **Reason Text Field**: Multi-line input (3 lines) for entering rejection reason
  - Placeholder: "Enter reason for rejection (optional)"
  - Optional field - can be left empty
  - Focused border turns orange when active
- **Action Buttons**: Cancel or Reject

## Data Flow
```
User clicks "Reject" 
  → Dialog opens with reason field
  → User enters reason (optional)
  → User clicks "Reject"
  → Reason sent to API
  → Stored in database with timestamp
```

## Database Storage
The rejection reason is stored in `call_logs_match_making.remark` field:

**With Reason:**
```
Rejected by telecaller on 2025-12-09 14:30:45. Reason: Not qualified for the position
```

**Without Reason:**
```
Rejected by telecaller on 2025-12-09 14:30:45
```

## Code Changes

### 1. Dialog (job_applicants_screen.dart)
- Added `TextEditingController` for reason input
- Added TextField widget with proper styling
- Proper controller disposal on cancel/submit
- Wrapped content in `SingleChildScrollView` for keyboard handling

### 2. API Service (phase2_api_service.dart)
- Added optional `reason` parameter to `rejectJobApplicant()`
- Sends reason as empty string if not provided

### 3. Backend API (phase2_reject_applicant_api.php)
- Accepts `reason` field from request
- Escapes reason text for SQL safety
- Formats remark with timestamp and reason
- Handles both update and insert scenarios

## Benefits
✅ Better tracking of rejection decisions
✅ Helps with future analysis and reporting
✅ Provides context for why applicants were rejected
✅ Optional field - doesn't force telecallers to enter reason
✅ Clean UI with proper validation and styling

## Example Usage
1. Telecaller reviews driver application
2. Clicks "Reject" button
3. Enters reason: "Insufficient driving experience"
4. Confirms rejection
5. System stores: "Rejected by telecaller on 2025-12-09 14:30:45. Reason: Insufficient driving experience"
