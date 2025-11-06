<?php
/**
 * Test Phase 2 User Data
 * Check what data is in admins table for caller_id 3
 */

require_once 'config.php';

header('Content-Type: application/json');

if (!$conn) {
    echo json_encode(['error' => 'Database connection failed']);
    exit;
}

// Get user with ID 3
$query = "SELECT 
    id,
    name,
    mobile,
    email,
    role,
    tc_for,
    department,
    created_at
FROM admins 
WHERE id = 3
LIMIT 1";

$result = $conn->query($query);

if (!$result) {
    echo json_encode(['error' => 'Query failed: ' . $conn->error]);
    exit;
}

if ($result->num_rows === 0) {
    echo json_encode(['error' => 'User with ID 3 not found']);
    exit;
}

$user = $result->fetch_assoc();

echo json_encode([
    'success' => true,
    'message' => 'User data for ID 3',
    'data' => $user
], JSON_PRETTY_PRINT);
?>
