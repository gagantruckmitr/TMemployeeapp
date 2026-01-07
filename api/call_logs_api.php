<?php
/**
 * Call Logs API - Based on actual call_logs table structure
 * Handles CRUD operations for call logs
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight OPTIONS requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database configuration
$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Database connection failed: ' . $e->getMessage()]);
    exit;
}

$action = $_GET['action'] ?? '';

switch($action) {
    case 'insert':
        insertCallLog($pdo);
        break;
    case 'get_all':
        getAllCallLogs($pdo);
        break;
    case 'get_by_id':
        getCallLogById($pdo);
        break;
    case 'update':
        updateCallLog($pdo);
        break;
    case 'delete':
        deleteCallLog($pdo);
        break;
    case 'get_table_structure':
        getTableStructure($pdo);
        break;
    default:
        echo json_encode(['success' => false, 'error' => 'Invalid action. Use: insert, get_all, get_by_id, update, delete, get_table_structure']);
}

/**
 * Get table structure
 */
function getTableStructure($pdo) {
    try {
        $stmt = $pdo->query("DESCRIBE call_logs");
        $columns = $stmt->fetchAll();
        
        echo json_encode([
            'success' => true,
            'columns' => $columns,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
    } catch(Exception $e) {
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
}

/**
 * Insert new call log
 * POST /api/call_logs_api.php?action=insert
 */
function insertCallLog($pdo) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        echo json_encode(['success' => false, 'error' => 'Method not allowed. Use POST.']);
        return;
    }
    
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Extract all fields from input
    $callerId = $input['caller_id'] ?? null;
    $tcFor = $input['tc_for'] ?? $input['call_source'] ?? null; // Use call_source as tc_for if not provided
    $userId = $input['user_id'] ?? null;
    $driverName = $input['driver_name'] ?? null;
    $callStatus = $input['call_status'] ?? 'pending';
    $feedback = $input['feedback'] ?? null;
    $remarks = $input['remarks'] ?? null;
    $notes = $input['notes'] ?? null;
    $callDuration = $input['call_duration'] ?? 0;
    $callerNumber = $input['caller_number'] ?? null;
    $userNumber = $input['user_number'] ?? null;
    $callTime = $input['call_time'] ?? null;
    $referenceId = $input['reference_id'] ?? null;
    $apiResponse = $input['api_response'] ?? null;
    $callInitiatedAt = $input['call_initiated_at'] ?? null;
    $callCompletedAt = $input['call_completed_at'] ?? null;
    $ipAddress = $input['ip_address'] ?? $_SERVER['REMOTE_ADDR'] ?? null;
    $recordingUrl = $input['recording_url'] ?? null;
    $manualCallRecordingUrl = $input['manual_call_recording_url'] ?? null;
    $myoperatorUniqueId = $input['myoperator_unique_id'] ?? null;
    $webhookData = $input['webhook_data'] ?? null;
    $callStartTime = $input['call_start_time'] ?? null;
    $callEndTime = $input['call_end_time'] ?? null;
    
    // Log the insert for debugging
    error_log("📞 Inserting call log: user_id=$userId, caller_id=$callerId, tc_for=$tcFor, status=$callStatus, feedback=$feedback");
    
    // Get call_source from input
    $callSource = $input['call_source'] ?? null;
    
    try {
        $sql = "INSERT INTO call_logs (
                    caller_id, tc_for, user_id, driver_name, call_status,
                    feedback, remarks, notes, call_duration, caller_number, user_number,
                    call_time, reference_id, api_response, call_initiated_at, call_completed_at,
                    ip_address, recording_url, manual_call_recording_url, myoperator_unique_id,
                    webhook_data, call_start_time, call_end_time, call_source, created_at, updated_at
                ) VALUES (
                    ?, ?, ?, ?, ?,
                    ?, ?, ?, ?, ?, ?,
                    COALESCE(?, NOW()), ?, ?, ?, ?,
                    ?, ?, ?, ?,
                    ?, ?, ?, ?, NOW(), NOW()
                )";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            $callerId, $tcFor, $userId, $driverName, $callStatus,
            $feedback, $remarks, $notes, $callDuration, $callerNumber, $userNumber,
            $callTime, $referenceId, $apiResponse, $callInitiatedAt, $callCompletedAt,
            $ipAddress, $recordingUrl, $manualCallRecordingUrl, $myoperatorUniqueId,
            $webhookData, $callStartTime, $callEndTime, $callSource
        ]);
        
        $insertedId = $pdo->lastInsertId();
        
        // Fetch the inserted record
        $stmt = $pdo->prepare("SELECT * FROM call_logs WHERE id = ?");
        $stmt->execute([$insertedId]);
        $insertedRecord = $stmt->fetch();
        
        echo json_encode([
            'success' => true,
            'message' => 'Call log inserted successfully',
            'id' => $insertedId,
            'data' => $insertedRecord,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        echo json_encode([
            'success' => false,
            'error' => 'Failed to insert call log: ' . $e->getMessage()
        ]);
    }
}

/**
 * Get all call logs with filters
 * GET /api/call_logs_api.php?action=get_all
 */
function getAllCallLogs($pdo) {
    try {
        $limit = (int)($_GET['limit'] ?? 50);
        $offset = (int)($_GET['offset'] ?? 0);
        
        $sql = "SELECT 
                    cl.*,
                    u.name as user_name,
                    u.mobile as user_mobile,
                    a.name as caller_name,
                    a.mobile as caller_mobile
                FROM call_logs cl
                LEFT JOIN users u ON cl.user_id = u.id
                LEFT JOIN admins a ON cl.caller_id = a.id
                WHERE 1=1";
        
        $params = [];
        
        // Filters
        if (!empty($_GET['caller_id'])) {
            $sql .= " AND cl.caller_id = ?";
            $params[] = $_GET['caller_id'];
        }
        
        if (!empty($_GET['user_id'])) {
            $sql .= " AND cl.user_id = ?";
            $params[] = $_GET['user_id'];
        }
        
        if (!empty($_GET['call_status'])) {
            $sql .= " AND cl.call_status = ?";
            $params[] = $_GET['call_status'];
        }
        
        if (!empty($_GET['tc_for'])) {
            $sql .= " AND cl.tc_for = ?";
            $params[] = $_GET['tc_for'];
        }
        
        if (!empty($_GET['reference_id'])) {
            $sql .= " AND cl.reference_id = ?";
            $params[] = $_GET['reference_id'];
        }
        
        if (!empty($_GET['from_date'])) {
            $sql .= " AND cl.call_time >= ?";
            $params[] = $_GET['from_date'];
        }
        
        if (!empty($_GET['to_date'])) {
            $sql .= " AND cl.call_time <= ?";
            $params[] = $_GET['to_date'];
        }
        
        $sql .= " ORDER BY cl.call_time DESC, cl.id DESC LIMIT $limit OFFSET $offset";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        $callLogs = $stmt->fetchAll();
        
        // Get total count
        $countSql = "SELECT COUNT(*) as total FROM call_logs cl WHERE 1=1";
        $countParams = [];
        
        if (!empty($_GET['caller_id'])) {
            $countSql .= " AND cl.caller_id = ?";
            $countParams[] = $_GET['caller_id'];
        }
        if (!empty($_GET['user_id'])) {
            $countSql .= " AND cl.user_id = ?";
            $countParams[] = $_GET['user_id'];
        }
        if (!empty($_GET['call_status'])) {
            $countSql .= " AND cl.call_status = ?";
            $countParams[] = $_GET['call_status'];
        }
        
        $countStmt = $pdo->prepare($countSql);
        $countStmt->execute($countParams);
        $totalCount = $countStmt->fetch()['total'];
        
        echo json_encode([
            'success' => true,
            'data' => $callLogs,
            'count' => count($callLogs),
            'total' => $totalCount,
            'limit' => $limit,
            'offset' => $offset,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        echo json_encode([
            'success' => false,
            'error' => 'Failed to fetch call logs: ' . $e->getMessage()
        ]);
    }
}

/**
 * Get single call log by ID
 * GET /api/call_logs_api.php?action=get_by_id&id=123
 */
function getCallLogById($pdo) {
    $id = $_GET['id'] ?? '';
    
    if (empty($id)) {
        echo json_encode(['success' => false, 'error' => 'ID required']);
        return;
    }
    
    try {
        $sql = "SELECT 
                    cl.*,
                    u.name as user_name,
                    u.mobile as user_mobile,
                    u.email as user_email,
                    a.name as caller_name,
                    a.mobile as caller_mobile,
                    a.email as caller_email
                FROM call_logs cl
                LEFT JOIN users u ON cl.user_id = u.id
                LEFT JOIN admins a ON cl.caller_id = a.id
                WHERE cl.id = ?";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([$id]);
        $callLog = $stmt->fetch();
        
        if (!$callLog) {
            echo json_encode(['success' => false, 'error' => 'Call log not found']);
            return;
        }
        
        echo json_encode([
            'success' => true,
            'data' => $callLog,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        echo json_encode([
            'success' => false,
            'error' => 'Failed to fetch call log: ' . $e->getMessage()
        ]);
    }
}

/**
 * Update call log
 * POST /api/call_logs_api.php?action=update
 */
function updateCallLog($pdo) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        echo json_encode(['success' => false, 'error' => 'Method not allowed. Use POST.']);
        return;
    }
    
    $input = json_decode(file_get_contents('php://input'), true);
    $id = $input['id'] ?? '';
    
    if (empty($id)) {
        echo json_encode(['success' => false, 'error' => 'ID required']);
        return;
    }
    
    try {
        // Build dynamic UPDATE query based on provided fields
        $updateFields = [];
        $params = [];
        
        $allowedFields = [
            'caller_id', 'tc_for', 'user_id', 'driver_name', 'call_status',
            'feedback', 'remarks', 'notes', 'call_duration', 'caller_number', 'user_number',
            'call_time', 'reference_id', 'api_response', 'call_initiated_at', 'call_completed_at',
            'ip_address', 'recording_url', 'manual_call_recording_url', 'myoperator_unique_id',
            'webhook_data', 'call_start_time', 'call_end_time'
        ];
        
        foreach ($allowedFields as $field) {
            if (isset($input[$field])) {
                $updateFields[] = "$field = ?";
                $params[] = $input[$field];
            }
        }
        
        if (empty($updateFields)) {
            echo json_encode(['success' => false, 'error' => 'No fields to update']);
            return;
        }
        
        $updateFields[] = "updated_at = NOW()";
        $params[] = $id;
        
        $sql = "UPDATE call_logs SET " . implode(', ', $updateFields) . " WHERE id = ?";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute($params);
        
        // Fetch updated record
        $stmt = $pdo->prepare("SELECT * FROM call_logs WHERE id = ?");
        $stmt->execute([$id]);
        $updatedRecord = $stmt->fetch();
        
        echo json_encode([
            'success' => true,
            'message' => 'Call log updated successfully',
            'data' => $updatedRecord,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        echo json_encode([
            'success' => false,
            'error' => 'Failed to update call log: ' . $e->getMessage()
        ]);
    }
}

/**
 * Delete call log
 * POST /api/call_logs_api.php?action=delete
 */
function deleteCallLog($pdo) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        echo json_encode(['success' => false, 'error' => 'Method not allowed. Use POST.']);
        return;
    }
    
    $input = json_decode(file_get_contents('php://input'), true);
    $id = $input['id'] ?? '';
    
    if (empty($id)) {
        echo json_encode(['success' => false, 'error' => 'ID required']);
        return;
    }
    
    try {
        $stmt = $pdo->prepare("DELETE FROM call_logs WHERE id = ?");
        $stmt->execute([$id]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Call log deleted successfully',
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        echo json_encode([
            'success' => false,
            'error' => 'Failed to delete call log: ' . $e->getMessage()
        ]);
    }
}
?>
