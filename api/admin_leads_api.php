<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Helper function to calculate engagement score
function calculateEngagementScore($totalCalls, $connectedCalls, $status) {
    $score = 0;
    
    // Base score from call attempts
    $score += min($totalCalls * 10, 50);
    
    // Bonus for connected calls
    $score += $connectedCalls * 15;
    
    // Status-based scoring
    $statusScores = [
        'interested' => 30,
        'callback' => 20,
        'connected' => 25,
        'fresh' => 10,
        'no_response' => 5,
        'not_interested' => 0
    ];
    
    $score += $statusScores[$status] ?? 0;
    
    return min($score, 100);
}

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $conn = new mysqli($host, $username, $password, $dbname);
    
    if ($conn->connect_error) {
        throw new Exception("Connection failed: " . $conn->connect_error);
    }
    
    $status = $_GET['status'] ?? 'all';
    $days = isset($_GET['days']) ? (int)$_GET['days'] : null; // null = show all, or specify days
    
    // Get drivers (leads) from users table registered in last 5 days with their call statistics
    $query = "SELECT 
        u.id,
        u.unique_id,
        u.name as driver_name,
        u.mobile as phone,
        u.email,
        u.city,
        u.states,
        u.status as user_status,
        u.assigned_to as assigned_to_id,
        u.Created_at,
        u.Updated_at,
        a.name as assigned_to,
        a.email as assigned_to_email,
        COALESCE(cl.total_calls, 0) as total_calls,
        COALESCE(cl.connected_calls, 0) as connected_calls,
        COALESCE(cl.interested_calls, 0) as interested_calls,
        COALESCE(cl.callback_calls, 0) as callback_calls,
        COALESCE(cl.not_interested_calls, 0) as not_interested_calls,
        COALESCE(cl.no_response_calls, 0) as no_response_calls,
        COALESCE(cl.avg_call_duration, 0) as avg_call_duration,
        cl.last_call_time,
        cl.last_call_status,
        cl.first_call_time
    FROM users u
    LEFT JOIN admins a ON u.assigned_to = a.id AND a.role = 'telecaller'
    LEFT JOIN (
        SELECT 
            user_id,
            COUNT(*) as total_calls,
            SUM(CASE WHEN call_status = 'connected' THEN 1 ELSE 0 END) as connected_calls,
            SUM(CASE WHEN call_status LIKE '%interest%' THEN 1 ELSE 0 END) as interested_calls,
            SUM(CASE WHEN call_status LIKE '%callback%' THEN 1 ELSE 0 END) as callback_calls,
            SUM(CASE WHEN call_status = 'not_interested' THEN 1 ELSE 0 END) as not_interested_calls,
            SUM(CASE WHEN call_status IN ('not_reachable', 'invalid') THEN 1 ELSE 0 END) as no_response_calls,
            AVG(CASE WHEN call_duration IS NOT NULL AND call_duration > 0 THEN call_duration ELSE 0 END) as avg_call_duration,
            MAX(call_time) as last_call_time,
            MIN(call_time) as first_call_time,
            (SELECT call_status FROM call_logs WHERE user_id = cl2.user_id ORDER BY call_time DESC LIMIT 1) as last_call_status
        FROM call_logs cl2
        GROUP BY user_id
    ) cl ON u.id = cl.user_id
    WHERE u.role = 'driver'";
    
    // Apply date filter only if days parameter is provided
    if ($days !== null && $days > 0) {
        $query .= " AND u.Created_at >= DATE_SUB(NOW(), INTERVAL $days DAY)";
    }
    
    // Apply status filter
    if ($status !== 'all') {
        if ($status === 'fresh') {
            // Fresh leads = no calls yet
            $query .= " AND cl.total_calls IS NULL";
        } else {
            // Filter by last call status
            $query .= " AND cl.last_call_status = '" . $conn->real_escape_string($status) . "'";
        }
    }
    
    
    $query .= " ORDER BY u.Created_at DESC LIMIT 1000";
    
    $result = $conn->query($query);
    
    if (!$result) {
        throw new Exception("Query failed: " . $conn->error);
    }
    
    $leads = [];
    
    while ($row = $result->fetch_assoc()) {
        $totalCalls = (int)$row['total_calls'];
        $connectedCalls = (int)$row['connected_calls'];
        $successRate = $totalCalls > 0 ? round(($connectedCalls / $totalCalls) * 100, 2) : 0;
        
        // Determine lead status
        $leadStatus = 'fresh';
        if ($row['last_call_status']) {
            $leadStatus = $row['last_call_status'];
        } elseif ($totalCalls > 0) {
            $leadStatus = 'pending';
        }
        
        $tmid = $row['unique_id'] ?: 'TM' . str_pad($row['id'], 6, '0', STR_PAD_LEFT);
        
        $leads[] = [
            'id' => (int)$row['id'],
            'tmid' => $tmid,
            'driver_name' => $row['driver_name'] ?: 'Unknown Driver',
            'phone' => $row['phone'] ?: 'N/A',
            'email' => $row['email'] ?: 'N/A',
            'location' => $row['city'] ? $row['city'] . ', ' . $row['states'] : 'N/A',
            'city' => $row['city'] ?: 'N/A',
            'state' => $row['states'] ?: 'N/A',
            'status' => $leadStatus,
            'user_status' => $row['user_status'] ?: 'inactive',
            'assigned_to' => $row['assigned_to'] ?: 'Unassigned',
            'assigned_to_id' => (int)$row['assigned_to_id'],
            'assigned_to_email' => $row['assigned_to_email'] ?: null,
            'last_contact' => $row['last_call_time'] ? date('M d, Y H:i', strtotime($row['last_call_time'])) : 'Never',
            'last_contact_raw' => $row['last_call_time'],
            'first_contact' => $row['first_call_time'] ? date('M d, Y H:i', strtotime($row['first_call_time'])) : null,
            'first_contact_raw' => $row['first_call_time'],
            'registration_date' => $row['Created_at'] ? date('M d, Y', strtotime($row['Created_at'])) : 'N/A',
            'registration_date_raw' => $row['Created_at'],
            'total_calls' => $totalCalls,
            'connected_calls' => $connectedCalls,
            'interested_calls' => (int)$row['interested_calls'],
            'callback_calls' => (int)$row['callback_calls'],
            'not_interested_calls' => (int)$row['not_interested_calls'],
            'no_response_calls' => (int)$row['no_response_calls'],
            'avg_call_duration' => round((float)$row['avg_call_duration'], 2),
            'success_rate' => $successRate,
            'engagement_score' => calculateEngagementScore($totalCalls, $connectedCalls, $leadStatus)
        ];
    }
    
    // Calculate summary statistics
    $summary = [
        'total_leads' => count($leads),
        'total_calls' => array_sum(array_column($leads, 'total_calls')),
        'total_connected' => array_sum(array_column($leads, 'connected_calls')),
        'by_status' => [
            'fresh' => count(array_filter($leads, fn($l) => $l['status'] === 'fresh')),
            'interested' => count(array_filter($leads, fn($l) => strpos($l['status'], 'interest') !== false)),
            'callback' => count(array_filter($leads, fn($l) => strpos($l['status'], 'callback') !== false)),
            'not_interested' => count(array_filter($leads, fn($l) => $l['status'] === 'not_interested')),
            'no_response' => count(array_filter($leads, fn($l) => in_array($l['status'], ['not_reachable', 'invalid']))),
            'connected' => count(array_filter($leads, fn($l) => $l['status'] === 'connected')),
        ],
        'assigned' => count(array_filter($leads, fn($l) => $l['assigned_to'] !== 'Unassigned')),
        'unassigned' => count(array_filter($leads, fn($l) => $l['assigned_to'] === 'Unassigned')),
    ];
    
    echo json_encode([
        'success' => true,
        'data' => $leads,
        'total' => count($leads),
        'summary' => $summary,
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    
    $conn->close();
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage(),
        'timestamp' => date('Y-m-d H:i:s')
    ]);
}
?>
