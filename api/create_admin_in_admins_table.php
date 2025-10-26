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
    
    echo "<h2>Creating Admin in 'admins' table...</h2>";
    
    // Admin credentials
    $adminMobile = '9999999999';
    $adminPassword = 'admin123';
    $adminName = 'Administrator';
    $adminEmail = 'admin@truckmitr.com';
    $adminRole = 'admin';
    $hashedPassword = password_hash($adminPassword, PASSWORD_DEFAULT);
    
    // Check if admin exists
    $checkQuery = "SELECT id FROM admins WHERE mobile = '$adminMobile' OR email = '$adminEmail' LIMIT 1";
    $result = $conn->query($checkQuery);
    
    if ($result && $result->num_rows > 0) {
        echo "<div style='background: #fff3cd; padding: 20px; border-radius: 8px; margin: 20px 0;'>";
        echo "<h3>✅ Admin user already exists!</h3>";
        echo "<p><strong>Mobile:</strong> 9999999999</p>";
        echo "<p><strong>Password:</strong> admin123</p>";
        echo "<p><a href='http://localhost:5173' target='_blank' style='background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;'>Go to Admin Panel</a></p>";
        echo "</div>";
    } else {
        // Insert admin user
        $insertQuery = "INSERT INTO admins (name, email, mobile, password, role, created_at, updated_at) 
                       VALUES ('$adminName', '$adminEmail', '$adminMobile', '$hashedPassword', '$adminRole', NOW(), NOW())";
        
        if ($conn->query($insertQuery)) {
            echo "<div style='background: #d4edda; padding: 20px; border-radius: 8px; margin: 20px 0;'>";
            echo "<h3>✅ Admin user created successfully!</h3>";
            echo "<p><strong>Mobile:</strong> 9999999999</p>";
            echo "<p><strong>Password:</strong> admin123</p>";
            echo "<p><strong>Email:</strong> admin@truckmitr.com</p>";
            echo "<hr>";
            echo "<h4>Next Steps:</h4>";
            echo "<ol>";
            echo "<li>Go to <a href='http://localhost:5173' target='_blank'>http://localhost:5173</a></li>";
            echo "<li>Login with mobile: <strong>9999999999</strong></li>";
            echo "<li>Password: <strong>admin123</strong></li>";
            echo "</ol>";
            echo "<p><a href='http://localhost:5173' target='_blank' style='background: #28a745; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block; margin-top: 10px;'>Open Admin Panel →</a></p>";
            echo "</div>";
        } else {
            echo "<div style='background: #f8d7da; padding: 20px; border-radius: 8px;'>";
            echo "<h3>❌ Error creating admin user</h3>";
            echo "<p>" . $conn->error . "</p>";
            echo "</div>";
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
