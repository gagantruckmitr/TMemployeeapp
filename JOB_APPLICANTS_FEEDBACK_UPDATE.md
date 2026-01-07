# Job Applicants Feedback Modal Update

## Overview
Updated the Call Feedback Modal for Job Applicants screen with new UI structure and feedback options.

## Changes Made

### 1. New UI Structure
- **3 Expandable Sections** for call status categories:
  - ✅ Connected (Green) - Expands to show 11 options
  - 📵 Not Connected (Orange) - Expands to show 7 options
  - 🕐 Call Back Later (Blue) - Expands to show 4 options

- **Auto-expanding feedback options** appear instantly below the selected category
- **Match Status** chips (Selected, Not Selected, Pending)
- **Call Remarks** text field (required for Connected and Call Back Later)

### 2. Updated Feedback Options

#### Connected - Driver Screening Completed
```
- Driver Interested
- Driver Not Interested
- Driver Already Booked / Busy
- Driver Does Not Work on That Route
- Driver Rate Mismatch
- Vehicle Not Available
- Vehicle Type Not Matching
- Driver Wants More Details
- Driver Wants to Speak to Transporter
- Driver Wants Call Back Later
- Driver Requested Callback on WhatsApp
```

#### Not Connected
```
- Ringing – No Answer
- Switched Off
- Not Reachable
- Call Disconnected
- Number Busy
- Wrong Number
- Third Person Received – Asked to Call Later
```

#### Call Back Later
```
- Busy Right Now
- Call Tomorrow Morning
- Call in Evening
- Call After 2 Days
```

### 3. Color Coding

**Green Cards** (Positive outcomes):
- Driver Interested
- Driver Wants More Details
- Driver Wants to Speak to Transporter
- Driver Wants Call Back Later
- Driver Requested Callback on WhatsApp

**Red Cards** (Negative outcomes):
- Driver Not Interested
- Driver Already Booked / Busy
- Driver Does Not Work on That Route
- Driver Rate Mismatch
- Vehicle Not Available
- Vehicle Type Not Matching

**Orange Cards** (Not Connected):
- All "Not Connected" options

**Blue Cards** (Call Back Later):
- All "Call Back Later" options

### 4. API Integration

#### IVR Call API
- **Endpoint**: `truckmitr.com/api/telehead/ivr-call-jobMatching`
- Automatically called when using EasyGo IVR for job applicants

#### Feedback Update API
- **Endpoint**: `truckmitr.com/api/telehead/ivr-call-update-jobMatching`
- Sends:
  - `call_status`: "connected" | "not_connected" | "callback_later"
  - `call_feedback`: Selected option (e.g., "Driver Interested")
  - `call_remarks`: Notes from telecaller
  - `id`: Match ID from IVR call response

### 5. Validation Rules
1. Must select a call status category (radio button)
2. Must select a feedback option from dropdown
3. Call Remarks is **mandatory** for:
   - Connected category
   - Call Back Later category
4. Call Remarks is **optional** for:
   - Not Connected category

### 6. User Flow
1. Telecaller calls driver using EasyGo IVR
2. After call ends, feedback modal appears
3. Click on call status category (Connected/Not Connected/Call Back Later)
4. Category expands instantly showing all feedback options below
5. Select specific feedback option from the expanded list
6. Select match status (optional)
7. Enter call remarks (required for Connected and Call Back Later)
8. Submit feedback

### 7. UI Behavior
- Click on a category to expand and see all options
- Click on the same category again to collapse it
- Only one category can be expanded at a time
- Selected category shows with colored border and background
- Selected feedback option is highlighted with radio button
- Expand/collapse icon (▼/▲) indicates current state
- **Modal is uncloseable** until feedback is submitted:
  - No close button (X) in header
  - No drag handle to dismiss
  - Back button disabled
  - Tapping outside modal doesn't close it
  - Must submit feedback to close
- Submit button is centered and 70% width
- "Required" badge shown in header to indicate mandatory feedback

### 8. Filter Options Updated
The feedback filter in Job Applicants screen now includes all new feedback options for easy filtering.

## Files Modified
1. `lib/features/calls/widgets/call_feedback_modal.dart`
   - Added expandable category sections
   - Options auto-expand below selected category
   - Updated validation logic
   - Improved UI/UX with instant feedback
   - **Made modal uncloseable without feedback submission**:
     - Wrapped in `PopScope(canPop: false)` to disable back button
     - Removed close button from header
     - Removed drag handle
     - Added "Required" badge to header
   - Centered submit button (70% width)

2. `lib/features/jobs/job_applicants_screen.dart`
   - Updated feedback filter options
   - Updated color coding functions
   - Updated call_status extraction logic
   - Made modal non-dismissible:
     - `isDismissible: false` - prevents tap outside to close
     - `enableDrag: false` - prevents drag down to close

## Testing Checklist
- [ ] Category sections expand/collapse correctly
- [ ] Only one category can be expanded at a time
- [ ] All feedback options show instantly when category is selected
- [ ] Radio buttons work for selecting feedback options
- [ ] Validation prevents submission without required fields
- [ ] Call remarks validation works for Connected and Call Back Later
- [ ] Feedback is saved correctly to API
- [ ] Card colors match feedback type
- [ ] Filter works with new feedback options
- [ ] IVR call integration works end-to-end
- [ ] Expand/collapse icons update correctly
