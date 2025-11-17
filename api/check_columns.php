<?php
require_once 'config.php';

$result = $conn->query('DESCRIBE users');
echo "Database Column Names:\n";
while ($row = $result->fetch_assoc()) {
    echo $row['Field'] . "\n";
}
?>
