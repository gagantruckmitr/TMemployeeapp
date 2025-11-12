<?php
/**
 * Test what the database actually returns
 */

require_once 'config.php';

header('Content-Type: text/plain');

echo "=== TIMESTAMP TEST ===\n\n";

// Get the latest applyjobs entry
$query = "SELECT 
    a.id,
    a.created_at as applied_at,
    u.name as driver_name,
    j.job_id
FROM applyjobs a
LEFT JOIN users u ON a.driver_id = u.id
LEFT JOIN jobs j ON a.job_id = j.id
ORDER BY a.created_at DESC
LIMIT 5";

$result = $conn->query($query);

echo "Latest 5 applications:\n";
echo str_repeat("-", 80) . "\n";

while ($row = $result->fetch_assoc()) {
    echo "ID: " . $row['id'] . "\n";
    echo "Driver: " . $row['driver_name'] . "\n";
    echo "Job: " . $row['job_id'] . "\n";
    echo "Applied At (from DB): " . $row['applied_at'] . "\n";
    echo "Applied At (PHP formatted): " . date('Y-m-d H:i:s', strtotime($row['applied_at'])) . "\n";
    echo "\n";
}

echo str_repeat("-", 80) . "\n";
echo "Current MySQL time: ";
$timeResult = $conn->query("SELECT NOW() as now");
echo $timeResult->fetch_assoc()['now'] . "\n";

echo "Current PHP time: " . date('Y-m-d H:i:s') . "\n";
echo "PHP Timezone: " . date_default_timezone_get() . "\n";

$tzResult = $conn->query("SELECT @@session.time_zone as tz");
echo "MySQL Session Timezone: " . $tzResult->fetch_assoc()['tz'] . "\n";

?>
