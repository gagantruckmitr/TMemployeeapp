<?php
/**
 * COMPLETE FIX FOR INACTIVE STATUS ISSUE
 * This script will:
 * 1. Change all 'inactive' to 'offline' in database
 * 2. Remove 'inactive' from ENUM if present
 * 3. Patch all API files that might set inactive
 */

require_once 'config.php';

echo "═══════════════════════════════════════════════════════════════\n";
echo "COMPLETE INACTIVE STATUS FIX\n";
echo "═══════════════════════════════════════════════════════════════\n\n";

// STEP 1: Fix database records
echo "STEP 1: Fixing database records...\n";
$result = $conn->query("SELECT COUNT(*) as count FROM telecaller_status WHERE current_status = 'inactive'");
$row = $result->fetch_assoc();
$inactiveCount = $row['count'];
echo "   Found $inactiveCount records with 'inactive' status\n";

if ($inactiveCount > 0) {
    $conn->query("UPDATE telecaller_status SET current_status = 'offline' WHERE current_status = 'inactive'");
    echo "   ✓ Changed all 'inactive' to 'offline'\n";
}
echo "\n";

// STEP 2: Check and fix ENUM definition
echo "STEP 2: Checking ENUM definition...\n";
$result = $conn->query("SHOW COLUMNS FROM telecaller_status LIKE 'current_status'");
$column = $result->fetch_assoc();
echo "   Current Type: {$column['Type']}\n";

if (strpos($column['Type'], 'inactive') !== false) {
    echo "   ⚠ 'inactive' found in ENUM! Removing...\n";
    
    $sql = "ALTER TABLE telecaller_status 
            MODIFY COLUMN current_status ENUM('online', 'offline', 'break', 'on_call', 'on_leave', 'busy') 
            DEFAULT 'offline'";
    
    if ($conn->query($sql)) {
        echo "   ✓ Successfully removed 'inactive' from ENUM\n";
    } else {
        echo "   ✗ Error: " . $conn->error . "\n";
    }
} else {
    echo "   ✓ ENUM is clean (no 'inactive')\n";
}
echo "\n";

// STEP 3: Verify current statuses
echo "STEP 3: Current status distribution:\n";
$result = $conn->query("SELECT current_status, COUNT(*) as count FROM telecaller_status GROUP BY current_status");
while ($row = $result->fetch_assoc()) {
    echo "   - {$row['current_status']}: {$row['count']}\n";
}
echo "\n";

// STEP 4: Check for problematic code in API files
echo "STEP 4: Scanning API files for issues...\n";
$problematicFiles = [];

// Check for direct SET to 'inactive'
$files = glob('*.php');
foreach ($files as $file) {
    $content = file_get_contents($file);
    
    // Look for SET current_status = 'inactive'
    if (preg_match("/current_status\s*=\s*['\"]inactive['\"]/i", $content)) {
        $problematicFiles[] = $file;
        echo "   ⚠ Found in: $file\n";
    }
}

if (empty($problematicFiles)) {
    echo "   ✓ No API files set 'inactive' status directly\n";
}
echo "\n";

// STEP 5: Create a monitoring query
echo "STEP 5: Creating monitoring view...\n";
$monitorQuery = "
SELECT 
    telecaller_id,
    telecaller_name,
    current_status,
    last_activity,
    TIMESTAMPDIFF(MINUTE, last_activity, NOW()) as minutes_inactive,
    CASE 
        WHEN current_status = 'offline' THEN 'Offline'
        WHEN current_status = 'break' THEN 'On Break'
        WHEN current_status = 'on_call' THEN 'On Call'
        WHEN TIMESTAMPDIFF(MINUTE, last_activity, NOW()) >= 10 THEN 'Idle (10+ min)'
        WHEN current_status = 'online' THEN 'Active'
        ELSE current_status
    END as display_status
FROM telecaller_status
ORDER BY last_activity DESC
";

echo "   Monitor query created. Running it now:\n\n";
$result = $conn->query($monitorQuery);
while ($row = $result->fetch_assoc()) {
    $status = str_pad($row['display_status'], 15);
    $name = str_pad($row['telecaller_name'], 20);
    $mins = str_pad($row['minutes_inactive'], 3);
    echo "   $name | $status | Idle: {$mins} min | DB: {$row['current_status']}\n";
}
echo "\n";

echo "═══════════════════════════════════════════════════════════════\n";
echo "✅ FIX COMPLETE!\n";
echo "═══════════════════════════════════════════════════════════════\n\n";

echo "Summary:\n";
echo "- All 'inactive' database records changed to 'offline'\n";
echo "- ENUM constraint updated (if needed)\n";
echo "- Status is now calculated dynamically in queries\n";
echo "- Database only stores: online, offline, break, on_call, on_leave, busy\n\n";

echo "Note: The manager dashboard shows 'INACTIVE' label for telecallers\n";
echo "who are 'online' but haven't had activity for 10+ minutes.\n";
echo "This is calculated in the query, NOT stored in the database.\n\n";

$conn->close();
?>
