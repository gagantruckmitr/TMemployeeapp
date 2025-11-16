<?php
/**
 * Test if user can login to both auth systems
 */

header('Content-Type: text/html; charset=utf-8');

$mobile = '8448079624';
$password = 'test123'; // Try common passwords

echo "<h2>Testing Login for Mobile: $mobile</h2>";

// Database connection
$host = '127.0.0.1';
$port = 3306;
$dbname = 'truckmitr';
$username = 'truckmitr';
$dbpassword = '825Redp&4';

$conn = new mysqli($host, $username, $dbpassword, $dbname, $port);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$conn->set_charset('utf8mb4');

// Check in admins table (Phase 2)
echo "<h3>Phase 2 Auth (admins table):</h3>";
$sql = "SELECT id, name, mobile, password, role, tc_for FROM admins WHERE mobile = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param('s', $mobile);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $user = $result->fetch_assoc();
    echo "<p style='color: green;'>✅ User found in admins table</p>";
    echo "<pre>";
    echo "ID: " . $user['id'] . "\n";
    echo "Name: " . $user['name'] . "\n";
    echo "Mobile: " . $user['mobile'] . "\n";
    echo "Role: " . $user['role'] . "\n";
    echo "tc_for: " . $user['tc_for'] . "\n";
    echo "Password (hashed): " . substr($user['password'], 0, 20) . "...\n";
    echo "</pre>";
    
    // Try to verify password
    echo "<h4>Password Verification:</h4>";
    $testPasswords = ['test123', '123456', 'password', 'admin', $mobile];
    foreach ($testPasswords as $testPass) {
        if (password_verify($testPass, $user['password'])) {
            echo "<p style='color: green;'>✅ Password '$testPass' works with password_verify()</p>";
        } elseif ($testPass === $user['password']) {
            echo "<p style='color: green;'>✅ Password '$testPass' matches (plain text)</p>";
        }
    }
} else {
    echo "<p style='color: red;'>❌ User NOT found in admins table</p>";
}

// Check in users table (Phase 1 - if exists)
echo "<h3>Phase 1 Auth (users table - if exists):</h3>";
$sql2 = "SELECT id, name, mobile, email, role FROM users WHERE mobile = ?";
$stmt2 = $conn->prepare($sql2);
if ($stmt2) {
    $stmt2->bind_param('s', $mobile);
    $stmt2->execute();
    $result2 = $stmt2->get_result();
    
    if ($result2->num_rows > 0) {
        $user2 = $result2->fetch_assoc();
        echo "<p style='color: green;'>✅ User found in users table</p>";
        echo "<pre>";
        print_r($user2);
        echo "</pre>";
    } else {
        echo "<p style='color: orange;'>⚠️ User NOT found in users table (Phase 1)</p>";
        echo "<p>This means the user can only login via Phase 2 auth system.</p>";
    }
} else {
    echo "<p style='color: gray;'>ℹ️ users table doesn't exist</p>";
}

$conn->close();
?>
