<?php
/**
 * Postman-Friendly Login Test
 * Use this to test login in Postman
 * 
 * POSTMAN SETUP:
 * Method: POST
 * URL: http://localhost/truckmitr-app/api/test_login_postman.php
 * Body: x-www-form-urlencoded
 * Key: mobile, Value: your_mobile_number
 * Key: password, Value: your_password
 */

require_once 'config.php';

header('Content-Type: application/json');

// Log the request for debugging
$debug = [
    'timestamp' => date('Y-m-d H:i:s'),
    'method' => $_SERVER['REQUEST_METHOD'],
    'content_type' => $_SERVER['CONTENT_TYPE'] ?? 'not set',
    'post_data' => $_POST,
    'raw_input' => file_get_contents('php://input'),
];

// Handle both form-data and JSON
$mobile = '';
$password = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // Try form-data first
    if (!empty($_POST['mobile'])) {
        $mobile = $_POST['mobile'];
        $password = $_POST['password'] ?? '';
    } else {
        // Try JSON
        $json = json_decode(file_get_contents('php://input'), true);
        if ($json) {
            $mobile = $json['mobile'] ?? '';
            $password = $json['password'] ?? '';
        }
    }
}

if (empty($mobile) || empty($password)) {
    echo json_encode([
        'success' => false,
        'message' => 'Mobile and password are required',
        'debug' => $debug,
        'help' => [
            'postman_setup' => [
                'method' => 'POST',
                'body_type' => 'x-www-form-urlencoded',
                'fields' => [
                    'mobile' => 'your_mobile_number',
                    'password' => 'your_password'
                ]
            ]
        ]
    ], JSON_PRETTY_PRINT);
    exit;
}

try {
    $mobile = $conn->real_escape_string($mobile);
    
    // Query admins table
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
    
    if (!$result) {
        throw new Exception('Query failed: ' . $conn->error);
    }
    
    if ($result->num_rows === 0) {
        echo json_encode([
            'success' => false,
            'message' => 'User not found or not authorized for match-making',
            'debug' => [
                'mobile_searched' => $mobile,
                'query' => $query
            ]
        ], JSON_PRETTY_PRINT);
        exit;
    }
    
    $user = $result->fetch_assoc();
    
    // Verify password
    $passwordValid = false;
    
    if (password_verify($password, $user['password'])) {
        $passwordValid = true;
    } elseif ($password === $user['password']) {
        $passwordValid = true;
    }
    
    if (!$passwordValid) {
        echo json_encode([
            'success' => false,
            'message' => 'Invalid password',
            'debug' => [
                'password_is_hashed' => (strlen($user['password']) > 50),
                'hint' => 'Password does not match'
            ]
        ], JSON_PRETTY_PRINT);
        exit;
    }
    
    // Success - return user data
    echo json_encode([
        'success' => true,
        'message' => 'Login successful',
        'data' => [
            'id' => (int)$user['id'],
            'name' => $user['name'],
            'mobile' => $user['mobile'],
            'email' => $user['email'] ?? '',
            'role' => $user['role'],
            'tcFor' => $user['tc_for'],
            'createdAt' => $user['created_at'],
        ]
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage(),
        'debug' => $debug
    ], JSON_PRETTY_PRINT);
}

$conn->close();
