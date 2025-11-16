#!/bin/bash

echo "🚀 Moving project to path without spaces and running on iPhone 16e..."
echo ""

# Define new path
NEW_PATH=~/TMemployeeapp

# Check if target already exists
if [ -d "$NEW_PATH" ]; then
    echo "⚠️  $NEW_PATH already exists!"
    echo "Options:"
    echo "  1. Remove it: rm -rf $NEW_PATH"
    echo "  2. Use a different name"
    exit 1
fi

# Get current directory
CURRENT_DIR="$(pwd)"

echo "📦 Copying project to $NEW_PATH..."
cp -R "$CURRENT_DIR" "$NEW_PATH"

echo "✅ Project copied successfully!"
echo ""
echo "📱 Running on iPhone 16e simulator..."
echo ""

# Change to new directory and run
cd "$NEW_PATH"
flutter run -d 72D0FB8A-4DAA-41E9-90EB-C049764BE5D4

echo ""
echo "💡 Your project is now at: $NEW_PATH"
echo "   You can delete the old one if everything works!"
