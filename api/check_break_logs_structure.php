<?php
require_once 'config.php';

echo "<h2>Break Logs Table Structure</h2>";

$result = $conn->query("DESCRIBE break_logs");

echo "<table border='1' cellpadding='10'>";
echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th></tr>";

while ($row = $result->fetch_assoc()) {
    echo "<tr>";
    echo "<td><strong>{$row['Field']}</strong></td>";
    echo "<td>{$row['Type']}</td>";
    echo "<td>{$row['Null']}</td>";
    echo "<td>{$row['Key']}</td>";
    echo "</tr>";
}

echo "</table>";

// Show sample data
echo "<br><h3>Sample Data:</h3>";
$result = $conn->query("SELECT * FROM break_logs LIMIT 5");

if ($result->num_rows > 0) {
    echo "<table border='1' cellpadding='10'>";
    $first = true;
    while ($row = $result->fetch_assoc()) {
        if ($first) {
            echo "<tr>";
            foreach (array_keys($row) as $col) {
                echo "<th>{$col}</th>";
            }
            echo "</tr>";
            $first = false;
        }
        echo "<tr>";
        foreach ($row as $val) {
            echo "<td>" . ($val ?: 'NULL') . "</td>";
        }
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p>No data in break_logs table</p>";
}

$conn->close();
