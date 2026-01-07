<?php
header('Content-Type: application/json');

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
        case 'update_feedback':
            updateCallFeedback($conn);
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
    $feedback = $_GET['feedback'] ?? null;
    $remarks = $_GET['remarks'] ?? null;
    $search = $_GET['search'] ?? null;
    $dateFrom = $_GET['date_from'] ?? null;
    $dateTo = $_GET['date_to'] ?? null;
    $limit = $_GET['limit'] ?? 1000;
    $offset = $_GET['offset'] ?? 0;
    
    if (!$callerId) {
        echo json_encode([
            'success' => false,
            'error' => 'Caller ID is required'
        ]);
        return;
    }
    
    // Build query - using LEFT JOIN to include toll-free and other calls without user_id
    $query = "
        SELECT 
            cl.id,
            cl.user_id as driver_id,
            COALESCE(u.unique_id, '') as tmid,
            COALESCE(cl.driver_name, u.name, 'Unknown') as driver_name,
            COALESCE(cl.user_number, u.mobile, '') as phone_number,
            cl.call_status as status,
            cl.feedback,
            cl.remarks,
            cl.call_duration as duration,
            cl.recording_url,
            cl.manual_call_recording_url,
            cl.tc_for,
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
        LEFT JOIN users u ON cl.user_id = u.id
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

    // Add feedback filter if provided
    if ($feedback && $feedback !== 'all') {
        $query .= " AND cl.feedback = ?";
        $params[] = $feedback;
        $types .= 's';
    }

    // Add remarks filter if provided
    if ($remarks && $remarks !== 'all') {
        if ($remarks === 'has_remarks') {
            $query .= " AND cl.remarks IS NOT NULL AND cl.remarks != ''";
        } elseif ($remarks === 'no_remarks') {
            $query .= " AND (cl.remarks IS NULL OR cl.remarks = '')";
        }
    }

    // Add date range filter if provided
    if ($dateFrom) {
        $query .= " AND DATE(COALESCE(cl.call_initiated_at, cl.call_time, cl.Created_at)) >= ?";
        $params[] = $dateFrom;
        $types .= 's';
    }
    
    if ($dateTo) {
        $query .= " AND DATE(COALESCE(cl.call_initiated_at, cl.call_time, cl.Created_at)) <= ?";
        $params[] = $dateTo;
        $types .= 's';
    }

    // Add search filter if provided - include call_logs fields for toll-free calls
    if ($search) {
        $query .= " AND (COALESCE(cl.driver_name, u.name) LIKE ? OR COALESCE(cl.user_number, u.mobile) LIKE ? OR u.unique_id LIKE ?)";
        $searchTerm = "%$search%";
        $params[] = $searchTerm;
        $params[] = $searchTerm;
        $params[] = $searchTerm;
        $types .= 'sss';
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
            'tmid' => $row['tmid'] ?? '',
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
            'seconds_ago' => (int)($row['seconds_ago'] ?? 0),
            'recording_url' => $row['recording_url'],
            'manual_call_recording_url' => $row['manual_call_recording_url'],
            'tc_for' => $row['tc_for'] ?? null
        ];
    }

    // Get total count for pagination/display - use LEFT JOIN to include all calls
    $countQuery = "
        SELECT COUNT(*) as total
        FROM call_logs cl
        LEFT JOIN users u ON cl.user_id = u.id
        WHERE cl.caller_id = ?
    ";
    
    $countParams = [$callerId];
    $countTypes = 'i';
    
    if ($status && $status !== 'all') {
        $countQuery .= " AND cl.call_status = ?";
        $countParams[] = $status;
        $countTypes .= 's';
    }

    if ($feedback && $feedback !== 'all') {
        $countQuery .= " AND cl.feedback = ?";
        $countParams[] = $feedback;
        $countTypes .= 's';
    }

    if ($remarks && $remarks !== 'all') {
        if ($remarks === 'has_remarks') {
            $countQuery .= " AND cl.remarks IS NOT NULL AND cl.remarks != ''";
        } elseif ($remarks === 'no_remarks') {
            $countQuery .= " AND (cl.remarks IS NULL OR cl.remarks = '')";
        }
    }

    // Add date range filter to count query
    if ($dateFrom) {
        $countQuery .= " AND DATE(COALESCE(cl.call_initiated_at, cl.call_time, cl.Created_at)) >= ?";
        $countParams[] = $dateFrom;
        $countTypes .= 's';
    }
    
    if ($dateTo) {
        $countQuery .= " AND DATE(COALESCE(cl.call_initiated_at, cl.call_time, cl.Created_at)) <= ?";
        $countParams[] = $dateTo;
        $countTypes .= 's';
    }

    if ($search) {
        $countQuery .= " AND (u.name LIKE ? OR u.mobile LIKE ? OR u.unique_id LIKE ?)";
        $searchTerm = "%$search%";
        $countParams[] = $searchTerm;
        $countParams[] = $searchTerm;
        $countParams[] = $searchTerm;
        $countTypes .= 'sss';
    }
    
    $stmtCount = $conn->prepare($countQuery);
    $stmtCount->bind_param($countTypes, ...$countParams);
    $stmtCount->execute();
    $totalRecords = $stmtCount->get_result()->fetch_assoc()['total'];
    
    echo json_encode([
        'success' => true,
        'data' => $history,
        'count' => count($history),
        'total_records' => $totalRecords
    ]);
}

function updateCallFeedback($conn) {
    // Get POST data
    $input = json_decode(file_get_contents('php://input'), true);
    
    $callLogId = $input['call_log_id'] ?? null;
    $callStatus = $input['call_status'] ?? null;
    $feedback = $input['feedback'] ?? null;
    $remarks = $input['remarks'] ?? null;
    
    if (!$callLogId) {
        echo json_encode([
            'success' => false,
            'error' => 'Call log ID is required'
        ]);
        return;
    }
    
    // Build update query
    $updates = [];
    $params = [];
    $types = '';
    
    if ($callStatus !== null) {
        $updates[] = "call_status = ?";
        $params[] = $callStatus;
        $types .= 's';
    }
    
    if ($feedback !== null) {
        $updates[] = "feedback = ?";
        $params[] = $feedback;
        $types .= 's';
    }
    
    if ($remarks !== null) {
        $updates[] = "remarks = ?";
        $params[] = $remarks;
        $types .= 's';
    }
    
    if (empty($updates)) {
        echo json_encode([
            'success' => false,
            'error' => 'No fields to update'
        ]);
        return;
    }
    
    // Add updated_at timestamp
    $updates[] = "updated_at = NOW()";
    
    // Add call_log_id to params
    $params[] = $callLogId;
    $types .= 'i';
    
    $query = "UPDATE call_logs SET " . implode(', ', $updates) . " WHERE id = ?";
    
    $stmt = $conn->prepare($query);
    if (!$stmt) {
        echo json_encode([
            'success' => false,
            'error' => 'Failed to prepare statement: ' . $conn->error
        ]);
        return;
    }
    
    $stmt->bind_param($types, ...$params);
    
    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Feedback updated successfully'
        ]);
    } else {
        echo json_encode([
            'success' => false,
            'error' => 'Failed to update feedback: ' . $stmt->error
        ]);
    }
}

$conn->close();
?>


