# Fix: Connection Error - Localhost Issue

## Problem
The app is showing:
```
Connection error: ClientException with SocketException: Connection refused (OS Error: Connection refused, errno = 111), address = localhost, port = 50306
```

## Root Cause
The app is using a **cached build** with old localhost configuration instead of the production server URL.

## Solution

### Option 1: Clean and Rebuild (Recommended)
Run these commands in your terminal:

```bash
# Navigate to the Flutter project directory
cd Phase_2-

# Clean the build cache
flutter clean

# Get dependencies
flutter pub get

# Rebuild the app
flutter run
```

### Option 2: Force Rebuild
If Option 1 doesn't work:

```bash
cd Phase_2-

# Remove build directories
rm -rf build/
rm -rf .dart_tool/

# Clean
flutter clean

# Get dependencies
flutter pub get

# Rebuild
flutter run --no-sound-null-safety
```

### Option 3: Uninstall and Reinstall
If the above options don't work:

1. **Uninstall the app** from your device/emulator
2. Run:
```bash
cd Phase_2-
flutter clean
flutter pub get
flutter run
```

## Verification

After rebuilding, the app should connect to:
```
https://truckmitr.com/truckmitr-app/api/auth_api.php?action=login
```

Instead of:
```
http://localhost/TMemployeeApp/api/auth_api.php?action=login
```

## Why This Happens

Flutter caches compiled code for faster builds. When you change configuration (like API URLs), you need to clean the cache to pick up the new values.

## Prevention

Always run `flutter clean` after changing:
- API URLs
- Environment configurations
- Build configurations
- Dependencies

## Current Configuration

The app is correctly configured to use:
- **Base URL**: `https://truckmitr.com/truckmitr-app/api`
- **Server IP**: `truckmitr.com`

Location: `lib/core/config/api_config.dart`

## Still Having Issues?

If you're still seeing localhost errors after cleaning and rebuilding:

1. Check if you have multiple Flutter projects open
2. Make sure you're running from the correct directory (`Phase_2-`)
3. Verify the API config file:
   ```bash
   cat lib/core/config/api_config.dart
   ```
4. Check for any hardcoded localhost URLs:
   ```bash
   grep -r "localhost" lib/
   ```
