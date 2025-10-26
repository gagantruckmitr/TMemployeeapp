<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: text/html; charset=utf-8');

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "<h2>Testing Admin Login</h2>";
    
    // Get all admins
    $stmt = $pdo->query("SELECT id, name, email, mobile, role, password FROM admins");
    $admins = $stmt->fetchAll();
    
    echo "<h3>Existing Admins:</h3>";
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
    echo "<tr><th>ID</th><th>Name</th><th>Email</th><th>Mobile</th><th>Role</th><th>Password Hash</th><th>Test Login</th></tr>";
    
    foreach ($admins as $admin) {
        $testPassword = 'admin123';
        $passwordMatch = password_verify($testPassword, $admin['password']);
        
        echo "<tr>";
        echo "<td>{$admin['id']}</td>";
        echo "<td>{$admin['name']}</td>";
        echo "<td>{$admin['email']}</td>";
        echo "<td>{$admin['mobile']}</td>";
        echo "<td>{$admin['role']}</td>";
        echo "<td>" . substr($admin['password'], 0, 30) . "...</td>";
        echo "<td style='background: " . ($passwordMatch ? '#d4edda' : '#f8d7da') . "'>";
        echo $passwordMatch ? '✅ Password: admin123' : '❌ Wrong password';
        echo "</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    // Test login with mobile
    echo "<h3>Test Login API Call:</h3>";
    $testMobile = $admins[0]['mobile'] ?? '9999999999';
    $testPass = 'admin123';
    
    echo "<p><strong>Testing with:</strong></p>";
    echo "<ul>";
    echo "<li>Mobile: $testMobile</li>";
    echo "<li>Password: $testPass</li>";
    echo "</ul>";
    
    $stmt = $pdo->prepare("SELECT * FROM admins WHERE mobile = ?");
    $stmt->execute([$testMobile]);
    $user = $stmt->fetch();
    
    if ($user) {
        echo "<p style='background: #d4edda; padding: 10px;'>✅ User found in database</p>";
        
        if (password_verify($testPass, $user['password'])) {
            echo "<p style='background: #d4edda; padding: 10px;'>✅ Password verification successful!</p>";
            echo "<p><strong>Use these credentials to login:</strong></p>";
            echo "<ul>";
            echo "<li><strong>Mobile:</strong> {$user['mobile']}</li>";
            echo "<li><strong>Password:</strong> admin123</li>";
            echo "</ul>";
        } else {
            echo "<p style='background: #f8d7da; padding: 10px;'>❌ Password verification failed</p>";
            echo "<p>The password hash in database doesn't match 'admin123'</p>";
            echo "<p><a href='create_admin_in_admins_table.php'>Create new admin user</a></p>";
        }
    } else {
        echo "<p style='background: #f8d7da; padding: 10px;'>❌ User not found</p>";
        echo "<p><a href='create_admin_in_admins_table.php'>Create admin user</a></p>";
    }
    
} catch (Exception $e) {
    echo "<div style='background: #f8d7da; padding: 20px;'>";
    echo "<h3>Error:</h3>";
    echo "<p>" . $e->getMessage() . "</p>";
    echo "</div>";
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Test Admin Login</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 1200px;
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
            width: 100%;
        }
        th {
            background: #007bff;
            color: white;
        }
    </style>
</head>
</html>
