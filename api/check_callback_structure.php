<?php
require_once 'config.php';

echo "<h2>Callback Requests Table Structure</h2>";

// Show table structure
$result = $conn->query("DESCRIBE callback_requests");
echo "<table border='1' cellpadding='5'>";
echo "<tr><th>Field</th><th>Type</th></tr>";
while ($row = $result->fetch_assoc()) {
    echo "<tr><td>{$row['Field']}</td><td>{$row['Type']}</td></tr>";
}
echo "</table><br>";

// Show sample data
echo "<h3>Sample Data:</h3>";
$result = $conn->query("SELECT * FROM callback_requests LIMIT 3");
while ($row = $result->fetch_assoc()) {
    echo "<pre>";
    print_r($row);
    echo "</pre><hr>";
}

$conn->close();
?>
