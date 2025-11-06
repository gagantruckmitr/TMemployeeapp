<?php
// Simple test to check if PHP is working
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<!DOCTYPE html>";
echo "<html><head><title>Test</title></head><body>";
echo "<h1>PHP is working!</h1>";
echo "<p>PHP Version: " . phpversion() . "</p>";

// Test database connection
define('DB_HOST', '127.0.0.1');
define('DB_PORT', '3306');
define('DB_NAME', 'truckmitr');
define('DB_USER', 'truckmitr');
define('DB_PASS', '825Redp&4');

try {
    $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME, DB_PORT);
    
    if ($conn->connect_error) {
        echo "<p style='color:red;'>Database connection failed: " . $conn->connect_error . "</p>";
    } else {
        echo "<p style='color:green;'>Database connected successfully!</p>";
        
        // Test query
        $result = $conn->query("SELECT COUNT(*) as count FROM admins");
        if ($result) {
            $row = $result->fetch_assoc();
            echo "<p>Total admins in database: " . $row['count'] . "</p>";
        }
    }
} catch (Exception $e) {
    echo "<p style='color:red;'>Error: " . $e->getMessage() . "</p>";
}

echo "</body></html>";
?>
