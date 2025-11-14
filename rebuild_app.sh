#!/bin/bash

echo "🧹 Cleaning Flutter build cache..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo "🔨 Building app..."
flutter run

echo "✅ App rebuilt successfully!"
