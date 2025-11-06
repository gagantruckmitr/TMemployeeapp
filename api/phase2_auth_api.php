<?php
/**
 * Phase 2 Authentication API
 * Login for match-making telecallers using admins table
 */

require_once 'config.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = isset($_POST['action']) ? $_POST['action'] : '';
    
    if ($action === 'login') {
        login();
    } else {
        sendError('Invalid action', 400);
    }
} else {
    sendError('Method not allowed', 405);
}

function login() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    // Get phone and password from POST
    $mobile = isset($_POST['mobile']) ? $conn->real_escape_string($_POST['mobile']) : '';
    $password = isset($_POST['password']) ? $_POST['password'] : '';
    
    if (empty($mobile) || empty($password)) {
        sendError('Mobile and password are required', 400);
    }
    
    try {
        // Query admins table with role and tc_for conditions
        // Accept both 'match-making' and 'match_making' for backward compatibility
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
        AND (tc_for = 'match-making' OR tc_for = 'match_making')
        LIMIT 1";
        
        $result = $conn->query($query);
        
        if (!$result) {
            sendError('Query failed: ' . $conn->error, 500);
        }
        
        if ($result->num_rows === 0) {
            sendError('Invalid credentials or not authorized for match-making', 401);
        }
        
        $user = $result->fetch_assoc();
        
        // Verify password - check both hashed and plain text
        $passwordValid = false;
        
        // First try password_verify for hashed passwords
        if (password_verify($password, $user['password'])) {
            $passwordValid = true;
        }
        // If that fails, try direct comparison for plain text passwords
        elseif ($password === $user['password']) {
            $passwordValid = true;
        }
        
        if (!$passwordValid) {
            sendError('Invalid credentials', 401);
        }
        
        // Return user data (excluding password)
        $userData = [
            'id' => (int)$user['id'],
            'name' => $user['name'],
            'mobile' => $user['mobile'],
            'email' => $user['email'] ?? '',
            'role' => $user['role'],
            'tcFor' => $user['tc_for'],
            'createdAt' => $user['created_at'],
        ];
        
        sendSuccess($userData, 'Login successful');
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}
?>
