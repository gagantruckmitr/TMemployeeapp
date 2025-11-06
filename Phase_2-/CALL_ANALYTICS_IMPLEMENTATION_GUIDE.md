# Call Analytics & Feedback System - Implementation Guide

## Overview
Complete calling analytics system with detailed statistics, feedback collection, and call logs for Phase 2 app.

## Files Created

### 1. Models
- `Phase_2-/lib/models/call_analytics_model.dart` ✅
  - CallAnalytics model with all statistics
  - CallLog model for call history

### 2. API
- `api/phase2_call_analytics_api.php` ✅
  - GET stats: Detailed call statistics
  - GET logs: Call history with pagination
  - POST feedback: Save call feedback

### 3. Widgets
- `Phase_2-/lib/features/calls/widgets/call_feedback_modal.dart` ✅
  - Modal for collecting call feedback
  - 4 categories of feedback
  - Match status selection
  - Additional notes field

## Call Feedback Categories

### 1. Connected (Green)
- Interview Done
- Not Selected
- Will Confirm Later
- Match Making Done

### 2. Call Back (Orange)
- Ringing / Call Busy
- Switched Off / Not Reachable / Disconnected
- Didn't Pick

### 3. Call Back Later (Blue)
- Busy Right Now
- Call Tomorrow Morning
- Call in Evening
- Call After 2 Days

### 4. Match Status
- Selected
- Not Selected
- Pending

### 5. Additional Notes
- Free text field for remarks

## Statistics Tracked

### Main Stats
- Total Calls
- Transporter Calls
- Driver Calls
- Total Matches
- Selected
- Not Selected

### Detailed Breakdown
- Connected Calls
- Call Backs
- Call Back Later
- Interview Done
- Will Confirm Later
- Match Making Done
- Ringing/Busy
- Switched Off
- Didn't Pick
- Busy Right Now
- Call Tomorrow
- Call Evening
- Call After 2 Days

## Database Table

```sql
CREATE TABLE IF NOT EXISTS `call_logs_match_making` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `caller_id` int(11) NOT NULL,
  `unique_id_transporter` varchar(50) DEFAULT NULL,
  `unique_id_driver` varchar(50) DEFAULT NULL,
  `feedback` varchar(100) DEFAULT NULL,
  `match_status` varchar(50) DEFAULT NULL,
  `call_recording` varchar(255) DEFAULT NULL,
  `transporter_job_remark` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `caller_id` (`caller_id`),
  KEY `unique_id_transporter` (`unique_id_transporter`),
  KEY `unique_id_driver` (`unique_id_driver`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## Implementation Steps

### Step 1: Create Call Analytics Screen
Create `Phase_2-/lib/features/calls/call_analytics_screen.dart`:
- Pink curved header
- Statistics cards grid
- Call logs table
- Pull to refresh
- Search functionality

### Step 2: Add API Service Method
Update `Phase_2-/lib/core/services/phase2_api_service.dart`:
```dart
static Future<CallAnalytics> fetchCallAnalytics() async {
  final response = await http.get(
    Uri.parse('$baseUrl/phase2_call_analytics_api.php?action=stats'),
  );
  // Parse and return
}

static Future<List<CallLog>> fetchCallLogs({int limit = 50, int offset = 0}) async {
  final response = await http.get(
    Uri.parse('$baseUrl/phase2_call_analytics_api.php?action=logs&limit=$limit&offset=$offset'),
  );
  // Parse and return
}

static Future<void> saveCallFeedback({
  required int callerId,
  String? transporterTmid,
  String? driverTmid,
  required String feedback,
  String? matchStatus,
  String? notes,
}) async {
  final response = await http.post(
    Uri.parse('$baseUrl/phase2_call_analytics_api.php'),
    body: json.encode({
      'callerId': callerId,
      'uniqueIdTransporter': transporterTmid,
      'uniqueIdDriver': driverTmid,
      'feedback': feedback,
      'matchStatus': matchStatus,
      'additionalNotes': notes,
    }),
  );
  // Handle response
}
```

### Step 3: Integrate Feedback Modal
In match_making_screen.dart and job_applicants_screen.dart:
```dart
void _showCallFeedbackModal(String userType, String userName, String userTmid) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CallFeedbackModal(
      userType: userType,
      userName: userName,
      userTmid: userTmid,
      onSubmit: (feedback, matchStatus, notes) async {
        await Phase2ApiService.saveCallFeedback(
          callerId: currentUserId,
          transporterTmid: userType == 'transporter' ? userTmid : null,
          driverTmid: userType == 'driver' ? userTmid : null,
          feedback: feedback,
          matchStatus: matchStatus,
          notes: notes,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback saved successfully')),
        );
      },
    ),
  );
}
```

### Step 4: Update Call Buttons
Replace direct call buttons with feedback flow:
```dart
Material(
  color: Colors.green,
  borderRadius: BorderRadius.circular(10),
  child: InkWell(
    onTap: () async {
      // Make the call first
      await _makePhoneCall(driver.mobile);
      // Then show feedback modal
      _showCallFeedbackModal('driver', driver.name, driver.driverTmid);
    },
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.all(10),
      child: const Icon(Icons.call, color: Colors.white, size: 18),
    ),
  ),
),
```

## UI Design for Analytics Screen

### Header Section
- Pink curved header with 3D effect
- Title: "Call Analytics"
- Date range selector

### Statistics Grid (2x3)
```
┌─────────────┬─────────────┐
│ Total Calls │ Transporter │
│     150     │     85      │
├─────────────┼─────────────┤
│   Driver    │   Matches   │
│     65      │     42      │
├─────────────┼─────────────┤
│  Selected   │Not Selected │
│     28      │     14      │
└─────────────┴─────────────┘
```

### Detailed Breakdown
- Expandable sections for each category
- Color-coded chips
- Percentage indicators

### Call Logs Table
- Scrollable list
- User name, TMID, type
- Feedback badge
- Match status badge
- Timestamp
- Tap to view details

## Next Steps

1. Create call_analytics_screen.dart
2. Add navigation from main container
3. Implement statistics cards
4. Create call logs list
5. Add search and filters
6. Test feedback flow
7. Add charts/graphs (optional)

## Benefits

✅ Complete call tracking
✅ Detailed analytics
✅ Easy feedback collection
✅ Match status tracking
✅ Follow-up management
✅ Performance insights
✅ Data-driven decisions
