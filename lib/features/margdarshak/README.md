# Margdarshak (Field Agent) Module

## Overview
This module handles all functionality for field agents (Margdarshak) including authentication, dashboard, shop onboarding, driver management, and earnings tracking.

## Structure

```
lib/features/margdarshak/
├── models/
│   └── margdarshak_user_model.dart      # User and login response models
├── services/
│   ├── margdarshak_auth_service.dart    # Authentication service
│   ├── margdarshak_api_service.dart     # API service for all operations
│   └── notification_service.dart        # Push notification handling
├── screens/
│   ├── dashboard/
│   │   └── index.dart                   # Main dashboard screen
│   ├── add_shop/
│   │   └── index.dart                   # Shop onboarding screen
│   ├── profile/
│   │   └── index.dart                   # Profile management
│   └── navigation/
│       └── index.dart                   # Bottom navigation container
├── widgets/
│   ├── dashboard_stats_card.dart        # Stats display widget
│   ├── duty_tracking_widget.dart        # Check-in/out widget
│   ├── quick_action_card.dart           # Action buttons
│   └── recent_activity_card.dart        # Activity feed
└── utils/
    └── fcm_token_helper.dart            # FCM token utilities
```

## API Integration

### Authentication

**Endpoint:** `POST https://truckmitr.com/api/margdarshak/login`

**Request:**
```json
{
  "mobile": "6394752222",
  "password": "12345678"
}
```

**Response:**
```json
{
  "status": true,
  "message": "Login successful",
  "token": "1037|EWW75QnuGouzqXm0oruFm0t3q9p4ILZR4j7ACEJW6620ea4a",
  "data": {
    "user": {
      "id": 1,
      "employee_id": "TMFA0001",
      "name": "Gagan Shukla Cheeta",
      "email": null,
      "mobile": "6394752222",
      "role": "field_agent",
      "states": "35",
      "status": "active",
      "profile_image": null,
      "join_date": "2026-01-29",
      "state_name": "Uttar Pradesh"
    }
  }
}
```

### Dashboard Stats

**Endpoint:** `GET https://truckmitr.com/api/margdarshak/dashboard`

**Headers:**
```
Authorization: Bearer {token}
```

**Expected Response:**
```json
{
  "territory": {
    "state": "Uttar Pradesh",
    "districts": 3
  },
  "shops": {
    "total": 45,
    "dhabhas": 28,
    "puncture": 17,
    "pending": 5
  },
  "drivers": {
    "today": 12,
    "week": 78,
    "month": 234,
    "total": 1456
  },
  "earnings": {
    "today": 120,
    "week": 780,
    "month": 2340,
    "pending": 450
  }
}
```

### Other Endpoints

- `GET https://truckmitr.com/api/margdarshak/shops` - Get shops list
- `POST https://truckmitr.com/api/margdarshak/shops` - Add new shop
- `GET https://truckmitr.com/api/margdarshak/drivers` - Get drivers list
- `GET https://truckmitr.com/api/margdarshak/earnings` - Get earnings summary
- `POST https://truckmitr.com/api/margdarshak/duty-status` - Update duty status
- `GET https://truckmitr.com/api/margdarshak/territory` - Get territory info

## Services

### MargdarshakAuthService

Handles authentication and session management.

**Usage:**
```dart
final authService = MargdarshakAuthService();

// Login
final response = await authService.login(
  mobile: '6394752222',
  password: '12345678',
);

if (response.isSuccess) {
  print('Logged in: ${response.user?.name}');
}

// Check session
final hasSession = await authService.loadSession();

// Logout
await authService.logout();

// Get current user
final user = authService.currentUser;

// Get auth headers
final headers = authService.getAuthHeaders();
```

### MargdarshakApiService

Handles all API calls for field agent operations.

**Usage:**
```dart
final apiService = MargdarshakApiService();

// Get dashboard stats
final stats = await apiService.getDashboardStats();

// Get shops
final shops = await apiService.getShops(status: 'pending');

// Add shop
final result = await apiService.addShop({
  'name': 'Sharma Dhaba',
  'type': 'dhaba',
  'location': 'Pune',
});

// Get drivers
final drivers = await apiService.getDrivers(limit: 50);

// Get earnings
final earnings = await apiService.getEarnings(period: 'month');

// Update duty status
await apiService.updateDutyStatus(
  status: 'check_in',
  latitude: 18.5204,
  longitude: 73.8567,
);
```

## Models

### MargdarshakUser

Represents a field agent user.

**Properties:**
- `id` - User ID
- `employeeId` - Employee ID (e.g., TMFA0001)
- `name` - Full name
- `mobile` - Mobile number
- `role` - User role (field_agent)
- `states` - State ID
- `stateName` - State name
- `status` - Account status (active/inactive)
- `joinDate` - Join date
- Bank details (optional)

### MargdarshakLoginResponse

Represents login API response.

**Properties:**
- `status` - Success/failure status
- `message` - Response message
- `token` - Auth token
- `user` - User object

## Login Flow

1. User enters mobile and password
2. App calls `MargdarshakAuthService.login()`
3. Service makes POST request to `/api/margdarshak/login`
4. On success:
   - User data and token saved to memory
   - Session persisted to SharedPreferences
   - User redirected to dashboard
5. On failure:
   - Error message displayed

## Dashboard Flow

1. Dashboard loads on app start
2. Checks for existing session via `loadSession()`
3. If session exists, loads user data
4. Fetches dashboard stats from API
5. Displays:
   - User info header
   - Duty tracking widget
   - Territory summary
   - Stats cards (shops, drivers, earnings)
   - Quick action buttons
   - Recent activity feed
6. On API failure, shows offline mode with cached data

## Configuration

Update API base URL in `lib/core/config/api_config.dart`:

```dart
// Margdarshak API Base URL (separate from main API)
static const String margdarshakApiBase = 'https://truckmitr.com/api';
```

**Note:** The Margdarshak API uses a different base URL (`https://truckmitr.com/api`) compared to the main app API (`https://devtruckmitr.in/truckmitr-app/api`).

## Demo Credentials

For testing, use:
- Mobile: `6394752222`
- Password: `12345678`

## Notes

- All API calls include Bearer token authentication
- Session is persisted across app restarts
- Offline mode available with cached data
- Push notifications supported via FCM
- Location tracking for duty check-in/out
