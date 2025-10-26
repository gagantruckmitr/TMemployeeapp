<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $conn = new mysqli($host, $username, $password, $dbname);
    
    if ($conn->connect_error) {
        throw new Exception("Connection failed: " . $conn->connect_error);
    }
    
    echo "Connected successfully\n\n";
    
    // Check tables
    echo "Checking tables...\n";
    $tables = ['admins', 'call_logs', 'drivers'];
    foreach ($tables as $table) {
        $result = $conn->query("SHOW TABLES LIKE '$table'");
        echo "$table: " . ($result->num_rows > 0 ? "EXISTS" : "NOT FOUND") . "\n";
    }
    
    echo "\n\nChecking admins table structure...\n";
    $result = $conn->query("DESCRIBE admins");
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            echo $row['Field'] . " - " . $row['Type'] . "\n";
        }
    }
    
    echo "\n\nChecking call_logs table structure...\n";
    $result = $conn->query("DESCRIBE call_logs");
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            echo $row['Field'] . " - " . $row['Type'] . "\n";
        }
    }
    
    echo "\n\nChecking drivers table structure...\n";
    $result = $conn->query("DESCRIBE drivers");
    if ($result) {
        while ($row = $result->fetch_assoc()) {
            echo $row['Field'] . " - " . $row['Type'] . "\n";
        }
    }
    
    echo "\n\nTesting simple query...\n";
    $result = $conn->query("SELECT id, name, email, mobile, role FROM admins WHERE role = 'telecaller' LIMIT 1");
    if ($result) {
        $row = $result->fetch_assoc();
        print_r($row);
    } else {
        echo "Error: " . $conn->error . "\n";
    }
    
    $conn->close();
    
} catch (Exception $e) {
    echo "Error: " . $e->getMessage();
}
