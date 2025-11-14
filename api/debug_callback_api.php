<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

echo "<h2>Debug Callback API</h2>";

// Test authentication
echo "<h3>Testing Authentication...</h3>";
$adminId = $_GET['auth_admin_id'] ?? 1;
echo "Admin ID: $adminId<br>";

$stmt = $conn->prepare("SELECT * FROM admins WHERE id = ? LIMIT 1");
$stmt->bind_param("i", $adminId);
$stmt->execute();
$result = $stmt->get_result();
$user = $result->fetch_assoc();

if ($user) {
    echo "✅ User found:<br>";
    echo "<pre>";
    print_r($user);
    echo "</pre>";
} else {
    echo "❌ User not found<br>";
    die();
}

// Test callback requests query
echo "<h3>Testing Callback Requests Query...</h3>";
$role = $user['role'] ?? null;
$tc_for = $user['tc_for'] ?? null;
echo "Role: $role<br>";
echo "TC For: $tc_for<br><br>";

// Check if users table has tc_for column
echo "Checking users table structure...<br>";
$checkCol = $conn->query("SHOW COLUMNS FROM users LIKE 'tc_for'");
if ($checkCol->num_rows > 0) {
    echo "✅ users.tc_for column exists<br><br>";
} else {
    echo "❌ users.tc_for column does NOT exist<br>";
    echo "Available columns in users table:<br>";
    $cols = $conn->query("DESCRIBE users");
    while ($col = $cols->fetch_assoc()) {
        echo "- {$col['Field']}<br>";
    }
    echo "<br>";
}

$sql = "SELECT cr.* FROM callback_requests cr 
        INNER JOIN users u ON cr.unique_id = u.unique_id 
        WHERE u.tc_for = 'call-back' ";

if ($role === 'telecaller' && $tc_for === 'call-back') {
    $sql .= " AND cr.assigned_to = ? ORDER BY cr.created_at DESC LIMIT 5";
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        echo "❌ Prepare failed: " . $conn->error . "<br>";
        die();
    }
    $stmt->bind_param("i", $user['id']);
} elseif (in_array($role, ['admin', 'manager'])) {
    $sql .= " ORDER BY cr.created_at DESC LIMIT 5";
    $stmt = $conn->prepare($sql);
    if (!$stmt) {
        echo "❌ Prepare failed: " . $conn->error . "<br>";
        die();
    }
} else {
    echo "❌ Access denied for role: $role<br>";
    die();
}

echo "SQL: $sql<br><br>";

if (!$stmt->execute()) {
    echo "❌ Execute failed: " . $stmt->error . "<br>";
    die();
}
$result = $stmt->get_result();

echo "Found " . $result->num_rows . " callback requests<br><br>";

if ($result->num_rows > 0) {
    echo "<h3>Sample Callback Requests:</h3>";
    while ($row = $result->fetch_assoc()) {
        echo "<pre>";
        print_r($row);
        echo "</pre><hr>";
    }
}

$conn->close();
?>
