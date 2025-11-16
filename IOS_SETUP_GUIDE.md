# iOS Setup Guide for iPhone

This guide will help you prepare and run the TMEmployee app on your iPhone.

## Prerequisites

- macOS with Xcode installed (version 14.0 or later)
- CocoaPods installed (`sudo gem install cocoapods`)
- Flutter SDK installed
- An iPhone (iOS 12.0 or later)
- Apple Developer account (for device deployment)

## Quick Setup

Run the automated setup script:

```bash
./setup_ios.sh
```

## Manual Setup Steps

If you prefer to set up manually:

### 1. Clean and Get Dependencies

```bash
flutter clean
flutter pub get
```

### 2. Install CocoaPods Dependencies

```bash
cd ios
pod install
cd ..
```

### 3. Configure Code Signing

1. Open `ios/Runner.xcworkspace` in Xcode (NOT Runner.xcodeproj)
2. Select the "Runner" project in the left sidebar
3. Select the "Runner" target
4. Go to "Signing & Capabilities" tab
5. Check "Automatically manage signing"
6. Select your Team from the dropdown
7. Xcode will automatically create a provisioning profile

### 4. Connect Your iPhone

1. Connect your iPhone to your Mac via USB
2. Unlock your iPhone
3. Trust the computer when prompted
4. In Xcode, select your iPhone from the device dropdown at the top

### 5. Run the App

```bash
flutter run
```

Or from Xcode, click the Play button.

## Permissions Configured

The app has been configured with the following iOS permissions:

- **Phone Calls** - For telecaller functionality
- **Microphone** - For call recordings
- **Photo Library** - For profile pictures
- **Camera** - For taking photos
- **File Access** - For document management
- **Background Audio** - For call audio in background

## Troubleshooting

### Issue: "No Podfile found"

**Solution:**
```bash
cd ios
pod deintegrate
pod install
```

### Issue: Code signing error

**Solution:**
1. Open `ios/Runner.xcworkspace` in Xcode
2. Go to Signing & Capabilities
3. Select your development team
4. Clean build folder (Cmd + Shift + K)
5. Build again (Cmd + B)

### Issue: "Untrusted Developer"

When you first run the app on your iPhone, you may see "Untrusted Developer":

1. Go to Settings > General > VPN & Device Management
2. Find your developer profile
3. Tap "Trust [Your Name]"
4. Confirm by tapping "Trust"

### Issue: Build fails with deployment target error

**Solution:**
The minimum iOS version is set to 12.0. If you need to change it:
1. Open `ios/Podfile`
2. Change `platform :ios, '12.0'` to your desired version
3. Run `pod install` again

### Issue: Folder path with spaces

If your project is in a folder with spaces (like "untitled folder 9.33.42 pm"), CocoaPods may have issues. Consider:
1. Moving the project to a path without spaces
2. Or use the setup script which handles this

## Running on Physical Device

```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d [device-id]

# Run in release mode
flutter run --release
```

## Building for Distribution

### Debug Build
```bash
flutter build ios --debug
```

### Release Build
```bash
flutter build ios --release
```

### Create IPA for TestFlight/App Store
```bash
flutter build ipa
```

The IPA will be created at: `build/ios/ipa/`

## App Configuration

### Bundle Identifier
Default: `com.example.tmemployeeapp`

To change:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner target
3. Change Bundle Identifier in General tab

### App Name
Current: "TMcall"

To change, edit `ios/Runner/Info.plist`:
```xml
<key>CFBundleDisplayName</key>
<string>Your App Name</string>
```

### App Icon
Place your app icon at: `assets/images/app_icon.png`

Then run:
```bash
flutter pub run flutter_launcher_icons
```

## Network Configuration

The app is configured to allow HTTP connections (for development). For production, you should:

1. Use HTTPS for all API endpoints
2. Remove or restrict `NSAllowsArbitraryLoads` in Info.plist

## Testing on Simulator

```bash
# Open iOS Simulator
open -a Simulator

# Run app on simulator
flutter run
```

## Next Steps

1. ✅ iOS configuration complete
2. ✅ Permissions added
3. ✅ Podfile created
4. 🔄 Run `./setup_ios.sh` or follow manual steps
5. 📱 Connect iPhone and run `flutter run`
6. 🎉 Test the app!

## Support

For Flutter iOS issues, check:
- [Flutter iOS Setup](https://docs.flutter.dev/get-started/install/macos#ios-setup)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
