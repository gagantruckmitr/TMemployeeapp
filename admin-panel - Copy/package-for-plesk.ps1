# PowerShell script to package admin panel for Plesk deployment

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "TruckMitr Admin Panel - Plesk Package" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if dist folder exists
if (-Not (Test-Path "dist")) {
    Write-Host "Error: dist folder not found. Please run 'npm run build' first." -ForegroundColor Red
    exit 1
}

Write-Host "[Step 1] Copying .htaccess to dist folder..." -ForegroundColor Yellow
Copy-Item ".htaccess" "dist\.htaccess" -Force
Write-Host "✓ .htaccess copied" -ForegroundColor Green
Write-Host ""

Write-Host "[Step 2] Creating deployment package..." -ForegroundColor Yellow
$zipPath = "admin-panel-deploy.zip"

# Remove old zip if exists
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

# Create zip file
Compress-Archive -Path "dist\*" -DestinationPath $zipPath -Force
Write-Host "✓ Package created: $zipPath" -ForegroundColor Green
Write-Host ""

# Get file size
$fileSize = (Get-Item $zipPath).Length / 1MB
Write-Host "Package size: $([math]::Round($fileSize, 2)) MB" -ForegroundColor Cyan
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "DEPLOYMENT INSTRUCTIONS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Login to your Plesk control panel" -ForegroundColor White
Write-Host "2. Go to File Manager" -ForegroundColor White
Write-Host "3. Navigate to httpdocs/" -ForegroundColor White
Write-Host "4. Create a folder named 'admin'" -ForegroundColor White
Write-Host "5. Enter the admin folder" -ForegroundColor White
Write-Host "6. Upload: admin-panel-deploy.zip" -ForegroundColor Yellow
Write-Host "7. Right-click the zip → Extract" -ForegroundColor White
Write-Host "8. Delete the zip file" -ForegroundColor White
Write-Host ""
Write-Host "Your admin panel will be available at:" -ForegroundColor Green
Write-Host "https://yourdomain.com/admin" -ForegroundColor Cyan
Write-Host ""
Write-Host "✓ Package ready for deployment!" -ForegroundColor Green
Write-Host ""

# Open folder
Write-Host "Opening folder..." -ForegroundColor Yellow
Start-Process explorer.exe -ArgumentList (Get-Location).Path
