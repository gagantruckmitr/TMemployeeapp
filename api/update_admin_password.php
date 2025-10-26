<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "<h2>Updating Admin Password...</h2>";
    
    // Update Rony (admin) with new password
    $newPassword = 'admin123';
    $hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);
    
    // Update admin user (ID 8 - Rony)
    $stmt = $pdo->prepare("UPDATE admins SET password = ? WHERE id = 8");
    $stmt->execute([$hashedPassword]);
    
    echo "<div style='background: #d4edda; padding: 20px; border-radius: 8px; margin: 20px 0;'>";
    echo "<h3>✅ Password updated successfully!</h3>";
    echo "<p><strong>Login Credentials:</strong></p>";
    echo "<ul>";
    echo "<li><strong>Mobile:</strong> 9876543210</li>";
    echo "<li><strong>Password:</strong> admin123</li>";
    echo "<li><strong>Name:</strong> Rony (Admin)</li>";
    echo "</ul>";
    echo "<hr>";
    echo "<p><a href='http://localhost:5173' target='_blank' style='background: #28a745; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px; display: inline-block;'>Login to Admin Panel →</a></p>";
    echo "</div>";
    
    // Also update Deepak Arora (first admin)
    $stmt2 = $pdo->prepare("UPDATE admins SET password = ? WHERE id = 1");
    $stmt2->execute([$hashedPassword]);
    
    echo "<div style='background: #d1ecf1; padding: 20px; border-radius: 8px; margin: 20px 0;'>";
    echo "<h3>✅ Alternative Login (Deepak Arora):</h3>";
    echo "<ul>";
    echo "<li><strong>Mobile:</strong> 8800549949</li>";
    echo "<li><strong>Password:</strong> admin123</li>";
    echo "</ul>";
    echo "</div>";
    
    // Verify the update
    echo "<h3>Verification:</h3>";
    $stmt = $pdo->query("SELECT id, name, mobile, role FROM admins WHERE id IN (1, 8)");
    $users = $stmt->fetchAll();
    
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse; background: white;'>";
    echo "<tr><th>ID</th><th>Name</th><th>Mobile</th><th>Role</th><th>Password Test</th></tr>";
    
    foreach ($users as $user) {
        $stmt = $pdo->prepare("SELECT password FROM admins WHERE id = ?");
        $stmt->execute([$user['id']]);
        $pass = $stmt->fetch()['password'];
        $match = password_verify('admin123', $pass);
        
        echo "<tr>";
        echo "<td>{$user['id']}</td>";
        echo "<td>{$user['name']}</td>";
        echo "<td>{$user['mobile']}</td>";
        echo "<td>{$user['role']}</td>";
        echo "<td style='background: " . ($match ? '#d4edda' : '#f8d7da') . "'>";
        echo $match ? '✅ Works' : '❌ Failed';
        echo "</td>";
        echo "</tr>";
    }
    echo "</table>";
    
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
    <title>Update Admin Password</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
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
            width: 100%;
            margin: 20px 0;
        }
        th {
            background: #007bff;
            color: white;
        }
    </style>
</head>
</html>
