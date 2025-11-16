#!/bin/bash

echo "=========================================="
echo "Deploying Job Applicants Feedback Fix"
echo "=========================================="
echo ""

# Check if the file exists
if [ ! -f "api/phase2_job_applicants_api.php" ]; then
    echo "❌ Error: api/phase2_job_applicants_api.php not found"
    exit 1
fi

echo "✅ Local file found: api/phase2_job_applicants_api.php"
echo ""

# Show what will be deployed
echo "This script will deploy the updated API file to production."
echo "The fix adds feedback fields (callFeedback, matchStatus, feedbackNotes) to the API response."
echo ""

# Instructions for manual deployment
echo "📋 DEPLOYMENT INSTRUCTIONS:"
echo "============================"
echo ""
echo "1. Upload the file to production server:"
echo "   File: api/phase2_job_applicants_api.php"
echo "   Destination: /truckmitr-app/api/phase2_job_applicants_api.php"
echo ""
echo "2. Verify the deployment:"
echo "   curl 'https://truckmitr.com/truckmitr-app/api/phase2_job_applicants_api.php?job_id=TMJB00418'"
echo ""
echo "3. Test in the app:"
echo "   - Restart the Flutter app"
echo "   - Navigate to a job with applicants (e.g., TMJB00418)"
echo "   - Pull to refresh"
echo "   - Drivers with feedback should show color-coded cards"
echo ""

# Create a backup reminder
echo "⚠️  IMPORTANT: Backup the current production file before deploying!"
echo ""

# Show the key changes
echo "📝 KEY CHANGES IN THE FILE:"
echo "==========================="
echo "Added to response array (around line 150):"
echo "  'transporterTmid' => \$row['transporter_tmid'] ?? '',"
echo "  'transporterName' => \$row['transporter_name'] ?? '',"
echo "  'callFeedback' => \$row['call_feedback'] ?? null,"
echo "  'matchStatus' => \$row['match_status'] ?? null,"
echo "  'feedbackNotes' => \$row['feedback_notes'] ?? null,"
echo ""

echo "✅ Ready to deploy!"
