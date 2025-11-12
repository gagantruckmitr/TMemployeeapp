<?php
/**
 * Verify Server Timezone Configuration
 */

require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

echo "<h1>Server Timezone Verification</h1>";
echo "<hr>";

// 1. System time
echo "<h2>1. System Information</h2>";
echo "<p><strong>PHP date():</strong> " . date('Y-m-d H:i:s') . "</p>";
echo "<p><strong>PHP timezone:</strong> " . date_default_timezone_get() . "</p>";
echo "<p><strong>PHP time():</strong> " . time() . "</p>";
echo "<hr>";

// 2. MySQL without timezone setting
$conn2 = new mysqli('127.0.0.1', 'truckmitr', '825Redp&4', 'truckmitr', 3306);
$result = $conn2->query("SELECT NOW() as now, UNIX_TIMESTAMP(NOW()) as unix_now, @@session.time_zone as session_tz, @@global.time_zone as global_tz, @@system_time_zone as system_tz");
$row = $result->fetch_assoc();

echo "<h2>2. MySQL (Without SET time_zone)</h2>";
echo "<p><strong>NOW():</strong> " . $row['now'] . "</p>";
echo "<p><strong>UNIX_TIMESTAMP(NOW()):</strong> " . $row['unix_now'] . "</p>";
echo "<p><strong>Session timezone:</strong> " . $row['session_tz'] . "</p>";
echo "<p><strong>Global timezone:</strong> " . $row['global_tz'] . "</p>";
echo "<p><strong>System timezone:</strong> " . $row['system_tz'] . "</p>";

$phpUnix = time();
$mysqlUnix = $row['unix_now'];
$diff = $phpUnix - $mysqlUnix;

echo "<p><strong>Difference from PHP:</strong> " . $diff . " seconds (" . round($diff/3600, 2) . " hours)</p>";

if (abs($diff) > 300) {
    echo "<p style='color: red;'><strong>⚠️ MySQL and PHP times are different!</strong></p>";
    echo "<p>MySQL is likely in UTC while PHP is in IST.</p>";
} else {
    echo "<p style='color: green;'><strong>✓ MySQL and PHP times match</strong></p>";
}

echo "<hr>";

// 3. MySQL with timezone setting
$conn2->query("SET time_zone = '+05:30'");
$result = $conn2->query("SELECT NOW() as now, UNIX_TIMESTAMP(NOW()) as unix_now");
$row = $result->fetch_assoc();

echo "<h2>3. MySQL (With SET time_zone = '+05:30')</h2>";
echo "<p><strong>NOW():</strong> " . $row['now'] . "</p>";
echo "<p><strong>UNIX_TIMESTAMP(NOW()):</strong> " . $row['unix_now'] . "</p>";

$mysqlUnix2 = $row['unix_now'];
$diff2 = $phpUnix - $mysqlUnix2;

echo "<p><strong>Difference from PHP:</strong> " . $diff2 . " seconds</p>";

if (abs($diff2) > 300) {
    echo "<p style='color: red;'><strong>⚠️ Still different after setting timezone!</strong></p>";
} else {
    echo "<p style='color: green;'><strong>✓ Times match after setting timezone</strong></p>";
}

echo "<hr>";

// 4. Recommendation
echo "<h2>4. Recommendation</h2>";

if (abs($diff) > 300) {
    echo "<p style='color: orange;'><strong>MySQL server is in UTC, not IST</strong></p>";
    echo "<p><strong>Solution:</strong> We MUST use <code>SET time_zone = '+05:30'</code> in config.php</p>";
    echo "<p>This ensures NOW() returns IST time when inserting records.</p>";
} else {
    echo "<p style='color: green;'><strong>MySQL server is already in IST</strong></p>";
    echo "<p><strong>Solution:</strong> Do NOT use <code>SET time_zone</code> - it will cause double conversion</p>";
}

$conn2->close();
?>
