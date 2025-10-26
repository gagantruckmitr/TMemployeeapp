# TruckMitr Plesk Deployment Preparation Script
# This script prepares all files for Plesk deployment

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TruckMitr Plesk Deployment Preparation" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Set deployment directory
$deployDir = "C:\TruckMitr-Deploy"
$projectRoot = Get-Location

Write-Host "Project Root: $projectRoot" -ForegroundColor Yellow
Write-Host "Deployment Directory: $deployDir" -ForegroundColor Yellow
Write-Host ""

# Step 1: Create deployment directory
Write-Host "[1/6] Creating deployment directory..." -ForegroundColor Green
if (Test-Path $deployDir) {
    Write-Host "  Removing existing deployment directory..." -ForegroundColor Yellow
    Remove-Item -Path $deployDir -Recurse -Force
}
New-Item -ItemType Directory -Path $deployDir -Force | Out-Null
Write-Host "  Done" -ForegroundColor Green
Write-Host ""

# Step 2: Copy API files
Write-Host "[2/6] Copying API files..." -ForegroundColor Green
$apiSource = Join-Path $projectRoot "api"
$apiDest = Join-Path $deployDir "api"

if (Test-Path $apiSource) {
    Copy-Item -Path $apiSource -Destination $apiDest -Recurse -Force
    Write-Host "  API files copied" -ForegroundColor Green
}
else {
    Write-Host "  API folder not found!" -ForegroundColor Red
}
Write-Host ""

# Step 3: Copy admin panel
Write-Host "[3/6] Copying admin panel..." -ForegroundColor Green
$adminSource = Join-Path $projectRoot "admin"
$adminDest = Join-Path $deployDir "admin"

if (Test-Path $adminSource) {
    Copy-Item -Path $adminSource -Destination $adminDest -Recurse -Force
    Write-Host "  Admin panel copied" -ForegroundColor Green
}
else {
    Write-Host "  Admin folder not found (optional)" -ForegroundColor Yellow
}
Write-Host ""

# Step 4: Copy configuration files
Write-Host "[4/6] Copying configuration files..." -ForegroundColor Green

# .htaccess
$htaccessSource = Join-Path $projectRoot ".htaccess"
if (Test-Path $htaccessSource) {
    Copy-Item -Path $htaccessSource -Destination $deployDir -Force
    Write-Host "  .htaccess copied" -ForegroundColor Green
}
else {
    Write-Host "  .htaccess not found" -ForegroundColor Yellow
}

# .user.ini
$userIniSource = Join-Path $projectRoot ".user.ini"
if (Test-Path $userIniSource) {
    Copy-Item -Path $userIniSource -Destination $deployDir -Force
    Write-Host "  .user.ini copied" -ForegroundColor Green
}
else {
    Write-Host "  .user.ini not found" -ForegroundColor Yellow
}
Write-Host ""

# Step 5: Replace config.php with production version
Write-Host "[5/6] Setting up production configuration..." -ForegroundColor Green
$configProdSource = Join-Path $projectRoot "api\config_production.php"
$configDest = Join-Path $deployDir "api\config.php"

if (Test-Path $configProdSource) {
    Copy-Item -Path $configProdSource -Destination $configDest -Force
    Write-Host "  Production config.php created" -ForegroundColor Green
}
else {
    Write-Host "  config_production.php not found!" -ForegroundColor Red
}
Write-Host ""

# Step 6: Create README
Write-Host "[6/6] Creating deployment instructions..." -ForegroundColor Green
$readmeContent = "TruckMitr Plesk Deployment Package`n`n"
$readmeContent += "Upload all files to: /httpdocs/truckmitr-app/`n`n"
$readmeContent += "Test: https://truckmitr.com/truckmitr-app/api/test_connection.php`n"

$readmePath = Join-Path $deployDir "README.txt"
$readmeContent | Out-File -FilePath $readmePath -Encoding UTF8
Write-Host "  README.txt created" -ForegroundColor Green
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Package Ready!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Location: $deployDir" -ForegroundColor Yellow
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "1. Review files in: $deployDir" -ForegroundColor White
Write-Host "2. Login to Plesk: https://82.29.161.25:8443" -ForegroundColor White
Write-Host "3. Upload all files via File Manager" -ForegroundColor White
Write-Host "4. Test: https://truckmitr.com/truckmitr-app/api/test_connection.php" -ForegroundColor White
Write-Host ""

# Open deployment folder
Write-Host "Opening deployment folder..." -ForegroundColor Green
Start-Process explorer.exe $deployDir
