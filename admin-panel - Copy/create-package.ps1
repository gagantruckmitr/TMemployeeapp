# Simple PowerShell script to package admin panel for Plesk

Write-Host ""
Write-Host "Creating Plesk deployment package..." -ForegroundColor Cyan
Write-Host ""

# Check if dist folder exists
if (-Not (Test-Path "dist")) {
    Write-Host "ERROR: dist folder not found!" -ForegroundColor Red
    Write-Host "Please run 'npm run build' first." -ForegroundColor Yellow
    exit 1
}

# Copy .htaccess
Write-Host "Copying .htaccess..." -ForegroundColor Yellow
Copy-Item ".htaccess" "dist\.htaccess" -Force

# Remove old zip
if (Test-Path "admin-panel-deploy.zip") {
    Remove-Item "admin-panel-deploy.zip" -Force
}

# Create zip
Write-Host "Creating zip file..." -ForegroundColor Yellow
Compress-Archive -Path "dist\*" -DestinationPath "admin-panel-deploy.zip" -Force

# Get size
$size = (Get-Item "admin-panel-deploy.zip").Length / 1MB
$sizeRounded = [math]::Round($size, 2)

Write-Host ""
Write-Host "SUCCESS!" -ForegroundColor Green
Write-Host "Package created: admin-panel-deploy.zip ($sizeRounded MB)" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Login to Plesk" -ForegroundColor White
Write-Host "2. Go to File Manager > httpdocs/" -ForegroundColor White
Write-Host "3. Create 'admin' folder" -ForegroundColor White
Write-Host "4. Upload admin-panel-deploy.zip" -ForegroundColor White
Write-Host "5. Extract the zip file" -ForegroundColor White
Write-Host ""
Write-Host "Your admin panel will be at: https://yourdomain.com/admin" -ForegroundColor Green
Write-Host ""
