<?php
require_once 'config.php';

header('Content-Type: application/json');

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    getNextLead();
} else {
    sendError('Method not allowed', 405);
}

function getNextLead() {
    global $conn;
    
    try {
        // Use 'id' parameter from admin panel
        $telecaller_id = (int)($_GET['id'] ?? $_GET['telecaller_id'] ?? 0);
        
        if (!$telecaller_id) {
            sendError('Telecaller ID required');
        }
        
        // Get telecaller info
        $telecaller = getTelecallerInfo($telecaller_id);
        
        if (!$telecaller) {
            sendError('Telecaller not found');
        }
        
        $type = $telecaller['telecaller_type'];
        $level = $telecaller['calling_level'];
        
        // Get next telecaller in round-robin for this type+level
        $next_telecaller = getNextTelecallerInRoundRobin($type, $level);
        
        // Only assign if it's this telecaller's turn
        if ($next_telecaller != $telecaller_id) {
            sendError('Not your turn. Wait for round-robin assignment.');
        }
        
        // Get lead based on level
        if ($level == 1) {
            $lead = getFreshLead($type);
        } else {
            $lead = getFollowUpLead($type, $level);
        }
        
        if ($lead) {
            // Update round-robin tracker
            updateRoundRobinTracker($type, $level, $telecaller_id);
            sendSuccess($lead);
        } else {
            sendError('No leads available');
        }
    } catch (Exception $e) {
        error_log('Tiered Lead Assignment Error: ' . $e->getMessage());
        sendError('Internal server error: ' . $e->getMessage(), 500);
    }
}

function getTelecallerInfo($telecaller_id) {
    global $conn;
    
    // Check admins table (where telecallers are stored)
    $query = "SELECT id, name, telecaller_type, calling_level 
              FROM admins 
              WHERE id = ? AND role = 'telecaller'";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param('i', $telecaller_id);
    $stmt->execute();
    $result = $stmt->get_result();
    
    return $result->fetch_assoc();
}

function getFreshLead($type) {
    global $conn;
    
    // Get fresh leads that haven't been called yet
    $query = "SELECT u.* 
              FROM users u
              WHERE u.user_type = ?
              AND u.role = 'user'
              AND u.id NOT IN (SELECT DISTINCT user_id FROM call_logs WHERE user_id IS NOT NULL)
              ORDER BY u.created_at ASC
              LIMIT 1";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param('s', $type);
    $stmt->execute();
    $result = $stmt->get_result();
    
    return $result->fetch_assoc();
}

function getFollowUpLead($type, $level) {
    global $conn;
    
    // Get leads that were called by previous level
    $previous_level = $level - 1;
    
    // Days to look back based on level
    $days_back = [
        2 => 7,   // Level 2: Follow up after 7 days
        3 => 14,  // Level 3: Re-engage after 14 days
        4 => 30   // Level 4: Final attempt after 30 days
    ];
    
    $days = $days_back[$level] ?? 7;
    
    // Join with admins table (where telecallers are stored)
    $query = "SELECT u.*, 
              MAX(cl.created_at) as last_call_date,
              COUNT(cl.id) as call_count
              FROM users u
              INNER JOIN call_logs cl ON u.id = cl.user_id
              INNER JOIN admins tc ON cl.telecaller_id = tc.id
              WHERE u.user_type = ?
              AND tc.calling_level = ?
              AND cl.call_status IN ('not_interested', 'no_response', 'call_back_later')
              AND cl.created_at >= DATE_SUB(NOW(), INTERVAL ? DAY)
              AND cl.created_at <= DATE_SUB(NOW(), INTERVAL ? DAY)
              GROUP BY u.id
              ORDER BY last_call_date ASC
              LIMIT 1";
    
    $stmt = $conn->prepare($query);
    $min_days = $days - 3; // Start calling 3 days before target
    $stmt->bind_param('siii', $type, $previous_level, $days, $min_days);
    $stmt->execute();
    $result = $stmt->get_result();
    
    return $result->fetch_assoc();
}

function getNextTelecallerInRoundRobin($type, $level) {
    global $conn;
    
    // Get all telecallers for this type and level from admins table
    $query = "SELECT id FROM admins 
              WHERE role = 'telecaller' 
              AND telecaller_type = ?
              AND calling_level = ?
              ORDER BY id ASC";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param('si', $type, $level);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $telecallers = [];
    while ($row = $result->fetch_assoc()) {
        $telecallers[] = $row['id'];
    }
    
    if (empty($telecallers)) {
        return null;
    }
    
    // Get last assigned telecaller
    $tracker_query = "SELECT last_assigned_telecaller_id 
                      FROM lead_assignment_tracker 
                      WHERE telecaller_type = ? AND calling_level = ?";
    
    $stmt = $conn->prepare($tracker_query);
    $stmt->bind_param('si', $type, $level);
    $stmt->execute();
    $tracker_result = $stmt->get_result();
    $tracker = $tracker_result->fetch_assoc();
    
    $last_assigned = $tracker['last_assigned_telecaller_id'] ?? null;
    
    // Find next telecaller in round-robin
    if ($last_assigned) {
        $current_index = array_search($last_assigned, $telecallers);
        $next_index = ($current_index + 1) % count($telecallers);
        return $telecallers[$next_index];
    }
    
    // First assignment
    return $telecallers[0];
}

function updateRoundRobinTracker($type, $level, $telecaller_id) {
    global $conn;
    
    $query = "INSERT INTO lead_assignment_tracker (telecaller_type, calling_level, last_assigned_telecaller_id, updated_at)
              VALUES (?, ?, ?, NOW())
              ON DUPLICATE KEY UPDATE 
              last_assigned_telecaller_id = ?,
              updated_at = NOW()";
    
    $stmt = $conn->prepare($query);
    $stmt->bind_param('siii', $type, $level, $telecaller_id, $telecaller_id);
    $stmt->execute();
}
