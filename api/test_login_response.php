<?php
require_once 'config.php';
header('Content-Type: application/json');

// Simulate login for mobile 7678361210
$mobile = '7678361210';

$query = "SELECT 
    id,
    name,
    mobile,
    email,
    password,
    role,
    tc_for,
    created_at
FROM admins 
WHERE mobile = '$mobile' 
AND role = 'telecaller' 
AND tc_for = 'match_making'
LIMIT 1";

$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    $user = $result->fetch_assoc();
    
    // This is what the login API returns
    $userData = [
        'id' => (int)$user['id'],
        'name' => $user['name'],
        'mobile' => $user['mobile'],
        'email' => $user['email'] ?? '',
        'role' => $user['role'],
        'tcFor' => $user['tc_for'],
        'createdAt' => $user['created_at'],
    ];
    
    echo json_encode([
        'success' => true,
        'message' => 'Login successful',
        'data' => $userData
    ], JSON_PRETTY_PRINT);
} else {
    echo json_encode([
        'success' => false,
        'message' => 'User not found'
    ]);
}
?>
