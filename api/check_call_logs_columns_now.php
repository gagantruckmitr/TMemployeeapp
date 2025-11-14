<?php
header('Content-Type: text/plain; charset=utf-8');

require_once 'config.php';

echo "Checking call_logs table structure...\n\n";

$result = $conn->query("DESCRIBE call_logs");

echo "Columns in call_logs table:\n";
echo "----------------------------\n";

while ($row = $result->fetch_assoc()) {
    echo $row['Field'] . " (" . $row['Type'] . ")\n";
}

$conn->close();
?>
