<?php
// Telecaller Dashboard Stats API
// Returns stats for a specific telecaller including pending leads
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET');

require_once 'config.php';
require_once 'update_activity_middleware.php';

$callerId = (int)($_GET['caller_id'] ?? 1);

try {
    // 1. Get total assigned leads (users assigned to this telecaller)
    $stmt = $pdo->prepare("
        SELECT COUNT(*) as total_assigned
        FROM users 
        WHERE assigned_to = ? 
        AND role IN ('driver', 'transporter')
    ");
    $stmt->execute([$callerId]);
    $assignedData = $stmt->fetch();
    $totalAssigned = (int)$assignedData['total_assigned'];
    
    // 2. Get call logs stats for this telecaller
    $stmt = $pdo->prepare("
        SELECT 
            COUNT(*) as total_calls,
            COUNT(CASE WHEN call_status = 'connected' THEN 1 END) as connected_calls,
            COUNT(CASE WHEN call_status IN ('callback', 'callback_later') THEN 1 END) as callbacks_scheduled,
            COUNT(CASE WHEN feedback = 'interested' THEN 1 END) as interested_count
        FROM call_logs 
        WHERE caller_id = ?
    ");
    $stmt->execute([$callerId]);
    $callStats = $stmt->fetch();
    
    $totalCalls = (int)$callStats['total_calls'];
    $connectedCalls = (int)$callStats['connected_calls'];
    $callbacksScheduled = (int)$callStats['callbacks_scheduled'];
    $interestedCount = (int)$callStats['interested_count'];
    
    // 3. Get unique users who have been called by THIS telecaller
    $stmt = $pdo->prepare("
        SELECT COUNT(DISTINCT user_id) as called_users
        FROM call_logs 
        WHERE caller_id = ?
        AND user_id IS NOT NULL
    ");
    $stmt->execute([$callerId]);
    $calledData = $stmt->fetch();
    $calledUsers = (int)$calledData['called_users'];
    
    // 4. Calculate fresh leads (assigned but not called yet)
    // This should match the fresh_leads_api.php count exactly
    $stmt = $pdo->prepare("
        SELECT COUNT(*) as fresh_count
        FROM users u
        WHERE u.role IN ('driver', 'transporter')
        AND u.assigned_to = ?
        AND u.id NOT IN (
            SELECT DISTINCT user_id 
            FROM call_logs
            WHERE caller_id = ?
            AND user_id IS NOT NULL
        )
    ");
    $stmt->execute([$callerId, $callerId]);
    $freshData = $stmt->fetch();
    $freshLeads = (int)$freshData['fresh_count'];
    
    // Pending calls = Fresh leads (not called yet)
    $pendingCalls = $freshLeads;
    
    // 5. Get today's stats
    $stmt = $pdo->prepare("
        SELECT 
            COUNT(*) as calls_today,
            COUNT(CASE WHEN call_status = 'connected' THEN 1 END) as connected_today
        FROM call_logs 
        WHERE caller_id = ?
        AND DATE(call_time) = CURDATE()
    ");
    $stmt->execute([$callerId]);
    $todayStats = $stmt->fetch();
    
    // 6. Calculate success rate
    $successRate = $totalCalls > 0 ? round(($connectedCalls / $totalCalls) * 100, 1) : 0;
    
    echo json_encode([
        'success' => true,
        'data' => [
            'total_calls' => $totalCalls,
            'connected_calls' => $connectedCalls,
            'pending_calls' => $pendingCalls, // Leads not called yet (same as fresh leads)
            'fresh_leads' => $freshLeads, // Uncalled leads
            'callbacks_scheduled' => $callbacksScheduled,
            'interested_count' => $interestedCount,
            'calls_today' => (int)$todayStats['calls_today'],
            'connected_today' => (int)$todayStats['connected_today'],
            'success_rate' => $successRate,
            'total_assigned' => $totalAssigned,
            'called_users' => $calledUsers,
        ],
        'caller_id' => $callerId,
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    
} catch(Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Failed to fetch dashboard stats: ' . $e->getMessage(),
        'file' => $e->getFile(),
        'line' => $e->getLine()
    ]);
}
?>
