<?php
/**
 * Check Current Timezone Setting
 */

require_once 'config.php';

header('Content-Type: text/plain');

echo "=== TIMEZONE CHECK ===\n\n";
echo "PHP Timezone: " . date_default_timezone_get() . "\n";
echo "PHP Time: " . date('Y-m-d H:i:s') . "\n\n";

$result = $conn->query("SELECT NOW() as now, @@session.time_zone as tz");
$row = $result->fetch_assoc();

echo "MySQL NOW(): " . $row['now'] . "\n";
echo "MySQL Timezone: " . $row['tz'] . "\n\n";

if ($row['tz'] === '+05:30') {
    echo "✓ MySQL timezone is correctly set to IST\n";
} else {
    echo "✗ MySQL timezone is NOT set to IST!\n";
    echo "  Expected: +05:30\n";
    echo "  Actual: " . $row['tz'] . "\n";
}

// Test NOW() function
$testResult = $conn->query("SELECT NOW() as test_time");
$testRow = $testResult->fetch_assoc();
echo "\nTest NOW() result: " . $testRow['test_time'] . "\n";

$phpTime = date('Y-m-d H:i:s');
$mysqlTime = $testRow['test_time'];

if ($phpTime === $mysqlTime || abs(strtotime($phpTime) - strtotime($mysqlTime)) < 60) {
    echo "✓ PHP and MySQL times match!\n";
} else {
    echo "✗ PHP and MySQL times DON'T match!\n";
    echo "  Difference: " . (strtotime($phpTime) - strtotime($mysqlTime)) . " seconds\n";
}
?>
