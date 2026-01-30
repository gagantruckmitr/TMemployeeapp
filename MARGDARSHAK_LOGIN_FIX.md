# Margdarshak Login Redirect Loop - Fix

## Problem
After successful login, the app was stuck in a redirect loop between the role selection page and login page, never reaching the Margdarshak dashboard.

## Root Cause
The splash screen was only checking for `userRole == 'margdarshak'`, but the API returns `role: 'field_agent'`. While the `MargdarshakAuthService` correctly saves `'user_role'` as `'margdarshak'` in SharedPreferences, there was a potential mismatch.

## Solution

### 1. Updated Splash Screen Role Check
**File:** `lib/features/splash/splash_screen.dart`

```dart
// Before
else if (userRole == 'margdarshak') {
  context.go('/margdarshak-dashboard');
}

// After
else if (userRole == 'margdarshak' || userRole == 'field_agent') {
  context.go('/margdarshak-dashboard');
}
```

This ensures both role values are handled correctly.

### 2. Updated Login Navigation
**File:** `lib/features/auth/margdarshak_login_page.dart`

```dart
// Use goNamed instead of go for cleaner navigation
context.goNamed('margdarshak-dashboard');
```

### 3. Session Check on Login Page
The login page already checks for existing session in `initState()`:

```dart
Future<void> _checkExistingSession() async {
  final hasSession = await _authService.loadSession();
  if (hasSession && mounted) {
    context.goNamed('margdarshak-dashboard');
  }
}
```

This prevents showing the login page if user is already logged in.

## How It Works Now

### Login Flow
```
1. User enters credentials
   ↓
2. MargdarshakAuthService.login()
   ↓
3. API returns: role = "field_agent"
   ↓
4. Service saves: user_role = "margdarshak"
   ↓
5. Navigate to: /margdarshak-dashboard
   ↓
6. Success! ✅
```

### App Restart Flow
```
1. App starts → Splash Screen
   ↓
2. Check isLoggedIn() → true
   ↓
3. RealAuthService restores session
   ↓
4. Check userRole → "margdarshak"
   ↓
5. Navigate to: /margdarshak-dashboard
   ↓
6. Success! ✅
```

## Key Points

1. **Role Mapping**: API returns `"field_agent"`, but we save as `"margdarshak"` for consistency
2. **Session Persistence**: Both services work together:
   - `MargdarshakAuthService`: Handles Margdarshak-specific auth
   - `RealAuthService`: Handles session restoration on app restart
3. **Navigation**: Using `goNamed()` for cleaner route management

## Testing

### Test Case 1: Fresh Login
1. Open app
2. Select "Field Agent"
3. Enter credentials: 6394752222 / 12345678
4. Click Login
5. **Expected**: Navigate directly to Margdarshak Dashboard ✅

### Test Case 2: App Restart
1. Login as Margdarshak
2. Close app completely
3. Reopen app
4. **Expected**: Splash → Margdarshak Dashboard (no login required) ✅

### Test Case 3: Logout & Login
1. Logout from Margdarshak Dashboard
2. Select "Field Agent" again
3. Login
4. **Expected**: Navigate to Margdarshak Dashboard ✅

## Files Modified

1. `lib/features/splash/splash_screen.dart` - Added `field_agent` role check
2. `lib/features/auth/margdarshak_login_page.dart` - Updated navigation method

## No Breaking Changes

- Telecaller login still works
- Manager login still works
- All existing functionality preserved
