<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Database configuration
$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $conn = new mysqli($host, $username, $password, $dbname);
    
    if ($conn->connect_error) {
        die("Connection failed: " . $conn->connect_error);
    }
    
    echo "<h2>Creating Admin User...</h2>";
    
    // Check if username column exists
    $result = $conn->query("SHOW COLUMNS FROM users LIKE 'username'");
    if ($result->num_rows == 0) {
        echo "<p>Adding username column...</p>";
        if (!$conn->query("ALTER TABLE users ADD COLUMN username VARCHAR(100) UNIQUE AFTER email")) {
            echo "<p style='color: orange;'>Note: " . $conn->error . "</p>";
        }
    }
    
    // Admin credentials
    $adminUsername = 'admin';
    $adminPassword = 'admin123';
    $adminName = 'Administrator';
    $adminEmail = 'admin@truckmitr.com';
    $adminPhone = '9999999999';
    $hashedPassword = password_hash($adminPassword, PASSWORD_DEFAULT);
    
    // Check if admin exists
    $checkQuery = "SELECT id FROM users WHERE email = '$adminEmail' OR phone = '$adminPhone' LIMIT 1";
    $result = $conn->query($checkQuery);
    
    if ($result && $result->num_rows > 0) {
        echo "<div style='background: #fff3cd; padding: 20px; border-radius: 8px; margin: 20px 0;'>";
        echo "<h3>✅ Admin user already exists!</h3>";
        echo "<p><strong>Username:</strong> admin</p>";
        echo "<p><strong>Password:</strong> admin123</p>";
        echo "<p><a href='http://localhost:5173' style='background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;'>Go to Admin Panel</a></p>";
        echo "</div>";
    } else {
        // Insert admin user - try with username first
        $insertQuery = "INSERT INTO users (name, email, username, phone, password, role, status, created_at) 
                       VALUES ('$adminName', '$adminEmail', '$adminUsername', '$adminPhone', '$hashedPassword', 'admin', 'active', NOW())";
        
        if ($conn->query($insertQuery)) {
            echo "<div style='background: #d4edda; padding: 20px; border-radius: 8px; margin: 20px 0;'>";
            echo "<h3>✅ Admin user created successfully!</h3>";
            echo "<p><strong>Username:</strong> admin</p>";
            echo "<p><strong>Password:</strong> admin123</p>";
            echo "<p><strong>Email:</strong> admin@truckmitr.com</p>";
            echo "<hr>";
            echo "<h4>Next Steps:</h4>";
            echo "<ol>";
            echo "<li>Go to <a href='http://localhost:5173' target='_blank'>http://localhost:5173</a></li>";
            echo "<li>Login with username: <strong>admin</strong></li>";
            echo "<li>Password: <strong>admin123</strong></li>";
            echo "</ol>";
            echo "<p><a href='http://localhost:5173' target='_blank' style='background: #28a745; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin-top: 10px;'>Open Admin Panel</a></p>";
            echo "</div>";
        } else {
            // Try without username column if it fails
            $insertQuery2 = "INSERT INTO users (name, email, phone, password, role, status, created_at) 
                            VALUES ('$adminName', '$adminEmail', '$adminPhone', '$hashedPassword', 'admin', 'active', NOW())";
            
            if ($conn->query($insertQuery2)) {
                echo "<div style='background: #d4edda; padding: 20px; border-radius: 8px; margin: 20px 0;'>";
                echo "<h3>✅ Admin user created successfully!</h3>";
                echo "<p><strong>Email:</strong> admin@truckmitr.com</p>";
                echo "<p><strong>Password:</strong> admin123</p>";
                echo "<p style='color: orange;'><em>Note: Login with email instead of username</em></p>";
                echo "<hr>";
                echo "<h4>Next Steps:</h4>";
                echo "<ol>";
                echo "<li>Go to <a href='http://localhost:5173' target='_blank'>http://localhost:5173</a></li>";
                echo "<li>Login with email: <strong>admin@truckmitr.com</strong></li>";
                echo "<li>Password: <strong>admin123</strong></li>";
                echo "</ol>";
                echo "<p><a href='http://localhost:5173' target='_blank' style='background: #28a745; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin-top: 10px;'>Open Admin Panel</a></p>";
                echo "</div>";
            } else {
                echo "<div style='background: #f8d7da; padding: 20px; border-radius: 8px;'>";
                echo "<h3>❌ Error creating admin user</h3>";
                echo "<p>" . $conn->error . "</p>";
                echo "</div>";
            }
        }
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
    <title>Create Admin User - TruckMitr</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        h2 {
            color: #333;
            border-bottom: 2px solid #007bff;
            padding-bottom: 10px;
        }
    </style>
</head>
<body>
</body>
</html>
