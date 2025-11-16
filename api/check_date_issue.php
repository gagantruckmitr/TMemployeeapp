<?php
/**
 * Check Date Issue - Are call_time dates in the future?
 */

require_once 'config.php';

echo "<h2>Checking Date Issue</h2>";
echo "<hr>";

echo "<h3>Current Server Time</h3>";
echo "<p><strong>PHP Date:</strong> " . date('Y-m-d H:i:s') . "</p>";
echo "<p><strong>PHP Timezone:</strong> " . date_default_timezone_get() . "</p>";

$result = $conn->query("SELECT NOW() as db_now, CURDATE() as db_curdate");
$row = $result->fetch_assoc();
echo "<p><strong>MySQL NOW():</strong> " . $row['db_now'] . "</p>";
echo "<p><strong>MySQL CURDATE():</strong> " . $row['db_curdate'] . "</p>";

echo "<hr>";

echo "<h3>Sample call_logs Dates</h3>";
$result = $conn->query("SELECT id, call_time, YEAR(call_time) as year FROM call_logs ORDER BY id DESC LIMIT 10");
echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
echo "<tr><th>ID</th><th>Call Time</th><th>Year</th></tr>";
while ($row = $result->fetch_assoc()) {
    $style = $row['year'] == 2025 ? 'background: #fff3cd;' : '';
    echo "<tr style='$style'><td>{$row['id']}</td><td>{$row['call_time']}</td><td>{$row['year']}</td></tr>";
}
echo "</table>";

echo "<hr>";

echo "<h3>Sample payments Dates</h3>";
$result = $conn->query("SELECT id, created_at, YEAR(created_at) as year FROM payments WHERE payment_status='captured' ORDER BY id DESC LIMIT 10");
echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
echo "<tr><th>ID</th><th>Created At</th><th>Year</th></tr>";
while ($row = $result->fetch_assoc()) {
    $style = $row['year'] == 2025 ? 'background: #fff3cd;' : '';
    echo "<tr style='$style'><td>{$row['id']}</td><td>{$row['created_at']}</td><td>{$row['year']}</td></tr>";
}
echo "</table>";

echo "<hr>";

echo "<h3>Analysis</h3>";
echo "<p>If call_time dates are in 2025 but we're in 2024, this could cause issues with date comparisons.</p>";
echo "<p>The system prompt says current date is: <strong>November 20, 2025</strong></p>";
echo "<p>So dates in 2025 are actually correct!</p>";

echo "<hr>";

// The real issue: Let's check if payment.created_at is DATETIME or TIMESTAMP
echo "<h3>Check Table Structures</h3>";

$result = $conn->query("DESCRIBE call_logs");
echo "<h4>call_logs.call_time</h4>";
while ($row = $result->fetch_assoc()) {
    if ($row['Field'] == 'call_time') {
        echo "<pre>" . print_r($row, true) . "</pre>";
    }
}

$result = $conn->query("DESCRIBE payments");
echo "<h4>payments.created_at</h4>";
while ($row = $result->fetch_assoc()) {
    if ($row['Field'] == 'created_at') {
        echo "<pre>" . print_r($row, true) . "</pre>";
    }
}

echo "<hr>";
echo "<p><em>Check completed at " . date('Y-m-d H:i:s') . "</em></p>";
