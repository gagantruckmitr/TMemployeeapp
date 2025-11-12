<?php
/**
 * Direct SQL Fix for Call Logs
 * Run this to fix ALL timestamps in call_logs and call_logs_match_making
 */

require_once 'config.php';

header('Content-Type: text/plain');

echo "=== DIRECT SQL TIMESTAMP FIX ===\n\n";

$dryRun = !isset($_GET['fix']) || $_GET['fix'] !== 'yes';

if ($dryRun) {
    echo "DRY RUN MODE - Add ?fix=yes to actually run\n\n";
}

// SQL to fix call_logs_match_making
$sql1 = "UPDATE call_logs_match_making 
         SET created_at = DATE_ADD(created_at, INTERVAL 5 HOUR) + INTERVAL 30 MINUTE,
             updated_at = DATE_ADD(updated_at, INTERVAL 5 HOUR) + INTERVAL 30 MINUTE
         WHERE created_at < DATE_SUB(NOW(), INTERVAL 4 HOUR)
         AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)";

// SQL to fix call_logs
$sql2 = "UPDATE call_logs 
         SET created_at = DATE_ADD(created_at, INTERVAL 5 HOUR) + INTERVAL 30 MINUTE
         WHERE created_at < DATE_SUB(NOW(), INTERVAL 4 HOUR)
         AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)";

echo "SQL Query 1 (call_logs_match_making):\n";
echo $sql1 . "\n\n";

echo "SQL Query 2 (call_logs):\n";
echo $sql2 . "\n\n";

if (!$dryRun) {
    echo "EXECUTING...\n\n";
    
    // Fix call_logs_match_making
    if ($conn->query($sql1)) {
        $affected1 = $conn->affected_rows;
        echo "✓ call_logs_match_making: Fixed $affected1 records\n";
    } else {
        echo "✗ call_logs_match_making: Error - " . $conn->error . "\n";
    }
    
    // Fix call_logs
    if ($conn->query($sql2)) {
        $affected2 = $conn->affected_rows;
        echo "✓ call_logs: Fixed $affected2 records\n";
    } else {
        echo "✗ call_logs: Error - " . $conn->error . "\n";
    }
    
    echo "\nDONE!\n";
} else {
    echo "To execute these queries, visit:\n";
    echo $_SERVER['PHP_SELF'] . "?fix=yes\n";
}

echo "\n=== Current Time Check ===\n";
echo "PHP: " . date('Y-m-d H:i:s') . "\n";
$mysqlTime = $conn->query("SELECT NOW() as now")->fetch_assoc()['now'];
echo "MySQL: $mysqlTime\n";
?>
