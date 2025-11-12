<?php
/**
 * Timestamp Diagnostic Tool
 * Checks for timezone mismatches and future timestamps
 */

require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

echo "<h1>Timestamp Diagnostic Report</h1>";
echo "<hr>";

// 1. Check PHP timezone
echo "<h2>1. PHP Configuration</h2>";
echo "<strong>PHP Timezone:</strong> " . date_default_timezone_get() . "<br>";
echo "<strong>Current PHP Time:</strong> " . date('Y-m-d H:i:s') . "<br>";
echo "<strong>Current Unix Timestamp:</strong> " . time() . "<br>";
echo "<hr>";

// 2. Check MySQL timezone
echo "<h2>2. MySQL Configuration</h2>";
$result = $conn->query("SELECT NOW() as mysql_now, @@session.time_zone as session_tz, @@global.time_zone as global_tz");
if ($result) {
    $row = $result->fetch_assoc();
    echo "<strong>MySQL NOW():</strong> " . $row['mysql_now'] . "<br>";
    echo "<strong>Session Timezone:</strong> " . $row['session_tz'] . "<br>";
    echo "<strong>Global Timezone:</strong> " . $row['global_tz'] . "<br>";
}
echo "<hr>";

// 3. Check applyjobs table for future timestamps
echo "<h2>3. Future Timestamps in applyjobs Table</h2>";
$futureQuery = "SELECT 
    a.id,
    a.job_id,
    a.driver_id,
    u.name as driver_name,
    a.created_at,
    UNIX_TIMESTAMP(a.created_at) as created_timestamp,
    UNIX_TIMESTAMP(NOW()) as current_timestamp,
    UNIX_TIMESTAMP(a.created_at) - UNIX_TIMESTAMP(NOW()) as diff_seconds
FROM applyjobs a
LEFT JOIN users u ON a.driver_id = u.id
WHERE a.created_at > NOW()
ORDER BY a.created_at DESC
LIMIT 20";

$result = $conn->query($futureQuery);
if ($result && $result->num_rows > 0) {
    echo "<strong style='color: red;'>Found " . $result->num_rows . " future timestamps!</strong><br><br>";
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>ID</th><th>Job ID</th><th>Driver</th><th>Created At</th><th>Diff (seconds)</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . $row['id'] . "</td>";
        echo "<td>" . $row['job_id'] . "</td>";
        echo "<td>" . $row['driver_name'] . "</td>";
        echo "<td>" . $row['created_at'] . "</td>";
        echo "<td style='color: red;'>+" . round($row['diff_seconds']) . "s</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<strong style='color: green;'>No future timestamps found!</strong><br>";
}
echo "<hr>";

// 4. Check recent applyjobs entries
echo "<h2>4. Recent applyjobs Entries (Last 10)</h2>";
$recentQuery = "SELECT 
    a.id,
    a.job_id,
    a.driver_id,
    u.name as driver_name,
    a.created_at,
    UNIX_TIMESTAMP(a.created_at) as created_timestamp,
    UNIX_TIMESTAMP(NOW()) as current_timestamp,
    UNIX_TIMESTAMP(a.created_at) - UNIX_TIMESTAMP(NOW()) as diff_seconds
FROM applyjobs a
LEFT JOIN users u ON a.driver_id = u.id
ORDER BY a.created_at DESC
LIMIT 10";

$result = $conn->query($recentQuery);
if ($result) {
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>ID</th><th>Job ID</th><th>Driver</th><th>Created At</th><th>Diff (seconds)</th></tr>";
    while ($row = $result->fetch_assoc()) {
        $diffSeconds = round($row['diff_seconds']);
        $color = $diffSeconds > 0 ? 'red' : 'green';
        echo "<tr>";
        echo "<td>" . $row['id'] . "</td>";
        echo "<td>" . $row['job_id'] . "</td>";
        echo "<td>" . $row['driver_name'] . "</td>";
        echo "<td>" . $row['created_at'] . "</td>";
        echo "<td style='color: $color;'>" . ($diffSeconds > 0 ? '+' : '') . $diffSeconds . "s</td>";
        echo "</tr>";
    }
    echo "</table>";
}
echo "<hr>";

// 5. Recommendation
echo "<h2>5. Recommendations</h2>";
$result = $conn->query("SELECT @@session.time_zone as session_tz");
$row = $result->fetch_assoc();
$mysqlTz = $row['session_tz'];

if ($mysqlTz !== '+05:30') {
    echo "<p style='color: orange;'><strong>⚠️ MySQL timezone is '$mysqlTz' but should be '+05:30' (IST)</strong></p>";
    echo "<p>The config.php file sets it to '+05:30', but it may not be working.</p>";
} else {
    echo "<p style='color: green;'><strong>✓ MySQL timezone is correctly set to IST (+05:30)</strong></p>";
}

$phpTz = date_default_timezone_get();
if ($phpTz !== 'Asia/Kolkata') {
    echo "<p style='color: orange;'><strong>⚠️ PHP timezone is '$phpTz' but should be 'Asia/Kolkata'</strong></p>";
} else {
    echo "<p style='color: green;'><strong>✓ PHP timezone is correctly set to Asia/Kolkata</strong></p>";
}

echo "<hr>";
echo "<p><em>Generated at: " . date('Y-m-d H:i:s') . "</em></p>";
?>
