<?php
/**
 * EasyGo IVR API Handler
 * Manages token generation and call initiation for EasyGo IVR system
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'config.php';

// EasyGo IVR Configuration
define('EASYGO_USERNAME', 'admin@truckmitr.com');
define('EASYGO_PASSWORD', '6515a6cb823fcbe20f7287bd4659d5ba');
define('EASYGO_DID', '6882742');
define('EASYGO_TOKEN_URL', 'https://client.easygoivr.com/masterapiJwt/gentoken');
define('EASYGO_DIAL_URL', 'https://client.easygoivr.com/easygoapiJwt/request/dial');

// MANUAL TOKEN - Update this with token from EasyGo support
// Contact EasyGo support to get a fresh token and update here
define('EASYGO_MANUAL_TOKEN', 'CONTACT_EASYGO_SUPPORT_FOR_TOKEN');

/**
 * Generate new EasyGo API token using Basic Auth
 */
function generateEasyGoToken() {
    $ch = curl_init(EASYGO_TOKEN_URL);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    
    // Use HTTP Basic Authentication
    curl_setopt($ch, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
    curl_setopt($ch, CURLOPT_USERPWD, EASYGO_USERNAME . ':' . EASYGO_PASSWORD);
    
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json'
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode === 200 && $response) {
        $json = json_decode($response, true);
        if (isset($json['API_TOKEN']) || isset($json['token'])) {
            $token = $json['API_TOKEN'] ?? $json['token'];
            // Store token in database with expiry
            storeToken($token, $json['expiry_time'] ?? $json['expires_at'] ?? null);
            return $token;
        }
    }
    
    return null;
}

/**
 * Store token in database
 */
function storeToken($token, $expiresAt = null) {
    global $conn;
    
    // Calculate expiry (default 30 days if not provided)
    if ($expiresAt === null) {
        $expiresAt = date('Y-m-d H:i:s', strtotime('+30 days'));
    }
    
    // Check if table exists
    $tableCheck = $conn->query("SHOW TABLES LIKE 'easygo_tokens'");
    if ($tableCheck && $tableCheck->num_rows > 0) {
        $stmt = $conn->prepare("
            INSERT INTO easygo_tokens (token, expires_at, created_at)
            VALUES (?, ?, NOW())
            ON DUPLICATE KEY UPDATE
            token = VALUES(token),
            expires_at = VALUES(expires_at),
            updated_at = NOW()
        ");
        
        $stmt->bind_param('ss', $token, $expiresAt);
        $stmt->execute();
        $stmt->close();
    }
    // If table doesn't exist, just continue without storing
}

/**
 * Get valid token from database or use manual token
 */
function getValidToken() {
    global $conn;
    
    // First, check if manual token is set
    if (defined('EASYGO_MANUAL_TOKEN') && EASYGO_MANUAL_TOKEN !== 'CONTACT_EASYGO_SUPPORT_FOR_TOKEN') {
        return EASYGO_MANUAL_TOKEN;
    }
    
    // Check if table exists
    $tableCheck = $conn->query("SHOW TABLES LIKE 'easygo_tokens'");
    if ($tableCheck && $tableCheck->num_rows > 0) {
        // Try to get existing valid token (regenerate 5 minutes before expiry)
        $stmt = $conn->prepare("
            SELECT token, expires_at 
            FROM easygo_tokens 
            WHERE expires_at > DATE_ADD(NOW(), INTERVAL 10 MINUTE)
            ORDER BY created_at DESC 
            LIMIT 1
        ");
        
        $stmt->execute();
        $result = $stmt->get_result();
        
        if ($row = $result->fetch_assoc()) {
            $stmt->close();
            return $row['token'];
        }
        
        $stmt->close();
    }
    
    
    $token = generateEasyGoToken();
    if ($token) {
        return $token;
    }
    
    // Return error message if no token available
    return null;
}

/**
 * Initiate EasyGo IVR call
 */
function initiateEasyGoCall($exten, $number, $duration = '', $callerId = null, $contactId = null, $contactType = 'driver', $driverName = null, $callSource = null) {
    $token = getValidToken();
    
    if (!$token) {
        return [
            'success' => false,
            'error' => 'Failed to generate API token'
        ];
    }
    
    // Generate reference_id BEFORE making the call
    $referenceId = 'easygo_' . uniqid() . '_' . time();
    
    $data = [
        'exten' => $exten,
        'number' => $number,
        'did' => EASYGO_DID,
        'duration' => $duration
    ];
    
    $ch = curl_init(EASYGO_DIAL_URL);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 30);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'API-Token: ' . $token
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);
    
    if ($curlError) {
        return [
            'success' => false,
            'error' => 'Connection error: ' . $curlError
        ];
    }
    
    if ($httpCode === 200 && $response) {
        $json = json_decode($response, true);
        
        // Log the call attempt in call_logs table with our reference_id
        $callLogId = logEasyGoCall($exten, $number, $json, $httpCode, $callerId, $contactId, $contactType, $referenceId, $driverName, $callSource);
        
        return [
            'success' => true,
            'data' => $json,
            'reference_id' => $referenceId,
            'call_log_id' => $callLogId
        ];
    }
    
    return [
        'success' => false,
        'error' => 'HTTP ' . $httpCode . ': ' . $response
    ];
}

/**
 * Log EasyGo call in call_logs table
 */
function logEasyGoCall($exten, $number, $response, $httpCode, $callerId, $contactId, $contactType = 'driver', $referenceId = null, $driverName = null, $callSource = null) {
    global $conn;
    
    // Use provided reference_id or generate one
    if (!$referenceId) {
        $referenceId = 'easygo_' . uniqid() . '_' . time();
    }
    
    $callStatus = ($httpCode === 200) ? 'pending' : 'failed';
    $responseJson = json_encode($response);
    $tcFor = 'easygo_ivr_' . $contactType; // Store call type info
    
    // Convert contactId to integer for user_id field
    $userId = is_numeric($contactId) ? intval($contactId) : 0;
    
    // Insert into call_logs table matching actual structure
    $stmt = $conn->prepare("
        INSERT INTO call_logs 
        (caller_id, tc_for, user_id, driver_name, call_status, caller_number, user_number,
         reference_id, api_response, call_source, call_initiated_at, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), NOW())
    ");
    
    // Map parameters correctly:
    // caller_id = telecaller ID (int)
    // tc_for = 'easygo_ivr_driver' or 'easygo_ivr_transporter' (string)
    // user_id = contact ID as integer (int)
    // driver_name = driver/contact name (string)
    // call_status = 'pending' or 'failed' (string)
    // caller_number = telecaller phone (string)
    // user_number = client phone (string)
    // reference_id = Our generated reference ID (string)
    // api_response = JSON response (string)
    // call_source = source of call (e.g., 'job_posting', 'job_applicants', null for regular) (string)
    $stmt->bind_param('isisssssss', 
        $callerId,      // caller_id (int)
        $tcFor,         // tc_for (string)
        $userId,        // user_id (int)
        $driverName,    // driver_name (string)
        $callStatus,    // call_status (string)
        $exten,         // caller_number (string)
        $number,        // user_number (string)
        $referenceId,   // reference_id (string)
        $responseJson,  // api_response (string)
        $callSource     // call_source (string)
    );
    
    if (!$stmt->execute()) {
        error_log("EasyGo IVR: Failed to insert call log - " . $stmt->error);
        $stmt->close();
        return null;
    }
    
    $callLogId = $conn->insert_id;
    $stmt->close();
    
    return $callLogId;
}

// Handle API requests
$action = $_GET['action'] ?? $_POST['action'] ?? '';

switch ($action) {
    case 'generate_token':
        $token = generateEasyGoToken();
        if ($token) {
            echo json_encode([
                'success' => true,
                'token' => $token
            ]);
        } else {
            echo json_encode([
                'success' => false,
                'error' => 'Failed to generate token'
            ]);
        }
        break;
        
    case 'initiate_call':
        $input = json_decode(file_get_contents('php://input'), true);
        
        $exten = $input['exten'] ?? '';
        $number = $input['number'] ?? '';
        $duration = $input['duration'] ?? '';
        $callerId = $input['caller_id'] ?? null;
        $contactId = $input['contact_id'] ?? null;
        $contactType = $input['contact_type'] ?? 'driver';
        $driverName = $input['driver_name'] ?? $input['contact_name'] ?? null;
        $callSource = $input['call_source'] ?? null; // e.g., 'job_posting', 'job_applicants'
        
        // Debug log
        error_log("EasyGo IVR Call - Driver Name: " . ($driverName ?? 'NULL'));
        error_log("EasyGo IVR Call - Call Source: " . ($callSource ?? 'NULL'));
        error_log("EasyGo IVR Call - Input: " . json_encode($input));
        
        // Validate inputs
        if (empty($exten) || empty($number)) {
            echo json_encode([
                'success' => false,
                'error' => 'Missing required parameters: exten and number'
            ]);
            exit;
        }
        
        // Clean phone numbers (remove non-digits)
        $exten = preg_replace('/[^\d]/', '', $exten);
        $number = preg_replace('/[^\d]/', '', $number);
        
        // Validate phone numbers
        if (strlen($exten) < 10 || strlen($number) < 10) {
            echo json_encode([
                'success' => false,
                'error' => 'Invalid phone number format'
            ]);
            exit;
        }
        
        $result = initiateEasyGoCall($exten, $number, $duration, $callerId, $contactId, $contactType, $driverName, $callSource);
        echo json_encode($result);
        break;
        
    case 'get_call_logs':
        $limit = $_GET['limit'] ?? 50;
        $callerId = $_GET['caller_id'] ?? null;
        
        $query = "
            SELECT * FROM call_logs 
            WHERE tc_for LIKE 'easygo_ivr%'
        ";
        
        if ($callerId) {
            $query .= " AND caller_id = ?";
        }
        
        $query .= " ORDER BY created_at DESC LIMIT ?";
        
        $stmt = $conn->prepare($query);
        
        if ($callerId) {
            $stmt->bind_param('ii', $callerId, $limit);
        } else {
            $stmt->bind_param('i', $limit);
        }
        
        $stmt->execute();
        $result = $stmt->get_result();
        
        $logs = [];
        while ($row = $result->fetch_assoc()) {
            $logs[] = $row;
        }
        
        $stmt->close();
        
        echo json_encode([
            'success' => true,
            'data' => $logs
        ]);
        break;
        
    case 'update_feedback':
        $input = json_decode(file_get_contents('php://input'), true);
        
        $callLogId = $input['call_log_id'] ?? null;
        $referenceId = $input['reference_id'] ?? null;
        $feedback = $input['feedback'] ?? '';
        $callStatus = $input['call_status'] ?? '';
        $callDuration = $input['call_duration'] ?? null;
        $remarks = $input['remarks'] ?? null;
        
        if (!$callLogId && !$referenceId) {
            echo json_encode([
                'success' => false,
                'error' => 'Missing call_log_id or reference_id'
            ]);
            exit;
        }
        
        // First check if record exists and get the ID
        if ($callLogId) {
            $checkStmt = $conn->prepare("SELECT id, reference_id FROM call_logs WHERE id = ?");
            $checkStmt->bind_param('i', $callLogId);
        } else {
            $checkStmt = $conn->prepare("SELECT id, reference_id FROM call_logs WHERE reference_id = ?");
            $checkStmt->bind_param('s', $referenceId);
        }
        
        $checkStmt->execute();
        $checkResult = $checkStmt->get_result();
        
        if ($checkResult->num_rows === 0) {
            $checkStmt->close();
            
            // Debug: Check what reference_ids exist
            $debugStmt = $conn->query("SELECT reference_id FROM call_logs WHERE reference_id LIKE 'easygo_%' ORDER BY id DESC LIMIT 5");
            $existingRefs = [];
            while ($row = $debugStmt->fetch_assoc()) {
                $existingRefs[] = $row['reference_id'];
            }
            
            echo json_encode([
                'success' => false,
                'error' => 'Call log not found with ' . ($callLogId ? "id: $callLogId" : "reference_id: $referenceId"),
                'debug' => [
                    'searched_for' => $referenceId ?? $callLogId,
                    'recent_reference_ids' => $existingRefs
                ]
            ]);
            exit;
        }
        
        $row = $checkResult->fetch_assoc();
        $actualCallLogId = $row['id'];
        $actualReferenceId = $row['reference_id'];
        $checkStmt->close();
        
        // Get driver_name from input
        $driverName = $input['driver_name'] ?? $input['contact_name'] ?? null;
        
        // Build update query - always use the actual call_log_id we found
        $query = "UPDATE call_logs SET ";
        $params = [];
        $types = '';
        
        if ($driverName !== null) {
            $query .= "driver_name = ?, ";
            $params[] = $driverName;
            $types .= 's';
        }
        
        if ($feedback) {
            $query .= "feedback = ?, ";
            $params[] = $feedback;
            $types .= 's';
        }
        
        if ($callStatus) {
            $query .= "call_status = ?, ";
            $params[] = $callStatus;
            $types .= 's';
        }
        
        if ($callDuration !== null) {
            $query .= "call_duration = ?, ";
            $params[] = $callDuration;
            $types .= 'i';
        }
        
        if ($remarks !== null) {
            $query .= "remarks = ?, ";
            $params[] = $remarks;
            $types .= 's';
        }
        
        $query .= "updated_at = NOW() WHERE id = ?";
        $params[] = $actualCallLogId;
        $types .= 'i';
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param($types, ...$params);
        $success = $stmt->execute();
        $affectedRows = $stmt->affected_rows;
        $error = $stmt->error;
        $stmt->close();
        
        echo json_encode([
            'success' => $success && $affectedRows > 0,
            'message' => $success && $affectedRows > 0 ? 'Feedback updated successfully' : 'Failed to update feedback',
            'affected_rows' => $affectedRows,
            'call_log_id' => $actualCallLogId,
            'reference_id' => $actualReferenceId,
            'error' => $error ?: null
        ]);
        break;
        
    default:
        echo json_encode([
            'success' => false,
            'error' => 'Invalid action'
        ]);
        break;
}

$conn->close();
?>
