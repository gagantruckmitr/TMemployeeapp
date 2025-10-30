<?php
/**
 * FIXED - Simple Leave Management API using caller_id
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'config.php';

$action = $_GET['action'] ?? $_POST['action'] ?? '';

try {
    switch ($action) {
        // Break management - FIXED to use caller_id
        case 'start_break':
            startBreak($conn);
            break;
        case 'end_break':
            endBreak($conn);
            break;
        case 'get_active_break':
            getActiveBreak($conn);
            break;
        case 'get_break_history':
            getBreakHistory($conn);
            break;
        
        default:
            echo json_encode(['success' => false, 'error' => 'Invalid action']);
    }
} catch (Exception $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}

// ═══════════════════════════════════════════════════════════════
// BREAK MANAGEMENT - FIXED TO USE caller_id
// ═══════════════════════════════════════════════════════════════

function startBreak($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $callerId = $input['telecaller_id'] ?? null; // Accept telecaller_id from app
    $breakType = $input['break_type'] ?? 'personal_break';
    $notes = $input['notes'] ?? '';
    
    if (!$callerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    // Get telecaller name
    $stmt = $conn->prepare("SELECT name FROM admins WHERE id = ?");
    $stmt->bind_param("i", $callerId);
    $stmt->execute();
    $telecallerName = $stmt->get_result()->fetch_assoc()['name'] ?? 'Unknown';
    
    // Check for active break using caller_id
    $stmt = $conn->prepare("SELECT id FROM break_logs WHERE caller_id = ? AND status = 'active'");
    $stmt->bind_param("i", $callerId);
    $stmt->execute();
    
    if ($stmt->get_result()->num_rows > 0) {
        echo json_encode(['success' => false, 'error' => 'You already have an active break']);
        return;
    }
    
    $conn->begin_transaction();
    
    try {
        // Insert using caller_id
        $query = "INSERT INTO break_logs 
                  (caller_id, telecaller_name, break_type, start_time, notes, status) 
                  VALUES (?, ?, ?, NOW(), ?, 'active')";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("isss", $callerId, $telecallerName, $breakType, $notes);
        $stmt->execute();
        
        $breakId = $conn->insert_id;
        
        // Update telecaller_status (this table uses telecaller_id)
        $query2 = "UPDATE telecaller_status SET 
                   current_status = 'break',
                   break_start_time = NOW(),
                   last_activity = NOW()
                   WHERE telecaller_id = ?";
        
        $stmt2 = $conn->prepare($query2);
        $stmt2->bind_param("i", $callerId);
        $stmt2->execute();
        
        $conn->commit();
        
        echo json_encode([
            'success' => true, 
            'message' => 'Break started',
            'break_id' => $breakId,
            'start_time' => date('Y-m-d H:i:s')
        ]);
        
    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
}

function endBreak($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $callerId = $input['telecaller_id'] ?? null;
    
    if (!$callerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    $conn->begin_transaction();
    
    try {
        // Find active break using caller_id
        $stmt = $conn->prepare("SELECT id, start_time FROM break_logs WHERE caller_id = ? AND status = 'active'");
        $stmt->bind_param("i", $callerId);
        $stmt->execute();
        $breakData = $stmt->get_result()->fetch_assoc();
        
        if (!$breakData) {
            echo json_encode(['success' => false, 'error' => 'No active break found']);
            return;
        }
        
        // End break
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
                   last_activity = NOW()
                   WHERE telecaller_id = ?";
        
        $stmt2 = $conn->prepare($query2);
        $stmt2->bind_param("i", $callerId);
        $stmt2->execute();
        
        $conn->commit();
        
        echo json_encode([
            'success' => true, 
            'message' => 'Break ended successfully',
            'end_time' => date('Y-m-d H:i:s')
        ]);
        
    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
}

function getActiveBreak($conn) {
    $callerId = $_GET['telecaller_id'] ?? null;
    
    if (!$callerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    // Query using caller_id
    $query = "SELECT *, 
              TIMESTAMPDIFF(SECOND, start_time, NOW()) as current_duration,
              TIME_FORMAT(SEC_TO_TIME(TIMESTAMPDIFF(SECOND, start_time, NOW())), '%H:%i:%s') as duration_formatted
              FROM break_logs 
              WHERE caller_id = ? AND status = 'active'";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $callerId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $break = $result->fetch_assoc();
        echo json_encode(['success' => true, 'data' => $break, 'has_active_break' => true]);
    } else {
        echo json_encode(['success' => true, 'data' => null, 'has_active_break' => false]);
    }
}

function getBreakHistory($conn) {
    $callerId = $_GET['telecaller_id'] ?? null;
    $date = $_GET['date'] ?? date('Y-m-d');
    
    if (!$callerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    // Query using caller_id
    $query = "SELECT *, 
              TIME_FORMAT(SEC_TO_TIME(duration_seconds), '%H:%i:%s') as duration_formatted
              FROM break_logs 
              WHERE caller_id = ? AND DATE(start_time) = ?
              ORDER BY start_time DESC";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("is", $callerId, $date);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $breaks = [];
    $totalBreakTime = 0;
    
    while ($row = $result->fetch_assoc()) {
        $breaks[] = $row;
        $totalBreakTime += $row['duration_seconds'] ?? 0;
    }
    
    echo json_encode([
        'success' => true, 
        'data' => $breaks, 
        'count' => count($breaks),
        'total_break_time' => $totalBreakTime,
        'total_break_time_formatted' => gmdate('H:i:s', $totalBreakTime)
    ]);
}

$conn->close();
?>
