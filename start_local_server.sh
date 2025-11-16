#!/bin/bash
# Start local PHP server for testing
# This will serve the api folder on 192.168.1.13:80

echo "🚀 Starting local PHP server..."
echo "📁 Serving from: api folder"
echo "🌐 URL: http://192.168.1.13/api"
echo ""
echo "⚠️  Make sure you're running this with sudo for port 80"
echo ""

# Navigate to the project root (parent of api folder)
cd "$(dirname "$0")"

# Start PHP built-in server on port 80 (requires sudo)
# The -t flag sets the document root
sudo php -S 192.168.1.13:80 -t .

# Alternative: If port 80 is blocked, use port 8080
# php -S 192.168.1.13:8080 -t .
# Then update api_config.dart to: http://192.168.1.13:8080/api
