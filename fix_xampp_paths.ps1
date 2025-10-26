# Fix Admin Panel Paths for XAMPP
Write-Host "Fixing admin panel paths for XAMPP..." -ForegroundColor Green

$adminPath = "D:\xampp\htdocs\api\admin"

# Fix login.php
$loginFile = "$adminPath\login.php"
if (Test-Path $loginFile) {
    $content = Get-Content $loginFile -Raw
    $content = $content -replace [regex]::Escape("require_once '../api/config.php';"), "require_once '../config.php';"
    Set-Content $loginFile -Value $content -NoNewline
    Write-Host "Fixed login.php" -ForegroundColor Green
}

# Fix index.php
$indexFile = "$adminPath\index.php"
if (Test-Path $indexFile) {
    $content = Get-Content $indexFile -Raw
    $content = $content -replace [regex]::Escape("require_once '../api/config.php';"), "require_once '../config.php';"
    Set-Content $indexFile -Value $content -NoNewline
    Write-Host "Fixed index.php" -ForegroundColor Green
}

# Fix test_setup.php
$testFile = "$adminPath\test_setup.php"
if (Test-Path $testFile) {
    $content = Get-Content $testFile -Raw
    $content = $content -replace [regex]::Escape("require_once '../api/config.php';"), "require_once '../config.php';"
    Set-Content $testFile -Value $content -NoNewline
    Write-Host "Fixed test_setup.php" -ForegroundColor Green
}

# Fix logout.php
$logoutFile = "$adminPath\logout.php"
if (Test-Path $logoutFile) {
    $content = Get-Content $logoutFile -Raw
    $content = $content -replace [regex]::Escape("require_once '../api/config.php';"), "require_once '../config.php';"
    Set-Content $logoutFile -Value $content -NoNewline
    Write-Host "Fixed logout.php" -ForegroundColor Green
}

# Fix JavaScript API paths
$jsFile = "$adminPath\assets\js\modern-admin.js"
if (Test-Path $jsFile) {
    $content = Get-Content $jsFile -Raw
    $content = $content -replace [regex]::Escape("fetch('../api/complete_admin_api.php"), "fetch('api/complete_admin_api.php"
    Set-Content $jsFile -Value $content -NoNewline
    Write-Host "Fixed modern-admin.js" -ForegroundColor Green
}

Write-Host ""
Write-Host "All paths fixed!" -ForegroundColor Green
Write-Host ""
Write-Host "Now open: http://localhost/api/admin/test_setup.php" -ForegroundColor Cyan
