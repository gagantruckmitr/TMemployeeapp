# Manager Tracking Dashboard - Complete Specification

## Overview
A comprehensive, beautiful tracking dashboard for managers to monitor all team activities in one place.

## Features

### 1. Live Status Tab
**Shows real-time status of all telecallers**

Components:
- Summary cards (Online, On Break, Offline counts)
- Individual telecaller cards showing:
  - Name and avatar
  - Current status (online/break/offline)
  - Inactive warning (if >10 min)
  - Login time
  - Logout time
  - Online duration
  - Total break time today
  - Today's calls
  - Today's connected calls
  - Last activity time

### 2. Leave Requests Tab
**Manage all leave requests**

Components:
- Pending requests count badge
- Leave request cards showing:
  - Telecaller name
  - Leave type (Sick, Casual, Emergency, etc.)
  - Start date - End date
  - Total days
  - Reason
  - Request date
  - Approve/Reject buttons
- Filter by status (Pending, Approved, Rejected)
- Search by telecaller name

### 3. Break History Tab
**View all breaks taken today**

Components:
- Summary cards:
  - Total breaks today
  - Total break time
  - Average break duration
  - Most common break type
- Break cards showing:
  - Telecaller name
  - Break type with icon
  - Start time
  - End time (or "Active" if ongoing)
  - Duration
  - Status (Active/Completed)
- Filter by:
  - Break type
  - Telecaller
  - Status (Active/Completed)
- Timeline view option

## UI Design

### Color Scheme
- Primary: Teal (#14B8A6)
- Success: Green (#10B981)
- Warning: Orange (#F59E0B)
- Error: Red (#EF4444)
- Info: Blue (#3B82F6)
- Background: Light Gray (#F5F7FA)

### Card Design
- White background
- Rounded corners (16px)
- Subtle shadow
- Color-coded status indicators
- Icons for visual clarity

### Status Colors
- Online: Green
- On Break: Orange
- Offline: Gray
- Inactive: Orange with warning icon

### Break Type Colors
- Tea Break: Orange
- Lunch Break: Green
- Prayer Break: Blue
- Personal Break: Purple

## API Endpoints Needed

### 1. Get All Status
```
GET /api/live_status_api.php?action=get_all_status
Response: {
  success: true,
  data: [
    {
      telecaller_id: 3,
      telecaller_name: "Pooja Pal",
      current_status: "online",
      login_time: "2025-01-15 09:00:00",
      logout_time: null,
      online_duration: "02:30:00",
      total_break_duration: "00:15:00",
      today_calls: 25,
      today_connected: 15,
      is_inactive: false
    }
  ]
}
```

### 2. Get Leave Requests
```
GET /api/enhanced_leave_management_api.php?action=get_pending_approvals
Response: {
  success: true,
  data: [
    {
      id: 1,
      telecaller_id: 3,
      telecaller_name: "Pooja Pal",
      leave_type: "casual_leave",
      start_date: "2025-01-20",
      end_date: "2025-01-21",
      total_days: 2,
      reason: "Personal work",
      status: "pending",
      created_at: "2025-01-15 10:00:00"
    }
  ]
}
```

### 3. Approve/Reject Leave
```
POST /api/enhanced_leave_management_api.php?action=approve_leave
Body: {
  leave_id: 1,
  manager_id: 2,
  status: "approved",
  remarks: "Approved"
}
```

### 4. Get Today's Breaks
```
GET /api/enhanced_leave_management_api.php?action=get_all_breaks_today
Response: {
  success: true,
  data: [
    {
      id: 1,
      telecaller_id: 3,
      telecaller_name: "Pooja Pal",
      break_type: "tea_break",
      start_time: "2025-01-15 10:30:00",
      end_time: "2025-01-15 10:45:00",
      duration_seconds: 900,
      duration_formatted: "00:15:00",
      status: "completed"
    }
  ]
}
```

## Implementation Files

### Main Screen
`lib/features/manager/screens/team_tracking_screen.dart`
- TabController with 3 tabs
- Auto-refresh every 10 seconds
- Pull-to-refresh
- Loading states

### Tab Widgets
1. `lib/features/manager/widgets/live_status_tab.dart`
2. `lib/features/manager/widgets/leave_requests_tab.dart`
3. `lib/features/manager/widgets/break_history_tab.dart`

### Supporting Widgets
1. `lib/features/manager/widgets/telecaller_status_card.dart`
2. `lib/features/manager/widgets/leave_request_card.dart`
3. `lib/features/manager/widgets/break_history_card.dart`
4. `lib/features/manager/widgets/approval_dialog.dart`

## Features Summary

✅ Real-time status monitoring
✅ Leave request management
✅ Break history tracking
✅ Auto-refresh every 10 seconds
✅ Pull-to-refresh
✅ Search and filter
✅ Approve/reject leaves
✅ Color-coded indicators
✅ Inactive warnings
✅ Summary statistics
✅ Beautiful UI design

## Integration

Add to manager dashboard:
```dart
// In manager_dashboard_page.dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TeamTrackingScreen(),
      ),
    );
  },
  child: const Text('Team Tracking'),
)
```

Or add as a tab in the existing dashboard.

## Next Steps

1. Create the main screen with TabController
2. Implement each tab widget
3. Create API endpoints for leave approval
4. Add search and filter functionality
5. Add export functionality
6. Add notifications for pending approvals
7. Add analytics and reports

This will give managers complete visibility into their team's activities!
