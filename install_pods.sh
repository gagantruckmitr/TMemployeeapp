#!/bin/bash

echo "🔧 Installing iOS CocoaPods dependencies..."
echo ""

# Get the absolute path to the ios directory
IOS_DIR="$(cd "$(dirname "$0")/ios" && pwd)"

echo "📍 iOS directory: $IOS_DIR"
echo ""

# Change to ios directory and run pod install
cd "$IOS_DIR" || exit 1

echo "🧹 Cleaning previous pod installations..."
rm -rf Pods Podfile.lock .symlinks

echo "📦 Running pod install..."
/usr/local/bin/pod install --repo-update

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ CocoaPods installation successful!"
    echo ""
    echo "📱 Next steps:"
    echo "   1. Connect your iPhone via USB"
    echo "   2. Run: flutter run"
    echo "   Or open ios/Runner.xcworkspace in Xcode"
else
    echo ""
    echo "❌ CocoaPods installation failed"
    echo ""
    echo "Try these solutions:"
    echo "   1. Update CocoaPods: sudo gem install cocoapods"
    echo "   2. Update repo: pod repo update"
    echo "   3. Open Xcode and let it install components"
    exit 1
fi
