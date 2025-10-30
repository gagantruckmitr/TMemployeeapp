# Riverpod Migration Guide

## Why Migrate to Riverpod?

### Benefits:
✓ **Compile-time safety** - Catch errors before runtime
✓ **No BuildContext needed** - Access state anywhere
✓ **Better testability** - Easy to mock and test
✓ **Auto-dispose** - Automatic memory management
✓ **DevTools support** - Better debugging
✓ **Less boilerplate** - Cleaner code
✓ **Global state** - Share state across screens easily

## Step-by-Step Migration Plan

### Phase 1: Setup (1-2 hours)

#### 1. Add Dependencies

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Add Riverpod
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  
  # Keep existing dependencies
  shared_preferences: ^2.3.2
  go_router: ^14.2.7
  http: ^1.2.2
  # ... rest of your dependencies

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Add code generation
  build_runner: ^2.4.9
  riverpod_generator: ^2.4.0
  riverpod_lint: ^2.3.10
```

#### 2. Run Installation

```bash
flutter pub get
```

#### 3. Wrap App with ProviderScope

```dart
// lib/main.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(
    const ProviderScope(  // Wrap with ProviderScope
      child: MyApp(),
    ),
  );
}
```

### Phase 2: Create Providers (2-3 days)

#### Create Provider Directory Structure

```
lib/
├── core/
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   ├── telecaller_provider.dart
│   │   ├── manager_provider.dart
│   │   ├── leave_provider.dart
│   │   └── dashboard_provider.dart
```

#### Example 1: Auth Provider

```dart
// lib/core/providers/auth_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/real_auth_service.dart';

part 'auth_provider.g.dart';

// Current user provider
@riverpod
class CurrentUser extends _$CurrentUser {
  @override
  UserProfile? build() {
    return RealAuthService.instance.currentUser;
  }

  Future<void> login(String mobile, String password) async {
    state = null; // Set loading state
    final result = await RealAuthService.instance.login(mobile, password);
    if (result.isSuccess) {
      state = result.user;
    }
  }

  Future<void> logout() async {
    await RealAuthService.instance.logout();
    state = null;
  }

  void updateUser(UserProfile user) {
    state = user;
  }
}

// Auth state provider (for checking if logged in)
@riverpod
bool isLoggedIn(IsLoggedInRef ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
}

// User role provider
@riverpod
String? userRole(UserRoleRef ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role;
}
```

#### Example 2: Dashboard Provider

```dart
// lib/core/providers/dashboard_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/api_service.dart';

part 'dashboard_provider.g.dart';

// Dashboard stats provider with auto-refresh
@riverpod
class DashboardStats extends _$DashboardStats {
  @override
  Future<Map<String, dynamic>> build(String telecallerId) async {
    // Auto-refresh every 30 seconds
    final timer = Timer.periodic(const Duration(seconds: 30), (_) {
      ref.invalidateSelf();
    });
    ref.onDispose(() => timer.cancel());
    
    return await ApiService.getDashboardStats(telecallerId);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// Pending calls count
@riverpod
Future<int> pendingCallsCount(PendingCallsCountRef ref, String telecallerId) async {
  final stats = await ref.watch(dashboardStatsProvider(telecallerId).future);
  return stats['pending_calls'] ?? 0;
}
```

#### Example 3: Leave Requests Provider

```dart
// lib/core/providers/leave_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/api_service.dart';
import '../../models/leave_models.dart';

part 'leave_provider.g.dart';

// Telecaller's leave requests
@riverpod
class MyLeaveRequests extends _$MyLeaveRequests {
  @override
  Future<List<LeaveRequest>> build(String telecallerId) async {
    return await ApiService.getLeaveRequests(telecallerId: telecallerId);
  }

  Future<void> applyLeave({
    required LeaveType type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    final telecallerId = ref.read(currentUserProvider)?.id.toString() ?? '';
    
    final success = await ApiService.applyLeave(
      telecallerId: telecallerId,
      leaveType: type.name,
      startDate: startDate,
      endDate: endDate,
      totalDays: endDate.difference(startDate).inDays + 1,
      reason: reason,
    );

    if (success) {
      ref.invalidateSelf(); // Refresh the list
    }
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

// Manager's leave approval list
@riverpod
class LeaveApprovalList extends _$LeaveApprovalList {
  @override
  Future<List<LeaveRequest>> build(String managerId) async {
    return await ApiService.getAllLeaveRequests(managerId: managerId);
  }

  Future<void> approveLeave(String leaveId, String remarks) async {
    final managerId = ref.read(currentUserProvider)?.id.toString() ?? '';
    
    final success = await ApiService.updateLeaveStatus(
      leaveId: leaveId,
      status: 'approved',
      managerId: managerId,
      managerRemarks: remarks,
    );

    if (success) {
      ref.invalidateSelf();
    }
  }

  Future<void> rejectLeave(String leaveId, String remarks) async {
    final managerId = ref.read(currentUserProvider)?.id.toString() ?? '';
    
    final success = await ApiService.updateLeaveStatus(
      leaveId: leaveId,
      status: 'rejected',
      managerId: managerId,
      managerRemarks: remarks,
    );

    if (success) {
      ref.invalidateSelf();
    }
  }
}
```

#### 4. Generate Code

```bash
# Run code generation
dart run build_runner build --delete-conflicting-outputs

# Or watch for changes
dart run build_runner watch --delete-conflicting-outputs
```

### Phase 3: Migrate Screens (1-2 weeks)

#### Before (StatefulWidget):

```dart
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await ApiService.getDashboardStats(userId);
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return LoadingWidget();
    if (_error != null) return ErrorWidget(_error!);
    return StatsDisplay(_stats!);
  }
}
```

#### After (ConsumerWidget):

```dart
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final statsAsync = ref.watch(dashboardStatsProvider(user!.id.toString()));

    return statsAsync.when(
      data: (stats) => StatsDisplay(stats),
      loading: () => LoadingWidget(),
      error: (error, stack) => ErrorWidget(error.toString()),
    );
  }
}
```

#### Migration Pattern for Each Screen:

1. **Change StatefulWidget to ConsumerWidget**
2. **Remove State class**
3. **Replace setState() with ref.watch()**
4. **Use .when() for async data**
5. **Remove initState() and dispose()**

### Phase 4: Migrate Services (3-5 days)

#### Keep Services but Make Them Stateless

```dart
// Before: Singleton with state
class RealAuthService {
  static RealAuthService? _instance;
  UserProfile? _currentUser;  // ❌ Remove this
  
  static RealAuthService get instance {
    _instance ??= RealAuthService._();
    return _instance!;
  }
}

// After: Pure service (no state)
class AuthService {
  const AuthService();  // ✓ Stateless
  
  Future<LoginResult> login(String mobile, String password) async {
    // Just return data, don't store it
    final response = await http.post(...);
    return LoginResult.fromJson(response);
  }
}

// Provider for the service
@riverpod
AuthService authService(AuthServiceRef ref) {
  return const AuthService();
}
```

### Phase 5: Update Navigation (1 day)

#### GoRouter with Riverpod

```dart
// lib/routes/app_router.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

@riverpod
GoRouter router(RouterRef ref) {
  final isLoggedIn = ref.watch(isLoggedInProvider);
  final userRole = ref.watch(userRoleProvider);

  return GoRouter(
    redirect: (context, state) {
      if (!isLoggedIn && state.location != '/login') {
        return '/login';
      }
      if (isLoggedIn && state.location == '/login') {
        return userRole == 'manager' ? '/manager-dashboard' : '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => LoginPage()),
      GoRoute(path: '/dashboard', builder: (context, state) => DashboardPage()),
      // ... more routes
    ],
  );
}

// In main.dart
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      routerConfig: router,
      // ...
    );
  }
}
```

## Migration Priority Order

### High Priority (Migrate First):
1. ✓ **Auth State** - Login, logout, current user
2. ✓ **Dashboard Stats** - Most frequently accessed
3. ✓ **Leave Management** - Complex state with approvals

### Medium Priority:
4. **Telecaller Status** - Online/offline tracking
5. **Call History** - Frequently refreshed data
6. **Driver Assignments** - Manager dashboard

### Low Priority (Can Wait):
7. **Settings** - Rarely changed
8. **Profile** - Static data
9. **Analytics** - Read-only data

## Testing Strategy

### 1. Unit Tests

```dart
// test/providers/auth_provider_test.dart
void main() {
  test('login updates current user', () async {
    final container = ProviderContainer();
    
    await container.read(currentUserProvider.notifier).login('1234567890', 'password');
    
    final user = container.read(currentUserProvider);
    expect(user, isNotNull);
    expect(user?.mobile, '1234567890');
  });
}
```

### 2. Widget Tests

```dart
testWidgets('Dashboard shows stats', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dashboardStatsProvider.overrideWith((ref) => mockStats),
      ],
      child: MaterialApp(home: DashboardPage()),
    ),
  );
  
  expect(find.text('Total Calls: 100'), findsOneWidget);
});
```

## Common Pitfalls & Solutions

### 1. Provider Not Found
```dart
// ❌ Wrong
class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(...);
  }
}

// ✓ Correct
void main() {
  runApp(
    ProviderScope(  // Must wrap at root
      child: MyApp(),
    ),
  );
}
```

### 2. Forgetting to Generate Code
```bash
# Always run after creating/modifying providers
dart run build_runner build --delete-conflicting-outputs
```

### 3. Circular Dependencies
```dart
// ❌ Wrong
@riverpod
String userRole(UserRoleRef ref) {
  final user = ref.watch(currentUserProvider);
  return user?.role ?? '';
}

@riverpod
UserProfile? currentUser(CurrentUserRef ref) {
  final role = ref.watch(userRoleProvider);  // Circular!
  return ...;
}

// ✓ Correct - Use family or parameters
@riverpod
String userRole(UserRoleRef ref, UserProfile user) {
  return user.role;
}
```

## Estimated Timeline

| Phase | Duration | Effort |
|-------|----------|--------|
| Setup & Dependencies | 2 hours | Easy |
| Create Core Providers | 2-3 days | Medium |
| Migrate Auth & Dashboard | 2-3 days | Medium |
| Migrate Other Screens | 1 week | Medium |
| Refactor Services | 3-5 days | Hard |
| Testing & Bug Fixes | 3-5 days | Medium |
| **Total** | **3-4 weeks** | **Medium-Hard** |

## Gradual Migration Strategy

You don't have to migrate everything at once:

### Week 1: Foundation
- Add Riverpod dependencies
- Wrap app with ProviderScope
- Create auth provider
- Migrate login/logout

### Week 2: Core Features
- Dashboard providers
- Leave management providers
- Migrate 2-3 main screens

### Week 3: Remaining Screens
- Migrate remaining screens
- Refactor services
- Remove old DataProvider

### Week 4: Polish
- Testing
- Bug fixes
- Performance optimization
- Documentation

## Resources

- **Official Docs**: https://riverpod.dev
- **Migration Guide**: https://riverpod.dev/docs/from_provider/motivation
- **Code Generation**: https://riverpod.dev/docs/concepts/about_code_generation
- **Best Practices**: https://riverpod.dev/docs/essentials/first_request

## Conclusion

Migrating to Riverpod will:
- ✓ Make your code more maintainable
- ✓ Improve testability
- ✓ Reduce boilerplate
- ✓ Provide better developer experience

**Recommendation**: Start with a small feature (like leave management) to get familiar with Riverpod before migrating the entire app.
