<?php
/**
 * ═══════════════════════════════════════════════════════════════
 * TELECALLER STATUS TRACKING API
 * ═══════════════════════════════════════════════════════════════
 * 
 * Tracks everything about telecaller activity:
 * - Login/Logout times
 * - Online/Offline status
 * - Break times and duration
 * - Call statistics
 * - Live activity tracking
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'config.php';

$action = $_GET['action'] ?? $_POST['action'] ?? '';

try {
    switch ($action) {
        case 'update_status':
            updateTelecallerStatus($conn);
            break;
        case 'get_status':
            getTelecallerStatus($conn);
            break;
        case 'get_all_status':
            getAllTelecallerStatus($conn);
            break;
        case 'start_break':
            startBreak($conn);
            break;
        case 'end_break':
            endBreak($conn);
            break;
        case 'login':
            recordLogin($conn);
            break;
        case 'logout':
            recordLogout($conn);
            break;
        case 'heartbeat':
            updateHeartbeat($conn);
            break;
        default:
            echo json_encode(['success' => false, 'error' => 'Invalid action']);
    }
} catch (Exception $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}

// Update telecaller status (online, offline, on_call, break, busy)
function updateTelecallerStatus($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    $telecallerId = $input['telecaller_id'] ?? null;
    $status = $input['status'] ?? null;
    $currentCallId = $input['current_call_id'] ?? null;
    
    if (!$telecallerId || !$status) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID and status required']);
        return;
    }
    
    // Validate status - only allow specific values
    $validStatuses = ['online', 'offline', 'break', 'on_call', 'on_leave', 'busy'];
    if (!in_array($status, $validStatuses)) {
        // If invalid status like 'inactive', convert to 'offline'
        $status = ($status === 'inactive' || $status === 'active') ? 'offline' : 'online';
    }
    
    // Check if record exists
    $stmt = $conn->prepare("SELECT id FROM telecaller_status WHERE telecaller_id = ?");
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    $exists = $stmt->get_result()->num_rows > 0;
    
    if ($exists) {
        // Update existing record
        $query = "UPDATE telecaller_status SET 
                  current_status = ?,
                  last_activity = NOW(),
                  current_call_id = ?,
                  updated_at = NOW()
                  WHERE telecaller_id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("sii", $status, $currentCallId, $telecallerId);
    } else {
        // Insert new record
        $query = "INSERT INTO telecaller_status 
                  (telecaller_id, current_status, last_activity, current_call_id, created_at, updated_at) 
                  VALUES (?, ?, NOW(), ?, NOW(), NOW())";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("isi", $telecallerId, $status, $currentCallId);
    }
    
    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Status updated']);
    } else {
        echo json_encode(['success' => false, 'error' => $conn->error]);
    }
}

// Get single telecaller status
function getTelecallerStatus($conn) {
    $telecallerId = $_GET['telecaller_id'] ?? null;
    
    if (!$telecallerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    $query = "
        SELECT 
            ts.*,
            a.name as telecaller_name,
            a.email,
            a.mobile,
            TIMESTAMPDIFF(SECOND, ts.login_time, NOW()) as online_duration_seconds,
            CASE 
                WHEN ts.current_status = 'online' AND TIMESTAMPDIFF(MINUTE, ts.last_activity, NOW()) > 5 THEN 'idle'
                ELSE ts.current_status
            END as actual_status
        FROM telecaller_status ts
        INNER JOIN admins a ON ts.telecaller_id = a.id
        WHERE ts.telecaller_id = ?
    ";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($row = $result->fetch_assoc()) {
        echo json_encode(['success' => true, 'data' => $row]);
    } else {
        echo json_encode(['success' => false, 'error' => 'Status not found']);
    }
}

// Get all telecaller statuses (for manager dashboard)
function getAllTelecallerStatus($conn) {
    $query = "
        SELECT 
            ts.*,
            a.name as telecaller_name,
            a.email,
            a.mobile,
            a.role,
            TIMESTAMPDIFF(SECOND, ts.login_time, NOW()) as online_duration_seconds,
            TIMESTAMPDIFF(SECOND, ts.break_start_time, NOW()) as current_break_duration,
            TIMESTAMPDIFF(MINUTE, ts.last_activity, NOW()) as minutes_since_activity,
            CASE 
                WHEN ts.login_time IS NULL THEN 'offline'
                WHEN ts.logout_time IS NOT NULL AND ts.logout_time > ts.login_time THEN 'offline'
                WHEN ts.current_status = 'offline' THEN 'offline'
                WHEN ts.current_status = 'break' THEN 'break'
                WHEN ts.current_status = 'on_call' THEN 'on_call'
                WHEN TIMESTAMPDIFF(MINUTE, ts.last_activity, NOW()) >= 10 THEN 'inactive'
                WHEN ts.current_status = 'online' THEN 'online'
                ELSE 'online'
            END as actual_status,
            (SELECT COUNT(*) FROM call_logs WHERE caller_id = ts.telecaller_id AND DATE(Created_at) = CURDATE()) as today_calls,
            (SELECT SUM(duration_seconds) 
             FROM break_logs 
             WHERE caller_id = ts.telecaller_id 
             AND DATE(start_time) = CURDATE() 
             AND status = 'completed') as total_break_seconds_today,
            (SELECT break_type 
             FROM break_logs 
             WHERE caller_id = ts.telecaller_id 
             AND status = 'active' 
             ORDER BY start_time DESC 
             LIMIT 1) as current_break_type
        FROM telecaller_status ts
        INNER JOIN admins a ON ts.telecaller_id = a.id
        WHERE a.role = 'telecaller'
        ORDER BY 
            ts.login_time DESC,
            ts.last_activity DESC
    ";
    
    $result = $conn->query($query);
    $statuses = [];
    
    while ($row = $result->fetch_assoc()) {
        $statuses[] = $row;
    }
    
    echo json_encode(['success' => true, 'data' => $statuses, 'count' => count($statuses)]);
}

// Start break
function startBreak($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    $telecallerId = $input['telecaller_id'] ?? null;
    $breakType = $input['break_type'] ?? 'personal_break';
    
    if (!$telecallerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    // Get telecaller name
    $stmt = $conn->prepare("SELECT name FROM admins WHERE id = ?");
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    $telecallerName = $stmt->get_result()->fetch_assoc()['name'] ?? 'Unknown';
    
    // Check if there's already an active break
    $stmt = $conn->prepare("SELECT id FROM break_logs WHERE caller_id = ? AND status = 'active'");
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    if ($stmt->get_result()->num_rows > 0) {
        echo json_encode(['success' => false, 'error' => 'Break already active']);
        return;
    }
    
    $conn->begin_transaction();
    
    try {
        // Update telecaller_status
        $query = "UPDATE telecaller_status SET 
                  current_status = 'break',
                  break_start_time = NOW(),
                  last_activity = NOW(),
                  updated_at = NOW()
                  WHERE telecaller_id = ?";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $telecallerId);
        $stmt->execute();
        
        // Insert into break_logs
        $query2 = "INSERT INTO break_logs 
                   (caller_id, telecaller_name, break_type, start_time, status) 
                   VALUES (?, ?, ?, NOW(), 'active')";
        
        $stmt2 = $conn->prepare($query2);
        $stmt2->bind_param("iss", $telecallerId, $telecallerName, $breakType);
        $stmt2->execute();
        
        $breakId = $conn->insert_id;
        
        $conn->commit();
        
        echo json_encode([
            'success' => true, 
            'message' => 'Break started',
            'break_id' => $breakId
        ]);
    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
}

// End break
function endBreak($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    $telecallerId = $input['telecaller_id'] ?? null;
    
    if (!$telecallerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    $conn->begin_transaction();
    
    try {
        // Get active break
        $stmt = $conn->prepare("SELECT id, start_time FROM break_logs WHERE caller_id = ? AND status = 'active'");
        $stmt->bind_param("i", $telecallerId);
        $stmt->execute();
        $breakData = $stmt->get_result()->fetch_assoc();
        
        if (!$breakData) {
            echo json_encode(['success' => false, 'error' => 'No active break found']);
            return;
        }
        
        // Update break_logs
        $query = "UPDATE break_logs SET 
                  end_time = NOW(),
                  duration_seconds = TIMESTAMPDIFF(SECOND, start_time, NOW()),
                  status = 'completed'
                  WHERE id = ?";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $breakData['id']);
        $stmt->execute();
        
        // Update telecaller_status
        $query2 = "UPDATE telecaller_status SET 
                   current_status = 'online',
                   total_break_duration = total_break_duration + TIMESTAMPDIFF(SECOND, break_start_time, NOW()),
                   break_start_time = NULL,
                   last_activity = NOW(),
                   updated_at = NOW()
                   WHERE telecaller_id = ?";
        
        $stmt2 = $conn->prepare($query2);
        $stmt2->bind_param("i", $telecallerId);
        $stmt2->execute();
        
        $conn->commit();
        
        echo json_encode(['success' => true, 'message' => 'Break ended']);
    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
}

// Record login
function recordLogin($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    $telecallerId = $input['telecaller_id'] ?? null;
    
    if (!$telecallerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    // Get telecaller name
    $stmt = $conn->prepare("SELECT name FROM admins WHERE id = ?");
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    $result = $stmt->get_result();
    $telecallerName = $result->fetch_assoc()['name'] ?? 'Unknown';
    
    // Check if record exists
    $stmt = $conn->prepare("SELECT id FROM telecaller_status WHERE telecaller_id = ?");
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    $exists = $stmt->get_result()->num_rows > 0;
    
    if ($exists) {
        // Update existing record
        $query = "UPDATE telecaller_status SET 
                  login_time = NOW(),
                  logout_time = NULL,
                  current_status = 'online',
                  last_activity = NOW(),
                  total_break_duration = 0,
                  break_start_time = NULL,
                  updated_at = NOW()
                  WHERE telecaller_id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $telecallerId);
    } else {
        // Insert new record
        $query = "INSERT INTO telecaller_status 
                  (telecaller_id, telecaller_name, login_time, current_status, last_activity, created_at, updated_at) 
                  VALUES (?, ?, NOW(), 'online', NOW(), NOW(), NOW())";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("is", $telecallerId, $telecallerName);
    }
    
    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Login recorded']);
    } else {
        echo json_encode(['success' => false, 'error' => $conn->error]);
    }
}

// Record logout
function recordLogout($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    $telecallerId = $input['telecaller_id'] ?? null;
    
    if (!$telecallerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    // Calculate total online duration
    $query = "UPDATE telecaller_status SET 
              logout_time = NOW(),
              current_status = 'offline',
              total_online_duration = TIMESTAMPDIFF(SECOND, login_time, NOW()),
              last_activity = NOW(),
              current_call_id = NULL,
              break_start_time = NULL,
              updated_at = NOW()
              WHERE telecaller_id = ?";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $telecallerId);
    
    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Logout recorded']);
    } else {
        echo json_encode(['success' => false, 'error' => $conn->error]);
    }
}

// Update heartbeat (called every 30 seconds to show telecaller is active)
function updateHeartbeat($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    $telecallerId = $input['telecaller_id'] ?? null;
    
    if (!$telecallerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    $query = "UPDATE telecaller_status SET 
              last_activity = NOW(),
              updated_at = NOW()
              WHERE telecaller_id = ?";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $telecallerId);
    
    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Heartbeat updated']);
    } else {
        echo json_encode(['success' => false, 'error' => $conn->error]);
    }
}

$conn->close();
?>
