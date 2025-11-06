# Transporter Call Feedback System ✅

## Overview
New hierarchical call feedback system for telecallers when calling transporters about job postings.

## Call Status Structure

### Level 1: Main Status
Telecaller first selects the main call status:

1. **Connected** (Green)
2. **Not Connected** (Red)

### Level 2: Sub-Status Options

#### If "Connected" selected:
- Call Back Later
- Details Received ⭐
- Not a Genuine Transporter
- He is Driver, mistakenly registered as Transporter

#### If "Not Connected" selected:
- Ringing / Call Busy
- Switched Off / Not Reachable

### Level 3: Feedback Notes (Conditional)
- **Only shown when**: "Connected: Details Received" is selected
- **Field**: Multi-line text input for detailed feedback
- **Required**: Yes (must enter notes before submitting)

## Database Storage Format

The call status is saved in a combined format:

```
Format: "{MainStatus}: {SubStatus}"

Examples:
- "Connected: Details Received"
- "Connected: Call Back Later"
- "Not Connected: Ringing / Call Busy"
- "Connected: Not a Genuine Transporter"
```

## Database Fields

### job_brief_table
- `call_status_feedback` (VARCHAR): Stores the combined status
- `notes` (TEXT): Stores feedback notes (only when Details Received)

Example data:
```sql
call_status_feedback: "Connected: Details Received"
notes: "Transporter confirmed availability of 5 drivers for Delhi-Mumbai route. Salary expectation 30k-35k. Can start within 2 days."
```

## User Flow

1. **Telecaller calls transporter**
2. **Opens feedback modal**
3. **Selects main status**: Connected or Not Connected
4. **Selects sub-status**: From available options
5. **If "Details Received"**: Enters detailed notes
6. **Submits feedback**: Data saved to database

## UI Features

### Main Status Buttons
- Large, clear buttons with icons
- Green for Connected, Red for Not Connected
- Visual feedback on selection

### Sub-Status Options
- Radio button style selection
- Clear, readable options
- Highlights selected option

### Notes Field
- Only appears for "Details Received"
- Multi-line text area
- Placeholder text for guidance
- Required validation

### Submit Button
- Disabled until all required fields filled
- Loading state during submission
- Clear success/error feedback

## API Integration

### Endpoint
`POST /api/phase2_job_brief_api.php`

### Request Body
```json
{
  "uniqueId": "TM2511HRTR14825",
  "jobId": "TMJB00429",
  "callerId": 3,
  "callStatusFeedback": "Connected: Details Received",
  "notes": "Transporter details...",
  "name": "Transporter Name",
  "jobLocation": "Delhi",
  ...other fields
}
```

### Response
```json
{
  "success": true,
  "message": "Job brief saved successfully",
  "data": {
    "id": 123,
    "uniqueId": "TM2511HRTR14825",
    "jobId": "TMJB00429"
  }
}
```

## Benefits

✅ **Clear hierarchy**: Two-level selection is intuitive
✅ **Comprehensive options**: Covers all call scenarios
✅ **Conditional fields**: Notes only when needed
✅ **Data consistency**: Standardized format in database
✅ **Easy reporting**: Can filter by main status or sub-status
✅ **Better tracking**: Detailed feedback for successful calls

## Usage Example

```dart
import 'package:your_app/features/jobs/widgets/show_transporter_call_feedback.dart';

// Show feedback modal
await showTransporterCallFeedback(
  context: context,
  transporterTmid: 'TM2511HRTR14825',
  transporterName: 'Rajpal Transport',
  jobId: 'TMJB00429',
  onSubmit: (callStatus, notes) async {
    // Save to database
    await Phase2ApiService.saveJobBrief(
      uniqueId: transporterTmid,
      jobId: jobId,
      callStatusFeedback: callStatus,
      notes: notes,
      // ...other fields
    );
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Feedback saved successfully')),
    );
  },
);
```

## Files Created

1. `transporter_call_feedback_modal.dart` - Main modal widget
2. `show_transporter_call_feedback.dart` - Helper function

## Next Steps

To integrate this into your app:

1. Import the helper function where you need it
2. Call `showTransporterCallFeedback()` after telecaller makes a call
3. Handle the `onSubmit` callback to save data
4. Update your API to accept the new format
5. Test all scenarios thoroughly

The system is ready to use!
