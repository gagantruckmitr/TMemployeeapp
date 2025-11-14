<?php
require_once 'config.php';

echo "<h2>Payments Table Structure</h2>";

$result = $conn->query("DESCRIBE payments");
if ($result) {
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>Field</th><th>Type</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr><td>{$row['Field']}</td><td>{$row['Type']}</td></tr>";
    }
    echo "</table>";
} else {
    echo "Error: " . $conn->error;
}

$conn->close();
?>
