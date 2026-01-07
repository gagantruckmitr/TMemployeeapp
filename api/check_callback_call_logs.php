<?php
/**
 * Check call_logs data for callback requests
 */
header('Content-Type: application/json');
require_once 'config.php';

try {
    $conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
    
    // Check call_logs with call_source = 'callback_requests'
    $sql = "SELECT 
                cl.*,
                u.unique_id,
                u.name as user_name
            FROM call_logs cl
            LEFT JOIN users u ON cl.user_id = u.id
            WHERE cl.call_source = 'callback_requests'
            ORDER BY cl.created_at DESC
            LIMIT 10";
    
    $result = $conn->query($sql);
    $logs = [];
    
    while ($row = $result->fetch_assoc()) {
        $logs[] = $row;
    }
    
    echo json_encode([
        'success' => true,
        'count' => count($logs),
        'logs' => $logs
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
