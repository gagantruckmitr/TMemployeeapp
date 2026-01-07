<?php
/**
 * Find and test a transporter's profile completion
 */

require_once 'config.php';

// Find a transporter user
$stmt = $conn->prepare("
    SELECT id, unique_id, name, role 
    FROM users 
    WHERE role = 'transporter' 
    LIMIT 5
");
$stmt->execute();
$result = $stmt->get_result();

echo "<h2>Transporter Users</h2>";
echo "<table border='1' cellpadding='5'>";
echo "<tr><th>ID</th><th>TMID</th><th>Name</th><th>Test Link</th></tr>";

while ($row = $result->fetch_assoc()) {
    echo "<tr>";
    echo "<td>{$row['id']}</td>";
    echo "<td>{$row['unique_id']}</td>";
    echo "<td>{$row['name']}</td>";
    echo "<td><a href='test_profile_completion_consistency.php?user_id={$row['id']}' target='_blank'>Test Profile</a></td>";
    echo "</tr>";
}

echo "</table>";

// Also check callback requests for transporters
echo "<h2>Transporters in Callback Requests</h2>";
$stmt = $conn->prepare("
    SELECT DISTINCT cr.unique_id, u.id, u.name, u.role
    FROM callback_requests cr
    LEFT JOIN users u ON cr.unique_id = u.unique_id
    WHERE u.role = 'transporter'
    LIMIT 10
");
$stmt->execute();
$result = $stmt->get_result();

echo "<table border='1' cellpadding='5'>";
echo "<tr><th>User ID</th><th>TMID</th><th>Name</th><th>Test Link</th></tr>";

while ($row = $result->fetch_assoc()) {
    echo "<tr>";
    echo "<td>{$row['id']}</td>";
    echo "<td>{$row['unique_id']}</td>";
    echo "<td>{$row['name']}</td>";
    echo "<td><a href='test_profile_completion_consistency.php?user_id={$row['id']}' target='_blank'>Test Profile</a></td>";
    echo "</tr>";
}

echo "</table>";
?>
