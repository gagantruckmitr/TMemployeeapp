# State Management Architecture

## Overview
This Flutter app uses a **hybrid state management approach** combining multiple patterns:

## 1. Primary State Management: **StatefulWidget + setState()**

The app primarily uses Flutter's built-in state management with `StatefulWidget` and `setState()`. This is evident throughout the codebase:

- Dashboard pages
- List screens
- Form dialogs
- Detail pages

### Example:
```dart
class _ManagerDashboardPageState extends State<ManagerDashboardPage> {
  bool _isLoading = true;
  List<TelecallerInfo> _telecallers = [];
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    // Load data...
    setState(() {
      _isLoading = false;
    });
  }
}
```

## 2. Secondary: **ChangeNotifier (Provider Pattern)**

The app has a `DataProvider` class that extends `ChangeNotifier`, which is part of the Provider pattern:

**Location:** `lib/core/providers/data_provider.dart`

### Features:
- Dashboard statistics
- Callback requests
- User data (drivers/transporters)
- Loading states
- Error handling

### Usage:
```dart
class DataProvider extends ChangeNotifier {
  Map<String, int> _dashboardStats = {};
  
  Future<void> loadDashboardStats() async {
    _isLoadingStats = true;
    notifyListeners();
    // Load data...
    notifyListeners();
  }
}
```

**Note:** While the Provider infrastructure exists, it's not heavily used throughout the app. Most screens use direct service calls with setState().

## 3. **Singleton Services (Service Layer Pattern)**

The app heavily relies on singleton service classes for business logic and API calls:

### Core Services:
- **RealAuthService** - Authentication & user session
- **ApiService** - HTTP API calls
- **ManagerService** - Manager-specific operations
- **TelecallerService** - Telecaller operations
- **SmartCallingService** - Calling functionality
- **TelecallerStatusService** - Status tracking
- **ActivityTrackerService** - Activity monitoring

### Pattern:
```dart
class RealAuthService {
  static RealAuthService? _instance;
  
  static RealAuthService get instance {
    _instance ??= RealAuthService._();
    return _instance!;
  }
  
  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;
}
```

## 4. **SharedPreferences (Persistent State)**

Used for storing user session data:

```dart
static const String _keyIsLoggedIn = 'is_logged_in';
static const String _keyUserId = 'user_id';
static const String _keyUserName = 'user_name';
static const String _keyUserRole = 'user_role';
```

## 5. **Navigation State: GoRouter**

For routing and navigation state management:

**Dependency:** `go_router: ^14.2.7`

## Architecture Summary

```
┌─────────────────────────────────────────┐
│           UI Layer (Widgets)            │
│  StatefulWidget + setState()            │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│      Service Layer (Singletons)         │
│  - RealAuthService                      │
│  - ApiService                           │
│  - ManagerService                       │
│  - TelecallerService                    │
└─────────────────┬───────────────────────┘
                  │
┌─────────────────▼───────────────────────┐
│         Data Layer (API/DB)             │
│  - HTTP calls to PHP backend            │
│  - SharedPreferences                    │
└─────────────────────────────────────────┘
```

## State Management Flow

1. **UI triggers action** → User interacts with widget
2. **Widget calls service** → Direct service method call
3. **Service makes API call** → HTTP request to backend
4. **Service returns data** → Response parsed
5. **Widget updates state** → setState() called
6. **UI rebuilds** → Widget tree updates

## Pros of Current Approach

✓ **Simple and straightforward** - Easy to understand
✓ **No complex dependencies** - Minimal learning curve
✓ **Direct control** - Clear data flow
✓ **Good for small-medium apps** - Works well at current scale
✓ **Fast development** - Quick to implement features

## Cons of Current Approach

✗ **State duplication** - Same data loaded in multiple screens
✗ **No global state** - Each screen manages its own state
✗ **Manual refresh** - Need to manually reload data
✗ **Boilerplate code** - Repetitive setState() patterns
✗ **Testing complexity** - Harder to unit test

## Recommendations for Scaling

If the app grows significantly, consider migrating to:

1. **Riverpod** - Modern, compile-safe provider
2. **Bloc/Cubit** - For complex business logic
3. **GetX** - For rapid development with less boilerplate

## Current Dependencies

```yaml
# No dedicated state management package
# Using built-in Flutter state management

dependencies:
  flutter:
    sdk: flutter
  shared_preferences: ^2.3.2  # For persistent state
  go_router: ^14.2.7          # For navigation state
```

## Conclusion

The app uses a **pragmatic, service-oriented architecture** with:
- StatefulWidget for local UI state
- Singleton services for business logic
- Direct API calls without complex state management
- SharedPreferences for persistence

This approach is suitable for the current app size and complexity, providing a good balance between simplicity and functionality.
