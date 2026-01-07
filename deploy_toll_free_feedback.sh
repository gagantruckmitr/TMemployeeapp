#!/bin/bash

# Deploy Toll-Free Feedback API to Production
# This script uploads the necessary files to the production server

echo "🚀 Deploying Toll-Free Feedback API..."

# Files to deploy
FILES=(
    "api/toll_free_feedback_api.php"
    "api/.htaccess"
)

echo ""
echo "📦 Files to deploy:"
for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (NOT FOUND)"
    fi
done

echo ""
echo "📋 Deployment Instructions:"
echo ""
echo "Option 1: Using FTP/SFTP"
echo "  1. Connect to truckmitr.com via FTP/SFTP"
echo "  2. Upload these files:"
echo "     - api/toll_free_feedback_api.php"
echo "     - api/.htaccess"
echo "  3. Set permissions: chmod 644 *.php"
echo ""
echo "Option 2: Using cPanel File Manager"
echo "  1. Login to cPanel"
echo "  2. Open File Manager"
echo "  3. Navigate to public_html/api/"
echo "  4. Upload toll_free_feedback_api.php"
echo "  5. Upload .htaccess (if not exists)"
echo ""
echo "Option 3: Using Git (if configured)"
echo "  git add api/toll_free_feedback_api.php api/.htaccess"
echo "  git commit -m 'Add toll-free feedback API'"
echo "  git push origin main"
echo "  # Then pull on server"
echo ""
echo "Option 4: Using rsync/scp"
echo "  scp api/toll_free_feedback_api.php user@truckmitr.com:/path/to/api/"
echo "  scp api/.htaccess user@truckmitr.com:/path/to/api/"
echo ""
echo "✅ After deployment, test at:"
echo "   https://truckmitr.com/api/toll_free_feedback_api.php?action=get_history&caller_id=3&limit=5"
echo ""
