# Job Matching Manual Call Implementation Guide

## Overview
This guide explains how to implement manual call functionality for job matching in the TruckMitr Employee App.

## API Endpoints

### 1. Initiate Job Matching Call
**Endpoint:** `https://development.truckmitr.com/api/telehead/manual-call-jobMatching`

**Method:** POST

**Request Body:**
```json
{
  "unique_id_transporter": "TM2501UPTR34342",
  "unique_id_driver": "TM2601DLDR44345",
  "user_id_transporter": 12,
  "user_id_driver": 45,
  "assigned_to": 5,
  "job_id": "TMJB00064",
  "driver_name": "Ramesh Kumar",
  "transporter_name": "ABC Logistics"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 3297
  }
}
```

### 2. Update Job Matching Call
**Endpoint:** `https://development.truckmitr.com/api/telehead/manual-call-update-jobMatching`

**Method:** POST

**Request Body:**
```json
{
  "id": 3297,
  "call_status": "connected",
  "call_feedback": "Driver agreed for job",
  "call_remarks": "Will start tomorrow",
  "match_status": "pending",
  "driver_name": "Ramesh Kumar",
  "transporter_name": "ABC Logistics"
}
```

## Implementation Files

### 1. Service Layer
**File:** `lib/core/services/manual_call_service.dart`

Added two new methods:
- `initiateJobMatchingCall()` - Initiates a job matching call
- `updateJobMatchingCall()` - Updates call with feedback

### 2. Helper Widget
**File:** `lib/features/telecaller/widgets/manual_call_job_matching_helper.dart`

Provides helper methods:
- `initiateJobMatchingCall()` - Handles the complete flow of initiating a call
- `updateJobMatchingCall()` - Updates the call with feedback

### 3. Feedback Modal
**File:** `lib/features/jobs/widgets/job_matching_feedback_modal.dart`

A modal dialog for collecting feedback with:
- Call Status (connected, not_connected, call_back)
- Feedback options based on call status
- Match Status (pending, confirmed, rejected)
- Remarks field

## Usage Example

### In Job Applicants Screen

```dart
import 'package:flutter/material.dart';
import '../../features/telecaller/widgets/manual_call_job_matching_helper.dart';
import '../../features/jobs/widgets/job_matching_feedback_modal.dart';

class JobApplicantsScreen extends StatefulWidget {
  // ... existing code
}

class _JobApplicantsScreenState extends State<JobApplicantsScreen> {
  int? _currentCallId;

  // Method to initiate manual call
  Future<void> _initiateManualCall(DriverApplicant driver) async {
    await ManualCallJobMatchingHelper.initiateJobMatchingCall(
      context: context,
      uniqueIdTransporter: _transporterTmid,
      uniqueIdDriver: driver.tmid,
      userIdTransporter: _transporterUserId.toString(),
      userIdDriver: driver.userId.toString(),
      jobId: widget.jobId,
      driverName: driver.name,
      transporterName: _transporterName,
      phoneNumber: driver.phoneNumber,
      onCallInitiated: (id) {
        setState(() {
          _currentCallId = id;
        });
        
        // Show feedback modal after call
        _showFeedbackModal(driver);
      },
    );
  }

  // Method to show feedback modal
  Future<void> _showFeedbackModal(DriverApplicant driver) async {
    if (_currentCallId == null) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => JobMatchingFeedbackModal(
        driverName: driver.name,
        transporterName: _transporterName,
        onSubmit: (callStatus, callFeedback, remarks, matchStatus) async {
          // Update the call with feedback
          await ManualCallJobMatchingHelper.updateJobMatchingCall(
            context: context,
            id: _currentCallId!,
            callStatus: callStatus,
            callFeedback: callFeedback,
            callRemarks: remarks,
            matchStatus: matchStatus,
            driverName: driver.name,
            transporterName: _transporterName,
          );

          // Close modal
          if (context.mounted) {
            Navigator.of(context).pop();
          }

          // Refresh the list
          _loadApplicants();
        },
      ),
    );
  }

  // Add call button in your UI
  Widget _buildCallButton(DriverApplicant driver) {
    return IconButton(
      icon: Icon(Icons.phone),
      onPressed: () => _initiateManualCall(driver),
      tooltip: 'Manual Call',
    );
  }
}
```

### In Dynamic Jobs Screen

```dart
import 'package:flutter/material.dart';
import '../../features/telecaller/widgets/manual_call_job_matching_helper.dart';
import '../../features/jobs/widgets/job_matching_feedback_modal.dart';

class DynamicJobsScreen extends StatefulWidget {
  // ... existing code
}

class _DynamicJobsScreenState extends State<DynamicJobsScreen> {
  int? _currentCallId;

  Future<void> _makeManualCall({
    required String transporterTmid,
    required String driverTmid,
    required String transporterUserId,
    required String driverUserId,
    required String jobId,
    required String driverName,
    required String transporterName,
    required String phoneNumber,
  }) async {
    await ManualCallJobMatchingHelper.initiateJobMatchingCall(
      context: context,
      uniqueIdTransporter: transporterTmid,
      uniqueIdDriver: driverTmid,
      userIdTransporter: transporterUserId,
      userIdDriver: driverUserId,
      jobId: jobId,
      driverName: driverName,
      transporterName: transporterName,
      phoneNumber: phoneNumber,
      onCallInitiated: (id) {
        setState(() {
          _currentCallId = id;
        });
        
        // Show feedback modal
        _showJobMatchingFeedback(driverName, transporterName);
      },
    );
  }

  Future<void> _showJobMatchingFeedback(String driverName, String transporterName) async {
    if (_currentCallId == null) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => JobMatchingFeedbackModal(
        driverName: driverName,
        transporterName: transporterName,
        onSubmit: (callStatus, callFeedback, remarks, matchStatus) async {
          await ManualCallJobMatchingHelper.updateJobMatchingCall(
            context: context,
            id: _currentCallId!,
            callStatus: callStatus,
            callFeedback: callFeedback,
            callRemarks: remarks,
            matchStatus: matchStatus,
            driverName: driverName,
            transporterName: transporterName,
          );

          if (context.mounted) {
            Navigator.of(context).pop();
          }

          // Refresh data
          _refreshJobs();
        },
      ),
    );
  }
}
```

### In Call History Hub Screen

```dart
import 'package:flutter/material.dart';
import '../../features/telecaller/widgets/manual_call_job_matching_helper.dart';
import '../../features/jobs/widgets/job_matching_feedback_modal.dart';

class CallHistoryHubScreen extends StatefulWidget {
  // ... existing code
}

class _CallHistoryHubScreenState extends State<CallHistoryHubScreen> {
  // Add manual call functionality for job matching calls
  Future<void> _retryJobMatchingCall(CallHistoryItem item) async {
    int? callId;

    await ManualCallJobMatchingHelper.initiateJobMatchingCall(
      context: context,
      uniqueIdTransporter: item.transporterTmid,
      uniqueIdDriver: item.driverTmid,
      userIdTransporter: item.transporterUserId,
      userIdDriver: item.driverUserId,
      jobId: item.jobId,
      driverName: item.driverName,
      transporterName: item.transporterName,
      phoneNumber: item.phoneNumber,
      onCallInitiated: (id) {
        callId = id;
        _showFeedbackForRetry(id, item.driverName, item.transporterName);
      },
    );
  }

  Future<void> _showFeedbackForRetry(int callId, String driverName, String transporterName) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => JobMatchingFeedbackModal(
        driverName: driverName,
        transporterName: transporterName,
        onSubmit: (callStatus, callFeedback, remarks, matchStatus) async {
          await ManualCallJobMatchingHelper.updateJobMatchingCall(
            context: context,
            id: callId,
            callStatus: callStatus,
            callFeedback: callFeedback,
            callRemarks: remarks,
            matchStatus: matchStatus,
            driverName: driverName,
            transporterName: transporterName,
          );

          if (context.mounted) {
            Navigator.of(context).pop();
          }

          _refreshCallHistory();
        },
      ),
    );
  }
}
```

## Call Status Options

### Call Status
- `connected` - Call was answered
- `not_connected` - Call was not answered
- `call_back` - Need to call back later

### Feedback Options (based on call status)

**For "connected":**
- Driver agreed for job
- Driver rejected job
- Driver wants more details
- Driver will call back
- Wrong number
- Not interested

**For "not_connected":**
- Ringing / Call Busy
- Switched Off / Not Reachable
- Invalid number

**For "call_back":**
- Call back in 1 hour
- Call back in 2 hours
- Call back tomorrow
- Call back next week

### Match Status (Optional)
- `pending` - Match is pending
- `confirmed` - Match is confirmed
- `rejected` - Match is rejected

## Features

1. **Automatic Call Initiation**: The helper automatically initiates the API call and opens the phone dialer
2. **Feedback Collection**: Modal dialog collects structured feedback
3. **Error Handling**: Comprehensive error handling with user-friendly messages
4. **Loading States**: Shows loading indicators during API calls
5. **Validation**: Ensures required fields are filled before submission
6. **Optional Fields**: Remarks and match status are optional

## Notes

- The `assigned_to` field is automatically populated from the current logged-in user
- Phone numbers are automatically cleaned (removing non-digit characters) before dialing
- The modal prevents dismissal until feedback is submitted
- All API calls include proper authentication headers
- Comprehensive logging for debugging

## Testing

To test the implementation:

1. Navigate to Job Applicants Screen
2. Click the call button for a driver
3. The phone dialer should open
4. After the call, the feedback modal appears
5. Select call status and feedback
6. Optionally add remarks and match status
7. Submit the feedback
8. Verify the call is logged in the backend
