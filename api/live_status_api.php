<?php
/**
 * Live Status Tracking API
 * Handles login/logout times, break status, heartbeat, and auto-logout
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'config.php';

$action = $_GET['action'] ?? $_POST['action'] ?? '';

try {
    switch ($action) {
        case 'login':
            handleLogin($conn);
            break;
        case 'logout':
            handleLogout($conn);
            break;
        case 'heartbeat':
            handleHeartbeat($conn);
            break;
        case 'get_status':
            getStatus($conn);
            break;
        case 'get_all_status':
            getAllStatus($conn);
            break;
        case 'check_inactive':
            checkInactive($conn);
            break;
        default:
            echo json_encode(['success' => false, 'error' => 'Invalid action']);
    }
} catch (Exception $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}

function handleLogin($conn) {
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
    $result = $stmt->get_result()->fetch_assoc();
    $telecallerName = $result['name'] ?? 'Unknown';
    
    // Check if status record exists
    $stmt = $conn->prepare("SELECT id FROM telecaller_status WHERE telecaller_id = ?");
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    $exists = $stmt->get_result()->num_rows > 0;
    
    if ($exists) {
        // Update existing record
        $query = "UPDATE telecaller_status SET 
                  current_status = 'online',
                  login_time = NOW(),
                  logout_time = NULL,
                  last_activity = NOW(),
                  telecaller_name = ?
                  WHERE telecaller_id = ?";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("si", $telecallerName, $telecallerId);
    } else {
        // Insert new record
        $query = "INSERT INTO telecaller_status 
                  (telecaller_id, telecaller_name, current_status, login_time, last_activity) 
                  VALUES (?, ?, 'online', NOW(), NOW())";
        $stmt = $conn->prepare($query);
        $stmt->bind_param("is", $telecallerId, $telecallerName);
    }
    
    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Login recorded',
            'login_time' => date('Y-m-d H:i:s')
        ]);
    } else {
        echo json_encode(['success' => false, 'error' => $conn->error]);
    }
}

function handleLogout($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    $telecallerId = $input['telecaller_id'] ?? null;
    
    if (!$telecallerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    // End any active breaks
    $stmt = $conn->prepare("UPDATE break_logs SET 
                           status = 'completed',
                           end_time = NOW(),
                           duration_seconds = TIMESTAMPDIFF(SECOND, start_time, NOW())
                           WHERE telecaller_id = ? AND status = 'active'");
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    
    // Update status
    $query = "UPDATE telecaller_status SET 
              current_status = 'offline',
              logout_time = NOW(),
              last_activity = NOW()
              WHERE telecaller_id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $telecallerId);
    
    if ($stmt->execute()) {
        echo json_encode([
            'success' => true,
            'message' => 'Logout recorded',
            'logout_time' => date('Y-m-d H:i:s')
        ]);
    } else {
        echo json_encode(['success' => false, 'error' => $conn->error]);
    }
}

function handleHeartbeat($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    $telecallerId = $input['telecaller_id'] ?? null;
    
    if (!$telecallerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    $query = "UPDATE telecaller_status SET 
              last_activity = NOW()
              WHERE telecaller_id = ?";
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $telecallerId);
    
    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Heartbeat recorded']);
    } else {
        echo json_encode(['success' => false, 'error' => $conn->error]);
    }
}

function getStatus($conn) {
    $telecallerId = $_GET['telecaller_id'] ?? null;
    
    if (!$telecallerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    $query = "SELECT ts.*,
              TIMESTAMPDIFF(SECOND, ts.login_time, NOW()) as online_seconds,
              TIMESTAMPDIFF(SECOND, ts.last_activity, NOW()) as inactive_seconds,
              (SELECT COUNT(*) FROM break_logs WHERE caller_id = ts.telecaller_id AND DATE(start_time) = CURDATE()) as today_breaks,
              (SELECT SUM(duration_seconds) FROM break_logs WHERE caller_id = ts.telecaller_id AND DATE(start_time) = CURDATE() AND status = 'completed') as total_break_seconds
              FROM telecaller_status ts
              WHERE ts.telecaller_id = ?";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    $result = $stmt->get_result()->fetch_assoc();
    
    if ($result) {
        // Format durations
        $result['online_duration'] = formatDuration($result['online_seconds'] ?? 0);
        $result['inactive_duration'] = formatDuration($result['inactive_seconds'] ?? 0);
        $result['total_break_duration'] = formatDuration($result['total_break_seconds'] ?? 0);
        $result['is_inactive'] = ($result['inactive_seconds'] ?? 0) > 600; // 10 minutes
        
        echo json_encode(['success' => true, 'data' => $result]);
    } else {
        echo json_encode(['success' => false, 'error' => 'Status not found']);
    }
}

function getAllStatus($conn) {
    $query = "SELECT ts.*,
              TIMESTAMPDIFF(SECOND, ts.login_time, NOW()) as online_seconds,
              TIMESTAMPDIFF(SECOND, ts.last_activity, NOW()) as inactive_seconds,
              (SELECT COUNT(*) FROM break_logs WHERE caller_id = ts.telecaller_id AND DATE(start_time) = CURDATE()) as today_breaks,
              (SELECT SUM(duration_seconds) FROM break_logs WHERE caller_id = ts.telecaller_id AND DATE(start_time) = CURDATE() AND status = 'completed') as total_break_seconds,
              (SELECT COUNT(*) FROM call_logs WHERE caller_id = ts.telecaller_id AND DATE(call_time) = CURDATE()) as today_calls,
              (SELECT COUNT(*) FROM call_logs WHERE caller_id = ts.telecaller_id AND DATE(call_time) = CURDATE() AND call_status = 'connected') as today_connected
              FROM telecaller_status ts
              ORDER BY ts.current_status DESC, ts.last_activity DESC";
    
    $result = $conn->query($query);
    $statuses = [];
    
    while ($row = $result->fetch_assoc()) {
        $row['online_duration'] = formatDuration($row['online_seconds'] ?? 0);
        $row['inactive_duration'] = formatDuration($row['inactive_seconds'] ?? 0);
        $row['total_break_duration'] = formatDuration($row['total_break_seconds'] ?? 0);
        
        $inactiveSeconds = $row['inactive_seconds'] ?? 0;
        
        // Calculate display status based on activity
        // If on break or on_call, keep that status
        if ($row['current_status'] === 'break' || $row['current_status'] === 'on_call') {
            $row['display_status'] = $row['current_status'];
            $row['is_inactive'] = false;
        }
        // If activity < 10 min, show as online
        else if ($inactiveSeconds < 600) {
            $row['display_status'] = 'online';
            $row['is_inactive'] = false;
        }
        // If activity 10-30 min, show as offline (but not inactive)
        else if ($inactiveSeconds < 1800) {
            $row['display_status'] = 'offline';
            $row['is_inactive'] = false;
        }
        // If activity > 30 min, show as offline + inactive
        else {
            $row['display_status'] = 'offline';
            $row['is_inactive'] = true;
        }
        
        $statuses[] = $row;
    }
    
    echo json_encode(['success' => true, 'data' => $statuses]);
}

function checkInactive($conn) {
    // Find telecallers inactive for more than 10 minutes
    $query = "SELECT telecaller_id, telecaller_name, 
              TIMESTAMPDIFF(SECOND, last_activity, NOW()) as inactive_seconds
              FROM telecaller_status
              WHERE current_status != 'offline' 
              AND TIMESTAMPDIFF(SECOND, last_activity, NOW()) > 600";
    
    $result = $conn->query($query);
    $inactive = [];
    
    while ($row = $result->fetch_assoc()) {
        $inactive[] = $row;
        
        // Auto-logout disabled - handled by app instead
        // $stmt = $conn->prepare("UPDATE telecaller_status SET 
        //                        current_status = 'offline',
        //                        logout_time = NOW()
        //                        WHERE telecaller_id = ?");
        // $stmt->bind_param("i", $row['telecaller_id']);
        // $stmt->execute();
    }
    
    echo json_encode([
        'success' => true,
        'auto_logged_out' => count($inactive),
        'data' => $inactive
    ]);
}

function formatDuration($seconds) {
    $hours = floor($seconds / 3600);
    $minutes = floor(($seconds % 3600) / 60);
    $secs = $seconds % 60;
    return sprintf('%02d:%02d:%02d', $hours, $minutes, $secs);
}
