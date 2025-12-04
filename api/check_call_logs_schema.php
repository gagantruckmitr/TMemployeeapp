<?php
require_once 'config.php';
$result = $conn->query("DESCRIBE call_logs_match_making");
while ($row = $result->fetch_assoc()) {
    echo $row['Field'] . " - " . $row['Type'] . "\n";
}
?>
