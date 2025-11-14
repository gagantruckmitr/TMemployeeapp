<?php
require_once 'config.php';

echo "<h2>Testing Callback Request API</h2>";

// Test 1: Check if callback_requests table exists
echo "<h3>1. Checking callback_requests table...</h3>";
$result = $conn->query("SHOW TABLES LIKE 'callback_requests'");
if ($result->num_rows > 0) {
    echo "✅ Table exists<br>";
} else {
    echo "❌ Table does not exist<br>";
}

// Test 2: Check for sample data
echo "<h3>2. Sample callback requests...</h3>";
$result = $conn->query("SELECT * FROM callback_requests LIMIT 5");
echo "Found " . $result->num_rows . " records<br>";

// Test 3: Find ANY user
echo "<h3>3. Finding users...</h3>";
$result = $conn->query("SELECT id, name, role FROM users LIMIT 10");
if (!$result) {
    echo "❌ Error querying users: " . $conn->error . "<br>";
} elseif ($result->num_rows > 0) {
    echo "Found " . $result->num_rows . " users:<br>";
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>ID</th><th>Name</th><th>Role</th></tr>";
    $firstUser = null;
    while ($user = $result->fetch_assoc()) {
        if (!$firstUser) $firstUser = $user;
        echo "<tr><td>{$user['id']}</td><td>" . htmlspecialchars($user['name']) . "</td><td>{$user['role']}</td></tr>";
    }
    echo "</table><br>";
    
    echo "<h3>4. Test API URLs (using user ID: {$firstUser['id']}):</h3>";
    $baseUrl = "callback_request_api.php";
    echo "<strong>Get all callback requests:</strong><br>";
    echo "<a href='{$baseUrl}?action=index&auth_user_id={$firstUser['id']}' target='_blank'>{$baseUrl}?action=index&auth_user_id={$firstUser['id']}</a><br><br>";
    
    echo "<strong>Get single callback request (ID 1):</strong><br>";
    echo "<a href='{$baseUrl}?action=show&id=1' target='_blank'>{$baseUrl}?action=show&id=1</a><br><br>";
    
    echo "<strong>Export callback requests:</strong><br>";
    echo "<a href='{$baseUrl}?action=export&from_date=2024-01-01&to_date=2024-12-31' target='_blank'>{$baseUrl}?action=export&from_date=2024-01-01&to_date=2024-12-31</a><br><br>";
    
    echo "<h3>5. Direct API Test Links (No Auth Required):</h3>";
    echo "<strong>Show callback request #1:</strong><br>";
    echo "<a href='{$baseUrl}?action=show&id=1' target='_blank'>{$baseUrl}?action=show&id=1</a><br><br>";
    
    echo "<strong>Export (no auth needed):</strong><br>";
    echo "<a href='{$baseUrl}?action=export&from_date=2024-01-01&to_date=2024-12-31' target='_blank'>{$baseUrl}?action=export&from_date=2024-01-01&to_date=2024-12-31</a><br>";
} else {
    echo "❌ No users found in database<br>";
}

$conn->close();
?>
