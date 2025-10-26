<?php
// Fix user passwords in the database
$host = 'localhost';
$dbname = 'truckmitr';
$username = 'root';
$password = '';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "<h2>Fixing User Passwords</h2>";
    
    // Get all users
    $stmt = $pdo->query("SELECT id, name, mobile, role FROM admins");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "<table border='1' cellpadding='10'>";
    echo "<tr><th>ID</th><th>Name</th><th>Mobile</th><th>Role</th><th>New Password</th><th>Status</th></tr>";
    
    foreach ($users as $user) {
        // Set simple password based on role
        $newPassword = 't'; // Simple password for testing
        $hashedPassword = password_hash($newPassword, PASSWORD_BCRYPT);
        
        // Update password
        $updateStmt = $pdo->prepare("UPDATE admins SET password = ? WHERE id = ?");
        $updateStmt->execute([$hashedPassword, $user['id']]);
        
        echo "<tr>";
        echo "<td>{$user['id']}</td>";
        echo "<td>{$user['name']}</td>";
        echo "<td>{$user['mobile']}</td>";
        echo "<td>{$user['role']}</td>";
        echo "<td><strong>t</strong></td>";
        echo "<td style='color: green;'>✓ Updated</td>";
        echo "</tr>";
    }
    
    echo "</table>";
    
    echo "<br><h3 style='color: green;'>✓ All passwords updated successfully!</h3>";
    echo "<p>You can now login with:</p>";
    echo "<ul>";
    foreach ($users as $user) {
        echo "<li>Mobile: <strong>{$user['mobile']}</strong>, Password: <strong>t</strong> ({$user['name']} - {$user['role']})</li>";
    }
    echo "</ul>";
    
} catch(PDOException $e) {
    echo "<p style='color: red;'>Error: " . $e->getMessage() . "</p>";
}
?>
