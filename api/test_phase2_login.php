<?php
/**
 * Test Phase 2 Login - Debug Script
 */

require_once 'config.php';

header('Content-Type: application/json');

$mobile = '7678361210'; // Test mobile number

try {
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
    LIMIT 1";
    
    $result = $conn->query($query);
    
    if (!$result) {
        echo json_encode(['error' => 'Query failed: ' . $conn->error]);
        exit;
    }
    
    if ($result->num_rows === 0) {
        echo json_encode(['error' => 'No user found with mobile: ' . $mobile]);
        exit;
    }
    
    $user = $result->fetch_assoc();
    
    // Hide password for security
    $user['password'] = '***hidden***';
    $user['password_length'] = strlen($user['password']);
    
    echo json_encode([
        'success' => true,
        'user' => $user,
        'message' => 'User found. Check role and tc_for values.'
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode(['error' => $e->getMessage()]);
}
