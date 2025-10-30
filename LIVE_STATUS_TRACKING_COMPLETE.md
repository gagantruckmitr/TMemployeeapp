# Live Status Tracking System - Complete Implementation

## Features Implemented

### 1. Activity Tracking Service
**File:** `lib/core/services/activity_tracker_service.dart`

Features:
- Tracks user activity in real-time
- Sends heartbeat every 30 seconds
- Checks for inactivity every 30 seconds
- Auto-logout after 10 minutes of inactivity
- Records last activity timestamp

### 2. Live Status API
**File:** `api/live_status_api.php`

Endpoints:
- `login` - Records login time and sets status to online
- `logout` - Records logout time and sets status to offline
- `heartbeat` - Updates last activity timestamp
- `get_status` - Gets status for a single telecaller
- `get_all_status` - Gets status for all telecallers
- `check_inactive` - Finds and auto-logs out inactive users

### 3. Break Status Popup
**File:** `lib/features/telecaller/widgets/break_status_popup.dart`

Features:
- Beautiful gradient design matching break type
- Real-time timer showing break duration
- Shows break start time
- End Break button
- Color-coded by break type:
  - Tea Break: Orange
  - Lunch Break: Green
  - Prayer Break: Blue
  - Personal Break: Purple

### 4. Live Telecaller Status Widget (Manager Dashboard)
**File:** `lib/features/manager/widgets/live_telecaller_status_widget.dart`

Features:
- Shows all telecallers with live status
- Auto-refreshes every 10 seconds
- Status badges (Online, On Break, Offline)
- Displays for each telecaller:
  - Login time
  - Online duration
  - Total break time
  - Today's calls
  - Today's connected calls
  - Last activity time
  - Inactive warning (if >10 min)

### 5. Enhanced Leave Break Widget
**File:** `lib/features/telecaller/widgets/enhanced_leave_break_widget.dart`

Updates:
- Integrated break popup
- Shows popup when break starts
- Popup stays until break is ended
- Debug logging for troubleshooting

### 6. Real Auth Service Updates
**File:** `lib/core/services/real_auth_service.dart`

Updates:
- Records login time on successful login
- Records logout time on logout
- Integrates with live status API
- Maintains backward compatibility

## Database Structure

### telecaller_status table
```sql
CREATE TABLE `telecaller_status` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `telecaller_id` int(11) NOT NULL UNIQUE,
  `telecaller_name` varchar(255) DEFAULT NULL,
  `current_status` enum('offline','online','on_call','break','on_leave') DEFAULT 'offline',
  `login_time` datetime DEFAULT NULL,
  `logout_time` datetime DEFAULT NULL,
  `break_start_time` datetime DEFAULT NULL,
  `total_online_seconds` int(11) DEFAULT 0,
  `total_break_seconds` int(11) DEFAULT 0,
  `today_calls` int(11) DEFAULT 0,
  `today_connected` int(11) DEFAULT 0,
  `last_activity` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `telecaller_id` (`telecaller_id`),
  KEY `current_status` (`current_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## How It Works

### Login Flow
1. User logs in
2. `RealAuthService` calls `_recordLogin()`
3. API creates/updates record in `telecaller_status`
4. Sets `current_status` = 'online'
5. Records `login_time` = NOW()
6. Sets `last_activity` = NOW()

### Activity Tracking
1. `ActivityTrackerService` starts on app launch
2. Sends heartbeat every 30 seconds
3. Updates `last_activity` in database
4. Checks for inactivity locally
5. If inactive >10 min, triggers auto-logout

### Break Flow
1. User taps break button
2. API creates record in `break_logs`
3. Updates `telecaller_status.current_status` = 'break'
4. Shows beautiful break popup
5. Timer runs in popup
6. User taps "End Break"
7. API updates break record
8. Updates status back to 'online'
9. Popup closes

### Logout Flow
1. User logs out (manual or auto)
2. `RealAuthService` calls `_recordLogout()`
3. API ends any active breaks
4. Updates `telecaller_status.current_status` = 'offline'
5. Records `logout_time` = NOW()
6. Clears local session

### Manager Dashboard
1. Widget loads all telecaller statuses
2. Auto-refreshes every 10 seconds
3. Shows real-time data:
   - Current status
   - Login/logout times
   - Break durations
   - Call statistics
   - Inactive warnings
4. Color-coded status indicators

## Integration Steps

### 1. Add Activity Tracking to App
```dart
// In main.dart or app.dart
import 'core/services/activity_tracker_service.dart';

// After successful login
ActivityTrackerService.instance.startTracking();

// On logout
ActivityTrackerService.instance.stopTracking();
```

### 2. Add Live Status to Manager Dashboard
```dart
// In manager_dashboard_page.dart
import 'widgets/live_telecaller_status_widget.dart';

// Add to dashboard
LiveTelecallerStatusWidget()
```

### 3. Record User Activity
```dart
// On any user interaction (tap, scroll, etc.)
ActivityTrackerService.instance.recordActivity();
```

## API Endpoints

### Login
```
POST /api/live_status_api.php?action=login
Body: {"telecaller_id": 3}
```

### Logout
```
POST /api/live_status_api.php?action=logout
Body: {"telecaller_id": 3}
```

### Heartbeat
```
POST /api/live_status_api.php?action=heartbeat
Body: {"telecaller_id": 3, "last_activity": "2025-01-15T10:30:00"}
```

### Get Status
```
GET /api/live_status_api.php?action=get_status&telecaller_id=3
```

### Get All Status
```
GET /api/live_status_api.php?action=get_all_status
```

### Check Inactive
```
GET /api/live_status_api.php?action=check_inactive
```

## Testing

### Test Login Recording
1. Login to app
2. Check database: `SELECT * FROM telecaller_status WHERE telecaller_id = 3`
3. Verify `login_time` is set
4. Verify `current_status` = 'online'

### Test Break Popup
1. Tap any break button
2. Verify popup appears
3. Verify timer is running
4. Tap "End Break"
5. Verify popup closes

### Test Auto-Logout
1. Login to app
2. Don't interact for 10 minutes
3. Verify auto-logout occurs
4. Check database: `logout_time` should be set

### Test Manager Dashboard
1. Login as manager
2. Navigate to dashboard
3. Verify live status widget shows
4. Verify data refreshes every 10 seconds
5. Verify inactive warnings appear

## Configuration

### Inactivity Timeout
Change in `activity_tracker_service.dart`:
```dart
static const Duration _inactivityTimeout = Duration(minutes: 10);
```

### Heartbeat Interval
Change in `activity_tracker_service.dart`:
```dart
static const Duration _heartbeatInterval = Duration(seconds: 30);
```

### Dashboard Refresh Rate
Change in `live_telecaller_status_widget.dart`:
```dart
_refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
```

## Benefits

✅ Real-time status tracking
✅ Automatic inactivity detection
✅ Beautiful break popups
✅ Manager visibility into team activity
✅ Accurate time tracking
✅ Auto-logout for security
✅ Heartbeat mechanism for reliability
✅ Scalable architecture

## Next Steps (Optional)

1. Add push notifications for inactive users
2. Add break time limits
3. Add productivity reports
4. Add status change history
5. Add manager alerts for long breaks
6. Add team performance metrics
7. Add export functionality for reports
