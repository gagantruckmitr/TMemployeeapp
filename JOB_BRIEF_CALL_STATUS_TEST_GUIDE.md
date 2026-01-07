# Job Brief Call Status Selection - Test Guide

## Testing the Implementation

### Prerequisites
- App is running on a device or emulator
- User is logged in as a telecaller
- Job postings are available and assigned to the current user

### Test Scenario 1: Connected - Transporter Confirmed Job Details

1. Navigate to Job Postings screen
2. Find a job assigned to you
3. Click the **call icon** (green button)
4. **Call Status Selection Modal** appears
5. Select **"Connected"** status
6. Select **"Transporter Confirmed Job Details"** feedback
7. Click **"Continue"**
8. Select **"EasyGo IVR"** call type
9. Wait for the IVR call to complete
10. **Expected Result:** 
    - API call to `ivr-call-update-jobBrief` is made with status "Connected: Transporter Confirmed Job Details"
    - Job Brief Feedback modal automatically opens
    - Telecaller can fill in job details

### Test Scenario 2: Connected - Other Feedback Options

1. Repeat steps 1-7 but select a different feedback option (e.g., "Transporter Wants to Hold the Job")
2. Select **"EasyGo IVR"** call type
3. Wait for the IVR call to complete
4. **Expected Result:**
    - API call to `ivr-call-update-jobBrief` is made with the selected status and feedback
    - No additional modal appears
    - Feedback is saved

### Test Scenario 3: Not Connected - Ringing/Call Busy

1. Navigate to Job Postings screen
2. Click the call icon on a job assigned to you
3. Select **"Not Connected"** status
4. Select **"Ringing/Call Busy"** feedback
5. Click **"Continue"**
6. Select **"EasyGo IVR"** call type
7. Wait for the IVR call to complete
8. **Expected Result:**
    - API call to `ivr-call-update-jobBrief` is made with status "Not Connected: Ringing/Call Busy"
    - No additional modal appears

### Test Scenario 4: Call Back Later - Busy Right now

1. Navigate to Job Postings screen
2. Click the call icon on a job assigned to you
3. Select **"Call Back Later"** status
4. Select **"Busy Right now"** feedback
5. Click **"Continue"**
6. Select **"EasyGo IVR"** call type
7. Wait for the IVR call to complete
8. **Expected Result:**
    - API call to `ivr-call-update-jobBrief` is made with status "Call Back Later: Busy Right now"
    - No additional modal appears

### Test Scenario 5: Manual Call

1. Navigate to Job Postings screen
2. Click the call icon on a job assigned to you
3. Select **"Connected"** status
4. Select **"Transporter Confirmed Job Details"** feedback
5. Click **"Continue"**
6. Select **"Manual Call"** call type
7. Direct phone call is initiated
8. **Expected Result:**
    - Phone call is made directly
    - After call ends, API call to `ivr-call-update-jobBrief` is made
    - If feedback was "Transporter Confirmed Job Details", Job Brief modal opens

### Test Scenario 6: Job Not Assigned to You

1. Navigate to Job Postings screen
2. Find a job NOT assigned to you
3. Click the call icon
4. **Expected Result:**
    - Orange snackbar appears: "This job is assigned to another telecaller"
    - No modal appears

## API Verification

### Check API Calls in Network Tab

**Call Initiation API:**
- URL: `https://truckmitr.com/api/telehead/ivr-call-jobBrief`
- Method: POST
- Expected in network tab when EasyGo IVR is selected

**Call Status Update API:**
- URL: `https://truckmitr.com/api/telehead/ivr-call-update-jobBrief`
- Method: POST
- Payload example:
  ```json
  {
    "job_brief_id": "12345",
    "call_status": "Connected: Transporter Confirmed Job Details",
    "caller_id": 123
  }
  ```
- Expected after IVR call completes

## Debugging

### Check Console Logs
Look for these log messages:
- `✓ Job brief call status updated successfully` - API call succeeded
- `✗ Failed to update call status: [message]` - API call failed
- `✗ API error: [status_code]` - Network error

### Common Issues

**Issue: Modal doesn't appear**
- Check if job is assigned to current user
- Check if user is logged in

**Issue: API call fails**
- Check network connectivity
- Verify API endpoint is correct
- Check if job_brief_id is being passed correctly

**Issue: Job Brief modal doesn't open after "Transporter Confirmed Job Details"**
- Check if API response includes success flag
- Verify the feedback text matches exactly: "Transporter Confirmed Job Details"

## Expected Behavior Summary

| Status | Feedback | After Call | Next Action |
|--------|----------|-----------|-------------|
| Connected | Transporter Confirmed Job Details | API call | Job Brief modal opens |
| Connected | Other options | API call | No modal |
| Not Connected | Any option | API call | No modal |
| Call Back Later | Any option | API call | No modal |

## Notes

- All API calls include proper error handling
- The implementation maintains backward compatibility
- Call status is saved in format: "Status: Feedback"
- Job Brief ID is obtained from the IVR call response
