<?php
/**
 * Test Current User ID
 * Check what user ID is being used
 */

require_once 'config.php';

header('Content-Type: application/json');

// Simulate getting user from session or token
// In your actual app, this would come from the authentication

// For testing, let's check what's in the admins table
try {
    $query = "SELECT id, name, email, role, tc_for FROM admins ORDER BY id";
    $result = $conn->query($query);
    
    $users = [];
    while ($row = $result->fetch_assoc()) {
        $users[] = $row;
    }
    
    // Also check what caller_ids exist in call_logs_match_making
    $callLogsQuery = "SELECT DISTINCT caller_id FROM call_logs_match_making";
    $callLogsResult = $conn->query($callLogsQuery);
    
    $callerIds = [];
    while ($row = $callLogsResult->fetch_assoc()) {
        $callerIds[] = $row['caller_id'];
    }
    
    echo json_encode([
        'success' => true,
        'admins' => $users,
        'callerIdsInLogs' => $callerIds,
        'message' => 'Check which admin ID you are logged in with and compare with caller_ids in logs'
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}

$conn->close();
