<?php
/**
 * Toll-Free Feedback API
 * Saves call feedback for toll-free calls with tc_for='toll-free'
 */

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 0);  // Don't display, but log
ini_set('log_errors', 1);

require_once 'config.php';

// config.php already sets headers and creates $pdo connection

// Log the request
error_log('=== Toll-Free Feedback API Request ===');
error_log('Method: ' . $_SERVER['REQUEST_METHOD']);
error_log('Action: ' . ($_GET['action'] ?? 'none'));
error_log('Raw Input: ' . file_get_contents('php://input'));

try {
    $action = $_GET['action'] ?? 'submit_feedback';

    if ($_SERVER['REQUEST_METHOD'] === 'POST' && $action === 'submit_feedback') {
        submitFeedback($pdo);
    } elseif ($_SERVER['REQUEST_METHOD'] === 'GET' && $action === 'get_history') {
        getCallHistory($pdo);
    } else {
        http_response_code(405);
        echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    }
} catch (Throwable $e) {
    error_log('FATAL ERROR in toll_free_feedback_api.php: ' . $e->getMessage());
    error_log('Stack trace: ' . $e->getTraceAsString());
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Server error: ' . $e->getMessage(),
        'error' => $e->getMessage(),
        'line' => $e->getLine(),
        'file' => basename($e->getFile())
    ]);
}

function submitFeedback($pdo) {
    try {
        $rawInput = file_get_contents('php://input');
        error_log('Toll-Free Feedback Raw Input: ' . $rawInput);
        
        $input = json_decode($rawInput, true);
        
        if (json_last_error() !== JSON_ERROR_NONE) {
            echo json_encode([
                'success' => false,
                'message' => 'Invalid JSON: ' . json_last_error_msg()
            ]);
            return;
        }
        
        // NO RESTRICTIONS - Any telecaller can submit feedback
        $callerId = $input['caller_id'] ?? null;
        $leadId = $input['lead_id'] ?? null;
        $name = $input['name'] ?? '';
        $mobile = $input['mobile'] ?? '';
        $feedback = $input['feedback'] ?? '';
        $remarks = $input['remarks'] ?? '';
        
        error_log('Parsed data - caller_id: ' . $callerId . ', lead_id: ' . $leadId);
        
        if (!$callerId || !$leadId) {
            echo json_encode([
                'success' => false,
                'message' => 'caller_id and lead_id are required',
                'received' => [
                    'caller_id' => $callerId,
                    'lead_id' => $leadId
                ]
            ]);
            return;
        }
        
        // Get user's TMID and role
        $userSql = "SELECT unique_id, role FROM users WHERE id = :lead_id LIMIT 1";
        $userStmt = $pdo->prepare($userSql);
        $userStmt->execute(['lead_id' => $leadId]);
        $user = $userStmt->fetch();
        
        if (!$user) {
            error_log('User not found with ID: ' . $leadId);
            echo json_encode([
                'success' => false,
                'message' => 'User not found with ID: ' . $leadId
            ]);
            return;
        }
        
        $tmid = $user['unique_id'] ?? '';
        $role = $user['role'] ?? 'driver';
        
        error_log('User found - TMID: ' . $tmid . ', Role: ' . $role);
        
        // Insert into call_logs table with tc_for='toll-free'
        // This ensures it appears in call history with toll-free filter
        $sql = "INSERT INTO call_logs (
                    caller_id,
                    user_id,
                    user_number,
                    driver_name,
                    feedback,
                    remarks,
                    call_status,
                    call_time,
                    tc_for,
                    unique_id_driver,
                    call_source
                ) VALUES (
                    :caller_id,
                    :user_id,
                    :user_number,
                    :driver_name,
                    :feedback,
                    :remarks,
                    :call_status,
                    NOW(),
                    'toll-free',
                    :tmid,
                    'toll-free'
                )";
        
        $stmt = $pdo->prepare($sql);
        
        $callStatus = mapFeedbackToStatus($feedback);
        error_log('Inserting call log - Status: ' . $callStatus);
        
        $stmt->execute([
            'caller_id' => $callerId,
            'user_id' => $leadId,
            'user_number' => $mobile,
            'driver_name' => $name,
            'feedback' => $feedback,
            'remarks' => $remarks,
            'call_status' => $callStatus,
            'tmid' => $tmid
        ]);
        
        $callLogId = $pdo->lastInsertId();
        error_log('Call log inserted with ID: ' . $callLogId);
        
        echo json_encode([
            'success' => true,
            'message' => 'Feedback saved successfully - No restrictions applied',
            'data' => [
                'id' => $callLogId,
                'caller_id' => $callerId,
                'user_id' => $leadId,
                'tmid' => $tmid,
                'role' => $role,
                'feedback' => $feedback,
                'tc_for' => 'toll-free',
                'call_source' => 'toll-free',
                'message' => 'Any telecaller can submit toll-free feedback'
            ]
        ]);
        
    } catch(Exception $e) {
        error_log('Toll-Free Feedback Error: ' . $e->getMessage());
        error_log('Stack trace: ' . $e->getTraceAsString());
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to save feedback: ' . $e->getMessage(),
            'error_details' => $e->getMessage(),
            'line' => $e->getLine(),
            'file' => basename($e->getFile())
        ]);
    }
}

function getCallHistory($pdo) {
    try {
        $callerId = $_GET['caller_id'] ?? null;
        $limit = (int)($_GET['limit'] ?? 50);
        
        error_log('Fetching toll-free history for caller_id: ' . $callerId);
        
        if (!$callerId) {
            echo json_encode([
                'success' => false,
                'message' => 'caller_id is required'
            ]);
            return;
        }
        
        $sql = "SELECT 
                    cl.*,
                    u.unique_id as tmid,
                    u.name as user_name,
                    u.mobile as user_mobile,
                    u.role as user_role
                FROM call_logs cl
                LEFT JOIN users u ON cl.user_id = u.id
                WHERE cl.caller_id = :caller_id 
                AND cl.tc_for = 'toll-free'
                ORDER BY cl.call_time DESC
                LIMIT :limit";
        
        $stmt = $pdo->prepare($sql);
        $stmt->bindValue(':caller_id', $callerId, PDO::PARAM_INT);
        $stmt->bindValue(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
        
        $history = $stmt->fetchAll();
        
        error_log('Fetched ' . count($history) . ' toll-free call records');
        
        echo json_encode([
            'success' => true,
            'data' => $history,
            'count' => count($history)
        ]);
        
    } catch(Exception $e) {
        error_log('Toll-Free History Error: ' . $e->getMessage());
        error_log('Stack trace: ' . $e->getTraceAsString());
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to fetch history: ' . $e->getMessage(),
            'error_details' => $e->getMessage()
        ]);
    }
}

function mapFeedbackToStatus($feedback) {
    $feedback = strtolower($feedback);
    
    if (strpos($feedback, 'connected') !== false || strpos($feedback, 'interested') !== false) {
        return 'connected';
    } elseif (strpos($feedback, 'call back') !== false || strpos($feedback, 'callback') !== false) {
        return 'callback';
    } elseif (strpos($feedback, 'not interested') !== false) {
        return 'not_interested';
    } elseif (strpos($feedback, 'not reachable') !== false || strpos($feedback, 'no answer') !== false) {
        return 'not_reachable';
    } elseif (strpos($feedback, 'invalid') !== false || strpos($feedback, 'wrong number') !== false) {
        return 'invalid';
    } else {
        return 'pending';
    }
}
?>
