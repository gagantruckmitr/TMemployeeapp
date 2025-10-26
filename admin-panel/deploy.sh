#!/bin/bash

# Admin Panel Deployment Script for Plesk
# This script builds and packages the admin panel for deployment

echo "🚀 TruckMitr Admin Panel - Deployment Script"
echo "=============================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Check if we're in the right directory
if [ ! -f "package.json" ]; then
    echo "❌ Error: package.json not found. Please run this script from the admin-panel directory."
    exit 1
fi

echo "${BLUE}📦 Step 1: Installing dependencies...${NC}"
npm install
if [ $? -ne 0 ]; then
    echo "❌ npm install failed"
    exit 1
fi
echo "${GREEN}✅ Dependencies installed${NC}"
echo ""

# Step 2: Build the project
echo "${BLUE}🏗️  Step 2: Building production bundle...${NC}"
npm run build
if [ $? -ne 0 ]; then
    echo "❌ Build failed"
    exit 1
fi
echo "${GREEN}✅ Build completed${NC}"
echo ""

# Step 3: Copy .htaccess to dist
echo "${BLUE}📄 Step 3: Adding .htaccess...${NC}"
cp .htaccess dist/.htaccess
echo "${GREEN}✅ .htaccess added${NC}"
echo ""

# Step 4: Create deployment package
echo "${BLUE}📦 Step 4: Creating deployment package...${NC}"
cd dist
zip -r ../admin-panel-deploy.zip . -x "*.DS_Store"
cd ..
echo "${GREEN}✅ Deployment package created: admin-panel-deploy.zip${NC}"
echo ""

# Step 5: Display instructions
echo "${YELLOW}=============================================="
echo "📤 DEPLOYMENT INSTRUCTIONS"
echo "==============================================${NC}"
echo ""
echo "1. Login to your Plesk control panel"
echo "2. Go to File Manager"
echo "3. Navigate to httpdocs/"
echo "4. Create a folder named 'admin' (if not exists)"
echo "5. Upload admin-panel-deploy.zip to httpdocs/admin/"
echo "6. Extract the zip file"
echo "7. Delete the zip file"
echo ""
echo "${GREEN}Your admin panel will be available at:${NC}"
echo "https://yourdomain.com/admin"
echo ""
echo "${YELLOW}Don't forget to:${NC}"
echo "- Update API_BASE_URL in src/config/api.js before building"
echo "- Ensure SSL certificate is installed"
echo "- Test the deployment"
echo ""
echo "${GREEN}✅ Deployment package ready!${NC}"
