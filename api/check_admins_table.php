<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $conn = new mysqli($host, $username, $password, $dbname);
    
    if ($conn->connect_error) {
        die("Connection failed: " . $conn->connect_error);
    }
    
    echo "<h2>Checking 'admins' Table...</h2>";
    
    // Check if table exists
    $result = $conn->query("SHOW TABLES LIKE 'admins'");
    
    if ($result->num_rows == 0) {
        echo "<div style='background: #f8d7da; padding: 20px; border-radius: 8px;'>";
        echo "<h3>❌ 'admins' table does not exist!</h3>";
        echo "<p>Creating the table now...</p>";
        
        $createTable = "CREATE TABLE IF NOT EXISTS `admins` (
            `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
            `name` varchar(255) NOT NULL,
            `email` varchar(255) NOT NULL,
            `mobile` varchar(20) NOT NULL,
            `password` varchar(255) NOT NULL,
            `role` enum('admin','manager','telecaller') NOT NULL DEFAULT 'telecaller',
            `remember_token` varchar(100) DEFAULT NULL,
            `created_at` timestamp NULL DEFAULT NULL,
            `updated_at` timestamp NULL DEFAULT NULL,
            PRIMARY KEY (`id`),
            UNIQUE KEY `email` (`email`),
            UNIQUE KEY `mobile` (`mobile`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
        
        if ($conn->query($createTable)) {
            echo "<p style='color: green;'>✅ Table created successfully!</p>";
        } else {
            echo "<p style='color: red;'>Error: " . $conn->error . "</p>";
        }
        echo "</div>";
    } else {
        echo "<p style='color: green;'>✅ 'admins' table exists!</p>";
    }
    
    // Show table structure
    echo "<h3>Table Structure:</h3>";
    $result = $conn->query("DESCRIBE admins");
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse; width: 100%;'>";
    echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>{$row['Field']}</td>";
        echo "<td>{$row['Type']}</td>";
        echo "<td>{$row['Null']}</td>";
        echo "<td>{$row['Key']}</td>";
        echo "<td>{$row['Default']}</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    // Show existing records
    echo "<h3>Existing Records:</h3>";
    $result = $conn->query("SELECT id, name, email, mobile, role, created_at FROM admins");
    
    if ($result->num_rows > 0) {
        echo "<table border='1' cellpadding='10' style='border-collapse: collapse; width: 100%;'>";
        echo "<tr><th>ID</th><th>Name</th><th>Email</th><th>Mobile</th><th>Role</th><th>Created</th></tr>";
        while ($row = $result->fetch_assoc()) {
            echo "<tr>";
            echo "<td>{$row['id']}</td>";
            echo "<td>{$row['name']}</td>";
            echo "<td>{$row['email']}</td>";
            echo "<td>{$row['mobile']}</td>";
            echo "<td>{$row['role']}</td>";
            echo "<td>{$row['created_at']}</td>";
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "<p style='background: #fff3cd; padding: 15px; border-radius: 8px;'>No records found. <a href='create_admin_in_admins_table.php'>Create admin user</a></p>";
    }
    
    $conn->close();
    
} catch (Exception $e) {
    echo "<div style='background: #f8d7da; padding: 20px; border-radius: 8px;'>";
    echo "<h3>❌ Error:</h3>";
    echo "<p>" . $e->getMessage() . "</p>";
    echo "</div>";
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Check Admins Table - TruckMitr</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 1000px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        h2, h3 {
            color: #333;
            border-bottom: 2px solid #007bff;
            padding-bottom: 10px;
        }
        table {
            background: white;
            margin: 20px 0;
        }
        th {
            background: #007bff;
            color: white;
        }
    </style>
</head>
<body>
</body>
</html>
