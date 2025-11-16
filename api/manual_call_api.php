<?php
/**
 * Manual Call API
 * Logs manual phone calls (direct dialing without IVR)
 * Saves to same database structure as IVR calls
 */

error_reporting(0);
ini_set('display_errors', '0');

if (ob_get_level()) {
    ob_end_clean();
}
ob_start();

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

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
    if (ob_get_level()) {
        ob_end_clean();
    }
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Database connection failed']);
    exit;
}

$action = $_GET['action'] ?? 'initiate_call';

switch($action) {
    case 'initiate_call':
        initiateManualCall($pdo);
        break;
    case 'update_feedback':
        updateCallFeedback($pdo);
        break;
    default:
        echo json_encode(['success' => false, 'error' => 'Invalid action']);
}

$output = ob_get_clean();
echo $output;

/**
 * Log manual call initiation
 */
function initiateManualCall($pdo) {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $rawInput = file_get_contents('php://input');
        $input = json_decode($rawInput, true);
        error_log('Manual Call POST input: ' . $rawInput);
    } else if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $input = $_GET;
        error_log('Manual Call GET input: ' . json_encode($input));
    } else {
        echo json_encode(['success' => false, 'error' => 'Method not allowed']);
        return;
    }
    
    $driverMobile = $input['driver_mobile'] ?? '';
    $callerId = (int)($input['caller_id'] ?? 0);
    $driverId = (int)($input['driver_id'] ?? 0);
    
    error_log("📱 Manual Call - Driver Mobile: $driverMobile, Caller ID: $callerId, Driver ID: $driverId");
    
    if (empty($callerId)) {
        echo json_encode([
            'success' => false, 
            'error' => 'Caller ID required',
            'received' => [
                'driver_mobile' => $driverMobile,
                'caller_id' => $callerId,
                'driver_id' => $driverId
            ]
        ]);
        return;
    }
    
    try {
        // Get telecaller info
        $stmt = $pdo->prepare("SELECT mobile, name FROM admins WHERE id = ?");
        $stmt->execute([$callerId]);
        $telecaller = $stmt->fetch();
        
        if (!$telecaller) {
            echo json_encode([
                'success' => false,
                'error' => 'Telecaller not found',
                'caller_id' => $callerId
            ]);
            return;
        }
        
        // Get driver info - try by mobile first, then by ID
        if (!empty($driverMobile)) {
            $stmt = $pdo->prepare("SELECT id, name, mobile, role FROM users WHERE mobile = ? AND role IN ('driver', 'transporter')");
            $stmt->execute([$driverMobile]);
            $driver = $stmt->fetch();
        } else if (!empty($driverId)) {
            // If mobile not provided, fetch by driver ID
            $stmt = $pdo->prepare("SELECT id, name, mobile, role FROM users WHERE id = ? AND role IN ('driver', 'transporter')");
            $stmt->execute([$driverId]);
            $driver = $stmt->fetch();
        } else {
            echo json_encode([
                'success' => false,
                'error' => 'Driver mobile or driver ID required'
            ]);
            return;
        }
        
        if (!$driver) {
            echo json_encode([
                'success' => false,
                'error' => 'User not found',
                'driver_mobile' => $driverMobile
            ]);
            return;
        }
        
        // Clean phone numbers
        $driverMobile = preg_replace('/[^0-9]/', '', $driver['mobile']);
        $telecallerMobile = preg_replace('/[^0-9]/', '', $telecaller['mobile']);
        
        if (strlen($driverMobile) > 10) {
            $driverMobile = substr($driverMobile, -10);
        }
        if (strlen($telecallerMobile) > 10) {
            $telecallerMobile = substr($telecallerMobile, -10);
        }
        
        $driverNumber = '+91' . $driverMobile;
        $telecallerNumber = '+91' . $telecallerMobile;
        
        // Generate unique reference ID for manual call
        $referenceId = 'MANUAL_' . time() . '_' . $callerId . '_' . $driver['id'];
        
        error_log('📞 Manual Call Setup: Driver=' . $driverNumber . ', Telecaller=' . $telecallerNumber);
        
        // Save to call_logs (same structure as IVR) with IST timezone
        $sql = "INSERT INTO call_logs 
                (caller_id, user_id, caller_number, user_number, driver_name, call_status, 
                 reference_id, api_response, call_time, created_at, updated_at) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, CONVERT_TZ(NOW(), '+00:00', '+05:30'), CONVERT_TZ(NOW(), '+00:00', '+05:30'), CONVERT_TZ(NOW(), '+00:00', '+05:30'))";
        
        $apiResponse = json_encode([
            'type' => 'manual',
            'status' => 'initiated',
            'message' => 'Manual call logged successfully',
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            $callerId,
            $driver['id'],
            $telecallerNumber,
            $driverNumber,
            $driver['name'],
            'pending',
            $referenceId,
            $apiResponse
        ]);
        
        $callLogId = $pdo->lastInsertId();
        
        error_log('✅ Manual call logged - ID: ' . $callLogId . ', Ref: ' . $referenceId);
        
        $responseData = [
            'success' => true,
            'message' => '📱 Manual call logged successfully',
            'call_type' => 'manual',
            'data' => [
                'call_log_id' => $callLogId,
                'reference_id' => $referenceId,
                'status' => 'initiated',
                'driver_name' => $driver['name'],
                'driver_number' => $driverNumber,
                'driver_mobile_raw' => $driverMobile,
                'telecaller_name' => $telecaller['name'],
                'telecaller_number' => $telecallerNumber,
                'instructions' => [
                    'step1' => '📱 Phone dialer will open automatically',
                    'step2' => '📞 Make the call manually',
                    'step3' => '✅ After call ends, submit feedback',
                    'step4' => '💾 Feedback will be saved to database'
                ]
            ],
            'timestamp' => date('Y-m-d H:i:s')
        ];
        
        error_log('📤 Manual call response: ' . json_encode($responseData));
        
        echo json_encode($responseData);
        
    } catch(Exception $e) {
        error_log('❌ Manual call error: ' . $e->getMessage());
        echo json_encode([
            'success' => false,
            'error' => 'Failed to log manual call: ' . $e->getMessage()
        ]);
    }
}

/**
 * Update call feedback after call completion
 */
function updateCallFeedback($pdo) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        echo json_encode(['success' => false, 'error' => 'Method not allowed']);
        return;
    }
    
    $rawInput = file_get_contents('php://input');
    $input = json_decode($rawInput, true);
    
    error_log("📝 Manual Call Update Feedback Raw Input: " . $rawInput);
    
    $referenceId = $input['reference_id'] ?? '';
    $callStatus = $input['call_status'] ?? 'pending';
    $feedback = $input['feedback'] ?? null;
    $remarks = $input['remarks'] ?? null;
    $callDuration = $input['call_duration'] ?? 0;
    
    error_log("📝 Manual Call Update Feedback Parsed: ref=$referenceId, status=$callStatus, feedback=$feedback, remarks=$remarks, duration=$callDuration");
    
    if (empty($referenceId)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Reference ID required']);
        return;
    }
    
    // Validate call_status
    $validStatuses = ['pending', 'connected', 'callback', 'callback_later', 'not_reachable', 'not_interested', 'invalid', 'completed', 'failed', 'cancelled'];
    if (!in_array($callStatus, $validStatuses)) {
        error_log("⚠️ Invalid call status: $callStatus, defaulting to 'pending'");
        $callStatus = 'pending';
    }
    
    try {
        // First check if the reference_id exists
        $checkSql = "SELECT id, call_status, feedback FROM call_logs WHERE reference_id = ?";
        $checkStmt = $pdo->prepare($checkSql);
        $checkStmt->execute([$referenceId]);
        $existingRecord = $checkStmt->fetch();
        
        if (!$existingRecord) {
            error_log("❌ No record found with reference_id: $referenceId");
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'error' => 'Call log not found with reference_id: ' . $referenceId
            ]);
            return;
        }
        
        error_log("📋 Existing record: ID={$existingRecord['id']}, Status={$existingRecord['call_status']}, Feedback={$existingRecord['feedback']}");
        
        // Update call log with IST timezone
        $sql = "UPDATE call_logs 
                SET call_status = ?, 
                    feedback = ?, 
                    remarks = ?,
                    call_duration = ?,
                    updated_at = CONVERT_TZ(NOW(), '+00:00', '+05:30')
                WHERE reference_id = ?";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([$callStatus, $feedback, $remarks, $callDuration, $referenceId]);
        
        $rowsAffected = $stmt->rowCount();
        error_log("✅ Manual Call Update Feedback: $rowsAffected rows affected for ref=$referenceId");
        
        // Fetch updated record to confirm
        $checkStmt->execute([$referenceId]);
        $updatedRecord = $checkStmt->fetch();
        error_log("📋 Updated record: Status={$updatedRecord['call_status']}, Feedback={$updatedRecord['feedback']}");
        
        echo json_encode([
            'success' => true,
            'message' => 'Call feedback updated successfully',
            'rows_affected' => $rowsAffected,
            'data' => [
                'call_log_id' => $updatedRecord['id'],
                'call_status' => $updatedRecord['call_status'],
                'feedback' => $updatedRecord['feedback'],
                'reference_id' => $referenceId
            ],
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        error_log("❌ Manual Call Update Feedback Error: " . $e->getMessage());
        http_response_code(500);
        echo json_encode(['success' => false, 'error' => 'Failed to update feedback: ' . $e->getMessage()]);
    }
}
?>
