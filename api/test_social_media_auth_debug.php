<?php
/**
 * Debug Social Media Authentication
 */

header('Content-Type: application/json');

// Database connection
$host = '127.0.0.1';
$port = 3306;
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $conn = new mysqli($host, $username, $password, $dbname, $port);
    
    if ($conn->connect_error) {
        throw new Exception('Database connection failed: ' . $conn->connect_error);
    }
    
    $conn->set_charset('utf8mb4');
    
} catch (Exception $e) {
    echo json_encode(['error' => 'Database error: ' . $e->getMessage()]);
    exit;
}

// Get user_id from query parameter
$userId = isset($_GET['user_id']) ? intval($_GET['user_id']) : 0;

echo "<h2>Social Media Auth Debug</h2>";
echo "<p><strong>User ID from request:</strong> $userId</p>";

// Check admins table
$sql = "SELECT id, name, mobile, role, tc_for FROM admins WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param('i', $userId);
$stmt->execute();
$result = $stmt->get_result();

echo "<h3>User Lookup in 'admins' table:</h3>";
if ($result->num_rows > 0) {
    $user = $result->fetch_assoc();
    echo "<pre>";
    print_r($user);
    echo "</pre>";
    
    echo "<p><strong>tc_for value:</strong> '" . $user['tc_for'] . "'</p>";
    echo "<p><strong>tc_for lowercase:</strong> '" . strtolower($user['tc_for']) . "'</p>";
    echo "<p><strong>Matches 'social-media'?</strong> " . (strtolower($user['tc_for']) === 'social-media' ? 'YES' : 'NO') . "</p>";
    
    if (strtolower($user['tc_for']) !== 'social-media') {
        echo "<p style='color: red;'><strong>ACCESS DENIED:</strong> User tc_for is '{$user['tc_for']}', not 'social-media'</p>";
    } else {
        echo "<p style='color: green;'><strong>ACCESS GRANTED:</strong> User has correct tc_for value</p>";
    }
} else {
    echo "<p style='color: red;'>No user found with ID: $userId</p>";
}

// List all social-media users
echo "<h3>All users with tc_for = 'social-media':</h3>";
$sql2 = "SELECT id, name, mobile, role, tc_for FROM admins WHERE tc_for LIKE '%social%'";
$result2 = $conn->query($sql2);

if ($result2->num_rows > 0) {
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>ID</th><th>Name</th><th>Mobile</th><th>Role</th><th>tc_for</th></tr>";
    while ($row = $result2->fetch_assoc()) {
        echo "<tr>";
        echo "<td>{$row['id']}</td>";
        echo "<td>{$row['name']}</td>";
        echo "<td>{$row['mobile']}</td>";
        echo "<td>{$row['role']}</td>";
        echo "<td>{$row['tc_for']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p>No users found with social-media tc_for</p>";
}

$conn->close();
?>
