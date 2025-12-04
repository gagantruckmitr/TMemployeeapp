<?php
require_once 'config.php';
$result = $conn->query("DESCRIBE job_brief_table");
while ($row = $result->fetch_assoc()) {
    echo $row['Field'] . " - " . $row['Type'] . "\n";
}
?>
