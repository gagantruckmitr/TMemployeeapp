<?php
require_once 'config.php';

echo "<h2>Call Logs Table Structure</h2>";

// Show table structure
$result = $conn->query("DESCRIBE call_logs");
echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th></tr>";
while ($row = $result->fetch_assoc()) {
    echo "<tr><td>{$row['Field']}</td><td>{$row['Type']}</td><td>{$row['Null']}</td><td>{$row['Key']}</td></tr>";
}
echo "</table>";

// Show sample data
echo "<h3>Sample Data (first 5 rows)</h3>";
$result = $conn->query("SELECT * FROM call_logs LIMIT 5");
echo "<pre>";
while ($row = $result->fetch_assoc()) {
    print_r($row);
}
echo "</pre>";

// Count rows
$result = $conn->query("SELECT COUNT(*) as count FROM call_logs");
$count = $result->fetch_assoc()['count'];
echo "<p><strong>Total rows:</strong> $count</p>";
?>
