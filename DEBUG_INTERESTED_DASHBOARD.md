# Debug Guide: Interested Dashboard Not Opening

## Quick Test Steps

### 1. Restart the App
```bash
# Stop the app completely
# Then restart it
flutter run
```

### 2. Test Navigation Manually
Add this temporary debug code to test the route:

**In `lib/widgets/navigation_drawer.dart`**, find the `_onSectionTap` method and add debug prints:

```dart
void _onSectionTap(NavigationSection section) {
  if (section != widget.currentSection) {
    HapticFeedback.lightImpact();
    
    // Special handling for Interested section - navigate to Phase 2 dashboard
    if (section == NavigationSection.interested) {
      debugPrint('🔵 Tapping Interested section');
      debugPrint('🔵 Navigating to: ${AppRouter.interestedDashboard}');
      context.push(AppRouter.interestedDashboard);
      debugPrint('🔵 Navigation called');
      _closeDrawer();
      return;
    }
    
    widget.onSectionChanged(section);
    _closeDrawer();
  }
}
```

### 3. Check Console Output
When you tap "Interested", you should see:
```
🔵 Tapping Interested section
🔵 Navigating to: /dashboard/interested-dashboard
🔵 Navigation called
```

### 4. Verify Route is Registered
The route should be defined in `lib/routes/app_router.dart`:
```dart
GoRoute(
  path: 'interested-dashboard',
  name: 'interested-dashboard',
  pageBuilder: (context, state) => CustomTransitionPage(
    key: state.pageKey,
    child: const InterestedDashboardWrapper(),
    ...
  ),
),
```

### 5. Test Direct Navigation
Add a test button to your main dashboard to test the route directly:

```dart
ElevatedButton(
  onPressed: () {
    debugPrint('🧪 Testing direct navigation');
    context.push('/dashboard/interested-dashboard');
  },
  child: const Text('Test Phase 2 Dashboard'),
)
```

## Common Issues & Solutions

### Issue 1: Nothing happens when tapping "Interested"
**Solution**: 
- Check if the drawer is closing (it should)
- Check console for navigation logs
- Verify the route path is correct

### Issue 2: Error "Route not found"
**Solution**:
- Verify route is defined in `app_router.dart`
- Check the path matches exactly: `'interested-dashboard'`
- Make sure it's a child route of `'/dashboard'`

### Issue 3: Dashboard shows loading forever
**Solution**:
- Check if `DynamicDashboardScreen` has any errors
- Verify API endpoints are accessible
- Check console for error messages

### Issue 4: "Not logged in" error
**Solution**:
- Login again
- Check if Phase 1 authentication is working
- Verify `RealAuthService.instance.currentUser` is not null

## Manual Test

### Test the wrapper directly:
Create a test file `lib/test_dashboard.dart`:

```dart
import 'package:flutter/material.dart';
import 'features/dashboard/dynamic_dashboard_screen.dart';

class TestDashboard extends StatelessWidget {
  const TestDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Dashboard'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const DynamicDashboardScreen(),
              ),
            );
          },
          child: const Text('Open Dynamic Dashboard'),
        ),
      ),
    );
  }
}
```

Then navigate to this test screen and tap the button.

## Verify Files

### 1. Check InterestedDashboardWrapper
File: `lib/features/dashboard/interested_dashboard_wrapper.dart`

Should look like:
```dart
import 'package:flutter/material.dart';
import '../dashboard/dynamic_dashboard_screen.dart';

class InterestedDashboardWrapper extends StatelessWidget {
  const InterestedDashboardWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return const DynamicDashboardScreen();
  }
}
```

### 2. Check Navigation Drawer
File: `lib/widgets/navigation_drawer.dart`

Should have:
```dart
if (section == NavigationSection.interested) {
  context.push(AppRouter.interestedDashboard);
  _closeDrawer();
  return;
}
```

### 3. Check App Router
File: `lib/routes/app_router.dart`

Should have:
```dart
static const String interestedDashboard = '/dashboard/interested-dashboard';
```

And the route definition under dashboard routes.

## Still Not Working?

### Try this alternative approach:

Replace the navigation in drawer with direct Navigator:

```dart
if (section == NavigationSection.interested) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const DynamicDashboardScreen(),
    ),
  );
  _closeDrawer();
  return;
}
```

This bypasses GoRouter and uses direct navigation.

## Contact Points

If still having issues, check:
1. Console logs for errors
2. Flutter doctor for any issues
3. Hot restart the app (not just hot reload)
4. Clear app data and login again
