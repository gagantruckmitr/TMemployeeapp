<?php
require_once 'config.php';

echo "Break Logs Table Structure:\n";
echo "============================\n\n";

$result = mysqli_query($conn, 'DESCRIBE break_logs');
while($row = mysqli_fetch_assoc($result)) {
    echo $row['Field'] . " - " . $row['Type'] . "\n";
}
