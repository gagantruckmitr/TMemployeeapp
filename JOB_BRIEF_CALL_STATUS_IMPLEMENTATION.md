# Job Brief Call Status Selection Implementation

## Overview
Implemented a three-stage call status selection flow for job posting calls with integrated API updates.

## Changes Made

### 1. New Modal: `job_call_status_selection_modal.dart`
Created a new modal that appears when the call icon is clicked on a job card. This modal provides:

**Three Main Status Options:**
- **Connected** (Green)
  - Transporter Confirmed Job Details
  - Transporter Wants to Modify Job Details
  - Transporter Wants to Hold the Job
  - Transporter Wants to Cancel the Job
  - Transporter Busy – Requested Call Back
  - Transporter Not Interested Anymore
  - Transporter Shared Additional Information (Notes)

- **Not Connected** (Red)
  - Ringing/Call Busy
  - Switched Off/ Not Reachable
  - Wrong Number

- **Call Back Later** (Orange)
  - Busy Right now
  - Call Tomorrow
  - Call in Evening
  - Call After 2 Days

### 2. Updated: `modern_job_card.dart`
Modified the job card to integrate the new call status selection flow:

**Key Changes:**
- Added import for `job_call_status_selection_modal.dart`
- Added import for `http` and `json` for API calls
- Updated `_makePhoneCall()` to show the status selection modal first
- Added new method `_updateJobBriefCallStatus()` to call the API
- Updated `_handleManualCall()` to accept status and feedback parameters
- Updated `_showTransporterCallFeedbackAfterIVR()` to accept status and feedback

### 3. API Integration

**Call Initiation API:**
- Endpoint: `https://truckmitr.com/api/telehead/ivr-call-jobBrief`
- Already integrated via `EasyGoIVRCallHelper.initiateCall()`
- Used for making the actual IVR call

**Call Status Update API:**
- Endpoint: `https://truckmitr.com/api/telehead/ivr-call-update-jobBrief`
- Called after the call is completed
- Sends:
  - `job_brief_id`: The ID returned from the IVR call
  - `call_status`: Format: "Status: Feedback" (e.g., "Connected: Transporter Confirmed Job Details")
  - `caller_id`: The telecaller's user ID

## Flow

1. **User clicks call icon** on a job card
2. **Call Status Selection Modal appears** with three status options
3. **User selects status** (Connected/Not Connected/Call Back Later)
4. **Feedback options appear** based on selected status
5. **User selects feedback** option
6. **Call Type Dialog appears** (Manual/EasyGo IVR)
7. **If EasyGo IVR selected:**
   - IVR call is initiated via `ivr-call-jobBrief` API
   - After call ends, `ivr-call-update-jobBrief` API is called with the selected status and feedback
   - If feedback is "Transporter Confirmed Job Details", the Job Brief Feedback modal opens
8. **If Manual Call selected:**
   - Direct phone call is made
   - After call, the same feedback is recorded via API

## Special Handling

**For "Transporter Confirmed Job Details":**
- When this option is selected and the call completes, the Job Brief Feedback modal automatically opens
- This allows the telecaller to collect detailed job information from the transporter

**For Other Statuses:**
- The call status is recorded via the API
- No additional modal is shown
- The feedback is saved for future reference

## API Response Handling

The `_updateJobBriefCallStatus()` method:
- Sends the selected status and feedback to the API
- Handles success/error responses
- Automatically opens the Job Brief modal if needed
- Shows appropriate error messages if the API call fails

## Notes

- The call status is sent in the format: "Status: Feedback" (e.g., "Connected: Transporter Confirmed Job Details")
- The API call happens after the IVR call completes
- All API calls include proper error handling and logging
- The implementation maintains backward compatibility with existing code
