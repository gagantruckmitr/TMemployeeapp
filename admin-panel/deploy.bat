@echo off
REM Admin Panel Deployment Script for Plesk (Windows)
REM This script builds and packages the admin panel for deployment

echo.
echo ========================================
echo TruckMitr Admin Panel - Deployment Script
echo ========================================
echo.

REM Step 1: Check if we're in the right directory
if not exist "package.json" (
    echo Error: package.json not found. Please run this script from the admin-panel directory.
    pause
    exit /b 1
)

echo [Step 1] Installing dependencies...
call npm install
if errorlevel 1 (
    echo Error: npm install failed
    pause
    exit /b 1
)
echo Dependencies installed successfully
echo.

echo [Step 2] Building production bundle...
call npm run build
if errorlevel 1 (
    echo Error: Build failed
    pause
    exit /b 1
)
echo Build completed successfully
echo.

echo [Step 3] Adding .htaccess...
copy .htaccess dist\.htaccess
echo .htaccess added
echo.

echo [Step 4] Creating deployment package...
cd dist
powershell Compress-Archive -Path * -DestinationPath ..\admin-panel-deploy.zip -Force
cd ..
echo Deployment package created: admin-panel-deploy.zip
echo.

echo ========================================
echo DEPLOYMENT INSTRUCTIONS
echo ========================================
echo.
echo 1. Login to your Plesk control panel
echo 2. Go to File Manager
echo 3. Navigate to httpdocs/
echo 4. Create a folder named 'admin' (if not exists)
echo 5. Upload admin-panel-deploy.zip to httpdocs/admin/
echo 6. Extract the zip file
echo 7. Delete the zip file
echo.
echo Your admin panel will be available at:
echo https://yourdomain.com/admin
echo.
echo Don't forget to:
echo - Update API_BASE_URL in src/config/api.js before building
echo - Ensure SSL certificate is installed
echo - Test the deployment
echo.
echo Deployment package ready!
echo.
pause
