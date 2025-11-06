<?php
/**
 * Simple Phase 2 Login Test
 * Test the login API with hardcoded credentials
 */

require_once 'config.php';

header('Content-Type: application/json');

echo json_encode([
    'test' => 'Phase 2 Login API Test',
    'file_exists' => file_exists(__DIR__ . '/phase2_auth_api.php'),
    'config_loaded' => defined('DB_HOST'),
    'db_connected' => $conn ? true : false,
    'request_method' => $_SERVER['REQUEST_METHOD'],
    'post_data' => $_POST,
    'get_data' => $_GET,
], JSON_PRETTY_PRINT);

// Test query
if ($conn) {
    $query = "SELECT COUNT(*) as total FROM admins WHERE role = 'telecaller' AND tc_for = 'match_making'";
    $result = $conn->query($query);
    if ($result) {
        $count = $result->fetch_assoc()['total'];
        echo "\n\nMatch-making telecallers in database: " . $count;
    }
    
    // Show sample user
    $query2 = "SELECT id, name, mobile, role, tc_for FROM admins WHERE role = 'telecaller' AND tc_for = 'match_making' LIMIT 1";
    $result2 = $conn->query($query2);
    if ($result2 && $result2->num_rows > 0) {
        echo "\n\nSample user:\n";
        echo json_encode($result2->fetch_assoc(), JSON_PRETTY_PRINT);
    }
}
