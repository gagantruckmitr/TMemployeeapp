<?php
/**
 * TeleCMI API for TMemployeeapp
 * Handles IVR calling functionality using TeleCMI service
 * 
 * Endpoints:
 * - POST /api/telecmi_api.php?action=sdk_token - Get SDK token for WebRTC calling
 * - POST /api/telecmi_api.php?action=click_to_call - Initiate click-to-call
 * - POST /api/telecmi_api.php?action=webhook - Receive TeleCMI webhooks
 */

require_once 'config.php';

// Load environment variables from .env file
function loadEnv() {
    // Try multiple possible locations for .env file
    $possiblePaths = [
        __DIR__ . '/../.env',
        __DIR__ . '/../../.env',
        dirname(dirname(__DIR__)) . '/.env',
        $_SERVER['DOCUMENT_ROOT'] . '/../.env',
    ];
    
    $envFile = null;
    foreach ($possiblePaths as $path) {
        if (file_exists($path)) {
            $envFile = $path;
            break;
        }
    }
    
    if (!$envFile) {
        error_log('TeleCMI: .env file not found in any expected location');
        return;
    }
    
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
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
}

loadEnv();

// TeleCMI Configuration - Using working credentials
define('TELECMI_APP_ID', getenv('TELECMI_APP_ID') ?: '33336628');
define('TELECMI_APP_SECRET', getenv('TELECMI_APP_SECRET') ?: 'bb0b92ca-3d8a-405b-87aa-fc035fe1cdc6');
define('TELECMI_SDK_BASE', getenv('TELECMI_SDK_BASE') ?: 'https://piopiy.telecmi.com/v1/agentLogin');
define('TELECMI_REST_BASE', getenv('TELECMI_REST_BASE') ?: 'https://rest.telecmi.com/v2/webrtc/click2call');
define('TELECMI_ACCESS_TOKEN', getenv('TELECMI_ACCESS_TOKEN') ?: '');
define('TELECMI_USER_ID', '5003'); // Registered TeleCMI user

// Validate credentials
if (empty(TELECMI_APP_ID) || empty(TELECMI_APP_SECRET)) {
    error_log('TeleCMI: Missing credentials in .env file');
}

// Get action from query parameter
$action = $_GET['action'] ?? '';

// Route to appropriate handler
switch ($action) {
    case 'sdk_token':
        handleSdkToken();
        break;
    
    case 'click_to_call':
        handleClickToCall();
        break;
    
    case 'update_feedback':
        handleUpdateFeedback();
        break;
    
    case 'webhook':
        handleWebhook();
        break;
    
    default:
        sendError('Invalid action. Use: sdk_token, click_to_call, update_feedback, or webhook', 400);
}

/**
 * Generate SDK token for WebRTC (voice calling through SDK)
 * POST /api/telecmi_api.php?action=sdk_token
 * Body: { "user_id": "5003" }
 */
function handleSdkToken() {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        sendError('Method not allowed. Use POST', 405);
    }
    
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['user_id']) || empty(trim($input['user_id']))) {
        sendError('user_id is required', 400);
    }
    
    $userId = trim($input['user_id']);
    
    // Format user_id with app_id
    $fullUserId = $userId . '_' . TELECMI_APP_ID;
    
    error_log("TeleCMI: Requesting SDK token for user: $fullUserId");
    
    $payload = [
        'user_id' => $fullUserId,
        'secret'  => TELECMI_APP_SECRET,
    ];
    
    $url = 'https://rest.telecmi.com/v2/webrtc/token';
    
    $response = makeCurlRequest($url, $payload);
    
    if ($response['success']) {
        error_log("TeleCMI: SDK token received successfully for user: $fullUserId");
        sendSuccess($response['data'], 'SDK token generated successfully');
    } else {
        error_log("TeleCMI: SDK token request failed - " . $response['error']);
        sendError($response['error'], $response['http_code'] ?? 500);
    }
}

/**
 * Click-to-Call (server initiated call)
 * POST /api/telecmi_api.php?action=click_to_call
 * Body: { "user_id": "5003", "to": "918448079624", "webrtc": false, "followme": true }
 */
function handleClickToCall() {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        sendError('Method not allowed. Use POST', 405);
    }
    
    $input = json_decode(file_get_contents('php://input'), true);
    
    // Validate required fields
    $callerId = $input['caller_id'] ?? null;
    $driverId = $input['driver_id'] ?? null;
    $driverMobile = $input['driver_mobile'] ?? null;
    
    if (!$driverMobile) {
        sendError('driver_mobile is required', 400);
    }
    
    if (!$callerId) {
        sendError('caller_id is required', 400);
    }
    
    // Use registered TeleCMI user
    $fullUserId = TELECMI_USER_ID . '_' . TELECMI_APP_ID;
    
    // Convert to integer (TeleCMI requires number, not string)
    $toNumber = (int)$driverMobile;
    
    error_log("TeleCMI: Initiating Click-to-Call for user $fullUserId to $toNumber");
    
    $payload = [
        'user_id'  => $fullUserId,
        'secret'   => TELECMI_APP_SECRET,
        'to'       => $toNumber,
        'webrtc'   => false,
        'followme' => true
    ];
    
    $url = TELECMI_REST_BASE;
    
    $response = makeCurlRequest($url, $payload, [], 'POST');
    
    if ($response['success']) {
        error_log("TeleCMI: Click-to-Call initiated successfully");
        
        // Generate call ID
        $callId = $response['data']['call_id'] ?? $response['data']['request_id'] ?? uniqid('telecmi_');
        
        // Log call to database with all details
        logTeleCMICallToDatabase($callId, $callerId, $driverId, $to, $fullUserId);
        
        sendSuccess([
            'call_id' => $callId,
            'request_id' => $callId,
            'status' => 'initiated',
            'telecmi_response' => $response['data']
        ], 'Call initiated successfully');
    } else {
        error_log("TeleCMI: Click-to-Call failed - " . $response['error']);
        sendError($response['error'], $response['http_code'] ?? 500);
    }
}

/**
 * TeleCMI Webhook Receiver
 * POST /api/telecmi_api.php?action=webhook
 * Receives call events from TeleCMI
 */
function handleWebhook() {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        sendError('Method not allowed. Use POST', 405);
    }
    
    $payload = json_decode(file_get_contents('php://input'), true);
    
    if (!$payload) {
        $payload = $_POST;
    }
    
    error_log("TeleCMI Webhook Received: " . json_encode($payload));
    
    $eventType = $payload['event'] ?? 'unknown';
    
    switch ($eventType) {
        case 'call.initiated':
            error_log("TeleCMI: Incoming call started");
            handleCallInitiated($payload);
            break;
        
        case 'call.answered':
            error_log("TeleCMI: Call answered");
            handleCallAnswered($payload);
            break;
        
        case 'call.ended':
            error_log("TeleCMI: Call ended");
            handleCallEnded($payload);
            break;
        
        default:
            error_log("TeleCMI: Unknown event type - $eventType");
            break;
    }
    
    // Always return 200 OK to acknowledge webhook
    http_response_code(200);
    echo json_encode(['status' => 'ok']);
    exit();
}

/**
 * Handle call initiated event
 */
function handleCallInitiated($payload) {
    global $conn;
    
    $callId = $payload['call_id'] ?? null;
    $from = $payload['from'] ?? null;
    $to = $payload['to'] ?? null;
    
    if (!$callId) return;
    
    $stmt = $conn->prepare("
        INSERT INTO call_logs (
            call_id, from_number, to_number, status, 
            initiated_at, created_at
        ) VALUES (?, ?, ?, 'initiated', NOW(), NOW())
        ON DUPLICATE KEY UPDATE 
            status = 'initiated',
            initiated_at = NOW()
    ");
    
    $stmt->bind_param('sss', $callId, $from, $to);
    $stmt->execute();
    $stmt->close();
}

/**
 * Handle call answered event
 */
function handleCallAnswered($payload) {
    global $conn;
    
    $callId = $payload['call_id'] ?? null;
    
    if (!$callId) return;
    
    $stmt = $conn->prepare("
        UPDATE call_logs 
        SET status = 'answered', answered_at = NOW()
        WHERE call_id = ?
    ");
    
    $stmt->bind_param('s', $callId);
    $stmt->execute();
    $stmt->close();
}

/**
 * Handle call ended event
 */
function handleCallEnded($payload) {
    global $conn;
    
    $callId = $payload['call_id'] ?? null;
    $duration = $payload['duration'] ?? 0;
    $status = $payload['status'] ?? 'completed';
    
    if (!$callId) return;
    
    $stmt = $conn->prepare("
        UPDATE call_logs 
        SET status = ?, duration = ?, ended_at = NOW()
        WHERE call_id = ?
    ");
    
    $stmt->bind_param('sis', $status, $duration, $callId);
    $stmt->execute();
    $stmt->close();
}

/**
 * Log TeleCMI call to database with full details
 */
function logTeleCMICallToDatabase($callId, $callerId, $driverId, $driverMobile, $telecmiUserId) {
    global $conn;
    
    $stmt = $conn->prepare("
        INSERT INTO call_logs (
            reference_id, caller_id, driver_id, driver_mobile, 
            call_type, status, provider, telecmi_user_id, created_at
        ) VALUES (?, ?, ?, ?, 'ivr', 'initiated', 'telecmi', ?, NOW())
    ");
    
    $stmt->bind_param('sisss', $callId, $callerId, $driverId, $driverMobile, $telecmiUserId);
    
    if ($stmt->execute()) {
        error_log("TeleCMI: Call logged to database - Call ID: $callId, Caller: $callerId, Driver: $driverId");
    } else {
        error_log("TeleCMI: Failed to log call to database - " . $stmt->error);
    }
    
    $stmt->close();
}

/**
 * Update call feedback
 * POST /api/telecmi_api.php?action=update_feedback
 * Body: { "reference_id": "call_id", "status": "completed", "feedback": "Interested", "remarks": "...", "call_duration": 120 }
 */
function handleUpdateFeedback() {
    global $conn;
    
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        sendError('Method not allowed. Use POST', 405);
    }
    
    $input = json_decode(file_get_contents('php://input'), true);
    
    if (!isset($input['reference_id']) || empty(trim($input['reference_id']))) {
        sendError('reference_id is required', 400);
    }
    
    $referenceId = trim($input['reference_id']);
    $status = $input['status'] ?? 'completed';
    $feedback = $input['feedback'] ?? null;
    $remarks = $input['remarks'] ?? null;
    $callDuration = $input['call_duration'] ?? 0;
    
    error_log("TeleCMI: Updating feedback for call $referenceId");
    
    $stmt = $conn->prepare("
        UPDATE call_logs 
        SET status = ?, feedback = ?, remarks = ?, call_duration = ?, updated_at = NOW()
        WHERE reference_id = ? AND provider = 'telecmi'
    ");
    
    $stmt->bind_param('sssis', $status, $feedback, $remarks, $callDuration, $referenceId);
    
    if ($stmt->execute()) {
        if ($stmt->affected_rows > 0) {
            error_log("TeleCMI: Feedback updated successfully for call $referenceId");
            sendSuccess(['updated' => true], 'Feedback updated successfully');
        } else {
            error_log("TeleCMI: No call found with reference_id $referenceId");
            sendError('Call not found', 404);
        }
    } else {
        error_log("TeleCMI: Failed to update feedback - " . $stmt->error);
        sendError('Failed to update feedback: ' . $stmt->error, 500);
    }
    
    $stmt->close();
}

/**
 * Make cURL request to TeleCMI API
 */
function makeCurlRequest($url, $payload = [], $headers = [], $method = 'POST') {
    $ch = curl_init();
    
    $defaultHeaders = [
        'Content-Type: application/json',
    ];
    
    $headers = array_merge($defaultHeaders, $headers);
    
    curl_setopt_array($ch, [
        CURLOPT_URL => $url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 10,
        CURLOPT_CUSTOMREQUEST => $method,
        CURLOPT_POSTFIELDS => json_encode($payload),
        CURLOPT_HTTPHEADER => $headers,
        CURLOPT_SSL_VERIFYPEER => true,
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    
    curl_close($ch);
    
    if ($error) {
        return [
            'success' => false,
            'error' => "cURL Error: $error",
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
            'error' => $data['msg'] ?? $data['message'] ?? 'Request failed',
            'data' => $data,
            'http_code' => $httpCode
        ];
    }
}

/**
 * Verify webhook signature (optional security)
 */
function verifyWebhookSignature() {
    $headers = getallheaders();
    $signature = $headers['X-TeleCMI-Signature'] ?? null;
    
    if (!$signature) {
        return false;
    }
    
    $payload = file_get_contents('php://input');
    $computed = hash_hmac('sha256', $payload, TELECMI_APP_SECRET);
    
    return hash_equals($computed, $signature);
}
