<?php
header('Content-Type: text/plain');
require_once 'config.php';

echo "=== CALL_LOGS_MATCH_MAKING TABLE COLUMNS ===\n\n";

$query = "SHOW COLUMNS FROM call_logs_match_making";
$result = $conn->query($query);

if ($result) {
    while ($row = $result->fetch_assoc()) {
        echo "Column: {$row['Field']} | Type: {$row['Type']}\n";
    }
} else {
    echo "ERROR: " . $conn->error;
}
?>
