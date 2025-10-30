<?php
/**
 * ═══════════════════════════════════════════════════════════════
 * ENHANCED LEAVE MANAGEMENT API WITH DUAL APPROVAL
 * ═══════════════════════════════════════════════════════════════
 * Features:
 * - Dual approval system (Manager + Admin)
 * - Online/Offline tracking
 * - Login/Logout management
 * - Break management
 * - Leave application and approval
 * - Attendance tracking
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
require_once 'update_activity_middleware.php';

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
        
        // Leave requests with dual approval
        case 'apply_leave':
            applyLeave($conn);
            break;
        case 'get_my_leaves':
            getMyLeaves($conn);
            break;
        case 'get_pending_approvals':
            getPendingApprovals($conn);
            break;
        case 'manager_approve_leave':
            managerApproveLeave($conn);
            break;
        case 'admin_approve_leave':
            adminApproveLeave($conn);
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
        case 'get_all_breaks_today':
            getAllBreaksToday($conn);
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
        
        // Manager dashboard
        case 'get_team_overview':
            getTeamOverview($conn);
            break;
        case 'get_leave_requests_for_approval':
            getLeaveRequestsForApproval($conn);
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
    
    // Get telecaller details
    $stmt = $conn->prepare("SELECT name, role FROM admins WHERE id = ?");
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    $telecaller = $stmt->get_result()->fetch_assoc();
    
    if (!$telecaller) {
        echo json_encode(['success' => false, 'error' => 'Telecaller not found']);
        return;
    }
    
    $conn->begin_transaction();
    
    try {
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
                      total_online_duration = 0,
                      total_break_duration = 0
                      WHERE telecaller_id = ?";
        } else {
            // Insert new record
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
        
        // Create attendance record for today
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
        // Get login time and calculate duration
        $stmt = $conn->prepare("SELECT login_time, total_break_duration FROM telecaller_status WHERE telecaller_id = ?");
        $stmt->bind_param("i", $telecallerId);
        $stmt->execute();
        $status = $stmt->get_result()->fetch_assoc();
        
        if (!$status) {
            echo json_encode(['success' => false, 'error' => 'No active session found']);
            return;
        }
        
        // Update telecaller status
        $query = "UPDATE telecaller_status SET 
                  current_status = 'offline',
                  logout_time = NOW(),
                  total_online_duration = TIMESTAMPDIFF(SECOND, login_time, NOW()),
                  last_activity = NOW()
                  WHERE telecaller_id = ?";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("i", $telecallerId);
        $stmt->execute();
        
        // Update attendance record
        $today = date('Y-m-d');
        $query2 = "UPDATE attendance SET 
                   logout_time = NOW(),
                   total_working_hours = ROUND(TIMESTAMPDIFF(SECOND, login_time, NOW()) / 3600, 2),
                   total_break_time = ?
                   WHERE telecaller_id = ? AND date = ?";
        
        $stmt2 = $conn->prepare($query2);
        $stmt2->bind_param("iis", $status['total_break_duration'], $telecallerId, $today);
        $stmt2->execute();
        
        // End any active breaks
        $query3 = "UPDATE break_logs SET 
                   end_time = NOW(),
                   duration_seconds = TIMESTAMPDIFF(SECOND, start_time, NOW()),
                   status = 'completed'
                   WHERE caller_id = ? AND status = 'active'";
        
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
// LEAVE REQUEST FUNCTIONS WITH DUAL APPROVAL
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
    
    // Get telecaller details
    $stmt = $conn->prepare("SELECT name FROM admins WHERE id = ?");
    $stmt->bind_param("i", $telecallerId);
    $stmt->execute();
    $telecaller = $stmt->get_result()->fetch_assoc();
    
    if (!$telecaller) {
        echo json_encode(['success' => false, 'error' => 'Telecaller not found']);
        return;
    }
    
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
    $stmt->bind_param("issssds", $telecallerId, $telecaller['name'], $leaveType, $startDate, $endDate, $totalDays, $reason);
    
    if ($stmt->execute()) {
        $leaveId = $conn->insert_id;
        echo json_encode([
            'success' => true, 
            'message' => 'Leave request submitted. Awaiting manager and admin approval.',
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
                  WHEN lr.status = 'approved' THEN 'Approved'
                  WHEN lr.status = 'rejected' THEN 'Rejected'
                  WHEN lr.status = 'cancelled' THEN 'Cancelled'
                  ELSE 'Pending Approval'
              END as approval_status_text,
              lr.approved_by_name,
              lr.approval_date
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

function getPendingApprovals($conn) {
    $approverId = $_GET['approver_id'] ?? null;
    $approverRole = $_GET['approver_role'] ?? null;
    
    if (!$approverId || !$approverRole) {
        echo json_encode(['success' => false, 'error' => 'Approver ID and role required']);
        return;
    }
    
    if ($approverRole === 'manager') {
        $query = "SELECT lr.*, a.mobile, a.email
                  FROM leave_requests lr
                  INNER JOIN admins a ON lr.telecaller_id = a.id
                  WHERE a.manager_id = ? 
                  AND lr.manager_approval_status = 'pending'
                  AND lr.status = 'pending'
                  ORDER BY lr.created_at ASC";
    } else if ($approverRole === 'admin') {
        $query = "SELECT lr.*, a.mobile, a.email
                  FROM leave_requests lr
                  INNER JOIN admins a ON lr.telecaller_id = a.id
                  WHERE lr.manager_approval_status = 'approved'
                  AND lr.admin_approval_status = 'pending'
                  AND lr.status = 'pending'
                  ORDER BY lr.created_at ASC";
    } else {
        echo json_encode(['success' => false, 'error' => 'Invalid approver role']);
        return;
    }
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $approverId);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $leaves = [];
    while ($row = $result->fetch_assoc()) {
        $leaves[] = $row;
    }
    
    echo json_encode(['success' => true, 'data' => $leaves, 'count' => count($leaves)]);
}

function managerApproveLeave($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $leaveId = $input['leave_id'] ?? null;
    $managerId = $input['manager_id'] ?? null;
    $action = $input['action'] ?? 'approve'; // approve or reject
    $rejectionReason = $input['rejection_reason'] ?? '';
    
    if (!$leaveId || !$managerId) {
        echo json_encode(['success' => false, 'error' => 'Leave ID and manager ID required']);
        return;
    }
    
    // Get manager name
    $stmt = $conn->prepare("SELECT name FROM admins WHERE id = ?");
    $stmt->bind_param("i", $managerId);
    $stmt->execute();
    $managerName = $stmt->get_result()->fetch_assoc()['name'] ?? 'Unknown';
    
    if ($action === 'approve') {
        $query = "UPDATE leave_requests SET 
                  manager_approval_status = 'approved',
                  manager_approved_by = ?,
                  manager_approved_by_name = ?,
                  manager_approval_date = NOW()
                  WHERE id = ? AND manager_approval_status = 'pending'";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("isi", $managerId, $managerName, $leaveId);
        
        if ($stmt->execute() && $stmt->affected_rows > 0) {
            echo json_encode([
                'success' => true, 
                'message' => 'Leave approved by manager. Awaiting admin approval.'
            ]);
        } else {
            echo json_encode(['success' => false, 'error' => 'Failed to approve leave']);
        }
    } else {
        $query = "UPDATE leave_requests SET 
                  manager_approval_status = 'rejected',
                  status = 'rejected',
                  manager_approved_by = ?,
                  manager_approved_by_name = ?,
                  manager_approval_date = NOW(),
                  rejection_reason = ?
                  WHERE id = ? AND manager_approval_status = 'pending'";
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param("issi", $managerId, $managerName, $rejectionReason, $leaveId);
        
        if ($stmt->execute() && $stmt->affected_rows > 0) {
            echo json_encode(['success' => true, 'message' => 'Leave rejected by manager']);
        } else {
            echo json_encode(['success' => false, 'error' => 'Failed to reject leave']);
        }
    }
}

function adminApproveLeave($conn) {
    $input = json_decode(file_get_contents('php://input'), true);
    
    $leaveId = $input['leave_id'] ?? null;
    $adminId = $input['admin_id'] ?? null;
    $action = $input['action'] ?? 'approve';
    $rejectionReason = $input['rejection_reason'] ?? '';
    
    if (!$leaveId || !$adminId) {
        echo json_encode(['success' => false, 'error' => 'Leave ID and admin ID required']);
        return;
    }
    
    // Get admin name
    $stmt = $conn->prepare("SELECT name FROM admins WHERE id = ?");
    $stmt->bind_param("i", $adminId);
    $stmt->execute();
    $adminName = $stmt->get_result()->fetch_assoc()['name'] ?? 'Unknown';
    
    // Get leave details
    $stmt = $conn->prepare("SELECT telecaller_id, telecaller_name, start_date, end_date, manager_approval_status 
                            FROM leave_requests WHERE id = ?");
    $stmt->bind_param("i", $leaveId);
    $stmt->execute();
    $leaveData = $stmt->get_result()->fetch_assoc();
    
    if (!$leaveData) {
        echo json_encode(['success' => false, 'error' => 'Leave request not found']);
        return;
    }
    
    if ($leaveData['manager_approval_status'] !== 'approved') {
        echo json_encode(['success' => false, 'error' => 'Manager approval required first']);
        return;
    }
    
    $conn->begin_transaction();
    
    try {
        if ($action === 'approve') {
            // Update leave request
            $query = "UPDATE leave_requests SET 
                      admin_approval_status = 'approved',
                      status = 'approved',
                      admin_approved_by = ?,
                      admin_approved_by_name = ?,
                      admin_approval_date = NOW(),
                      approved_by = ?,
                      approved_by_name = ?,
                      approval_date = NOW()
                      WHERE id = ?";
            
            $stmt = $conn->prepare($query);
            $stmt->bind_param("isisi", $adminId, $adminName, $adminId, $adminName, $leaveId);
            $stmt->execute();
            
            // Update telecaller status
            $query2 = "UPDATE telecaller_status SET 
                       current_status = 'on_leave',
                       is_on_leave = TRUE,
                       leave_reason = CONCAT('Approved leave from ', ?, ' to ', ?)
                       WHERE telecaller_id = ?";
            
            $stmt2 = $conn->prepare($query2);
            $stmt2->bind_param("ssi", $leaveData['start_date'], $leaveData['end_date'], $leaveData['telecaller_id']);
            $stmt2->execute();
            
            // Reassign leads
            reassignLeads($conn, $leaveData['telecaller_id'], $leaveData['telecaller_name'], $leaveId, $adminId, $adminName);
            
            $conn->commit();
            
            echo json_encode([
                'success' => true, 
                'message' => 'Leave fully approved. Telecaller marked as on leave and leads reassigned.'
            ]);
        } else {
            $query = "UPDATE leave_requests SET 
                      admin_approval_status = 'rejected',
                      status = 'rejected',
                      admin_approved_by = ?,
                      admin_approved_by_name = ?,
                      admin_approval_date = NOW(),
                      rejection_reason = ?
                      WHERE id = ?";
            
            $stmt = $conn->prepare($query);
            $stmt->bind_param("issi", $adminId, $adminName, $rejectionReason, $leaveId);
            $stmt->execute();
            
            $conn->commit();
            
            echo json_encode(['success' => true, 'message' => 'Leave rejected by admin']);
        }
        
    } catch (Exception $e) {
        $conn->rollback();
        echo json_encode(['success' => false, 'error' => $e->getMessage()]);
    }
}

function rejectLeave($conn) {
    // This function can be used by both manager and admin
    $input = json_decode(file_get_contents('php://input'), true);
    
    $leaveId = $input['leave_id'] ?? null;
    $approverId = $input['approver_id'] ?? null;
    $approverRole = $input['approver_role'] ?? null;
    $rejectionReason = $input['rejection_reason'] ?? 'Not specified';
    
    if (!$leaveId || !$approverId || !$approverRole) {
        echo json_encode(['success' => false, 'error' => 'All fields required']);
        return;
    }
    
    if ($approverRole === 'manager') {
        managerApproveLeave($conn);
    } else if ($approverRole === 'admin') {
        adminApproveLeave($conn);
    } else {
        echo json_encode(['success' => false, 'error' => 'Invalid approver role']);
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
    $stmt = $conn->prepare("SELECT id FROM break_logs WHERE caller_id = ? AND status = 'active'");
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
                  (caller_id, telecaller_name, break_type, start_time, notes, status) 
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
        // Get active break
        $stmt = $conn->prepare("SELECT id, start_time FROM break_logs WHERE caller_id = ? AND status = 'active'");
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
              (SELECT COUNT(*) FROM break_logs WHERE caller_id = ts.telecaller_id AND DATE(start_time) = CURDATE()) as today_breaks,
              (SELECT leave_type FROM leave_requests WHERE telecaller_id = ts.telecaller_id AND status = 'approved' AND CURDATE() BETWEEN start_date AND end_date LIMIT 1) as current_leave_type
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
    $managerId = $_GET['manager_id'] ?? null;
    
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
              (SELECT COUNT(*) FROM break_logs WHERE caller_id = ts.telecaller_id AND DATE(start_time) = CURDATE()) as today_breaks,
              (SELECT leave_type FROM leave_requests WHERE telecaller_id = ts.telecaller_id AND status = 'approved' AND CURDATE() BETWEEN start_date AND end_date LIMIT 1) as current_leave_type
              FROM telecaller_status ts
              INNER JOIN admins a ON ts.telecaller_id = a.id
              WHERE a.role = 'telecaller'";
    
    if ($managerId) {
        $query .= " AND a.manager_id = $managerId";
    }
    
    $query .= " ORDER BY 
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
// MANAGER DASHBOARD FUNCTIONS
// ═══════════════════════════════════════════════════════════════

function getTeamOverview($conn) {
    $managerId = $_GET['manager_id'] ?? null;
    
    if (!$managerId) {
        echo json_encode(['success' => false, 'error' => 'Manager ID required']);
        return;
    }
    
    // Get team statistics
    $query = "SELECT 
              COUNT(DISTINCT a.id) as total_telecallers,
              COUNT(DISTINCT CASE WHEN ts.current_status = 'online' THEN a.id END) as online_count,
              COUNT(DISTINCT CASE WHEN ts.current_status = 'offline' THEN a.id END) as offline_count,
              COUNT(DISTINCT CASE WHEN ts.current_status = 'on_call' THEN a.id END) as on_call_count,
              COUNT(DISTINCT CASE WHEN ts.current_status = 'break' THEN a.id END) as on_break_count,
              COUNT(DISTINCT CASE WHEN ts.is_on_leave = TRUE THEN a.id END) as on_leave_count,
              SUM(CASE WHEN DATE(att.date) = CURDATE() THEN att.total_calls ELSE 0 END) as today_total_calls,
              SUM(CASE WHEN DATE(att.date) = CURDATE() THEN att.connected_calls ELSE 0 END) as today_connected_calls
              FROM admins a
              LEFT JOIN telecaller_status ts ON a.id = ts.telecaller_id
              LEFT JOIN attendance att ON a.id = att.telecaller_id
              WHERE a.role = 'telecaller' AND a.manager_id = ?";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("i", $managerId);
    $stmt->execute();
    $stats = $stmt->get_result()->fetch_assoc();
    
    // Get pending leave requests
    $query2 = "SELECT COUNT(*) as pending_leaves
               FROM leave_requests lr
               INNER JOIN admins a ON lr.telecaller_id = a.id
               WHERE a.manager_id = ? 
               AND lr.manager_approval_status = 'pending'
               AND lr.status = 'pending'";
    
    $stmt2 = $conn->prepare($query2);
    $stmt2->bind_param("i", $managerId);
    $stmt2->execute();
    $leaveStats = $stmt2->get_result()->fetch_assoc();
    
    echo json_encode([
        'success' => true, 
        'data' => array_merge($stats, $leaveStats)
    ]);
}

function getLeaveRequestsForApproval($conn) {
    $managerId = $_GET['manager_id'] ?? null;
    $status = $_GET['status'] ?? null;
    
    $query = "SELECT lr.*, 
              a.name as telecaller_name,
              a.mobile, a.email,
              DATEDIFF(lr.start_date, CURDATE()) as days_until_leave
              FROM leave_requests lr
              INNER JOIN admins a ON lr.telecaller_id = a.id";
    
    $conditions = [];
    $params = [];
    $types = "";
    
    // Filter by manager if provided
    if ($managerId) {
        $conditions[] = "a.manager_id = ?";
        $params[] = $managerId;
        $types .= "i";
    }
    
    // Filter by status
    if ($status === 'pending') {
        $conditions[] = "lr.manager_approval_status = 'pending' AND lr.status = 'pending'";
    } else if ($status === 'approved') {
        $conditions[] = "lr.manager_approval_status = 'approved'";
    } else if ($status === 'rejected') {
        $conditions[] = "lr.manager_approval_status = 'rejected'";
    } else if ($status) {
        $conditions[] = "lr.status = ?";
        $params[] = $status;
        $types .= "s";
    }
    
    if (!empty($conditions)) {
        $query .= " WHERE " . implode(" AND ", $conditions);
    }
    
    $query .= " ORDER BY lr.created_at DESC";
    
    $stmt = $conn->prepare($query);
    
    if (!empty($params)) {
        $stmt->bind_param($types, ...$params);
    }
    
    $stmt->execute();
    $result = $stmt->get_result();
    
    $leaves = [];
    while ($row = $result->fetch_assoc()) {
        $leaves[] = $row;
    }
    
    echo json_encode(['success' => true, 'data' => $leaves, 'count' => count($leaves)]);
}


// ═══════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════

function reassignLeads($conn, $fromTelecallerId, $fromTelecallerName, $leaveRequestId, $approvedBy, $approverName) {
    // Get all pending/callback leads
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
    
    // Get available telecallers
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
    
    // Distribute leads
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

function getAllBreaksToday($conn) {
    $today = date('Y-m-d');
    
    $query = "SELECT bl.*, 
              CASE 
                  WHEN bl.status = 'active' THEN TIMESTAMPDIFF(SECOND, bl.start_time, NOW())
                  ELSE bl.duration_seconds
              END as current_duration_seconds,
              CASE 
                  WHEN bl.status = 'active' THEN SEC_TO_TIME(TIMESTAMPDIFF(SECOND, bl.start_time, NOW()))
                  ELSE bl.duration_formatted
              END as current_duration_formatted
              FROM break_logs bl
              WHERE DATE(bl.start_time) = ?
              ORDER BY bl.start_time DESC";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param("s", $today);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $breaks = [];
    while ($row = $result->fetch_assoc()) {
        $breaks[] = $row;
    }
    
    echo json_encode(['success' => true, 'data' => $breaks]);
}
