<?php
/**
 * Toll-Free Feedback API
 * Saves call feedback for toll-free calls with tc_for='toll-free'
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit;
}

require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
    $pdo->exec("SET time_zone = '+05:30'");
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database connection failed']);
    exit;
}

$action = $_GET['action'] ?? 'submit_feedback';

if ($_SERVER['REQUEST_METHOD'] === 'POST' && $action === 'submit_feedback') {
    submitFeedback($pdo);
} elseif ($_SERVER['REQUEST_METHOD'] === 'GET' && $action === 'get_history') {
    getCallHistory($pdo);
} else {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
}

function submitFeedback($pdo) {
    try {
        $input = json_decode(file_get_contents('php://input'), true);
        
        // NO RESTRICTIONS - Any telecaller can submit feedback
        $callerId = $input['caller_id'] ?? null;
        $leadId = $input['lead_id'] ?? null;
        $name = $input['name'] ?? '';
        $mobile = $input['mobile'] ?? '';
        $feedback = $input['feedback'] ?? '';
        $remarks = $input['remarks'] ?? '';
        
        if (!$callerId || !$leadId) {
            echo json_encode([
                'success' => false,
                'message' => 'caller_id and lead_id are required'
            ]);
            return;
        }
        
        // Get user's TMID and role
        $userSql = "SELECT unique_id, role FROM users WHERE id = :lead_id LIMIT 1";
        $userStmt = $pdo->prepare($userSql);
        $userStmt->execute(['lead_id' => $leadId]);
        $user = $userStmt->fetch();
        
        $tmid = $user['unique_id'] ?? '';
        $role = $user['role'] ?? 'driver';
        
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
        $stmt->execute([
            'caller_id' => $callerId,
            'user_id' => $leadId,
            'user_number' => $mobile,
            'driver_name' => $name,
            'feedback' => $feedback,
            'remarks' => $remarks,
            'call_status' => mapFeedbackToStatus($feedback),
            'tmid' => $tmid
        ]);
        
        $callLogId = $pdo->lastInsertId();
        
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
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to save feedback: ' . $e->getMessage()
        ]);
    }
}

function getCallHistory($pdo) {
    try {
        $callerId = $_GET['caller_id'] ?? null;
        $limit = (int)($_GET['limit'] ?? 50);
        
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
        
        echo json_encode([
            'success' => true,
            'data' => $history,
            'count' => count($history)
        ]);
        
    } catch(Exception $e) {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => 'Failed to fetch history: ' . $e->getMessage()
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
