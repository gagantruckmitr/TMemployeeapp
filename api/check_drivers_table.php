<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

$conn = new mysqli($host, $username, $password, $dbname);

echo "<h2>Checking Drivers Table Structure</h2>";

// Check table structure
echo "<h3>Table Structure:</h3>";
$result = $conn->query("DESCRIBE drivers");
if ($result) {
    echo "<table border='1'><tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr><td>{$row['Field']}</td><td>{$row['Type']}</td><td>{$row['Null']}</td><td>{$row['Key']}</td><td>{$row['Default']}</td></tr>";
    }
    echo "</table>";
}

// Count total drivers
echo "<h3>Total Drivers:</h3>";
$result = $conn->query("SELECT COUNT(*) as count FROM drivers");
if ($result) {
    $row = $result->fetch_assoc();
    echo "<p>Total: {$row['count']}</p>";
}

// Check assigned drivers
echo "<h3>Assigned Drivers:</h3>";
$result = $conn->query("SELECT COUNT(*) as count FROM drivers WHERE assigned_to IS NOT NULL AND assigned_to != ''");
if ($result) {
    $row = $result->fetch_assoc();
    echo "<p>Assigned: {$row['count']}</p>";
}

// Sample drivers
echo "<h3>Sample Drivers (First 5):</h3>";
$result = $conn->query("SELECT * FROM drivers LIMIT 5");
if ($result) {
    echo "<pre>";
    while ($row = $result->fetch_assoc()) {
        print_r($row);
    }
    echo "</pre>";
}

// Check assignments by telecaller
echo "<h3>Assignments by Telecaller:</h3>";
$result = $conn->query("SELECT assigned_to, COUNT(*) as count FROM drivers WHERE assigned_to IS NOT NULL AND assigned_to != '' GROUP BY assigned_to");
if ($result) {
    echo "<table border='1'><tr><th>Telecaller ID</th><th>Count</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr><td>{$row['assigned_to']}</td><td>{$row['count']}</td></tr>";
    }
    echo "</table>";
}

// Check if there's a status field
echo "<h3>Status Distribution:</h3>";
$result = $conn->query("SELECT status, COUNT(*) as count FROM drivers GROUP BY status");
if ($result) {
    echo "<table border='1'><tr><th>Status</th><th>Count</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr><td>{$row['status']}</td><td>{$row['count']}</td></tr>";
    }
    echo "</table>";
} else {
    echo "<p>No status field or error: " . $conn->error . "</p>";
}

$conn->close();
?>
