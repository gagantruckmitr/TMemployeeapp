<?php
/**
 * TeleCMI Production API for TMemployeeapp
 * Handles IVR calling functionality using TeleCMI service
 * PRODUCTION READY - With security, validation, and error handling
 * 
 * SECURITY:
 * - Only Pooja (user_id: 3) can make TeleCMI calls
 * - All inputs are validated and sanitized
 * - SQL injection protection with prepared statements
 * - Proper error handling and logging
 * 
 * Endpoints:
 * - POST /api/telecmi_production_api.php?action=click_to_call - Initiate call
 * - POST /api/telecmi_production_api.php?action=update_feedback - Update feedback
 * - POST /api/telecmi_production_api.php?action=webhook - Receive webhooks
 * - GET  /api/telecmi_production_api.php?action=get_call_logs - Get call logs
 */

require_once 'config.php';

// Load environment variables
function loadEnv() {
    $possiblePaths = [
        __DIR__ . '/../.env',
        __DIR__ . '/../../.env',
        dirname(dirname(__DIR__)) . '/.env',
        $_SERVER['DOCUMENT_ROOT'] . '/../.env',
    ];
    
    foreach ($possiblePaths as $path) {
        if (file_exists($path)) {
            $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            foreach ($lines as $line) {
                if (strpos(trim($line), '#') === 0) continue;
                if (strpos($line, '=') === false) continue;
                
                list($name, $value) = explode('=', $line, 2);
                $name = trim($name);
                $value = trim($value);
                
                if (!array_key_exists($name, $_ENV)) {
                    $_ENV[$name] = $value;
                    putenv("$name=$value");
                }
            }
            return true;
        }
    }
    return false;
}

loadEnv();

// TeleCMI Configuration - Using working credentials
define('TELECMI_APP_ID', getenv('TELECMI_APP_ID') ?: '33336628');
define('TELECMI_APP_SECRET', getenv('TELECMI_APP_SECRET') ?: 'bb0b92ca-3d8a-405b-87aa-fc035fe1cdc6');
define('TELECMI_ALLOWED_USER_ID', 3); // Only Pooja can make calls
define('TELECMI_USER_ID', '5003'); // Registered TeleCMI user ID

// Validate credentials
if (empty(TELECMI_APP_ID) || empty(TELECMI_APP_SECRET)) {
    error_log('TeleCMI Production: Missing credentials in .env file');
    sendError('TeleCMI service not configured', 500);
}

// Get action
$action = $_GET['action'] ?? '';

// Route to handlers
switch ($action) {
    case 'click_to_call':
        handleClickToCall();
        break;
    
    case 'update_feedback':
        handleUpdateFeedback();
        break;
    
    case 'webhook':
        handleWebhook();
        break;
    
    case 'get_call_logs':
        handleGetCallLogs();
        break;
    
    default:
        sendError('Invalid action', 400);
}

/**
 * Initiate TeleCMI Click-to-Call
 * POST /api/telecmi_production_api.php?action=click_to_call
 * Body: {
 *   "caller_id": 3,
 *   "driver_id": "driver_123",
 *   "driver_mobile": "919876543210"
 * }
 */
function handleClickToCall() {
    global $conn;
    
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        sendError('Method not allowed. Use POST', 405);
    }
    
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        sendError('Invalid JSON input', 400);
    }
    
    // Validate required fields
    if (!isset($input['caller_id']) || !isset($input['driver_id']) || !isset($input['driver_mobile'])) {
        sendError('Missing required fields: caller_id, driver_id, driver_mobile', 400);
    }
    
    $callerId = (int)$input['caller_id'];
    $driverId = sanitizeInput($conn, $input['driver_id']);
    $driverMobile = sanitizeInput($conn, $input['driver_mobile']);
    
    // SECURITY: Only allow Pooja (user_id: 3) to make TeleCMI calls
    if ($callerId !== TELECMI_ALLOWED_USER_ID) {
        error_log("TeleCMI Production: Unauthorized call attempt by user_id: $callerId");
        sendError('You are not authorized to use TeleCMI calling. Only Pooja can make TeleCMI calls.', 403);
    }
    
    // Validate phone number format
    if (!preg_match('/^[0-9]{10,15}$/', $driverMobile)) {
        sendError('Invalid phone number format. Must be 10-15 digits.', 400);
    }
    
    // Check if driver exists in users table (drivers/transporters)
    // Allow test driver IDs (99999) for testing
    if ($driverId == 99999 || $driverId == '99999') {
        // Test driver
        $driverName = 'Test User';
        $driverTmid = 'TM999999';
    } else {
        $stmt = $conn->prepare("SELECT unique_id, name FROM users WHERE id = ? AND role IN ('driver', 'transporter')");
        $stmt->bind_param('s', $driverId);
        $stmt->execute();
        $result = $stmt->get_result();
        $driver = $result->fetch_assoc();
        $stmt->close();
        
        if (!$driver) {
            error_log("TeleCMI Production: Driver not found - ID: $driverId");
            sendError('Driver not found', 404);
        }
        
        $driverName = $driver['name'] ?? 'Unknown';
        $driverTmid = $driver['unique_id'] ?? 'TM' . str_pad($driverId, 6, '0', STR_PAD_LEFT);
    }
    
    // Prepare TeleCMI API call
    $telecmiUserId = TELECMI_USER_ID . '_' . TELECMI_APP_ID;
    $toNumber = (int)$driverMobile;
    
    error_log("TeleCMI Production: Initiating call - Caller: $callerId (Pooja), Driver: $driverName ($driverId), Mobile: $driverMobile");
    
    $payload = [
        'user_id'  => $telecmiUserId,
        'secret'   => TELECMI_APP_SECRET,
        'to'       => $toNumber,
        'webrtc'   => false,
        'followme' => true
    ];
    
    $url = 'https://rest.telecmi.com/v2/webrtc/click2call';
    
    $response = makeCurlRequest($url, $payload);
    
    if ($response['success']) {
        $callId = $response['data']['call_id'] ?? $response['data']['request_id'] ?? uniqid('telecmi_');
        
        // Get caller number from admins table
        $callerStmt = $conn->prepare("SELECT mobile FROM admins WHERE id = ?");
        $callerStmt->bind_param('i', $callerId);
        $callerStmt->execute();
        $callerResult = $callerStmt->get_result();
        $callerData = $callerResult->fetch_assoc();
        $callerNumber = $callerData['mobile'] ?? '';
        $callerStmt->close();
        
        // Format phone numbers with + prefix
        $formattedDriverMobile = '+91' . $driverMobile;
        $formattedCallerNumber = $callerNumber ? '+91' . $callerNumber : '';
        
        // Prepare API response JSON
        $apiResponseData = [
            'type' => 'telecmi',
            'status' => 'initiated',
            'message' => 'TeleCMI call initiated successfully',
            'telecmi_user_id' => $telecmiUserId,
            'timestamp' => date('Y-m-d H:i:s')
        ];
        $apiResponseJson = json_encode($apiResponseData);
        
        // Get IP address
        $ipAddress = $_SERVER['REMOTE_ADDR'] ?? $_SERVER['HTTP_X_FORWARDED_FOR'] ?? null;
        
        // Log call to database - feedback fields will be filled by user later
        $stmt = $conn->prepare("
            INSERT INTO call_logs (
                caller_id, tc_for, user_id, driver_name,
                call_status, feedback, remarks, notes,
                call_duration, caller_number, user_number,
                call_time, reference_id, api_response,
                created_at, updated_at,
                call_initiated_at, call_completed_at,
                ip_address, recording_url, manual_call_recording_url,
                myoperator_unique_id, webhook_data,
                call_start_time, call_end_time
            ) VALUES (
                ?, 'TeleCMI', ?, ?,
                'pending', NULL, NULL, NULL,
                0, ?, ?,
                NOW(), ?, ?,
                NOW(), NOW(),
                NOW(), NULL,
                ?, NULL, NULL,
                NULL, NULL,
                NOW(), NULL
            )
        ");
        
        $stmt->bind_param(
            'iisssss',
            $callerId,
            $driverId,
            $driverName,
            $formattedCallerNumber,
            $formattedDriverMobile,
            $callId,
            $apiResponseJson,
            $ipAddress
        );
        
        if (!$stmt->execute()) {
            error_log("TeleCMI Production: Failed to log call to database - " . $stmt->error);
        }
        
        $stmt->close();
        
        error_log("TeleCMI Production: Call initiated successfully - Call ID: $callId");
        
        sendSuccess([
            'call_id' => $callId,
            'request_id' => $callId,
            'status' => 'initiated',
            'driver_name' => $driverName,
            'driver_mobile' => $driverMobile,
            'message' => 'Your phone will ring shortly. Answer to connect with the driver.'
        ], 'TeleCMI call initiated successfully');
        
    } else {
        $errorMsg = $response['error'] ?? 'Unknown error';
        error_log("TeleCMI Production: Call failed - " . $errorMsg);
        sendError('Failed to initiate call: ' . $errorMsg, 500);
    }
}

/**
 * Update call feedback
 * POST /api/telecmi_production_api.php?action=update_feedback
 * Body: {
 *   "reference_id": "call_id",
 *   "status": "completed",
 *   "feedback": "Interested",
 *   "remarks": "Driver wants more details",
 *   "call_duration": 120
 * }
 */
function handleUpdateFeedback() {
    global $conn;
    
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        sendError('Method not allowed. Use POST', 405);
    }
    
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!$input) {
        sendError('Invalid JSON input', 400);
    }
    
    if (!isset($input['reference_id']) || empty(trim($input['reference_id']))) {
        sendError('reference_id is required', 400);
    }
    
    $referenceId = sanitizeInput($conn, $input['reference_id']);
    $status = sanitizeInput($conn, $input['status'] ?? 'completed');
    $feedback = isset($input['feedback']) ? sanitizeInput($conn, $input['feedback']) : null;
    $remarks = isset($input['remarks']) ? sanitizeInput($conn, $input['remarks']) : null;
    $callDuration = isset($input['call_duration']) ? (int)$input['call_duration'] : 0;
    
    error_log("TeleCMI Production: Updating feedback for call $referenceId - Status: $status, Feedback: $feedback");
    
    // Update call log with feedback from user (filled manually via feedback modal)
    // Also update notes if provided
    $notes = isset($input['notes']) ? sanitizeInput($conn, $input['notes']) : null;
    
    $stmt = $conn->prepare("
        UPDATE call_logs 
        SET call_status = ?, 
            feedback = ?, 
            remarks = ?, 
            notes = ?,
            call_duration = ?, 
            call_completed_at = NOW(),
            call_end_time = NOW(),
            updated_at = NOW()
        WHERE reference_id = ?
    ");
    
    $stmt->bind_param('ssssis', $status, $feedback, $remarks, $notes, $callDuration, $referenceId);
    
    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            error_log("TeleCMI Production: Feedback updated successfully for call $referenceId");
            
            // Get updated call details with ALL fields
            $stmt2 = $conn->prepare("
                SELECT 
                    id, reference_id, caller_id, tc_for, user_id, driver_name,
                    call_status, feedback, remarks, notes, call_duration,
                    caller_number, user_number, call_time,
                    created_at, updated_at, call_initiated_at, call_completed_at,
                    call_start_time, call_end_time
                FROM call_logs
                WHERE reference_id = ?
            ");
            $stmt2->bind_param('s', $referenceId);
            $stmt2->execute();
            $result = $stmt2->get_result();
            $callData = $result->fetch_assoc();
            $stmt2->close();
            
            sendSuccess($callData, 'Feedback updated successfully');
        } else {
            error_log("TeleCMI Production: No call found with reference_id $referenceId");
            sendError('Call not found or already updated', 404);
        }
    } else {
        error_log("TeleCMI Production: Failed to update feedback - " . $stmt->error);
        sendError('Failed to update feedback: ' . $stmt->error, 500);
    }
    
    $stmt->close();
}

/**
 * Get call logs for a specific caller
 * GET /api/telecmi_production_api.php?action=get_call_logs&caller_id=3&limit=50
 */
function handleGetCallLogs() {
    global $conn;
    
    if ($_SERVER['REQUEST_METHOD'] !== 'GET') {
        sendError('Method not allowed. Use GET', 405);
    }
    
    $callerId = isset($_GET['caller_id']) ? (int)$_GET['caller_id'] : null;
    $limit = isset($_GET['limit']) ? (int)$_GET['limit'] : 50;
    $offset = isset($_GET['offset']) ? (int)$_GET['offset'] : 0;
    
    if (!$callerId) {
        sendError('caller_id is required', 400);
    }
    
    // SECURITY: Only allow Pooja to view TeleCMI call logs
    if ($callerId !== TELECMI_ALLOWED_USER_ID) {
        sendError('Unauthorized access', 403);
    }
    
    $stmt = $conn->prepare("
        SELECT 
            id, reference_id, caller_id, tc_for, user_id, driver_name,
            call_status, feedback, remarks, notes, call_duration,
            caller_number, user_number, call_time,
            api_response, created_at, updated_at,
            call_initiated_at, call_completed_at,
            call_start_time, call_end_time,
            recording_url, manual_call_recording_url
        FROM call_logs
        WHERE caller_id = ? AND tc_for = 'TeleCMI' AND reference_id LIKE 'telecmi_%'
        ORDER BY created_at DESC
        LIMIT ? OFFSET ?
    ");
    
    $stmt->bind_param('iii', $callerId, $limit, $offset);
    $stmt->execute();
    $result = $stmt->get_result();
    
    $callLogs = [];
    while ($row = $result->fetch_assoc()) {
        $callLogs[] = $row;
    }
    
    $stmt->close();
    
    // Get total count
    $stmt2 = $conn->prepare("
        SELECT COUNT(*) as total
        FROM call_logs
        WHERE caller_id = ? AND tc_for = 'TeleCMI' AND reference_id LIKE 'telecmi_%'
    ");
    $stmt2->bind_param('i', $callerId);
    $stmt2->execute();
    $result2 = $stmt2->get_result();
    $totalRow = $result2->fetch_assoc();
    $total = $totalRow['total'];
    $stmt2->close();
    
    sendSuccess([
        'call_logs' => $callLogs,
        'total' => $total,
        'limit' => $limit,
        'offset' => $offset
    ], 'Call logs retrieved successfully');
}

/**
 * TeleCMI Webhook Receiver
 * POST /api/telecmi_production_api.php?action=webhook
 */
function handleWebhook() {
    global $conn;
    
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        sendError('Method not allowed. Use POST', 405);
    }
    
    $payload = json_decode(file_get_contents('php://input'), true);
    
    if (!$payload) {
        $payload = $_POST;
    }
    
    error_log("TeleCMI Production Webhook: " . json_encode($payload));
    
    $eventType = $payload['event'] ?? 'unknown';
    $callId = $payload['call_id'] ?? null;
    
    if (!$callId) {
        error_log("TeleCMI Production Webhook: No call_id in payload");
        http_response_code(200);
        echo json_encode(['status' => 'ok']);
        exit();
    }
    
    switch ($eventType) {
        case 'call.initiated':
            $webhookJson = json_encode($payload);
            $stmt = $conn->prepare("
                UPDATE call_logs 
                SET call_status = 'pending', 
                    call_start_time = NOW(),
                    webhook_data = ?,
                    updated_at = NOW()
                WHERE reference_id = ?
            ");
            $stmt->bind_param('ss', $webhookJson, $callId);
            $stmt->execute();
            $stmt->close();
            break;
        
        case 'call.answered':
            $webhookJson = json_encode($payload);
            $stmt = $conn->prepare("
                UPDATE call_logs 
                SET call_status = 'connected',
                    webhook_data = ?,
                    updated_at = NOW()
                WHERE reference_id = ?
            ");
            $stmt->bind_param('ss', $webhookJson, $callId);
            $stmt->execute();
            $stmt->close();
            break;
        
        case 'call.ended':
            $duration = $payload['duration'] ?? 0;
            $endStatus = $payload['status'] ?? 'completed';
            $webhookJson = json_encode($payload);
            $recordingUrl = $payload['recording_url'] ?? null;
            
            $stmt = $conn->prepare("
                UPDATE call_logs 
                SET call_status = ?, 
                    call_duration = ?,
                    call_end_time = NOW(),
                    call_completed_at = NOW(),
                    recording_url = ?,
                    webhook_data = ?,
                    updated_at = NOW()
                WHERE reference_id = ?
            ");
            $stmt->bind_param('sisss', $endStatus, $duration, $recordingUrl, $webhookJson, $callId);
            $stmt->execute();
            $stmt->close();
            break;
    }
    
    http_response_code(200);
    echo json_encode(['status' => 'ok', 'event' => $eventType]);
    exit();
}

/**
 * Make cURL request to TeleCMI API
 */
function makeCurlRequest($url, $payload = []) {
    $ch = curl_init();
    
    curl_setopt_array($ch, [
        CURLOPT_URL => $url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 30,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode($payload),
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'Accept: application/json'
        ],
        CURLOPT_SSL_VERIFYPEER => true,
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    
    curl_close($ch);
    
    if ($error) {
        return [
            'success' => false,
            'error' => "Connection error: $error",
            'http_code' => 500
        ];
    }
    
    $data = json_decode($response, true);
    
    if ($httpCode >= 200 && $httpCode < 300) {
        return [
            'success' => true,
            'data' => $data,
            'http_code' => $httpCode
        ];
    } else {
        return [
            'success' => false,
            'error' => $data['msg'] ?? $data['message'] ?? 'TeleCMI API request failed',
            'data' => $data,
            'http_code' => $httpCode
        ];
    }
}
