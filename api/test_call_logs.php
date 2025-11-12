<?php
/**
 * Test call_logs data
 */

require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

echo "<h1>Call Logs Test</h1>";
echo "<hr>";

// Check if table exists
$tableCheck = $conn->query("SHOW TABLES LIKE 'call_logs'");
if (!$tableCheck || $tableCheck->num_rows === 0) {
    echo "<p style='color: red;'>call_logs table does NOT exist!</p>";
    exit;
}

echo "<p style='color: green;'>call_logs table exists</p>";

// Count total records
$countResult = $conn->query("SELECT COUNT(*) as total FROM call_logs");
$total = $countResult->fetch_assoc()['total'];
echo "<p><strong>Total records:</strong> $total</p>";

if ($total === 0) {
    echo "<p style='color: orange;'>Table is empty!</p>";
    exit;
}

// Show latest 10 records
echo "<h2>Latest 10 Records</h2>";
$query = "SELECT * FROM call_logs ORDER BY id DESC LIMIT 10";
$result = $conn->query($query);

echo "<table border='1' cellpadding='5' style='border-collapse: collapse; font-size: 12px;'>";
echo "<tr>";
$fields = $result->fetch_fields();
foreach ($fields as $field) {
    echo "<th>" . $field->name . "</th>";
}
echo "</tr>";

while ($row = $result->fetch_assoc()) {
    echo "<tr>";
    foreach ($row as $value) {
        echo "<td>" . htmlspecialchars($value ?? 'NULL') . "</td>";
    }
    echo "</tr>";
}
echo "</table>";

// Check today's records
echo "<hr>";
echo "<h2>Today's Records</h2>";
$todayQuery = "SELECT COUNT(*) as count FROM call_logs WHERE DATE(created_at) = CURDATE()";
$todayResult = $conn->query($todayQuery);
$todayCount = $todayResult->fetch_assoc()['count'];
echo "<p><strong>Records created today:</strong> $todayCount</p>";

// Check this week's records
$weekQuery = "SELECT COUNT(*) as count FROM call_logs WHERE created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)";
$weekResult = $conn->query($weekQuery);
$weekCount = $weekResult->fetch_assoc()['count'];
echo "<p><strong>Records this week:</strong> $weekCount</p>";

// Current time
echo "<hr>";
echo "<p><strong>Current MySQL time:</strong> " . $conn->query("SELECT NOW() as now")->fetch_assoc()['now'] . "</p>";
echo "<p><strong>Current date:</strong> " . $conn->query("SELECT CURDATE() as today")->fetch_assoc()['today'] . "</p>";
?>
