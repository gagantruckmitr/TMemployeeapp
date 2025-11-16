<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'config.php';

// Only allow GET requests
if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit;
}

try {
    $user_id = $_GET['user_id'] ?? null;
    $telecaller_id = $_GET['telecaller_id'] ?? null;
    $period = $_GET['period'] ?? 'all'; // 'today', 'week', 'month', 'all'
    
    // Support both user_id (driver) and telecaller_id (assigned_to) filters
    // If telecaller_id is provided, use it (for telecaller stats)
    // Otherwise use user_id (for driver stats)
    if ($telecaller_id) {
        $where = ['assigned_to = :telecaller_id'];
        $params = [':telecaller_id' => $telecaller_id];
    } elseif ($user_id) {
        $where = ['user_id = :user_id'];
        $params = [':user_id' => $user_id];
    } else {
        throw new Exception('Either user_id or telecaller_id is required');
    }
    
    // Add period filter
    switch ($period) {
        case 'today':
            $where[] = 'DATE(call_time) = CURDATE()';
            break;
        case 'week':
            $where[] = 'call_time >= DATE_SUB(NOW(), INTERVAL 7 DAY)';
            break;
        case 'month':
            $where[] = 'call_time >= DATE_SUB(NOW(), INTERVAL 30 DAY)';
            break;
    }
    
    $whereClause = implode(' AND ', $where);
    
    // Get total call hits
    $stmt = $pdo->prepare("
        SELECT COUNT(*) as total_calls
        FROM call_hit
        WHERE $whereClause
    ");
    $stmt->execute($params);
    $totalCalls = $stmt->fetch(PDO::FETCH_ASSOC)['total_calls'];
    
    // Get calls by date
    $stmt = $pdo->prepare("
        SELECT 
            DATE(call_time) as call_date,
            COUNT(*) as count
        FROM call_hit
        WHERE $whereClause
        GROUP BY DATE(call_time)
        ORDER BY call_date DESC
    ");
    $stmt->execute($params);
    $callsByDate = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get recent call hits (only existing columns)
    $stmt = $pdo->prepare("
        SELECT 
            id,
            user_id,
            call_time,
            assigned_to,
            created_at,
            updated_at
        FROM call_hit
        WHERE $whereClause
        ORDER BY created_at DESC
        LIMIT 50
    ");
    $stmt->execute($params);
    $recentCalls = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'success' => true,
        'data' => [
            'total_calls' => (int)$totalCalls,
            'calls_by_date' => $callsByDate,
            'recent_calls' => $recentCalls,
            'period' => $period
        ]
    ]);
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
