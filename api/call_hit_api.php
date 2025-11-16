<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'config.php';

// Log the request method for debugging
error_log("Call Hit API: Request method: " . $_SERVER['REQUEST_METHOD']);

// Only allow POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    error_log("Call Hit API: Rejected non-POST request: " . $_SERVER['REQUEST_METHOD']);
    http_response_code(405);
    echo json_encode([
        'success' => false, 
        'error' => 'Method not allowed. Expected POST, got ' . $_SERVER['REQUEST_METHOD']
    ]);
    exit;
}

try {
    // Log request for debugging
    error_log("Call Hit API: Request received at " . date('Y-m-d H:i:s'));
    
    // Get JSON input
    $rawInput = file_get_contents('php://input');
    error_log("Call Hit API: Raw input: " . $rawInput);
    
    $input = json_decode($rawInput, true);
    error_log("Call Hit API: Decoded input: " . json_encode($input));
    
    // Validate required fields - only use existing columns
    $user_id = $input['user_id'] ?? null;
    $call_time = $input['call_time'] ?? date('Y-m-d H:i:s');
    $assigned_to = $input['assigned_to'] ?? null;
    
    error_log("Call Hit API: user_id=$user_id, call_time=$call_time, assigned_to=$assigned_to");
    
    if (!$user_id) {
        throw new Exception('User ID is required');
    }
    
    // Insert into call_hit table with only existing columns
    $stmt = $pdo->prepare("
        INSERT INTO call_hit (
            user_id, 
            call_time, 
            assigned_to,
            created_at,
            updated_at
        ) VALUES (
            :user_id, 
            :call_time, 
            :assigned_to,
            NOW(),
            NOW()
        )
    ");
    
    $stmt->execute([
        ':user_id' => $user_id,
        ':call_time' => $call_time,
        ':assigned_to' => $assigned_to
    ]);
    
    $call_hit_id = $pdo->lastInsertId();
    
    error_log("Call Hit API: Successfully inserted call_hit_id=$call_hit_id");
    
    echo json_encode([
        'success' => true,
        'message' => 'Call hit logged successfully',
        'data' => [
            'call_hit_id' => $call_hit_id,
            'user_id' => $user_id,
            'call_time' => $call_time,
            'assigned_to' => $assigned_to
        ]
    ]);
    
} catch (Exception $e) {
    error_log("Call Hit API ERROR: " . $e->getMessage());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
