# Visual Flow Diagram - Job Brief Call Status

## Complete User Journey

```
┌─────────────────────────────────────────────────────────────────┐
│                    JOB POSTINGS SCREEN                          │
│                                                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Job Card                                                 │  │
│  │ ┌────────────────────────────────────────────────────┐  │  │
│  │ │ Transporter Name                                   │  │  │
│  │ │ Job Details                                        │  │  │
│  │ │ [Applicants] [Call Icon] [View Details]           │  │  │
│  │ │                    ↓ CLICK                         │  │  │
│  │ └────────────────────────────────────────────────────┘  │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│         CALL STATUS SELECTION MODAL (Appears Immediately)       │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 📞 Call Status                                          │   │
│  │ Transporter Name                                        │   │
│  │                                                         │   │
│  │ Select Call Status:                                     │   │
│  │ ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │   │
│  │ │ ✓ Connected  │  │ Not Connected│  │ Call Back    │   │   │
│  │ │   (Green)    │  │   (Red)      │  │ Later(Orange)│   │   │
│  │ └──────────────┘  └──────────────┘  └──────────────┘   │   │
│  │                                                         │   │
│  │ Select Feedback:                                        │   │
│  │ ┌──────────────────────────────────────────────────┐   │   │
│  │ │ ○ Transporter Confirmed Job Details             │   │   │
│  │ │ ○ Transporter Wants to Modify Job Details       │   │   │
│  │ │ ○ Transporter Wants to Hold the Job             │   │   │
│  │ │ ○ Transporter Wants to Cancel the Job           │   │   │
│  │ │ ○ Transporter Busy – Requested Call Back        │   │   │
│  │ │ ○ Transporter Not Interested Anymore            │   │   │
│  │ │ ○ Transporter Shared Additional Information      │   │   │
│  │ └──────────────────────────────────────────────────┘   │   │
│  │                                                         │   │
│  │ [Continue Button]                                       │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│              CALL TYPE SELECTION DIALOG                         │
│                                                                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ How would you like to call?                             │   │
│  │                                                         │   │
│  │ [Manual Call]  [EasyGo IVR]                             │   │
│  └─────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
                    ↙                    ↘
        ┌──────────────────┐    ┌──────────────────┐
        │  MANUAL CALL     │    │  EASYGO IVR      │
        └──────────────────┘    └──────────────────┘
                ↓                        ↓
        ┌──────────────────┐    ┌──────────────────┐
        │ Direct Phone     │    │ IVR Call Waiting │
        │ Call Made        │    │ Overlay          │
        │                  │    │                  │
        │ [Phone Rings]    │    │ Both phones ring │
        │                  │    │ Waiting...       │
        │ [Call Ends]      │    │ [Call Ends]      │
        └──────────────────┘    └──────────────────┘
                ↓                        ↓
        ┌──────────────────┐    ┌──────────────────┐
        │ API Call:        │    │ API Call:        │
        │ ivr-call-update- │    │ ivr-call-update- │
        │ jobBrief         │    │ jobBrief         │
        │                  │    │                  │
        │ Status: Manual   │    │ Status: IVR      │
        │ Feedback: [sel]  │    │ Feedback: [sel]  │
        └──────────────────┘    └──────────────────┘
                ↓                        ↓
        ┌──────────────────────────────────────────┐
        │ Check Feedback Type                      │
        └──────────────────────────────────────────┘
                ↓
        ┌──────────────────────────────────────────┐
        │ Is feedback "Transporter Confirmed       │
        │ Job Details"?                            │
        └──────────────────────────────────────────┘
            ↙                              ↘
        YES                                NO
        ↓                                  ↓
    ┌─────────────────────┐        ┌──────────────┐
    │ Job Brief Feedback  │        │ Feedback     │
    │ Modal Opens         │        │ Saved        │
    │                     │        │              │
    │ User fills in:      │        │ Done ✓       │
    │ - Job Details       │        └──────────────┘
    │ - Notes             │
    │ - Recording         │
    │                     │
    │ [Submit]            │
    │     ↓               │
    │ API Call:           │
    │ phase2_job_brief_   │
    │ api.php             │
    │     ↓               │
    │ Job Brief Saved ✓   │
    └─────────────────────┘
```

## Status Selection Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    STATUS SELECTION                             │
└─────────────────────────────────────────────────────────────────┘

CONNECTED (Green)
├─ Transporter Confirmed Job Details
│  └─ → Opens Job Brief Modal
├─ Transporter Wants to Modify Job Details
│  └─ → Saves Feedback
├─ Transporter Wants to Hold the Job
│  └─ → Saves Feedback
├─ Transporter Wants to Cancel the Job
│  └─ → Saves Feedback
├─ Transporter Busy – Requested Call Back
│  └─ → Saves Feedback
├─ Transporter Not Interested Anymore
│  └─ → Saves Feedback
└─ Transporter Shared Additional Information
   └─ → Saves Feedback

NOT CONNECTED (Red)
├─ Ringing/Call Busy
│  └─ → Saves Feedback
├─ Switched Off/ Not Reachable
│  └─ → Saves Feedback
└─ Wrong Number
   └─ → Saves Feedback

CALL BACK LATER (Orange)
├─ Busy Right now
│  └─ → Saves Feedback
├─ Call Tomorrow
│  └─ → Saves Feedback
├─ Call in Evening
│  └─ → Saves Feedback
└─ Call After 2 Days
   └─ → Saves Feedback
```

## API Call Sequence

```
┌──────────────────────────────────────────────────────────────────┐
│                    API CALL SEQUENCE                             │
└──────────────────────────────────────────────────────────────────┘

1. User clicks Call Icon
   ↓
2. Status Modal appears
   ↓
3. User selects Status & Feedback
   ↓
4. User selects Call Type
   ↓
5. API CALL #1: ivr-call-jobBrief
   ├─ Endpoint: https://truckmitr.com/api/telehead/ivr-call-jobBrief
   ├─ Method: POST
   ├─ Returns: job_brief_id
   └─ Status: ✓ Call Initiated
   ↓
6. IVR Call Waiting (Both phones ring)
   ↓
7. Call Ends
   ↓
8. API CALL #2: ivr-call-update-jobBrief
   ├─ Endpoint: https://truckmitr.com/api/telehead/ivr-call-update-jobBrief
   ├─ Method: POST
   ├─ Body: {
   │   "job_brief_id": "12345",
   │   "call_status": "Connected: Transporter Confirmed Job Details",
   │   "caller_id": 123
   │ }
   └─ Status: ✓ Status Updated
   ↓
9. Check Feedback Type
   ├─ If "Transporter Confirmed Job Details"
   │  └─ Open Job Brief Modal
   │     ↓
   │     10. API CALL #3: phase2_job_brief_api.php
   │         ├─ Endpoint: https://truckmitr.com/api/telehead/phase2_job_brief_api.php
   │         ├─ Method: POST
   │         ├─ Body: {
   │         │   "uniqueId": "TMID",
   │         │   "jobId": "JOB123",
   │         │   "callerId": 123,
   │         │   "name": "Transporter Name",
   │         │   "callStatusFeedback": "Connected: Transporter Confirmed Job Details",
   │         │   "callRecording": "url (optional)"
   │         │ }
   │         └─ Status: ✓ Job Brief Saved
   │
   └─ Otherwise
      └─ Done (Feedback Saved)
```

## State Management

```
┌──────────────────────────────────────────────────────────────────┐
│                    STATE FLOW                                    │
└──────────────────────────────────────────────────────────────────┘

Initial State
├─ _selectedStatus: null
├─ _selectedFeedback: null
└─ _isSubmitting: false

After Status Selection
├─ _selectedStatus: "Connected"
├─ _selectedFeedback: null
└─ _isSubmitting: false

After Feedback Selection
├─ _selectedStatus: "Connected"
├─ _selectedFeedback: "Transporter Confirmed Job Details"
└─ _isSubmitting: false

During Submission
├─ _selectedStatus: "Connected"
├─ _selectedFeedback: "Transporter Confirmed Job Details"
└─ _isSubmitting: true

After Submission
├─ Modal closes
├─ Call initiated
└─ Status updated via API
```

## Error Handling Flow

```
┌──────────────────────────────────────────────────────────────────┐
│                    ERROR HANDLING                                │
└──────────────────────────────────────────────────────────────────┘

User clicks Call Icon
    ↓
Check: Is job assigned to me?
├─ NO → Show orange snackbar "Job assigned to another telecaller"
└─ YES → Continue
    ↓
Show Status Modal
    ↓
User selects Status & Feedback
    ↓
Show Call Type Dialog
    ↓
Initiate Call
    ├─ Network Error → Show error snackbar
    ├─ Invalid Phone → Show error snackbar
    └─ Success → Continue
    ↓
Call Ends
    ↓
API Call: ivr-call-update-jobBrief
    ├─ Network Error → Log error, no modal
    ├─ API Error → Log error, no modal
    └─ Success → Check feedback type
    ↓
If "Transporter Confirmed Job Details"
    ├─ Open Job Brief Modal
    └─ User submits
        ├─ Network Error → Show error snackbar
        ├─ API Error → Show error snackbar
        └─ Success → Show success snackbar
```

## Component Hierarchy

```
ModernJobCard
├── _buildActionButtons()
│   └── Call Icon Button
│       └── _makePhoneCall()
│           ├── JobCallStatusSelectionModal
│           │   ├── Status Buttons
│           │   ├── Feedback Grid
│           │   └── Continue Button
│           │
│           ├── CallTypeSelectionDialog
│           │   ├── Manual Call Option
│           │   └── EasyGo IVR Option
│           │
│           ├── EasyGoIVRCallHelper.initiateCall()
│           │   └── IVRCallWaitingOverlay
│           │
│           └── _updateJobBriefCallStatus()
│               └── JobBriefFeedbackModal
│                   ├── Job Details Form
│                   ├── Notes Field
│                   ├── Recording Upload
│                   └── Submit Button
```

## Timeline

```
T0:   User clicks call icon
T1:   Status modal appears
T2:   User selects status & feedback
T3:   Call type dialog appears
T4:   User selects call type
T5:   IVR call initiated (API #1)
T6:   Both phones ring
T7:   Call in progress
T8:   Call ends
T9:   IVR overlay closes
T10:  Status updated (API #2)
T11:  Check feedback type
T12:  If "Confirmed Details" → Job Brief modal opens (API #3)
T13:  User fills job details
T14:  User submits
T15:  Job brief saved
T16:  Done ✓
```

---

This visual representation shows the complete flow from user interaction through API calls to final result.
