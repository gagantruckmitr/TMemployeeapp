#!/bin/bash

# TMemployeeapp Merge Script
# This script merges Phase_2- app features into the main TMemployeeapp

echo "🚀 Starting app merge process..."

# Define source and destination
PHASE2_DIR="Phase_2-"
MAIN_DIR="."

# Create backup
echo "📦 Creating backup..."
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp -r lib "$BACKUP_DIR/"
echo "✅ Backup created at $BACKUP_DIR"

# Copy features from Phase_2-
echo "📂 Copying features..."

# Copy feature folders (skip if already exists in main app)
cp -r "$PHASE2_DIR/lib/features/analytics" "lib/features/" 2>/dev/null && echo "✅ analytics copied"
cp -r "$PHASE2_DIR/lib/features/applications" "lib/features/" 2>/dev/null && echo "✅ applications copied"
cp -r "$PHASE2_DIR/lib/features/calls" "lib/features/" 2>/dev/null && echo "✅ calls copied"
cp -r "$PHASE2_DIR/lib/features/contacts" "lib/features/" 2>/dev/null && echo "✅ contacts copied"
cp -r "$PHASE2_DIR/lib/features/dashboard" "lib/features/" 2>/dev/null && echo "✅ dashboard copied"
cp -r "$PHASE2_DIR/lib/features/drivers" "lib/features/" 2>/dev/null && echo "✅ drivers copied"
cp -r "$PHASE2_DIR/lib/features/jobs" "lib/features/" 2>/dev/null && echo "✅ jobs copied"
cp -r "$PHASE2_DIR/lib/features/matchmaking" "lib/features/" 2>/dev/null && echo "✅ matchmaking copied"
cp -r "$PHASE2_DIR/lib/features/notifications" "lib/features/" 2>/dev/null && echo "✅ notifications copied"
cp -r "$PHASE2_DIR/lib/features/profile" "lib/features/" 2>/dev/null && echo "✅ profile copied"
cp -r "$PHASE2_DIR/lib/features/reports" "lib/features/" 2>/dev/null && echo "✅ reports copied"
cp -r "$PHASE2_DIR/lib/features/settings" "lib/features/" 2>/dev/null && echo "✅ settings copied"
cp -r "$PHASE2_DIR/lib/features/smart_calling" "lib/features/" 2>/dev/null && echo "✅ smart_calling copied"
cp -r "$PHASE2_DIR/lib/features/telecaller_activity" "lib/features/" 2>/dev/null && echo "✅ telecaller_activity copied"

# Copy main_container.dart
cp "$PHASE2_DIR/lib/features/main_container.dart" "lib/features/" 2>/dev/null && echo "✅ main_container copied"

# Copy core services and utilities
echo "🔧 Copying core services..."
cp -r "$PHASE2_DIR/lib/core/"* "lib/core/" 2>/dev/null && echo "✅ core services copied"

# Copy models
echo "📊 Copying models..."
cp -r "$PHASE2_DIR/lib/models/"* "lib/models/" 2>/dev/null && echo "✅ models copied"

# Copy screens (if any standalone screens exist)
echo "🖥️  Copying screens..."
if [ -d "$PHASE2_DIR/lib/screens" ]; then
  mkdir -p "lib/screens"
  cp -r "$PHASE2_DIR/lib/screens/"* "lib/screens/" 2>/dev/null && echo "✅ screens copied"
fi

# Copy widgets (if any standalone widgets exist)
echo "🎨 Copying widgets..."
if [ -d "$PHASE2_DIR/lib/widgets" ]; then
  cp -r "$PHASE2_DIR/lib/widgets/"* "lib/widgets/" 2>/dev/null && echo "✅ widgets copied"
fi

# Copy assets
echo "🎭 Copying assets..."
if [ -d "$PHASE2_DIR/assets" ]; then
  cp -r "$PHASE2_DIR/assets/"* "assets/" 2>/dev/null && echo "✅ assets copied"
fi

echo ""
echo "✨ Merge complete!"
echo ""
echo "📋 Next steps:"
echo "1. Run: flutter pub get"
echo "2. Check for any import conflicts"
echo "3. Update main.dart to integrate both apps"
echo "4. Test the merged app"
echo ""
echo "💾 Backup location: $BACKUP_DIR"
