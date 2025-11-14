<?php
require_once 'config.php';

echo "<h2>Testing Callback Requests API</h2>";

// Find admin users from admins table
echo "<h3>1. Finding admin/manager/telecaller users from 'admins' table...</h3>";
$result = $conn->query("SELECT id, name, role, tc_for FROM admins WHERE role IN ('admin', 'manager') OR (role = 'telecaller' AND tc_for = 'call-back') LIMIT 10");

if (!$result) {
    echo "❌ Database error: " . $conn->error . "<br><br>";
} elseif ($result->num_rows > 0) {
    echo "✅ Found " . $result->num_rows . " admin users:<br>";
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>ID</th><th>Name</th><th>Role</th><th>TC For</th></tr>";
    $adminUser = null;
    while ($user = $result->fetch_assoc()) {
        if (!$adminUser) $adminUser = $user;
        $tcFor = $user['tc_for'] ?? 'N/A';
        echo "<tr><td>{$user['id']}</td><td>" . htmlspecialchars($user['name']) . "</td><td>{$user['role']}</td><td>{$tcFor}</td></tr>";
    }
    echo "</table><br>";
    
    if ($adminUser) {
        echo "<h3>2. Test API URLs (using admin ID: {$adminUser['id']}):</h3>";
        $baseUrl = "callback_requests_api.php";
        echo "<strong>✅ Get all callback requests:</strong><br>";
        echo "<a href='{$baseUrl}?action=index&auth_admin_id={$adminUser['id']}' target='_blank'>{$baseUrl}?action=index&auth_admin_id={$adminUser['id']}</a><br><br>";
    }
} else {
    echo "❌ No admin users found in 'admins' table.<br><br>";
}

// Public endpoints (no auth required)
echo "<h3>3. Public API Endpoints (No Auth Required):</h3>";
$baseUrl = "callback_requests_api.php";

echo "<strong>Show callback request #1:</strong><br>";
echo "<a href='{$baseUrl}?action=show&id=1' target='_blank'>{$baseUrl}?action=show&id=1</a><br><br>";

echo "<strong>Export callback requests:</strong><br>";
echo "<a href='{$baseUrl}?action=export&from_date=2024-01-01&to_date=2024-12-31' target='_blank'>{$baseUrl}?action=export&from_date=2024-01-01&to_date=2024-12-31</a><br>";

$conn->close();
?>
