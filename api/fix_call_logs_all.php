<?php
/**
 * Fix ALL timestamps in call_logs table
 * No time restrictions - fixes everything
 */

require_once 'config.php';

header('Content-Type: text/plain');

echo "=== FIX ALL CALL_LOGS TIMESTAMPS ===\n\n";

$dryRun = !isset($_GET['fix']) || $_GET['fix'] !== 'yes';

if ($dryRun) {
    echo "DRY RUN MODE - Add ?fix=yes to execute\n\n";
}

// Check current time
echo "Current Time:\n";
echo "PHP: " . date('Y-m-d H:i:s') . "\n";
$mysqlTime = $conn->query("SELECT NOW() as now")->fetch_assoc()['now'];
echo "MySQL: $mysqlTime\n\n";

// Check if call_logs table exists
$tableCheck = $conn->query("SHOW TABLES LIKE 'call_logs'");
if (!$tableCheck || $tableCheck->num_rows === 0) {
    echo "ERROR: call_logs table does not exist!\n";
    exit;
}

// Get sample of current data
echo "Sample of current data (latest 5 records):\n";
$sampleQuery = "SELECT id, created_at FROM call_logs ORDER BY id DESC LIMIT 5";
$sampleResult = $conn->query($sampleQuery);

while ($row = $sampleResult->fetch_assoc()) {
    echo "ID " . $row['id'] . ": " . $row['created_at'] . "\n";
}

echo "\n";

// SQL to fix ALL records (no time restriction)
$sql = "UPDATE call_logs 
        SET created_at = DATE_ADD(created_at, INTERVAL 5 HOUR) + INTERVAL 30 MINUTE
        WHERE HOUR(created_at) < 12";  // Only fix if hour is 0-11 (likely UTC)

echo "SQL Query:\n";
echo $sql . "\n\n";

if (!$dryRun) {
    echo "EXECUTING...\n";
    
    if ($conn->query($sql)) {
        $affected = $conn->affected_rows;
        echo "✓ Fixed $affected records in call_logs\n\n";
        
        // Show sample after fix
        echo "Sample after fix (latest 5 records):\n";
        $sampleResult2 = $conn->query($sampleQuery);
        while ($row = $sampleResult2->fetch_assoc()) {
            echo "ID " . $row['id'] . ": " . $row['created_at'] . "\n";
        }
    } else {
        echo "✗ Error: " . $conn->error . "\n";
    }
} else {
    echo "To execute, visit: " . $_SERVER['PHP_SELF'] . "?fix=yes\n";
}

echo "\nDONE!\n";
?>
