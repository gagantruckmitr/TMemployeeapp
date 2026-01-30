# Margdarshak API URL Configuration

## ✅ Correct URLs

### Login Endpoint
```
POST https://truckmitr.com/api/margdarshak/login
```

### All Margdarshak Endpoints
```
Base URL: https://truckmitr.com/api

POST   /margdarshak/login           (Authentication)
GET    /margdarshak/dashboard       (Dashboard stats)
GET    /margdarshak/shops           (List shops)
POST   /margdarshak/shops           (Add shop)
GET    /margdarshak/drivers         (List drivers)
GET    /margdarshak/earnings        (Earnings summary)
POST   /margdarshak/duty-status     (Check-in/out)
GET    /margdarshak/territory       (Territory info)
```

## 📝 Configuration Location

File: `lib/core/config/api_config.dart`

```dart
class ApiConfig {
  // Main App API (Telecaller, etc.)
  static const String domain = 'devtruckmitr.in';
  static const String baseUrl = 'https://$domain/truckmitr-app/api';
  
  // Margdarshak API (Field Agent) - SEPARATE BASE URL
  static const String margdarshakApiBase = 'https://truckmitr.com/api';
}
```

## 🔍 Why Different URLs?

The Margdarshak (Field Agent) module uses a **separate API base URL** from the main app:

- **Main App APIs**: `https://devtruckmitr.in/truckmitr-app/api`
  - Used by: Telecaller, Dashboard, Jobs, Drivers, etc.
  
- **Margdarshak APIs**: `https://truckmitr.com/api`
  - Used by: Field Agent login, dashboard, shops, earnings

## 🔧 How It's Implemented

### Auth Service
```dart
// lib/features/margdarshak/services/margdarshak_auth_service.dart

final url = Uri.parse('${ApiConfig.margdarshakApiBase}/margdarshak/login');
// Results in: https://truckmitr.com/api/margdarshak/login
```

### API Service
```dart
// lib/features/margdarshak/services/margdarshak_api_service.dart

final url = Uri.parse('${ApiConfig.margdarshakApiBase}/margdarshak/dashboard');
// Results in: https://truckmitr.com/api/margdarshak/dashboard
```

## ✅ Verification

All Margdarshak services now use `ApiConfig.margdarshakApiBase` which points to:
```
https://truckmitr.com/api
```

This ensures all API calls go to the correct endpoint.

## 🧪 Test Login

```bash
curl -X POST https://truckmitr.com/api/margdarshak/login \
  -H "Content-Type: application/json" \
  -d '{
    "mobile": "6394752222",
    "password": "12345678"
  }'
```

Expected response:
```json
{
  "status": true,
  "message": "Login successful",
  "token": "...",
  "data": {
    "user": {
      "id": 1,
      "employee_id": "TMFA0001",
      "name": "Gagan Shukla Cheeta",
      "mobile": "6394752222",
      "role": "field_agent",
      "state_name": "Uttar Pradesh"
    }
  }
}
```
