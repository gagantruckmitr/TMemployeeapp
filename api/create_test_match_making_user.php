<?php
/**
 * Create Test Match-Making User
 * Run this once to create a test user for Phase 2
 */

require_once 'config.php';

header('Content-Type: application/json');

try {
    // Check if user already exists
    $checkQuery = "SELECT id, name, mobile FROM admins WHERE mobile = '9999999999' AND tc_for = 'match_making'";
    $checkResult = $conn->query($checkQuery);
    
    if ($checkResult->num_rows > 0) {
        $existing = $checkResult->fetch_assoc();
        echo json_encode([
            'success' => true,
            'message' => 'Test user already exists',
            'user' => $existing,
            'credentials' => [
                'mobile' => '9999999999',
                'password' => 'test123'
            ]
        ], JSON_PRETTY_PRINT);
        exit;
    }
    
    // Create test user
    $name = 'Test Match Making';
    $mobile = '9999999999';
    $password = 'test123'; // Plain text for testing
    $email = 'test@matchmaking.com';
    $role = 'telecaller';
    $tcFor = 'match_making';
    
    $insertQuery = "INSERT INTO admins (name, mobile, email, password, role, tc_for, created_at, updated_at) 
                    VALUES ('$name', '$mobile', '$email', '$password', '$role', '$tcFor', NOW(), NOW())";
    
    if ($conn->query($insertQuery)) {
        echo json_encode([
            'success' => true,
            'message' => 'Test user created successfully',
            'user' => [
                'id' => $conn->insert_id,
                'name' => $name,
                'mobile' => $mobile,
                'role' => $role,
                'tc_for' => $tcFor
            ],
            'credentials' => [
                'mobile' => $mobile,
                'password' => $password
            ],
            'test_in_postman' => [
                'url' => 'http://localhost/truckmitr-app/api/test_login_postman.php',
                'method' => 'POST',
                'body_type' => 'x-www-form-urlencoded',
                'mobile' => $mobile,
                'password' => $password
            ]
        ], JSON_PRETTY_PRINT);
    } else {
        throw new Exception('Failed to create user: ' . $conn->error);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ], JSON_PRETTY_PRINT);
}

$conn->close();
