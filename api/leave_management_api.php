<?php
/**
 * ═══════════════════════════════════════════════════════════════
 * LEAVE MANAGEMENT API
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
        case 'get_break_history':
            getBreakHistory($conn);
            break;
        case 'get_active_breaks':
            getActiveBreaks($conn);
            break;
        
        // Attendance
        case 'get_attendance':
            getAttendance($conn);
            break;
        case 'get_my_attendance':
            getMyAttendance($conn);
            break;
        
        // Status management
        case 'update_status':
            updateStatus($conn);
            break;
        case 'get_status_history':
            getStatusHistory($conn);
            break;
        case 'get_all_telecaller_status':
            getAllTelecallerStatus($conn);
            break;
        
        default:
            echo json_encode(['success' => false, 'error' => 'Invalid action']);
    }
} catch (Exception $e) {
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}


// ═══════════════════════════════════════════════════════════════
// LEAVE REQUEST FUNCTIONS
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
    
    // Get telecaller name
    $stmt = $conn->prepare("SELECT name FROM admins WHERE id = ?");
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    $telecallerName = $stmt->get_result()->fetch_assoc()['name'] ?? 'Unknown';
    
    // Calculate total days
    $start = new DateTime($startDate);
    $end = new DateTime($endDate);
    $interval = $start->diff($end);
    $totalDays = $interval->days + 1;
    
    if ($leaveType === 'half_day') {
        $totalDays = 0.5;
    }
    
    // Insert leave request
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
    
    // Get approver name
    $stmt = $conn->prepare("SELECT name FROM admins WHERE id = ?");
    $stmt->bind_param("i", $approvedBy);
    $stmt->execute();
    $approverName = $stmt->get_result()->fetch_assoc()['name'] ?? 'Unknown';
    
    // Get leave request details
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
        // Update leave request
        $query = "UPDATE leave_requests SET 
                  status = 'approved',
                  approved_by = ?,
                  approved_by_name = ?,
                  approval_date = NOW()
                  WHERE id = ?";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("isi", $approvedBy, $approverName, $leaveId);
        $stmt->execute();
        
        // Update telecaller status to on_leave
        $query2 = "UPDATE telecaller_status SET 
                   current_status = 'on_leave',
                   is_on_leave = TRUE,
                   leave_reason = CONCAT('Approved leave from ', ?, ' to ', ?)
                   WHERE telecaller_id = ?";
        
        $stmt2 = $conn->prepare($query2);
        $stmt2->bind_param("ssi", $leaveData['start_date'], $leaveData['end_date'], $leaveData['telecaller_id']);
        $stmt2->execute();
        
        // Reassign leads to other telecallers
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
    
    // Get approver name
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
    
    // Get telecaller name
    $stmt = $conn->prepare("SELECT name FROM admins WHERE id = ?");
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    $telecallerName = $stmt->get_result()->fetch_assoc()['name'] ?? 'Unknown';
    
    // Check if there's an active break
    $stmt = $conn->prepare("SELECT id FROM break_logs WHERE telecaller_id = ? AND status = 'active'");
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    
    if ($stmt->get_result()->num_rows > 0) {
        echo json_encode(['success' => false, 'error' => 'You already have an active break']);
        return;
    }
    
    $conn->begin_transaction();
    
    try {
        // Insert break log
        $query = "INSERT INTO break_logs 
                  (telecaller_id, telecaller_name, break_type, start_time, notes, status) 
                  VALUES (?, ?, ?, NOW(), ?, 'active')";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("isss", $telecallerId, $telecallerName, $breakType, $notes);
        $stmt->execute();
        
        $breakId = $conn->insert_id;
        
        // Update telecaller status
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
            'break_id' => $breakId
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
        // Get active break
        $stmt = $conn->prepare("SELECT id, start_time FROM break_logs WHERE telecaller_id = ? AND status = 'active'");
        $stmt->bind_param("i", $telecallerId);
        $stmt->execute();
        $breakData = $stmt->get_result()->fetch_assoc();
        
        if (!$breakData) {
            echo json_encode(['success' => false, 'error' => 'No active break found']);
            return;
        }
        
        // Update break log
        $query = "UPDATE break_logs SET 
                  end_time = NOW(),
                  duration_seconds = TIMESTAMPDIFF(SECOND, start_time, NOW()),
                  status = 'completed'
                  WHERE id = ?";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $breakData['id']);
        $stmt->execute();
        
        // Update telecaller status
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
        
        echo json_encode(['success' => true, 'message' => 'Break ended successfully']);
        
    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
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
              WHERE telecaller_id = ? AND DATE(start_time) = ?
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
              INNER JOIN admins a ON bl.telecaller_id = a.id
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
// ATTENDANCE FUNCTIONS
// ═══════════════════════════════════════════════════════════════

function getAttendance($conn) {
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
        'total_working_hours' => 0
    ];
    
    while ($row = $result->fetch_assoc()) {
        $attendance[] = $row;
        $stats[$row['status']]++;
        $stats['total_working_hours'] += $row['total_working_hours'];
    }
    
    echo json_encode([
        'success' => true, 
        'data' => $attendance, 
        'stats' => $stats,
        'count' => count($attendance)
    ]);
}

function getMyAttendance($conn) {
    getAttendance($conn);
}


// ═══════════════════════════════════════════════════════════════
// STATUS MANAGEMENT FUNCTIONS
// ═══════════════════════════════════════════════════════════════

function updateStatus($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $telecallerId = $input['telecaller_id'] ?? null;
    $newStatus = $input['status'] ?? null;
    $changedBy = $input['changed_by'] ?? $telecallerId;
    $reason = $input['reason'] ?? '';
    
    if (!$telecallerId || !$newStatus) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID and status required']);
        return;
    }
    
    // Get current status
    $stmt = $conn->prepare("SELECT current_status FROM telecaller_status WHERE telecaller_id = ?");
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    $currentStatus = $stmt->get_result()->fetch_assoc()['current_status'] ?? 'offline';
    
    // Get names
    $stmt = $conn->prepare("SELECT name FROM admins WHERE id = ?");
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    $telecallerName = $stmt->get_result()->fetch_assoc()['name'] ?? 'Unknown';
    
    $stmt = $conn->prepare("SELECT name FROM admins WHERE id = ?");
    $stmt->bind_param("i", $changedBy);
    $stmt->execute();
    $changedByName = $stmt->get_result()->fetch_assoc()['name'] ?? 'System';
    
    $conn->begin_transaction();
    
    try {
        // Update status
        $query = "UPDATE telecaller_status SET 
                  current_status = ?,
                  last_activity = NOW()
                  WHERE telecaller_id = ?";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("si", $newStatus, $telecallerId);
        $stmt->execute();
        
        // Log status change
        $query2 = "INSERT INTO status_history 
                   (telecaller_id, telecaller_name, previous_status, new_status, changed_by, changed_by_name, reason) 
                   VALUES (?, ?, ?, ?, ?, ?, ?)";
        
        $stmt2 = $conn->prepare($query2);
        $stmt2->bind_param("isssiis", $telecallerId, $telecallerName, $currentStatus, $newStatus, $changedBy, $changedByName, $reason);
        $stmt2->execute();
        
        $conn->commit();
        
        echo json_encode(['success' => true, 'message' => 'Status updated successfully']);
        
    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
}

function getStatusHistory($conn) {
    $telecallerId = $_GET['telecaller_id'] ?? null;
    $limit = $_GET['limit'] ?? 50;
    
    if (!$telecallerId) {
        echo json_encode(['success' => false, 'error' => 'Telecaller ID required']);
        return;
    }
    
    $query = "SELECT * FROM status_history 
              WHERE telecaller_id = ?
              ORDER BY timestamp DESC
              LIMIT ?";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("ii", $telecallerId, $limit);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $history = [];
    while ($row = $result->fetch_assoc()) {
        $history[] = $row;
    }
    
    echo json_encode(['success' => true, 'data' => $history, 'count' => count($history)]);
}


function getAllTelecallerStatus($conn) {
    $query = "SELECT 
              ts.*,
              a.name as telecaller_name,
              a.email,
              a.mobile,
              a.role,
              TIMESTAMPDIFF(SECOND, ts.login_time, NOW()) as online_duration_seconds,
              TIMESTAMPDIFF(SECOND, ts.break_start_time, NOW()) as current_break_duration,
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
              (SELECT COUNT(*) FROM call_logs WHERE caller_id = ts.telecaller_id AND DATE(Created_at) = CURDATE() AND call_status = 'connected') as today_connected,
              (SELECT COUNT(*) FROM break_logs WHERE telecaller_id = ts.telecaller_id AND DATE(start_time) = CURDATE()) as today_breaks,
              (SELECT leave_type FROM leave_requests WHERE telecaller_id = ts.telecaller_id AND status = 'approved' AND CURDATE() BETWEEN start_date AND end_date LIMIT 1) as current_leave_type
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


// ═══════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════

function reassignLeads($conn, $fromTelecallerId, $fromTelecallerName, $leaveRequestId, $approvedBy, $approverName) {
    // Get all pending/callback leads from the telecaller on leave
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
        return; // No leads to reassign
    }
    
    // Get available telecallers (online and not on leave)
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
    
    // Distribute leads evenly
    $leadsPerTelecaller = ceil($leadsCount / count($availableTelecallers));
    $currentIndex = 0;
    
    foreach ($availableTelecallers as $telecaller) {
        $assignLeads = array_slice($leadIds, $currentIndex, $leadsPerTelecaller);
        
        if (empty($assignLeads)) break;
        
        $leadIdsStr = implode(',', $assignLeads);
        
        // Update drivers table
        $query = "UPDATE drivers SET 
                  assigned_to = ?,
                  telecaller_id = ?
                  WHERE id IN ($leadIdsStr)";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("ii", $telecaller['id'], $telecaller['id']);
        $stmt->execute();
        
        // Log reassignment
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
