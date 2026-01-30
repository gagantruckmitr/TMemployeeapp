# Margdarshak API Integration - Complete Structure

## 📁 File Structure

```
lib/features/margdarshak/
├── models/
│   └── margdarshak_user_model.dart          ✅ Created
│       ├── MargdarshakUser                  (User model)
│       └── MargdarshakLoginResponse         (Login response)
│
├── services/
│   ├── margdarshak_auth_service.dart        ✅ Created
│   │   ├── login()                          (Login with mobile/password)
│   │   ├── logout()                         (Clear session)
│   │   ├── loadSession()                    (Load saved session)
│   │   └── getAuthHeaders()                 (Get auth headers)
│   │
│   └── margdarshak_api_service.dart         ✅ Created
│       ├── getDashboardStats()              (Dashboard data)
│       ├── getShops()                       (Shops list)
│       ├── addShop()                        (Add new shop)
│       ├── getDrivers()                     (Drivers list)
│       ├── getEarnings()                    (Earnings summary)
│       ├── updateDutyStatus()               (Check-in/out)
│       └── getTerritoryInfo()               (Territory data)
│
├── screens/
│   └── dashboard/
│       └── index.dart                       ✅ Updated
│           └── Uses MargdarshakApiService
│
└── auth/
    └── margdarshak_login_page.dart          ✅ Updated
        └── Uses MargdarshakAuthService
```

## 🔌 API Endpoints

### Base URL
```
https://truckmitr.com/api
```

**Note:** Margdarshak uses a separate API base URL from the main app.
- Main App: `https://devtruckmitr.in/truckmitr-app/api`
- Margdarshak: `https://truckmitr.com/api`

### Authentication
```
POST https://truckmitr.com/api/margdarshak/login
```

### Dashboard & Operations
```
GET  https://truckmitr.com/api/margdarshak/dashboard      (Dashboard stats)
GET  https://truckmitr.com/api/margdarshak/shops          (List shops)
POST https://truckmitr.com/api/margdarshak/shops          (Add shop)
GET  https://truckmitr.com/api/margdarshak/drivers        (List drivers)
GET  https://truckmitr.com/api/margdarshak/earnings       (Earnings summary)
POST https://truckmitr.com/api/margdarshak/duty-status    (Check-in/out)
GET  https://truckmitr.com/api/margdarshak/territory      (Territory info)
```

## 🔐 Authentication Flow

```
┌─────────────────┐
│  Login Screen   │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ MargdarshakAuthService.login()      │
│ - POST https://truckmitr.com/api/   │
│        margdarshak/login            │
│ - Body: {mobile, password}          │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Response:                           │
│ {                                   │
│   "status": true,                   │
│   "token": "...",                   │
│   "data": {                         │
│     "user": {                       │
│       "id": 1,                      │
│       "employee_id": "TMFA0001",    │
│       "name": "...",                │
│       "mobile": "...",              │
│       "role": "field_agent",        │
│       "state_name": "..."           │
│     }                               │
│   }                                 │
│ }                                   │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Save to SharedPreferences:          │
│ - margdarshak_token                 │
│ - margdarshak_user                  │
│ - is_logged_in                      │
│ - user_role = "margdarshak"         │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────┐
│   Dashboard     │
└─────────────────┘
```

## 📊 Dashboard Data Flow

```
┌─────────────────┐
│   Dashboard     │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ MargdarshakApiService               │
│   .getDashboardStats()              │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ GET https://truckmitr.com/api/      │
│     margdarshak/dashboard           │
│ Headers:                            │
│   Authorization: Bearer {token}     │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│ Response:                           │
│ {                                   │
│   "territory": {                    │
│     "state": "Uttar Pradesh",       │
│     "districts": 3                  │
│   },                                │
│   "shops": {                        │
│     "total": 45,                    │
│     "pending": 5                    │
│   },                                │
│   "drivers": {                      │
│     "today": 12,                    │
│     "month": 234                    │
│   },                                │
│   "earnings": {                     │
│     "month": 2340,                  │
│     "pending": 450                  │
│   }                                 │
│ }                                   │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────┐
│  Display Stats  │
└─────────────────┘
```

## 💻 Code Examples

### Login
```dart
final authService = MargdarshakAuthService();

final response = await authService.login(
  mobile: '6394752222',
  password: '12345678',
);

if (response.isSuccess) {
  // Navigate to dashboard
  context.go(AppRouter.margdarshakDashboard);
}
```

### Get Dashboard Stats
```dart
final apiService = MargdarshakApiService();

try {
  final stats = await apiService.getDashboardStats();
  
  final shops = stats['shops']['total'];
  final drivers = stats['drivers']['month'];
  final earnings = stats['earnings']['month'];
  
  // Update UI
} catch (e) {
  // Show error or offline mode
}
```

### Add Shop
```dart
final result = await apiService.addShop({
  'name': 'Sharma Dhaba',
  'type': 'dhaba',
  'location': 'Pune',
  'contact': '9876543210',
  'latitude': 18.5204,
  'longitude': 73.8567,
});
```

### Check-in
```dart
await apiService.updateDutyStatus(
  status: 'check_in',
  latitude: 18.5204,
  longitude: 73.8567,
);
```

## 🔑 Key Features

### ✅ Implemented
- Login with mobile/password
- Session management (save/load/clear)
- Bearer token authentication
- Dashboard stats API integration
- Offline mode with fallback data
- User profile display
- Error handling

### 🎯 Ready for Backend
- Shop management APIs
- Driver management APIs
- Earnings tracking APIs
- Duty tracking APIs
- Territory management APIs

## 🧪 Testing

### Demo Credentials
```
Mobile: 6394752222
Password: 12345678
```

### Test Flow
1. Open app → Select "Field Agent"
2. Enter demo credentials
3. Click "Use Demo Account" button
4. Login → Dashboard loads
5. Dashboard shows:
   - User name and employee ID
   - Territory info
   - Stats cards
   - Quick actions
   - Recent activity

## 📝 Notes

- All services use singleton pattern
- Session persists across app restarts
- Automatic token refresh on app start
- Graceful fallback to offline mode
- Clean separation of concerns:
  - Models: Data structures
  - Services: Business logic
  - Screens: UI components

## 🚀 Next Steps

1. Backend team implements endpoints
2. Test with real API
3. Add error handling for specific cases
4. Implement remaining features:
   - Shop onboarding flow
   - Driver management
   - Earnings tracking
   - Territory management
   - Push notifications
