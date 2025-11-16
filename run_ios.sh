#!/bin/bash

echo "🚀 Running app on iPhone 16e..."
echo ""

# Check if working copy exists
if [ ! -d ~/TMemployeeapp ]; then
    echo "📦 Creating working copy (first time setup)..."
    cp -R "$(pwd)" ~/TMemployeeapp
    echo "✅ Working copy created at ~/TMemployeeapp"
    echo ""
fi

# Run from working copy
echo "▶️  Launching app..."
cd ~/TMemployeeapp && flutter run -d 72D0FB8A-4DAA-41E9-90EB-C049764BE5D4
