@echo off
echo ========================================
echo  Tiered Telecalling System Setup
echo ========================================
echo.

echo Step 1: Adding database columns...
curl -s http://192.168.29.149/api/add_telecaller_columns.php
echo.

echo Step 2: Creating tracker table...
curl -s http://192.168.29.149/api/create_tracker_table.php
echo.

echo Step 3: Running complete setup...
curl -s http://192.168.29.149/api/setup_tiered_calling_system.php
echo.

echo ========================================
echo  Setup Complete!
echo ========================================
echo.
echo Next Steps:
echo 1. Open Admin Panel: http://192.168.29.149/admin-panel
echo 2. Go to Telecallers page
echo 3. Edit each telecaller to set Type and Level
echo.
pause
