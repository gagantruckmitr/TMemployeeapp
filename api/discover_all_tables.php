<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

$conn = new mysqli($host, $username, $password, $dbname);

echo "<h2>All Tables in Database</h2>";

$result = $conn->query("SHOW TABLES");
if ($result) {
    echo "<ul>";
    while ($row = $result->fetch_array()) {
        $tableName = $row[0];
        echo "<li><strong>$tableName</strong>";
        
        // Get row count
        $countResult = $conn->query("SELECT COUNT(*) as count FROM `$tableName`");
        if ($countResult) {
            $countRow = $countResult->fetch_assoc();
            echo " - {$countRow['count']} rows";
        }
        echo "</li>";
    }
    echo "</ul>";
}

echo "<h2>Checking 'admins' table for telecallers</h2>";
$result = $conn->query("SELECT id, name, email, role FROM admins WHERE role = 'telecaller' LIMIT 5");
if ($result) {
    echo "<table border='1'><tr><th>ID</th><th>Name</th><th>Email</th><th>Role</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr><td>{$row['id']}</td><td>{$row['name']}</td><td>{$row['email']}</td><td>{$row['role']}</td></tr>";
    }
    echo "</table>";
}

echo "<h2>Checking for assignment-related tables</h2>";
$tables = ['telecaller_assignments', 'lead_assignments', 'driver_assignments', 'assignments'];
foreach ($tables as $table) {
    $result = $conn->query("SHOW TABLES LIKE '$table'");
    if ($result && $result->num_rows > 0) {
        echo "<h3>Found: $table</h3>";
        $result2 = $conn->query("SELECT * FROM `$table` LIMIT 5");
        if ($result2) {
            echo "<pre>";
            while ($row = $result2->fetch_assoc()) {
                print_r($row);
            }
            echo "</pre>";
        }
    }
}

$conn->close();
?>
