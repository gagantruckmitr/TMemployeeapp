<?php
// Get Called Leads API - Returns IDs of leads that have been called with feedback
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Database connection failed']);
    exit;
}

try {
    $callerId = (int)($_GET['caller_id'] ?? 0);
    
    if (!$callerId) {
        throw new Exception('caller_id parameter required');
    }
    
    // Get all user_ids that have been called by this telecaller
    // Only include leads where feedback has been submitted (not just initiated)
    $sql = "SELECT DISTINCT user_id 
            FROM call_logs 
            WHERE caller_id = :caller_id 
            AND user_id IS NOT NULL 
            AND user_id > 0
            AND feedback IS NOT NULL
            AND feedback != ''
            ORDER BY user_id";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute(['caller_id' => $callerId]);
    $results = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    // Convert to integers
    $calledLeadIds = array_map('intval', $results);
    
    echo json_encode([
        'success' => true,
        'caller_id' => $callerId,
        'called_lead_ids' => $calledLeadIds,
        'count' => count($calledLeadIds)
    ]);
    
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
