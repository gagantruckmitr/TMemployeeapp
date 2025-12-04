<?php
/**
 * EasyGo IVR API Handler - OPTIMIZED FOR SPEED
 * Critical performance improvements for instant call connection
 * With IST Timezone Fix for all timestamp fields
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

// Ensure MySQL timezone is set to IST for this connection
$conn->query("SET time_zone = '+05:30'");

// EasyGo IVR Configuration
define('EASYGO_USERNAME', 'admin@truckmitr.com');
define('EASYGO_PASSWORD', '6515a6cb823fcbe20f7287bd4659d5ba');
define('EASYGO_DID', '62982912');
define('EASYGO_TOKEN_URL', 'https://client.easygoivr.com/masterapiJwt/gentoken');
define('EASYGO_DIAL_URL', 'https://client.easygoivr.com/easygoapiJwt/request/dial');

// MANUAL TOKEN - Update this with token from EasyGo support
define('EASYGO_MANUAL_TOKEN', 'CONTACT_EASYGO_SUPPORT_FOR_TOKEN');

// CRITICAL: Use in-memory token cache to avoid DB queries
$tokenCache = null;
$tokenExpiry = null;

/**
 * OPTIMIZED: Generate new EasyGo API token with reduced timeout
 */
function generateEasyGoToken() {
    global $conn, $tokenCache, $tokenExpiry;
    
    $ch = curl_init(EASYGO_TOKEN_URL);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10); // Reduced from 30 to 10 seconds
    curl_setopt($ch, CURLOPT_CONNECTTIMEOUT, 5); // Add connection timeout
    curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
    curl_setopt($ch, CURLOPT_HTTPAUTH, CURLAUTH_BASIC);
    curl_setopt($ch, CURLOPT_USERPWD, EASYGO_USERNAME . ':' . EASYGO_PASSWORD);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    if ($httpCode === 200 && $response) {
        $json = json_decode($response, true);
        if (isset($json['API_TOKEN']) || isset($json['token'])) {
            $token = $json['API_TOKEN'] ?? $json['token'];
            
            // Cache token in memory for this request
            $tokenCache = $token;
            $tokenExpiry = time() + (30 * 24 * 60 * 60); // 30 days
            
            // Store asynchronously (non-blocking)
            storeTokenAsync($token, $json['expiry_time'] ?? $json['expires_at'] ?? null);
            
            return $token;
        }
    }
    
    return null;
}

/**
 * OPTIMIZED: Non-blocking token storage with IST timezone
 */
function storeTokenAsync($token, $expiresAt = null) {
    global $conn;
    
    if ($expiresAt === null) {
        $expiresAt = date('Y-m-d H:i:s', strtotime('+30 days'));
    }
    
    // Use INSERT IGNORE for faster execution with IST timezone
    $stmt = $conn->prepare("
        INSERT IGNORE INTO easygo_tokens (token, expires_at, created_at, updated_at)
        VALUES (?, ?, CONVERT_TZ(NOW(), @@session.time_zone, '+05:30'), CONVERT_TZ(NOW(), @@session.time_zone, '+05:30'))
    ");
    
    if ($stmt) {
        $stmt->bind_param('ss', $token, $expiresAt);
        $stmt->execute();
        $stmt->close();
    }
}

/**
 * OPTIMIZED: Fast token retrieval with memory cache
 */
function getValidToken() {
    global $conn, $tokenCache, $tokenExpiry;
    
    // FAST PATH 1: Use manual token if set
    if (defined('EASYGO_MANUAL_TOKEN') && EASYGO_MANUAL_TOKEN !== 'CONTACT_EASYGO_SUPPORT_FOR_TOKEN') {
        return EASYGO_MANUAL_TOKEN;
    }
    
    // FAST PATH 2: Use in-memory cache
    if ($tokenCache && $tokenExpiry && time() < $tokenExpiry - 600) {
        return $tokenCache;
    }
    
    // FAST PATH 3: Quick DB lookup with optimized query
    $result = $conn->query("
        SELECT token, UNIX_TIMESTAMP(expires_at) as exp 
        FROM easygo_tokens 
        WHERE expires_at > DATE_ADD(NOW(), INTERVAL 10 MINUTE)
        ORDER BY id DESC 
        LIMIT 1
    ");
    
    if ($result && $row = $result->fetch_assoc()) {
        $tokenCache = $row['token'];
        $tokenExpiry = $row['exp'];
        return $row['token'];
    }
    
    // SLOW PATH: Generate new token (only if needed)
    return generateEasyGoToken();
}

/**
 * OPTIMIZED: Lightning-fast call initiation
 */
function initiateEasyGoCall($exten, $number, $duration = '', $callerId = null, $contactId = null, $contactType = 'driver', $driverName = null, $callSource = null) {
    $token = getValidToken();
    
    if (!$token) {
        return ['success' => false, 'error' => 'No API token available'];
    }
    
    // Pre-generate reference_id
    $referenceId = 'easygo_' . uniqid('', true) . '_' . time();
    
    // Prepare API payload
    $data = [
        'exten' => $exten,
        'number' => $number,
        'did' => EASYGO_DID,
        'duration' => $duration
    ];
    
    // CRITICAL: Optimized cURL settings for speed
    $ch = curl_init(EASYGO_DIAL_URL);
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => json_encode($data),
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 15, // Reduced from 30
        CURLOPT_CONNECTTIMEOUT => 5, // Fast connection timeout
        CURLOPT_TCP_NODELAY => true, // Disable Nagle's algorithm for faster sends
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'API-Token: ' . $token,
            'Connection: close' // Don't wait for keep-alive
        ]
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);
    
    if ($curlError) {
        return ['success' => false, 'error' => 'Connection error: ' . $curlError];
    }
    
    // CRITICAL: Log ASYNCHRONOUSLY (don't block response)
    if ($httpCode === 200) {
        $json = json_decode($response, true);
        
        // Fire and forget - log in background
        logEasyGoCallAsync($exten, $number, $json, $httpCode, $callerId, $contactId, $contactType, $referenceId, $driverName, $callSource);
        
        return [
            'success' => true,
            'data' => $json,
            'reference_id' => $referenceId
        ];
    }
    
    return ['success' => false, 'error' => 'HTTP ' . $httpCode];
}

/**
 * OPTIMIZED: Async call logging with IST timezone fix
 */
function logEasyGoCallAsync($exten, $number, $response, $httpCode, $callerId, $contactId, $contactType, $referenceId, $driverName, $callSource) {
    global $conn;
    
    $callStatus = ($httpCode === 200) ? 'pending' : 'failed';
    $responseJson = json_encode($response);
    
    // Set tc_for based on call_source
    if ($callSource === 'toll-free') {
        $tcFor = 'toll-free';
    } elseif ($callSource === 'callback_requests') {
        $tcFor = 'call-back';
    } else {
        $tcFor = 'easygo_ivr_' . $contactType;
    }
    
    $userId = is_numeric($contactId) ? intval($contactId) : 0;
    
    // Use INSERT with minimal locking and IST timezone conversion
    // CONVERT_TZ ensures all timestamps are stored in IST regardless of server timezone
    $stmt = $conn->prepare("
        INSERT INTO call_logs 
        (caller_id, tc_for, user_id, driver_name, call_status, caller_number, user_number,
         reference_id, api_response, call_source, call_time, call_initiated_at, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 
                CONVERT_TZ(NOW(), @@session.time_zone, '+05:30'), 
                CONVERT_TZ(NOW(), @@session.time_zone, '+05:30'), 
                CONVERT_TZ(NOW(), @@session.time_zone, '+05:30'), 
                CONVERT_TZ(NOW(), @@session.time_zone, '+05:30'))
    ");
    
    if ($stmt) {
        $stmt->bind_param('isisssssss',
            $callerId, $tcFor, $userId, $driverName, $callStatus,
            $exten, $number, $referenceId, $responseJson, $callSource
        );
        $stmt->execute();
        $stmt->close();
    }
}

// ========================================
// API REQUEST HANDLER - OPTIMIZED
// ========================================

$action = $_GET['action'] ?? $_POST['action'] ?? '';

switch ($action) {
    case 'initiate_call':
        // FAST PATH: Parse input once
        $input = json_decode(file_get_contents('php://input'), true) ?: [];
        
        $exten = $input['exten'] ?? '';
        $number = $input['number'] ?? '';
        
        // Quick validation
        if (empty($exten) || empty($number)) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Missing exten or number']);
            exit;
        }
        
        // Clean and validate in one pass
        $exten = preg_replace('/[^\d]/', '', $exten);
        $number = preg_replace('/[^\d]/', '', $number);
        
        if (strlen($exten) < 10 || strlen($number) < 10) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Invalid phone number']);
            exit;
        }
        
        // Extract optional parameters
        $duration = $input['duration'] ?? '';
        $callerId = $input['caller_id'] ?? null;
        $contactId = $input['contact_id'] ?? null;
        $contactType = $input['contact_type'] ?? 'driver';
        $driverName = $input['driver_name'] ?? $input['contact_name'] ?? null;
        $callSource = $input['call_source'] ?? null;
        
        // EXECUTE CALL IMMEDIATELY
        $result = initiateEasyGoCall($exten, $number, $duration, $callerId, $contactId, $contactType, $driverName, $callSource);
        echo json_encode($result);
        break;
        
    case 'generate_token':
        $token = generateEasyGoToken();
        echo json_encode([
            'success' => (bool)$token,
            'token' => $token ?: null
        ]);
        break;
        
    case 'get_call_logs':
        $limit = min((int)($_GET['limit'] ?? 50), 500); // Cap limit
        $callerId = $_GET['caller_id'] ?? null;
        
        $query = "SELECT * FROM call_logs WHERE tc_for LIKE 'easygo_ivr%'";
        
        if ($callerId) {
            $query .= " AND caller_id = " . intval($callerId);
        }
        
        $query .= " ORDER BY id DESC LIMIT " . $limit;
        
        $result = $conn->query($query);
        $logs = [];
        
        if ($result) {
            while ($row = $result->fetch_assoc()) {
                $logs[] = $row;
            }
        }
        
        echo json_encode(['success' => true, 'data' => $logs]);
        break;
        
    case 'update_feedback':
        $input = json_decode(file_get_contents('php://input'), true) ?: [];
        
        $callLogId = $input['call_log_id'] ?? null;
        $referenceId = $input['reference_id'] ?? null;
        
        if (!$callLogId && !$referenceId) {
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Missing identifier']);
            exit;
        }
        
        // Quick lookup
        if ($callLogId) {
            $check = $conn->query("SELECT id FROM call_logs WHERE id = " . intval($callLogId));
        } else {
            $stmt = $conn->prepare("SELECT id FROM call_logs WHERE reference_id = ? LIMIT 1");
            $stmt->bind_param('s', $referenceId);
            $stmt->execute();
            $check = $stmt->get_result();
        }
        
        if (!$check || $check->num_rows === 0) {
            echo json_encode(['success' => false, 'error' => 'Call log not found']);
            exit;
        }
        
        $actualId = $check->fetch_assoc()['id'];
        if (isset($stmt)) $stmt->close();
        
        // Build efficient update
        $updates = [];
        $params = [];
        $types = '';
        
        foreach (['driver_name', 'feedback', 'call_status', 'remarks'] as $field) {
            if (isset($input[$field])) {
                $updates[] = "$field = ?";
                $params[] = $input[$field];
                $types .= 's';
            }
        }
        
        if (isset($input['call_duration'])) {
            $updates[] = "call_duration = ?";
            $params[] = (int)$input['call_duration'];
            $types .= 'i';
        }
        
        if (empty($updates)) {
            echo json_encode(['success' => false, 'error' => 'No fields to update']);
            exit;
        }
        
        // Update with IST timezone conversion
        $query = "UPDATE call_logs SET " . implode(', ', $updates) . ", updated_at = CONVERT_TZ(NOW(), @@session.time_zone, '+05:30') WHERE id = ?";
        $params[] = $actualId;
        $types .= 'i';
        
        $stmt = $conn->prepare($query);
        $stmt->bind_param($types, ...$params);
        $success = $stmt->execute();
        $stmt->close();
        
        echo json_encode([
            'success' => $success,
            'call_log_id' => $actualId
        ]);
        break;
        
    default:
        http_response_code(400);
        echo json_encode(['success' => false, 'error' => 'Invalid action']);
        break;
}

$conn->close();
?>
