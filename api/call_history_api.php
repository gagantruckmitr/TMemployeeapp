<?php
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'config.php';

// Get action from query parameter
$action = $_GET['action'] ?? '';

try {
    switch ($action) {
        case 'call_history':
            getCallHistory($conn);
            break;
        default:
            echo json_encode([
                'success' => false,
                'error' => 'Invalid action'
            ]);
    }
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}

function getCallHistory($conn) {
    $callerId = $_GET['caller_id'] ?? null;
    $status = $_GET['status'] ?? null;
    $limit = $_GET['limit'] ?? 100;
    $offset = $_GET['offset'] ?? 0;
    
    if (!$callerId) {
        echo json_encode([
            'success' => false,
            'error' => 'Caller ID is required'
        ]);
        return;
    }
    
    // Build query - using users table instead of drivers with proper timing
    $query = "
        SELECT 
            cl.id,
            cl.user_id as driver_id,
            u.name as driver_name,
            u.mobile as phone_number,
            cl.call_status as status,
            cl.feedback,
            cl.remarks,
            cl.call_duration as duration,
            COALESCE(cl.call_initiated_at, cl.call_time, cl.Created_at) as call_time,
            cl.call_initiated_at,
            cl.call_completed_at,
            TIMESTAMPDIFF(SECOND, COALESCE(cl.call_initiated_at, cl.call_time, cl.Created_at), NOW()) as seconds_ago,
            CASE 
                WHEN TIMESTAMPDIFF(SECOND, COALESCE(cl.call_initiated_at, cl.call_time, cl.Created_at), NOW()) < 60 THEN 'Just now'
                WHEN TIMESTAMPDIFF(SECOND, COALESCE(cl.call_initiated_at, cl.call_time, cl.Created_at), NOW()) < 3600 THEN CONCAT(FLOOR(TIMESTAMPDIFF(SECOND, COALESCE(cl.call_initiated_at, cl.call_time, cl.Created_at), NOW()) / 60), 'm ago')
                WHEN TIMESTAMPDIFF(SECOND, COALESCE(cl.call_initiated_at, cl.call_time, cl.Created_at), NOW()) < 86400 THEN CONCAT(FLOOR(TIMESTAMPDIFF(SECOND, COALESCE(cl.call_initiated_at, cl.call_time, cl.Created_at), NOW()) / 3600), 'h ago')
                ELSE CONCAT(FLOOR(TIMESTAMPDIFF(SECOND, COALESCE(cl.call_initiated_at, cl.call_time, cl.Created_at), NOW()) / 86400), 'd ago')
            END as time_ago,
            CONCAT(FLOOR(COALESCE(cl.call_duration, 0) / 60), ':', LPAD(COALESCE(cl.call_duration, 0) % 60, 2, '0')) as duration_formatted
        FROM call_logs cl
        INNER JOIN users u ON cl.user_id = u.id
        WHERE cl.caller_id = ?
    ";
    
    $params = [$callerId];
    $types = 'i';
    
    // Add status filter if provided
    if ($status && $status !== 'all') {
        $query .= " AND cl.call_status = ?";
        $params[] = $status;
        $types .= 's';
    }
    
    // Order by most recent first using actual call time
    $query .= " ORDER BY COALESCE(cl.call_initiated_at, cl.call_time, cl.Created_at) DESC LIMIT ? OFFSET ?";
    $params[] = (int)$limit;
    $params[] = (int)$offset;
    $types .= 'ii';
    
    $stmt = $conn->prepare($query);
    if (!$stmt) {
        echo json_encode([
            'success' => false,
            'error' => 'Failed to prepare statement: ' . $conn->error
        ]);
        return;
    }
    
    $stmt->bind_param($types, ...$params);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $history = [];
    while ($row = $result->fetch_assoc()) {
        $history[] = [
            'id' => $row['id'],
            'driver_id' => $row['driver_id'],
            'driver_name' => $row['driver_name'] ?? 'Unknown',
            'phone_number' => $row['phone_number'] ?? '',
            'status' => $row['status'],
            'feedback' => $row['feedback'],
            'remarks' => $row['remarks'],
            'duration' => (int)($row['duration'] ?? 0),
            'duration_formatted' => $row['duration_formatted'] ?? '0:00',
            'call_time' => $row['call_time'],
            'call_initiated_at' => $row['call_initiated_at'],
            'call_completed_at' => $row['call_completed_at'],
            'time_ago' => $row['time_ago'] ?? 'Unknown',
            'seconds_ago' => (int)($row['seconds_ago'] ?? 0)
        ];
    }
    
    echo json_encode([
        'success' => true,
        'data' => $history,
        'count' => count($history)
    ]);
}

$conn->close();
?>
