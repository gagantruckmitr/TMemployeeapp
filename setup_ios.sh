#!/bin/bash

echo "🚀 Setting up iOS for iPhone..."

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean

# Get dependencies
echo "📦 Getting Flutter dependencies..."
flutter pub get

# Navigate to iOS directory and install pods
echo "🔧 Installing CocoaPods dependencies..."
cd ios
pod deintegrate 2>/dev/null || true
pod install --repo-update

# Return to root
cd ..

echo "✅ iOS setup complete!"
echo ""
echo "📱 To run on iPhone:"
echo "   1. Connect your iPhone via USB"
echo "   2. Trust the computer on your iPhone"
echo "   3. Run: flutter run"
echo ""
echo "🏗️  To build for release:"
echo "   flutter build ios --release"
echo ""
echo "⚠️  Note: You'll need to configure code signing in Xcode"
echo "   Open ios/Runner.xcworkspace in Xcode and set your team"
