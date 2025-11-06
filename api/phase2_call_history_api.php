<?php
/**
 * Phase 2 Call History API with CRUD operations
 * Supports filtering by date range, feedback type, and search
 */

require_once 'config.php';

header('Content-Type: application/json');

if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    if (isset($_GET['action'])) {
        $action = $_GET['action'];
        if ($action === 'list') {
            getCallHistory();
        } elseif ($action === 'stats_by_period') {
            getStatsByPeriod();
        } elseif ($action === 'detail') {
            getCallDetail();
        } else {
            sendError('Invalid action', 400);
        }
    } else {
        getCallHistory();
    }
} elseif ($_SERVER['REQUEST_METHOD'] === 'PUT' || $_SERVER['REQUEST_METHOD'] === 'POST') {
    updateCallLog();
} elseif ($_SERVER['REQUEST_METHOD'] === 'DELETE') {
    deleteCallLog();
} else {
    sendError('Method not allowed', 405);
}

function getCallHistory() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    $callerId = isset($_GET['caller_id']) ? (int)$_GET['caller_id'] : 0;
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 50;
    $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
    $period = isset($_GET['period']) ? $_GET['period'] : 'all'; // all, today, week, month
    $feedbackFilter = isset($_GET['feedback']) ? $_GET['feedback'] : '';
    $search = isset($_GET['search']) ? $conn->real_escape_string($_GET['search']) : '';
    
    // Build WHERE clause
    $conditions = [];
    if ($callerId > 0) {
        $conditions[] = "clm.caller_id = $callerId";
    }
    
    // Date filtering
    if ($period === 'today') {
        $conditions[] = "DATE(clm.created_at) = CURDATE()";
    } elseif ($period === 'week') {
        $conditions[] = "clm.created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)";
    } elseif ($period === 'month') {
        $conditions[] = "clm.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)";
    }
    
    // Feedback filtering
    if (!empty($feedbackFilter)) {
        $conditions[] = "clm.feedback = '$feedbackFilter'";
    }
    
    // Search filtering
    if (!empty($search)) {
        $conditions[] = "(clm.driver_name LIKE '%$search%' OR clm.transporter_name LIKE '%$search%' OR clm.unique_id_driver LIKE '%$search%' OR clm.unique_id_transporter LIKE '%$search%')";
    }
    
    $whereClause = !empty($conditions) ? 'WHERE ' . implode(' AND ', $conditions) : '';
    
    try {
        // Get total count
        $countQuery = "SELECT COUNT(*) as total FROM call_logs_match_making clm $whereClause";
        $countResult = $conn->query($countQuery);
        $total = $countResult->fetch_assoc()['total'];
        
        // Get paginated data
        $query = "SELECT 
            clm.*,
            a.name as caller_name
        FROM call_logs_match_making clm
        LEFT JOIN admins a ON clm.caller_id = a.id
        $whereClause
        ORDER BY clm.created_at DESC
        LIMIT $limit OFFSET $offset";
        
        $result = $conn->query($query);
        
        if (!$result) {
            sendError('Query failed: ' . $conn->error, 500);
        }
        
        $logs = [];
        while ($row = $result->fetch_assoc()) {
            $logs[] = [
                'id' => (int)$row['id'],
                'callerId' => (int)$row['caller_id'],
                'callerName' => $row['caller_name'] ?? 'Unknown',
                'uniqueIdTransporter' => $row['unique_id_transporter'] ?? '',
                'uniqueIdDriver' => $row['unique_id_driver'] ?? '',
                'driverName' => $row['driver_name'] ?? '',
                'transporterName' => $row['transporter_name'] ?? '',
                'feedback' => $row['feedback'] ?? '',
                'matchStatus' => $row['match_status'] ?? '',
                'remark' => $row['remark'] ?? '',
                'jobId' => $row['job_id'] ?? '',
                'callRecording' => $row['call_recording'] ?? '',
                'createdAt' => $row['created_at'],
                'updatedAt' => $row['updated_at'],
            ];
        }
        
        sendSuccess([
            'logs' => $logs,
            'total' => (int)$total,
            'limit' => $limit,
            'offset' => $offset,
        ], 'Call history fetched successfully');
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}

function getStatsByPeriod() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    $callerId = isset($_GET['caller_id']) ? (int)$_GET['caller_id'] : 0;
    $period = isset($_GET['period']) ? $_GET['period'] : 'week'; // today, week, month
    
    $whereClause = $callerId > 0 ? "WHERE caller_id = $callerId" : "";
    
    // Date condition
    $dateCondition = "";
    if ($period === 'today') {
        $dateCondition = "AND DATE(created_at) = CURDATE()";
    } elseif ($period === 'week') {
        $dateCondition = "AND created_at >= DATE_SUB(NOW(), INTERVAL 7 DAY)";
    } elseif ($period === 'month') {
        $dateCondition = "AND created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)";
    }
    
    if (!empty($whereClause)) {
        $whereClause .= " $dateCondition";
    } else {
        $whereClause = "WHERE 1=1 $dateCondition";
    }
    
    try {
        $stats = [];
        
        // Total calls
        $totalQuery = "SELECT COUNT(*) as count FROM call_logs_match_making $whereClause";
        $stats['totalCalls'] = (int)$conn->query($totalQuery)->fetch_assoc()['count'];
        
        // By feedback type
        $feedbackQuery = "SELECT feedback, COUNT(*) as count FROM call_logs_match_making $whereClause GROUP BY feedback";
        $feedbackResult = $conn->query($feedbackQuery);
        $feedbackStats = [];
        while ($row = $feedbackResult->fetch_assoc()) {
            $feedbackStats[$row['feedback']] = (int)$row['count'];
        }
        $stats['byFeedback'] = $feedbackStats;
        
        // By date (last 7 days or 30 days)
        $days = $period === 'month' ? 30 : 7;
        $dateQuery = "SELECT DATE(created_at) as date, COUNT(*) as count 
                      FROM call_logs_match_making $whereClause 
                      GROUP BY DATE(created_at) 
                      ORDER BY date DESC 
                      LIMIT $days";
        $dateResult = $conn->query($dateQuery);
        $dateStats = [];
        while ($row = $dateResult->fetch_assoc()) {
            $dateStats[] = [
                'date' => $row['date'],
                'count' => (int)$row['count']
            ];
        }
        $stats['byDate'] = $dateStats;
        
        sendSuccess($stats, 'Period stats fetched successfully');
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}

function getCallDetail() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    
    if ($id === 0) {
        sendError('Call log ID is required', 400);
    }
    
    try {
        $query = "SELECT clm.*, a.name as caller_name 
                  FROM call_logs_match_making clm
                  LEFT JOIN admins a ON clm.caller_id = a.id
                  WHERE clm.id = $id LIMIT 1";
        
        $result = $conn->query($query);
        
        if (!$result || $result->num_rows === 0) {
            sendError('Call log not found', 404);
        }
        
        $row = $result->fetch_assoc();
        $detail = [
            'id' => (int)$row['id'],
            'callerId' => (int)$row['caller_id'],
            'callerName' => $row['caller_name'] ?? 'Unknown',
            'uniqueIdTransporter' => $row['unique_id_transporter'] ?? '',
            'uniqueIdDriver' => $row['unique_id_driver'] ?? '',
            'driverName' => $row['driver_name'] ?? '',
            'transporterName' => $row['transporter_name'] ?? '',
            'feedback' => $row['feedback'] ?? '',
            'matchStatus' => $row['match_status'] ?? '',
            'remark' => $row['remark'] ?? '',
            'jobId' => $row['job_id'] ?? '',
            'callRecording' => $row['call_recording'] ?? '',
            'createdAt' => $row['created_at'],
            'updatedAt' => $row['updated_at'],
        ];
        
        sendSuccess($detail, 'Call detail fetched successfully');
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}

function updateCallLog() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    $data = json_decode(file_get_contents('php://input'), true);
    
    if (!$data || !isset($data['id'])) {
        sendError('Invalid data or missing ID', 400);
    }
    
    $id = (int)$data['id'];
    $feedback = isset($data['feedback']) ? $conn->real_escape_string($data['feedback']) : null;
    $matchStatus = isset($data['matchStatus']) ? $conn->real_escape_string($data['matchStatus']) : null;
    $remark = isset($data['remark']) ? $conn->real_escape_string($data['remark']) : null;
    
    try {
        $updates = [];
        if ($feedback !== null) $updates[] = "feedback = '$feedback'";
        if ($matchStatus !== null) $updates[] = "match_status = '$matchStatus'";
        if ($remark !== null) $updates[] = "remark = '$remark'";
        $updates[] = "updated_at = NOW()";
        
        $updateStr = implode(', ', $updates);
        $query = "UPDATE call_logs_match_making SET $updateStr WHERE id = $id";
        
        if ($conn->query($query)) {
            sendSuccess(['id' => $id], 'Call log updated successfully');
        } else {
            sendError('Failed to update: ' . $conn->error, 500);
        }
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}

function deleteCallLog() {
    global $conn;
    
    if (!$conn) {
        sendError('Database connection not available', 500);
    }
    
    $id = isset($_GET['id']) ? (int)$_GET['id'] : 0;
    
    if ($id === 0) {
        sendError('Call log ID is required', 400);
    }
    
    try {
        $query = "DELETE FROM call_logs_match_making WHERE id = $id";
        
        if ($conn->query($query)) {
            sendSuccess(['id' => $id], 'Call log deleted successfully');
        } else {
            sendError('Failed to delete: ' . $conn->error, 500);
        }
        
    } catch (Exception $e) {
        sendError('Error: ' . $e->getMessage(), 500);
    }
}
?>
