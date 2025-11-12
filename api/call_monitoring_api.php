<?php
/**
 * Call Monitoring API
 * Get real-time call status, duration, recordings
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    // Set timezone to IST for correct NOW() and timestamp display
    $pdo->exec("SET time_zone = '+05:30'");
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Database connection failed']);
    exit;
}

$action = $_GET['action'] ?? 'get_call_history';

switch($action) {
    case 'get_call_status':
        getCallStatus($pdo);
        break;
    case 'get_call_history':
    case 'list': // Support both action names
    default:
        // Default to showing call history
        getCallHistory($pdo);
        break;
    case 'get_recording':
        getRecording($pdo);
        break;
    case 'get_active_calls':
        getActiveCalls($pdo);
        break;
}

/**
 * Get real-time call status by reference ID
 */
function getCallStatus($pdo) {
    $referenceId = $_GET['reference_id'] ?? '';
    
    if (empty($referenceId)) {
        echo json_encode(['success' => false, 'error' => 'Reference ID required']);
        return;
    }
    
    try {
        $sql = "SELECT 
                    cl.*,
                    u.name as driver_name,
                    u.mobile as driver_mobile,
                    a.name as telecaller_name,
                    a.mobile as telecaller_mobile,
                    TIMESTAMPDIFF(SECOND, cl.call_start_time, cl.call_end_time) as actual_duration
                FROM call_logs cl
                LEFT JOIN users u ON cl.user_id = u.id
                LEFT JOIN admins a ON cl.caller_id = a.id
                WHERE cl.reference_id = ?";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([$referenceId]);
        $call = $stmt->fetch();
        
        if (!$call) {
            echo json_encode(['success' => false, 'error' => 'Call not found']);
            return;
        }
        
        echo json_encode([
            'success' => true,
            'data' => [
                'reference_id' => $call['reference_id'],
                'myoperator_unique_id' => $call['myoperator_unique_id'],
                'call_status' => $call['call_status'],
                'call_duration' => $call['call_duration'],
                'call_start_time' => $call['call_start_time'],
                'call_end_time' => $call['call_end_time'],
                'recording_url' => $call['recording_url'],
                'driver_name' => $call['driver_name'],
                'driver_mobile' => $call['driver_mobile'],
                'telecaller_name' => $call['telecaller_name'],
                'telecaller_mobile' => $call['telecaller_mobile'],
                'feedback' => $call['feedback'],
                'remarks' => $call['remarks'],
                'has_feedback' => !empty($call['feedback']),
                'has_recording' => !empty($call['recording_url'])
            ]
        ]);
        
    } catch(Exception $e) {
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
}

/**
 * Get call history for a telecaller
 */
function getCallHistory($pdo) {
    $callerId = $_GET['caller_id'] ?? 0;
    $limit = $_GET['limit'] ?? 100;
    $offset = $_GET['offset'] ?? 0;
    // Support both 'filter' (from frontend) and 'date_range' parameters
    $dateRange = $_GET['filter'] ?? $_GET['date_range'] ?? 'today';
    $status = $_GET['status'] ?? '';
    $search = $_GET['search'] ?? '';
    
    try {
        $conditions = [];
        $params = [];
        
        // Caller filter - if 0, show all callers
        if ($callerId > 0) {
            $conditions[] = "cl.caller_id = ?";
            $params[] = $callerId;
        }
        
        // Date range filter
        if ($dateRange === 'today') {
            $conditions[] = "DATE(cl.created_at) = CURDATE()";
        } elseif ($dateRange === 'yesterday') {
            $conditions[] = "DATE(cl.created_at) = DATE_SUB(CURDATE(), INTERVAL 1 DAY)";
        } elseif ($dateRange === 'week') {
            $conditions[] = "cl.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)";
        } elseif ($dateRange === 'month') {
            $conditions[] = "cl.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)";
        }
        
        // Status filter
        if (!empty($status)) {
            $conditions[] = "cl.call_status = ?";
            $params[] = $status;
        }
        
        // Search filter
        if (!empty($search)) {
            $conditions[] = "(u.name LIKE ? OR u.mobile LIKE ? OR cl.reference_id LIKE ?)";
            $searchTerm = "%$search%";
            $params[] = $searchTerm;
            $params[] = $searchTerm;
            $params[] = $searchTerm;
        }
        
        $whereClause = !empty($conditions) ? 'WHERE ' . implode(' AND ', $conditions) : '';
        
        $sql = "SELECT 
                    cl.id,
                    cl.created_at as call_time,
                    cl.call_duration as duration,
                    cl.call_status as status,
                    cl.feedback,
                    u.name as driver_name,
                    u.mobile as phone,
                    a.name as telecaller_name
                FROM call_logs cl
                LEFT JOIN users u ON cl.user_id = u.id
                LEFT JOIN admins a ON cl.caller_id = a.id
                $whereClause
                ORDER BY cl.created_at DESC
                LIMIT ? OFFSET ?";
        
        $params[] = $limit;
        $params[] = $offset;
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $calls = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        // Calculate stats
        $statsConditions = $conditions;
        $statsParams = array_slice($params, 0, -2); // Remove limit and offset
        $statsWhereClause = !empty($statsConditions) ? 'WHERE ' . implode(' AND ', $statsConditions) : '';
        
        $statsSql = "SELECT 
                        COUNT(*) as total,
                        SUM(CASE WHEN cl.call_status = 'connected' THEN 1 ELSE 0 END) as connected,
                        AVG(CASE WHEN cl.call_duration > 0 THEN cl.call_duration ELSE NULL END) as avg_duration_seconds
                    FROM call_logs cl
                    LEFT JOIN users u ON cl.user_id = u.id
                    LEFT JOIN admins a ON cl.caller_id = a.id
                    $statsWhereClause";
        
        $statsStmt = $pdo->prepare($statsSql);
        $statsStmt->execute($statsParams);
        $stats = $statsStmt->fetch(PDO::FETCH_ASSOC);
        
        $avgDurationMinutes = $stats['avg_duration_seconds'] ? round($stats['avg_duration_seconds'] / 60, 1) : 0;
        $successRate = $stats['total'] > 0 ? round(($stats['connected'] / $stats['total']) * 100, 1) : 0;
        
        echo json_encode([
            'success' => true,
            'data' => [
                'calls' => $calls,
                'stats' => [
                    'total' => (int)$stats['total'],
                    'connected' => (int)$stats['connected'],
                    'avg_duration' => $avgDurationMinutes . 'm',
                    'success_rate' => $successRate
                ]
            ]
        ]);
        
    } catch(Exception $e) {
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
}

/**
 * Get recording URL for a call
 */
function getRecording($pdo) {
    $referenceId = $_GET['reference_id'] ?? '';
    
    if (empty($referenceId)) {
        echo json_encode(['success' => false, 'error' => 'Reference ID required']);
        return;
    }
    
    try {
        $stmt = $pdo->prepare("SELECT recording_url, call_duration FROM call_logs WHERE reference_id = ?");
        $stmt->execute([$referenceId]);
        $call = $stmt->fetch();
        
        if (!$call) {
            echo json_encode(['success' => false, 'error' => 'Call not found']);
            return;
        }
        
        if (empty($call['recording_url'])) {
            echo json_encode([
                'success' => false,
                'error' => 'Recording not available yet',
                'message' => 'Recording will be available within 5-10 minutes after call ends'
            ]);
            return;
        }
        
        echo json_encode([
            'success' => true,
            'data' => [
                'recording_url' => $call['recording_url'],
                'duration' => $call['call_duration']
            ]
        ]);
        
    } catch(Exception $e) {
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
}

/**
 * Get currently active calls
 */
function getActiveCalls($pdo) {
    try {
        $sql = "SELECT 
                    cl.*,
                    u.name as driver_name,
                    a.name as telecaller_name,
                    TIMESTAMPDIFF(SECOND, cl.call_start_time, NOW()) as current_duration
                FROM call_logs cl
                LEFT JOIN users u ON cl.user_id = u.id
                LEFT JOIN admins a ON cl.caller_id = a.id
                WHERE cl.call_status IN ('initiated', 'ringing', 'answered')
                AND cl.call_end_time IS NULL
                ORDER BY cl.call_start_time DESC";
        
        $stmt = $pdo->query($sql);
        $activeCalls = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'data' => $activeCalls,
            'count' => count($activeCalls)
        ]);
        
    } catch(Exception $e) {
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
}
?>
