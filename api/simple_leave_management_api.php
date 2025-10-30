<?php
/**
 * ═══════════════════════════════════════════════════════════════
 * SIMPLE LEAVE MANAGEMENT API - SINGLE APPROVAL
 * ═══════════════════════════════════════════════════════════════
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
        // Login/Logout
        case 'telecaller_login':
            telecallerLogin($conn);
            break;
        case 'telecaller_logout':
            telecallerLogout($conn);
            break;
        
        // Leave requests
        case 'apply_leave':
            applyLeave($conn);
            break;
        case 'get_my_leaves':
            getMyLeaves($conn);
            break;
        case 'get_all_leave_requests':
            getAllLeaveRequests($conn);
            break;
        case 'approve_leave':
            approveLeave($conn);
            break;
        case 'reject_leave':
            rejectLeave($conn);
            break;
        case 'cancel_leave':
            cancelLeave($conn);
            break;
        
        // Break management
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
        case 'get_active_breaks':
            getActiveBreaks($conn);
            break;
        
        // Status tracking
        case 'get_my_status':
            getMyStatus($conn);
            break;
        case 'get_all_telecaller_status':
            getAllTelecallerStatus($conn);
            break;
        case 'get_attendance_summary':
            getAttendanceSummary($conn);
            break;
        
        default:
            echo json_encode(['success' => false, 'error' => 'Invalid action']);
    }
} catch (Exception $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}


// ═══════════════════════════════════════════════════════════════
// LOGIN/LOGOUT FUNCTIONS
// ═══════════════════════════════════════════════════════════════

function telecallerLogin($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $telecallerId = $input['telecaller_id'] ?? null;
    
    if (!$telecallerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    $stmt = $conn->prepare("SELECT name FROM admins WHERE id = ?");
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    $telecaller = $stmt->get_result()->fetch_assoc();
    
    if (!$telecaller) {
        echo json_encode(['success' => false, 'error' => 'Telecaller not found']);
        return;
    }
    
    $conn->begin_transaction();
    
    try {
        $stmt = $conn->prepare("SELECT id FROM telecaller_status WHERE telecaller_id = ?");
        $stmt->bind_param("i", $telecallerId);
        $stmt->execute();
        $exists = $stmt->get_result()->num_rows > 0;
        
        if ($exists) {
            $query = "UPDATE telecaller_status SET 
                      current_status = 'online',
                      login_time = NOW(),
                      logout_time = NULL,
                      last_activity = NOW(),
                      total_online_duration = 0,
                      total_break_duration = 0
                      WHERE telecaller_id = ?";
        } else {
            $query = "INSERT INTO telecaller_status 
                      (telecaller_id, telecaller_name, current_status, login_time, last_activity) 
                      VALUES (?, ?, 'online', NOW(), NOW())";
        }
        
        $stmt = $conn->prepare($query);
        if ($exists) {
            $stmt->bind_param("i", $telecallerId);
        } else {
            $stmt->bind_param("iss", $telecallerId, $telecaller['name']);
        }
        $stmt->execute();
        
        $today = date('Y-m-d');
        $stmt = $conn->prepare("
            INSERT INTO attendance (telecaller_id, telecaller_name, date, login_time, status)
            VALUES (?, ?, ?, NOW(), 'present')
            ON DUPLICATE KEY UPDATE login_time = NOW(), status = 'present'
        ");
        $stmt->bind_param("iss", $telecallerId, $telecaller['name'], $today);
        $stmt->execute();
        
        $conn->commit();
        
        echo json_encode([
            'success' => true, 
            'message' => 'Login successful',
            'login_time' => date('Y-m-d H:i:s')
        ]);
        
    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
}

function telecallerLogout($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $telecallerId = $input['telecaller_id'] ?? null;
    
    if (!$telecallerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    $conn->begin_transaction();
    
    try {
        $stmt = $conn->prepare("SELECT login_time, total_break_duration FROM telecaller_status WHERE telecaller_id = ?");
        $stmt->bind_param("i", $telecallerId);
        $stmt->execute();
        $status = $stmt->get_result()->fetch_assoc();
        
        if (!$status) {
            echo json_encode(['success' => false, 'error' => 'No active session found']);
            return;
        }
        
        $query = "UPDATE telecaller_status SET 
                  current_status = 'offline',
                  logout_time = NOW(),
                  total_online_duration = TIMESTAMPDIFF(SECOND, login_time, NOW()),
                  last_activity = NOW()
                  WHERE telecaller_id = ?";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $telecallerId);
        $stmt->execute();
        
        $today = date('Y-m-d');
        $query2 = "UPDATE attendance SET 
                   logout_time = NOW(),
                   total_working_hours = ROUND(TIMESTAMPDIFF(SECOND, login_time, NOW()) / 3600, 2),
                   total_break_time = ?
                   WHERE telecaller_id = ? AND date = ?";
        
        $stmt2 = $conn->prepare($query2);
        $stmt2->bind_param("iis", $status['total_break_duration'], $telecallerId, $today);
        $stmt2->execute();
        
        $query3 = "UPDATE break_logs SET 
                   end_time = NOW(),
                   duration_seconds = TIMESTAMPDIFF(SECOND, start_time, NOW()),
                   status = 'completed'
                   WHERE telecaller_id = ? AND status = 'active'";
        
        $stmt3 = $conn->prepare($query3);
        $stmt3->bind_param("i", $telecallerId);
        $stmt3->execute();
        
        $conn->commit();
        
        echo json_encode([
            'success' => true, 
            'message' => 'Logout successful',
            'logout_time' => date('Y-m-d H:i:s')
        ]);
        
    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
}


// ═══════════════════════════════════════════════════════════════
// LEAVE REQUEST FUNCTIONS - SINGLE APPROVAL
// ═══════════════════════════════════════════════════════════════

function applyLeave($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $telecallerId = $input['telecaller_id'] ?? null;
    $leaveType = $input['leave_type'] ?? null;
    $startDate = $input['start_date'] ?? null;
    $endDate = $input['end_date'] ?? null;
    $reason = $input['reason'] ?? null;
    
    if (!$telecallerId || !$leaveType || !$startDate || !$endDate || !$reason) {
        echo json_encode(['success' => false, 'error' => 'All fields required']);
        return;
    }
    
    $stmt = $conn->prepare("SELECT name FROM admins WHERE id = ?");
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    $telecallerName = $stmt->get_result()->fetch_assoc()['name'] ?? 'Unknown';
    
    $start = new DateTime($startDate);
    $end = new DateTime($endDate);
    $interval = $start->diff($end);
    $totalDays = $interval->days + 1;
    
    if ($leaveType === 'half_day') {
        $totalDays = 0.5;
    }
    
    $query = "INSERT INTO leave_requests 
              (telecaller_id, telecaller_name, leave_type, start_date, end_date, total_days, reason, status) 
              VALUES (?, ?, ?, ?, ?, ?, ?, 'pending')";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("issssds", $telecallerId, $telecallerName, $leaveType, $startDate, $endDate, $totalDays, $reason);
    
    if ($stmt->execute()) {
        $leaveId = $conn->insert_id;
        echo json_encode([
            'success' => true, 
            'message' => 'Leave request submitted successfully',
            'leave_id' => $leaveId
        ]);
    } else {
        echo json_encode(['success' => false, 'error' => $conn->error]);
    }
}

function getMyLeaves($conn) {
    $telecallerId = $_GET['telecaller_id'] ?? null;
    
    if (!$telecallerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    $query = "SELECT lr.*, 
              CASE 
                  WHEN lr.status = 'pending' THEN 'Pending Approval'
                  WHEN lr.status = 'approved' THEN CONCAT('Approved by ', lr.approved_by_name)
                  WHEN lr.status = 'rejected' THEN 'Rejected'
                  WHEN lr.status = 'cancelled' THEN 'Cancelled'
              END as status_text
              FROM leave_requests lr
              WHERE lr.telecaller_id = ?
              ORDER BY lr.created_at DESC";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $leaves = [];
    while ($row = $result->fetch_assoc()) {
        $leaves[] = $row;
    }
    
    echo json_encode(['success' => true, 'data' => $leaves, 'count' => count($leaves)]);
}

function getAllLeaveRequests($conn) {
    $status = $_GET['status'] ?? 'all';
    
    $query = "SELECT lr.*, 
              a.mobile as telecaller_mobile,
              a.email as telecaller_email
              FROM leave_requests lr
              INNER JOIN admins a ON lr.telecaller_id = a.id
              WHERE a.role = 'telecaller'";
    
    if ($status !== 'all') {
        $query .= " AND lr.status = '$status'";
    }
    
    $query .= " ORDER BY 
                CASE lr.status 
                    WHEN 'pending' THEN 1 
                    WHEN 'approved' THEN 2 
                    WHEN 'rejected' THEN 3 
                    WHEN 'cancelled' THEN 4 
                END, 
                lr.created_at DESC";
    
    $result = $conn->query($query);
    $leaves = [];
    
    while ($row = $result->fetch_assoc()) {
        $leaves[] = $row;
    }
    
    echo json_encode(['success' => true, 'data' => $leaves, 'count' => count($leaves)]);
}

function approveLeave($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $leaveId = $input['leave_id'] ?? null;
    $approvedBy = $input['approved_by'] ?? null;
    
    if (!$leaveId || !$approvedBy) {
        echo json_encode(['success' => false, 'error' => 'Leave ID and approver ID required']);
        return;
    }
    
    $stmt = $conn->prepare("SELECT name FROM admins WHERE id = ?");
    $stmt->bind_param("i", $approvedBy);
    $stmt->execute();
    $approverName = $stmt->get_result()->fetch_assoc()['name'] ?? 'Unknown';
    
    $stmt = $conn->prepare("SELECT telecaller_id, telecaller_name, start_date, end_date FROM leave_requests WHERE id = ?");
    $stmt->bind_param("i", $leaveId);
    $stmt->execute();
    $leaveData = $stmt->get_result()->fetch_assoc();
    
    if (!$leaveData) {
        echo json_encode(['success' => false, 'error' => 'Leave request not found']);
        return;
    }
    
    $conn->begin_transaction();
    
    try {
        $query = "UPDATE leave_requests SET 
                  status = 'approved',
                  approved_by = ?,
                  approved_by_name = ?,
                  approval_date = NOW()
                  WHERE id = ?";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("isi", $approvedBy, $approverName, $leaveId);
        $stmt->execute();
        
        $query2 = "UPDATE telecaller_status SET 
                   current_status = 'on_leave',
                   is_on_leave = TRUE,
                   leave_reason = CONCAT('Approved leave from ', ?, ' to ', ?)
                   WHERE telecaller_id = ?";
        
        $stmt2 = $conn->prepare($query2);
        $stmt2->bind_param("ssi", $leaveData['start_date'], $leaveData['end_date'], $leaveData['telecaller_id']);
        $stmt2->execute();
        
        reassignLeads($conn, $leaveData['telecaller_id'], $leaveData['telecaller_name'], $leaveId, $approvedBy, $approverName);
        
        $conn->commit();
        
        echo json_encode([
            'success' => true, 
            'message' => 'Leave approved and leads reassigned successfully'
        ]);
        
    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
}

function rejectLeave($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $leaveId = $input['leave_id'] ?? null;
    $approvedBy = $input['approved_by'] ?? null;
    $rejectionReason = $input['rejection_reason'] ?? 'Not specified';
    
    if (!$leaveId || !$approvedBy) {
        echo json_encode(['success' => false, 'error' => 'Leave ID and approver ID required']);
        return;
    }
    
    $stmt = $conn->prepare("SELECT name FROM admins WHERE id = ?");
    $stmt->bind_param("i", $approvedBy);
    $stmt->execute();
    $approverName = $stmt->get_result()->fetch_assoc()['name'] ?? 'Unknown';
    
    $query = "UPDATE leave_requests SET 
              status = 'rejected',
              approved_by = ?,
              approved_by_name = ?,
              approval_date = NOW(),
              rejection_reason = ?
              WHERE id = ?";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("issi", $approvedBy, $approverName, $rejectionReason, $leaveId);
    
    if ($stmt->execute()) {
        echo json_encode(['success' => true, 'message' => 'Leave request rejected']);
    } else {
        echo json_encode(['success' => false, 'error' => $conn->error]);
    }
}

function cancelLeave($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $leaveId = $input['leave_id'] ?? null;
    $telecallerId = $input['telecaller_id'] ?? null;
    
    if (!$leaveId || !$telecallerId) {
        echo json_encode(['success' => false, 'error' => 'Leave ID and telecaller ID required']);
        return;
    }
    
    $query = "UPDATE leave_requests SET 
              status = 'cancelled'
              WHERE id = ? AND telecaller_id = ? AND status = 'pending'";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("ii", $leaveId, $telecallerId);
    
    if ($stmt->execute() && $stmt->affected_rows > 0) {
        echo json_encode(['success' => true, 'message' => 'Leave request cancelled']);
    } else {
        echo json_encode(['success' => false, 'error' => 'Cannot cancel this leave request']);
    }
}


// ═══════════════════════════════════════════════════════════════
// BREAK MANAGEMENT FUNCTIONS
// ═══════════════════════════════════════════════════════════════

function startBreak($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $telecallerId = $input['telecaller_id'] ?? null;
    $breakType = $input['break_type'] ?? 'personal_break';
    $notes = $input['notes'] ?? '';
    
    if (!$telecallerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    $stmt = $conn->prepare("SELECT name FROM admins WHERE id = ?");
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    $telecallerName = $stmt->get_result()->fetch_assoc()['name'] ?? 'Unknown';
    
    $stmt = $conn->prepare("SELECT id FROM break_logs WHERE caller_id = ? AND status = 'active'");
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    
    if ($stmt->get_result()->num_rows > 0) {
        echo json_encode(['success' => false, 'error' => 'You already have an active break']);
        return;
    }
    
    $conn->begin_transaction();
    
    try {
        $query = "INSERT INTO break_logs 
                  (caller_id, telecaller_name, break_type, start_time, notes, status) 
                  VALUES (?, ?, ?, NOW(), ?, 'active')";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("isss", $telecallerId, $telecallerName, $breakType, $notes);
        $stmt->execute();
        
        $breakId = $conn->insert_id;
        
        $query2 = "UPDATE telecaller_status SET 
                   current_status = 'break',
                   break_start_time = NOW(),
                   last_activity = NOW()
                   WHERE telecaller_id = ?";
        
        $stmt2 = $conn->prepare($query2);
        $stmt2->bind_param("i", $telecallerId);
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
    
    $telecallerId = $input['telecaller_id'] ?? null;
    
    if (!$telecallerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    $conn->begin_transaction();
    
    try {
        $stmt = $conn->prepare("SELECT id, start_time FROM break_logs WHERE caller_id = ? AND status = 'active'");
        $stmt->bind_param("i", $telecallerId);
        $stmt->execute();
        $breakData = $stmt->get_result()->fetch_assoc();
        
        if (!$breakData) {
            echo json_encode(['success' => false, 'error' => 'No active break found']);
            return;
        }
        
        $query = "UPDATE break_logs SET 
                  end_time = NOW(),
                  duration_seconds = TIMESTAMPDIFF(SECOND, start_time, NOW()),
                  status = 'completed'
                  WHERE id = ?";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $breakData['id']);
        $stmt->execute();
        
        $query2 = "UPDATE telecaller_status SET 
                   current_status = 'online',
                   total_break_duration = total_break_duration + TIMESTAMPDIFF(SECOND, break_start_time, NOW()),
                   break_start_time = NULL,
                   last_activity = NOW()
                   WHERE telecaller_id = ?";
        
        $stmt2 = $conn->prepare($query2);
        $stmt2->bind_param("i", $telecallerId);
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
    $telecallerId = $_GET['telecaller_id'] ?? null;
    
    if (!$telecallerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    $query = "SELECT *, 
              TIMESTAMPDIFF(SECOND, start_time, NOW()) as current_duration,
              TIME_FORMAT(SEC_TO_TIME(TIMESTAMPDIFF(SECOND, start_time, NOW())), '%H:%i:%s') as duration_formatted
              FROM break_logs 
              WHERE caller_id = ? AND status = 'active'";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $telecallerId);
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
    $telecallerId = $_GET['telecaller_id'] ?? null;
    $date = $_GET['date'] ?? date('Y-m-d');
    
    if (!$telecallerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    $query = "SELECT *, 
              TIME_FORMAT(SEC_TO_TIME(duration_seconds), '%H:%i:%s') as duration_formatted
              FROM break_logs 
              WHERE caller_id = ? AND DATE(start_time) = ?
              ORDER BY start_time DESC";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("is", $telecallerId, $date);
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

function getActiveBreaks($conn) {
    $query = "SELECT bl.*, 
              TIMESTAMPDIFF(SECOND, bl.start_time, NOW()) as current_duration,
              TIME_FORMAT(SEC_TO_TIME(TIMESTAMPDIFF(SECOND, bl.start_time, NOW())), '%H:%i:%s') as duration_formatted
              FROM break_logs bl
              INNER JOIN admins a ON bl.caller_id = a.id
              WHERE bl.status = 'active' AND a.role = 'telecaller'
              ORDER BY bl.start_time ASC";
    
    $result = $conn->query($query);
    $breaks = [];
    
    while ($row = $result->fetch_assoc()) {
        $breaks[] = $row;
    }
    
    echo json_encode(['success' => true, 'data' => $breaks, 'count' => count($breaks)]);
}


// ═══════════════════════════════════════════════════════════════
// STATUS TRACKING FUNCTIONS
// ═══════════════════════════════════════════════════════════════

function getMyStatus($conn) {
    $telecallerId = $_GET['telecaller_id'] ?? null;
    
    if (!$telecallerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    $query = "SELECT 
              ts.*,
              TIMESTAMPDIFF(SECOND, ts.login_time, NOW()) as online_duration_seconds,
              TIME_FORMAT(SEC_TO_TIME(TIMESTAMPDIFF(SECOND, ts.login_time, NOW())), '%H:%i:%s') as online_duration_formatted,
              TIME_FORMAT(SEC_TO_TIME(ts.total_break_duration), '%H:%i:%s') as total_break_formatted,
              (SELECT COUNT(*) FROM call_logs WHERE caller_id = ts.telecaller_id AND DATE(Created_at) = CURDATE()) as today_calls,
              (SELECT COUNT(*) FROM call_logs WHERE caller_id = ts.telecaller_id AND DATE(Created_at) = CURDATE() AND call_status = 'connected') as today_connected,
              (SELECT COUNT(*) FROM break_logs WHERE caller_id = ts.telecaller_id AND DATE(start_time) = CURDATE()) as today_breaks
              FROM telecaller_status ts
              WHERE ts.telecaller_id = ?";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    if ($result->num_rows > 0) {
        $status = $result->fetch_assoc();
        echo json_encode(['success' => true, 'data' => $status]);
    } else {
        echo json_encode(['success' => false, 'error' => 'Status not found']);
    }
}

function getAllTelecallerStatus($conn) {
    $query = "SELECT 
              ts.*,
              a.name as telecaller_name,
              a.email,
              a.mobile,
              TIMESTAMPDIFF(SECOND, ts.login_time, NOW()) as online_duration_seconds,
              TIME_FORMAT(SEC_TO_TIME(TIMESTAMPDIFF(SECOND, ts.login_time, NOW())), '%H:%i:%s') as online_duration_formatted,
              TIME_FORMAT(SEC_TO_TIME(ts.total_break_duration), '%H:%i:%s') as total_break_formatted,
              CASE 
                  WHEN ts.is_on_leave = TRUE THEN 'on_leave'
                  WHEN ts.current_status = 'online' AND TIMESTAMPDIFF(MINUTE, ts.last_activity, NOW()) > 5 THEN 'idle'
                  WHEN ts.login_time IS NULL THEN 'offline'
                  WHEN ts.logout_time > ts.login_time THEN 'offline'
                  ELSE ts.current_status
              END as actual_status,
              (SELECT COUNT(*) FROM call_logs WHERE caller_id = ts.telecaller_id AND DATE(Created_at) = CURDATE()) as today_calls,
              (SELECT COUNT(*) FROM call_logs WHERE caller_id = ts.telecaller_id AND DATE(Created_at) = CURDATE() AND call_status = 'connected') as today_connected
              FROM telecaller_status ts
              INNER JOIN admins a ON ts.telecaller_id = a.id
              WHERE a.role = 'telecaller'
              ORDER BY 
                  CASE ts.current_status
                      WHEN 'on_call' THEN 1
                      WHEN 'online' THEN 2
                      WHEN 'break' THEN 3
                      WHEN 'idle' THEN 4
                      WHEN 'on_leave' THEN 5
                      WHEN 'offline' THEN 6
                  END,
                  ts.last_activity DESC";
    
    $result = $conn->query($query);
    $statuses = [];
    
    $summary = [
        'online' => 0,
        'offline' => 0,
        'on_call' => 0,
        'break' => 0,
        'on_leave' => 0,
        'idle' => 0,
        'total' => 0
    ];
    
    while ($row = $result->fetch_assoc()) {
        $statuses[] = $row;
        $summary[$row['actual_status']]++;
        $summary['total']++;
    }
    
    echo json_encode([
        'success' => true, 
        'data' => $statuses, 
        'summary' => $summary,
        'count' => count($statuses)
    ]);
}

function getAttendanceSummary($conn) {
    $telecallerId = $_GET['telecaller_id'] ?? null;
    $month = $_GET['month'] ?? date('Y-m');
    
    if (!$telecallerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    $query = "SELECT * FROM attendance 
              WHERE telecaller_id = ? AND DATE_FORMAT(date, '%Y-%m') = ?
              ORDER BY date DESC";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("is", $telecallerId, $month);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $attendance = [];
    $stats = [
        'present' => 0,
        'absent' => 0,
        'half_day' => 0,
        'on_leave' => 0,
        'total_working_hours' => 0,
        'total_days' => 0
    ];
    
    while ($row = $result->fetch_assoc()) {
        $attendance[] = $row;
        $stats[$row['status']]++;
        $stats['total_working_hours'] += $row['total_working_hours'];
        $stats['total_days']++;
    }
    
    echo json_encode([
        'success' => true, 
        'data' => $attendance, 
        'stats' => $stats,
        'count' => count($attendance)
    ]);
}


// ═══════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════

function reassignLeads($conn, $fromTelecallerId, $fromTelecallerName, $leaveRequestId, $approvedBy, $approverName) {
    $stmt = $conn->prepare("
        SELECT id FROM drivers 
        WHERE assigned_to = ? 
        AND profile_completion_status IN ('pending', 'callback_later', 'not_interested')
    ");
    $stmt->bind_param("i", $fromTelecallerId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $leadIds = [];
    while ($row = $result->fetch_assoc()) {
        $leadIds[] = $row['id'];
    }
    
    $leadsCount = count($leadIds);
    
    if ($leadsCount === 0) {
        return;
    }
    
    $stmt = $conn->prepare("
        SELECT a.id, a.name, COUNT(d.id) as current_leads
        FROM admins a
        LEFT JOIN drivers d ON a.id = d.assigned_to
        LEFT JOIN telecaller_status ts ON a.id = ts.telecaller_id
        WHERE a.role = 'telecaller' 
        AND a.id != ?
        AND (ts.is_on_leave = FALSE OR ts.is_on_leave IS NULL)
        GROUP BY a.id, a.name
        ORDER BY current_leads ASC
        LIMIT 5
    ");
    $stmt->bind_param("i", $fromTelecallerId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $availableTelecallers = [];
    while ($row = $result->fetch_assoc()) {
        $availableTelecallers[] = $row;
    }
    
    if (empty($availableTelecallers)) {
        throw new Exception('No available telecallers to reassign leads');
    }
    
    $leadsPerTelecaller = ceil($leadsCount / count($availableTelecallers));
    $currentIndex = 0;
    
    foreach ($availableTelecallers as $telecaller) {
        $assignLeads = array_slice($leadIds, $currentIndex, $leadsPerTelecaller);
        
        if (empty($assignLeads)) break;
        
        $leadIdsStr = implode(',', $assignLeads);
        
        $query = "UPDATE drivers SET 
                  assigned_to = ?,
                  telecaller_id = ?
                  WHERE id IN ($leadIdsStr)";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("ii", $telecaller['id'], $telecaller['id']);
        $stmt->execute();
        
        $query2 = "INSERT INTO lead_reassignment_log 
                   (from_telecaller_id, from_telecaller_name, to_telecaller_id, to_telecaller_name, 
                    leads_count, reason, reassigned_by, reassigned_by_name, leave_request_id) 
                   VALUES (?, ?, ?, ?, ?, 'leave_approved', ?, ?, ?)";
        
        $stmt2 = $conn->prepare($query2);
        $assignedCount = count($assignLeads);
        $stmt2->bind_param("isisisi", 
            $fromTelecallerId, $fromTelecallerName, 
            $telecaller['id'], $telecaller['name'], 
            $assignedCount, $approvedBy, $approverName, $leaveRequestId
        );
        $stmt2->execute();
        
        $currentIndex += $leadsPerTelecaller;
    }
}

$conn->close();
?>
