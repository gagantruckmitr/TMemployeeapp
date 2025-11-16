# Quick Guide: Run on iPhone

Your Flutter app is now iOS-ready! Due to the spaces in your project folder path, we need to use Xcode to complete the setup.

## Option 1: Use Xcode (Recommended)

1. **Open the project in Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Let Xcode install dependencies:**
   - Xcode will automatically detect and install CocoaPods dependencies
   - Wait for "Indexing..." to complete

3. **Configure Code Signing:**
   - Select "Runner" in the left sidebar
   - Go to "Signing & Capabilities" tab
   - Check "Automatically manage signing"
   - Select your Apple Developer Team

4. **Connect your iPhone:**
   - Connect via USB
   - Unlock your iPhone
   - Trust the computer when prompted

5. **Select your iPhone:**
   - At the top of Xcode, click the device dropdown
   - Select your iPhone from the list

6. **Run the app:**
   - Click the Play button (▶️) in Xcode
   - Or press Cmd + R

## Option 2: Use Flutter CLI

Once Xcode has installed the pods, you can use Flutter:

```bash
# List devices
flutter devices

# Run on iPhone
flutter run

# Run in release mode
flutter run --release
```

## Option 3: Move Project (Alternative)

If you prefer using command line tools, move your project to a path without spaces:

```bash
# Move to a path without spaces
mv "/Users/apple/Desktop/untitled folder 9.33.42 pm/TMemployeeapp" ~/TMemployeeapp

# Then run pod install
cd ~/TMemployeeapp/ios
pod install
```

## Troubleshooting

### "Untrusted Developer" on iPhone

After first install:
1. Go to Settings > General > VPN & Device Management
2. Find your developer profile
3. Tap "Trust [Your Name]"

### Build Errors

If you see build errors:
1. In Xcode: Product > Clean Build Folder (Cmd + Shift + K)
2. Close Xcode
3. Delete derived data:
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData
   ```
4. Reopen Xcode and build again

### No iPhone Detected

1. Unplug and replug the iPhone
2. Unlock the iPhone
3. Trust the computer
4. In Xcode: Window > Devices and Simulators
5. Check if your iPhone appears

## What's Been Configured

✅ iOS permissions added (Phone, Microphone, Camera, Photos)
✅ Podfile created with all dependencies
✅ Info.plist updated with required permissions
✅ Minimum iOS version set to 12.0
✅ Background audio mode enabled
✅ Network security configured

## Next Steps

1. Open in Xcode: `open ios/Runner.xcworkspace`
2. Let Xcode install pods
3. Configure signing
4. Connect iPhone
5. Run! 🚀

## iPhone 17 Note

Since iPhone 17 doesn't exist yet (latest is iPhone 16), I assume you meant:
- iPhone 16 Pro Max
- iPhone 15 Pro
- Or running on iOS 17

The app is configured to work on any iPhone running iOS 12.0 or later, including all current models.
