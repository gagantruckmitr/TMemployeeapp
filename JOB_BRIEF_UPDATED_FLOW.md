# Job Brief Call Flow - Updated Implementation

## New Flow (Corrected)

```
User clicks call icon on job card
    ↓
Call Status Selection Modal appears immediately
    ↓
User selects Status:
  - Connected (Green)
  - Not Connected (Red)
  - Call Back Later (Orange)
    ↓
Feedback options appear based on selected status
    ↓
User selects Feedback option
    ↓
User clicks "Continue"
    ↓
Call Type Dialog appears:
  - Manual Call
  - EasyGo IVR
    ↓
If EasyGo IVR selected:
  ├─ IVR call initiated via ivr-call-jobBrief API
  ├─ Both phones ring (telecaller + transporter)
  ├─ Call waiting overlay shown
  ├─ When call ends, overlay closes
  ├─ API call to ivr-call-update-jobBrief with status & feedback
  └─ If feedback is "Transporter Confirmed Job Details":
      └─ Job Brief Feedback Modal opens
         (User fills in job details)
    ↓
If Manual Call selected:
  ├─ Direct phone call made
  ├─ After call ends
  ├─ API call to ivr-call-update-jobBrief with status & feedback
  └─ If feedback is "Transporter Confirmed Job Details":
      └─ Job Brief Feedback Modal opens
         (User fills in job details)
```

## Key Changes

### 1. Modal Timing
- **Before:** Call Status Modal appeared AFTER the call ended
- **Now:** Call Status Modal appears BEFORE the call starts

### 2. User Experience
- User selects status and feedback FIRST
- Then makes the call with that context
- After call ends, appropriate modal opens based on feedback

### 3. API Calls

**Call Initiation:**
- Endpoint: `https://truckmitr.com/api/telehead/ivr-call-jobBrief`
- Happens: When user selects "EasyGo IVR"
- Returns: job_brief_id

**Call Status Update:**
- Endpoint: `https://truckmitr.com/api/telehead/ivr-call-update-jobBrief`
- Happens: After call ends (IVR overlay closes)
- Sends: job_brief_id, call_status (format: "Status: Feedback"), caller_id

**Job Brief Save:**
- Endpoint: `https://truckmitr.com/api/telehead/phase2_job_brief_api.php`
- Happens: When user submits Job Brief Feedback Modal
- Sends: Job details, call status, notes, recording

## Status and Feedback Options

### Connected (Green)
```
- Transporter Confirmed Job Details
  → Opens Job Brief Feedback Modal
  
- Transporter Wants to Modify Job Details
  → Saves feedback, no modal
  
- Transporter Wants to Hold the Job
  → Saves feedback, no modal
  
- Transporter Wants to Cancel the Job
  → Saves feedback, no modal
  
- Transporter Busy – Requested Call Back
  → Saves feedback, no modal
  
- Transporter Not Interested Anymore
  → Saves feedback, no modal
  
- Transporter Shared Additional Information (Notes)
  → Saves feedback, no modal
```

### Not Connected (Red)
```
- Ringing/Call Busy
  → Saves feedback, no modal
  
- Switched Off/ Not Reachable
  → Saves feedback, no modal
  
- Wrong Number
  → Saves feedback, no modal
```

### Call Back Later (Orange)
```
- Busy Right now
  → Saves feedback, no modal
  
- Call Tomorrow
  → Saves feedback, no modal
  
- Call in Evening
  → Saves feedback, no modal
  
- Call After 2 Days
  → Saves feedback, no modal
```

## Implementation Details

### File: `lib/features/jobs/widgets/modern_job_card.dart`

**Method: `_makePhoneCall()`**
- Shows Call Status Selection Modal immediately
- Modal is non-dismissible (user must select or close)
- After selection, shows Call Type Dialog
- Initiates call based on selected type

**Method: `_updateJobBriefCallStatus()`**
- Called after IVR call ends
- Updates job brief with call status via API
- If feedback is "Transporter Confirmed Job Details":
  - Waits 500ms for IVR overlay to close
  - Opens Job Brief Feedback Modal

**Method: `_showJobBriefFeedbackDirectly()`**
- Opens Job Brief Feedback Modal
- User fills in job details
- Saves to database

### File: `lib/features/jobs/widgets/job_call_status_selection_modal.dart`

**Features:**
- Three status buttons (Connected, Not Connected, Call Back Later)
- Dynamic feedback options based on status
- Color-coded for easy identification
- Validation before allowing "Continue"
- Loading state during submission

## Testing Scenarios

### Scenario 1: Connected - Transporter Confirmed Job Details
1. Click call icon
2. Select "Connected"
3. Select "Transporter Confirmed Job Details"
4. Click "Continue"
5. Select "EasyGo IVR"
6. Wait for call to complete
7. **Expected:** Job Brief Feedback Modal opens

### Scenario 2: Connected - Other Feedback
1. Click call icon
2. Select "Connected"
3. Select "Transporter Wants to Hold the Job"
4. Click "Continue"
5. Select "EasyGo IVR"
6. Wait for call to complete
7. **Expected:** No modal, feedback saved

### Scenario 3: Not Connected
1. Click call icon
2. Select "Not Connected"
3. Select "Ringing/Call Busy"
4. Click "Continue"
5. Select "EasyGo IVR"
6. Wait for call to complete
7. **Expected:** No modal, feedback saved

### Scenario 4: Manual Call
1. Click call icon
2. Select "Connected"
3. Select "Transporter Confirmed Job Details"
4. Click "Continue"
5. Select "Manual Call"
6. Direct phone call made
7. After call ends
8. **Expected:** Job Brief Feedback Modal opens

## API Request/Response Examples

### Call Status Update Request
```json
{
  "job_brief_id": "12345",
  "call_status": "Connected: Transporter Confirmed Job Details",
  "caller_id": 123
}
```

### Call Status Update Response
```json
{
  "success": true,
  "message": "Call status updated successfully"
}
```

## Error Handling

- If API call fails: Error logged, no modal shown
- If job not assigned to user: Orange snackbar shown
- If user cancels modal: No call made
- If call fails: Error message shown

## Performance Notes

- Modal appears instantly
- Call initiation happens after user confirms
- API calls are asynchronous
- No blocking operations
- Smooth transitions between modals

## Backward Compatibility

- All existing functionality preserved
- No breaking changes
- Optional parameters handled gracefully
- Existing code paths still work

## Future Enhancements

1. Add call recording upload
2. Add notes field in status modal
3. Add call duration tracking
4. Add call quality rating
5. Add automatic retry for failed calls
6. Add offline support with sync
