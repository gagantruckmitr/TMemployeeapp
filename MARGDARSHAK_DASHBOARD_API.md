# Margdarshak Dashboard API Integration ✅

## Summary
Integrated the Margdarshak dashboard API endpoint with proper configuration and Bearer token authentication.

## API Endpoint

### GET /api/margdarshak/dashboard
**Authentication:** Bearer Token Required ✓

**Request:**
```
GET /api/margdarshak/dashboard
Headers:
  Authorization: Bearer {token}
```

**Response:**
```json
{
  "status": true,
  "message": "Dashboard data fetched successfully",
  "data": {
    "territory": {
      "state_name": "Uttar Pradesh",
      "districts_count": 2,
      "districts": ["Agra", "Aligarh"]
    },
    "shops": {
      "total_onboarded": 3,
      "dhaba_count": 2,
      "puncture_count": 1,
      "blocked_shops": 0
    },
    "drivers": {
      "total": 0,
      "today": 0,
      "this_week": 0,
      "this_month": 0
    },
    "earnings": {
      "total_amount": 0,
      "monthly_amount": 0,
      "pending_amount": 0
    }
  }
}
```

## Implementation

### 1. API Config (lib/core/config/api_config.dart)
Added dashboard endpoint as a getter:
```dart
static String get margdarshakDashboardApi => 
  '$margdarshakApiBase/margdarshak/dashboard';
```

### 2. API Service (lib/features/margdarshak/services/margdarshak_api_service.dart)
Updated to use config constant:
```dart
final url = Uri.parse(ApiConfig.margdarshakDashboardApi);
```

### 3. Dashboard Screen (lib/features/margdarshak/screens/dashboard/index.dart)
Updated to handle new response structure:
- Checks `response['status']` for success
- Extracts data from `response['data']`
- Handles new field names:
  - `territory.state_name`
  - `territory.districts_count`
  - `territory.districts` (array)
  - `shops.total_onboarded`
  - `shops.dhaba_count`
  - `shops.puncture_count`
  - `shops.blocked_shops`
  - `drivers.total`, `drivers.today`, `drivers.this_week`, `drivers.this_month`
  - `earnings.total_amount`, `earnings.monthly_amount`, `earnings.pending_amount`

## Features

✅ Centralized API endpoint in config
✅ Bearer token authentication
✅ Proper error handling
✅ Fallback to offline mode on failure
✅ Pull-to-refresh support
✅ Loading state management

## Benefits

1. **No Hardcoded URLs** - All endpoints in ApiConfig
2. **Easy Maintenance** - Change URL in one place
3. **Type Safety** - Compile-time checking
4. **Consistent Auth** - Bearer token auto-included
5. **Error Resilience** - Graceful fallback

## Files Modified

1. `lib/core/config/api_config.dart` - Added margdarshakDashboardApi
2. `lib/features/margdarshak/services/margdarshak_api_service.dart` - Use config constant
3. `lib/features/margdarshak/screens/dashboard/index.dart` - Handle new response structure

## Testing

Dashboard now fetches real data from:
- Territory info (state, districts)
- Shop counts (total, dhaba, puncture, blocked)
- Driver statistics (today, week, month, total)
- Earnings summary (total, monthly, pending)

All data updates on pull-to-refresh!
