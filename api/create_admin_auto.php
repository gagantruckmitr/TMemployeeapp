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
    
    echo "<h2>Setting up Admin User...</h2>";
    
    // Get actual column names from users table
    $result = $conn->query("DESCRIBE users");
    $columns = [];
    while ($row = $result->fetch_assoc()) {
        $columns[] = $row['Field'];
    }
    
    echo "<p>Found columns: " . implode(', ', $columns) . "</p>";
    
    // Admin credentials
    $adminPassword = 'admin123';
    $hashedPassword = password_hash($adminPassword, PASSWORD_DEFAULT);
    
    // Build insert query based on available columns
    $fields = ['name' => 'Administrator', 'email' => 'admin@truckmitr.com', 'password' => $hashedPassword, 'role' => 'admin', 'status' => 'active'];
    
    // Add optional fields if they exist
    if (in_array('username', $columns)) $fields['username'] = 'admin';
    if (in_array('phone', $columns)) $fields['phone'] = '9999999999';
    if (in_array('mobile', $columns)) $fields['mobile'] = '9999999999';
    if (in_array('created_at', $columns)) $fields['created_at'] = date('Y-m-d H:i:s');
    
    // Check if admin exists
    $checkQuery = "SELECT id FROM users WHERE email = 'admin@truckmitr.com' LIMIT 1";
    $result = $conn->query($checkQuery);
    
    if ($result && $result->num_rows > 0) {
        echo "<div style='background: #fff3cd; padding: 20px; border-radius: 8px; margin: 20px 0;'>";
        echo "<h3>✅ Admin user already exists!</h3>";
        echo "<p><strong>Login:</strong> admin@truckmitr.com (or 'admin' if username field exists)</p>";
        echo "<p><strong>Password:</strong> admin123</p>";
        echo "<p><a href='http://localhost:5173' target='_blank' style='background: #007bff; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;'>Go to Admin Panel</a></p>";
        echo "</div>";
    } else {
        // Build and execute insert
        $fieldNames = array_keys($fields);
        $fieldValues = array_map(function($v) use ($conn) { return "'" . $conn->real_escape_string($v) . "'"; }, array_values($fields));
        
        $insertQuery = "INSERT INTO users (" . implode(', ', $fieldNames) . ") VALUES (" . implode(', ', $fieldValues) . ")";
        
        echo "<p style='color: #666; font-size: 12px;'>Query: $insertQuery</p>";
        
        if ($conn->query($insertQuery)) {
            $loginField = in_array('username', $columns) ? 'admin' : 'admin@truckmitr.com';
            
            echo "<div style='background: #d4edda; padding: 20px; border-radius: 8px; margin: 20px 0;'>";
            echo "<h3>✅ Admin user created successfully!</h3>";
            echo "<p><strong>Login:</strong> $loginField</p>";
            echo "<p><strong>Password:</strong> admin123</p>";
            echo "<hr>";
            echo "<h4>Next Steps:</h4>";
            echo "<ol>";
            echo "<li>Go to <a href='http://localhost:5173' target='_blank'>http://localhost:5173</a></li>";
            echo "<li>Login with: <strong>$loginField</strong></li>";
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
