<?php
require_once 'config.php';
header('Content-Type: application/json');

$query = "SELECT id, name, mobile, email, role, tc_for, department, created_at FROM admins WHERE id = 3 LIMIT 1";
$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    $user = $result->fetch_assoc();
    echo json_encode(['success' => true, 'data' => $user], JSON_PRETTY_PRINT);
} else {
    echo json_encode(['success' => false, 'message' => 'User not found']);
}
?>
