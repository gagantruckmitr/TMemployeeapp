<?php
header('Content-Type: text/plain');
require_once 'config.php';

echo "=== FIXING FUTURE TIMESTAMPS IN APPLYJOBS ===\n\n";

// Check current timezone
$tzQuery = "SELECT @@session.time_zone as session_tz, NOW() as current_time";
$tzResult = $conn->query($tzQuery);
$tzRow = $tzResult->fetch_assoc();

echo "MySQL Session Timezone: {$tzRow['session_tz']}\n";
echo "MySQL Current Time: {$tzRow['current_time']}\n";
echo "PHP Timezone: " . date_default_timezone_get() . "\n";
echo "PHP Current Time: " . date('Y-m-d H:i:s') . "\n\n";

// Find future timestamps
$checkQuery = "SELECT COUNT(*) as count FROM applyjobs WHERE created_at > NOW()";
$checkResult = $conn->query($checkQuery);
$count = $checkResult->fetch_assoc()['count'];

echo "Found {$count} records with future timestamps\n\n";

if ($count > 0) {
    echo "Fixing timestamps by subtracting 4 hours...\n";
    
    // Fix by subtracting 4 hours (the difference we see)
    $fixQuery = "UPDATE applyjobs 
                 SET created_at = DATE_SUB(created_at, INTERVAL 4 HOUR)
                 WHERE created_at > NOW()";
    
    if ($conn->query($fixQuery)) {
        echo "✓ Fixed {$conn->affected_rows} records\n";
    } else {
        echo "✗ Error: " . $conn->error . "\n";
    }
    
    // Verify
    $verifyQuery = "SELECT COUNT(*) as count FROM applyjobs WHERE created_at > NOW()";
    $verifyResult = $conn->query($verifyQuery);
    $remaining = $verifyResult->fetch_assoc()['count'];
    
    echo "\nRemaining future timestamps: {$remaining}\n";
} else {
    echo "No future timestamps to fix!\n";
}
?>
