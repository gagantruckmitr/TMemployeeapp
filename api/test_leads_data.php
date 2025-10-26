<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

$conn = new mysqli($host, $username, $password, $dbname);

echo "Testing leads data sources...\n\n";

// Check call_logs for driver data
echo "Sample from call_logs:\n";
$result = $conn->query("SELECT driver_id, driver_name, driver_mobile, call_status, caller_id, call_time FROM call_logs LIMIT 5");
if ($result) {
    while ($row = $result->fetch_assoc()) {
        print_r($row);
    }
} else {
    echo "Error: " . $conn->error . "\n";
}

echo "\n\nUnique drivers from call_logs:\n";
$result = $conn->query("SELECT COUNT(DISTINCT driver_id) as count FROM call_logs WHERE driver_id IS NOT NULL");
if ($result) {
    $row = $result->fetch_assoc();
    echo "Total unique drivers: " . $row['count'] . "\n";
}

echo "\n\nDrivers with status breakdown:\n";
$result = $conn->query("SELECT call_status, COUNT(DISTINCT driver_id) as count FROM call_logs WHERE driver_id IS NOT NULL GROUP BY call_status");
if ($result) {
    while ($row = $result->fetch_assoc()) {
        echo $row['call_status'] . ": " . $row['count'] . "\n";
    }
}

$conn->close();
