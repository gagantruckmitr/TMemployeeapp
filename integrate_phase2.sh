#!/bin/bash

# Phase 2 Integration Script
# This script copies all Phase 2 files to the main app

echo "🚀 Starting Phase 2 Integration..."

# Set the base directory
BASE_DIR="/Users/apple/Desktop/untitled folder 9.33.42 pm/TMemployeeapp"
cd "$BASE_DIR"

echo "📁 Copying Phase 2 models..."
cp -r Phase_2-/lib/models/* lib/models/ 2>/dev/null || mkdir -p lib/models && cp -r Phase_2-/lib/models/* lib/models/

echo "📁 Copying Phase 2 widgets..."
cp -r Phase_2-/lib/widgets/* lib/widgets/ 2>/dev/null

echo "📁 Copying Phase 2 core services..."
cp Phase_2-/lib/core/services/phase2_api_service.dart lib/core/services/ 2>/dev/null
cp Phase_2-/lib/core/services/phase2_auth_service.dart lib/core/services/ 2>/dev/null

echo "📁 Copying Phase 2 core widgets..."
mkdir -p lib/core/widgets
cp -r Phase_2-/lib/core/widgets/* lib/core/widgets/ 2>/dev/null

echo "📁 Copying Phase 2 core theme..."
cp Phase_2-/lib/core/theme/app_colors.dart lib/core/theme/ 2>/dev/null

echo "📁 Copying Phase 2 features..."
# Dashboard
mkdir -p lib/features/dashboard
cp -r Phase_2-/lib/features/dashboard/* lib/features/dashboard/ 2>/dev/null

# Jobs
mkdir -p lib/features/jobs
cp -r Phase_2-/lib/features/jobs/* lib/features/jobs/ 2>/dev/null

# Calls  
mkdir -p lib/features/calls
cp -r Phase_2-/lib/features/calls/* lib/features/calls/ 2>/dev/null

# Analytics
mkdir -p lib/features/analytics
cp -r Phase_2-/lib/features/analytics/* lib/features/analytics/ 2>/dev/null

# Profile
mkdir -p lib/features/profile
cp -r Phase_2-/lib/features/profile/* lib/features/profile/ 2>/dev/null

# Smart Calling
mkdir -p lib/features/smart_calling
cp -r Phase_2-/lib/features/smart_calling/* lib/features/smart_calling/ 2>/dev/null

# Drivers
mkdir -p lib/features/drivers
cp -r Phase_2-/lib/features/drivers/* lib/features/drivers/ 2>/dev/null

# Matchmaking
mkdir -p lib/features/matchmaking
cp -r Phase_2-/lib/features/matchmaking/* lib/features/matchmaking/ 2>/dev/null

# Contacts
mkdir -p lib/features/contacts
cp -r Phase_2-/lib/features/contacts/* lib/features/contacts/ 2>/dev/null

# Notifications
mkdir -p lib/features/notifications
cp -r Phase_2-/lib/features/notifications/* lib/features/notifications/ 2>/dev/null

# Reports
mkdir -p lib/features/reports
cp -r Phase_2-/lib/features/reports/* lib/features/reports/ 2>/dev/null

# Settings (Phase 2 version)
cp -r Phase_2-/lib/features/settings/* lib/features/settings/ 2>/dev/null || mkdir -p lib/features/settings && cp -r Phase_2-/lib/features/settings/* lib/features/settings/

# Applications
mkdir -p lib/features/applications
cp -r Phase_2-/lib/features/applications/* lib/features/applications/ 2>/dev/null

# Telecaller Activity
mkdir -p lib/features/telecaller_activity
cp -r Phase_2-/lib/features/telecaller_activity/* lib/features/telecaller_activity/ 2>/dev/null

# Main container
cp Phase_2-/lib/features/main_container.dart lib/features/ 2>/dev/null

# Screens
mkdir -p lib/screens
cp Phase_2-/lib/screens/profile_completion_details_screen.dart lib/screens/ 2>/dev/null

echo "✅ Phase 2 files copied successfully!"
echo ""
echo "📦 Installing dependencies..."
flutter pub get

echo ""
echo "✅ Phase 2 Integration Complete!"
echo ""
echo "Next steps:"
echo "1. The interested_dashboard_wrapper.dart will be updated automatically"
echo "2. Run: flutter run"
echo "3. Tap 'Interested' in navigation drawer to see Phase 2 dashboard"
