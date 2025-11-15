<?php
/**
 * Click2Call IVR API Integration
 * Uses https://154.210.187.101/C2CAPI/webresources/Click2CallPost
 * for IVR calling with telecaller and driver
 */

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', '1');
ini_set('log_errors', '1');

// Clean any previous output
while (ob_get_level()) {
    ob_end_clean();
}

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

// Click2Call API Configuration
define('CLICK2CALL_API_URL', 'https://154.210.187.101/C2CAPI/webresources/Click2CallPost');
define('CLICK2CALL_UKEY', 'UFGMs6bXiXD4AIkjQGta8faKi');
define('CLICK2CALL_SERVICE_NO', '8037789293');
define('CLICK2CALL_IVR_TEMPLATE_ID', '345');

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

try {
    switch($action) {
        case 'initiate_call':
            initiateCall($pdo);
            break;
        case 'call_status':
            getCallStatus($pdo);
            break;
        case 'update_feedback':
            updateCallFeedback($pdo);
            break;
        default:
            http_response_code(400);
            echo json_encode(['success' => false, 'error' => 'Invalid action']);
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Server error: ' . $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ]);
}

/**
 * Initiate IVR call through Click2Call API
 */
function initiateCall($pdo) {
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $rawInput = file_get_contents('php://input');
        $input = json_decode($rawInput, true);
        error_log('POST Raw input: ' . $rawInput);
    } else if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        $input = $_GET;
        error_log('GET input: ' . json_encode($input));
    } else {
        echo json_encode(['success' => false, 'error' => 'Method not allowed']);
        return;
    }
    
    $driverMobile = $input['driver_mobile'] ?? '';
    $callerId = (int)($input['caller_id'] ?? 0);
    $driverId = $input['driver_id'] ?? null; // Can be string or int
    
    error_log("📞 Click2Call - Driver Mobile: $driverMobile, Caller ID: $callerId, Driver ID: $driverId");
    
    if (empty($driverMobile) || empty($callerId)) {
        http_response_code(400);
        echo json_encode([
            'success' => false, 
            'error' => 'Driver mobile and caller ID required',
            'received' => [
                'driver_mobile' => $driverMobile,
                'caller_id' => $callerId
            ]
        ]);
        return;
    }
    
    try {
        // Get telecaller info from admins table (only telecallers, not admins)
        $stmt = $pdo->prepare("SELECT mobile, name, role FROM admins WHERE id = ? AND role = 'telecaller'");
        $stmt->execute([$callerId]);
        $telecaller = $stmt->fetch();
        
        error_log("Telecaller query result: " . json_encode($telecaller));
        
        if (!$telecaller) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'error' => 'Telecaller not found or user is not a telecaller',
                'caller_id' => $callerId,
                'note' => 'Only users with role=telecaller can make calls'
            ]);
            return;
        }
        
        // Get driver/transporter info from users table
        $stmt = $pdo->prepare("SELECT id, name, mobile, role FROM users WHERE mobile = ? AND role IN ('driver', 'transporter')");
        $stmt->execute([$driverMobile]);
        $driver = $stmt->fetch();
        
        error_log("Driver query result: " . json_encode($driver));
        
        if (!$driver) {
            http_response_code(404);
            echo json_encode([
                'success' => false,
                'error' => 'User not found in database',
                'driver_mobile' => $driverMobile,
                'note' => 'User must exist in users table with role=driver or transporter'
            ]);
            return;
        }
        
        // Clean phone numbers - remove all non-digits
        $cleanDriverMobile = preg_replace('/[^0-9]/', '', $driver['mobile']);
        $cleanTelecallerMobile = preg_replace('/[^0-9]/', '', $telecaller['mobile']);
        
        // Ensure 10 digits
        if (strlen($cleanDriverMobile) > 10) {
            $cleanDriverMobile = substr($cleanDriverMobile, -10);
        }
        if (strlen($cleanTelecallerMobile) > 10) {
            $cleanTelecallerMobile = substr($cleanTelecallerMobile, -10);
        }
        
        error_log('📱 Call Setup: Driver=' . $cleanDriverMobile . ', Telecaller=' . $cleanTelecallerMobile);
        
        // Generate unique reference ID
        $referenceId = 'C2C_' . time() . '_' . $callerId . '_' . $driver['id'];
        
        // Prepare Click2Call API payload
        $payload = [
            'sourcetype' => '0',
            'customivr' => true,
            'credittype' => '2',
            'filetype' => '2',
            'ukey' => CLICK2CALL_UKEY,
            'serviceno' => CLICK2CALL_SERVICE_NO,
            'ivrtemplateid' => CLICK2CALL_IVR_TEMPLATE_ID,
            'custcli' => CLICK2CALL_SERVICE_NO,
            'isrefno' => true,
            'msisdnlist' => [
                [
                    'phoneno' => $cleanDriverMobile,      // Driver's phone number
                    'agentno' => $cleanTelecallerMobile   // Telecaller's phone number from admins table
                ]
            ]
        ];
        
        error_log('🚀 Click2Call Payload: ' . json_encode($payload));
        
        // Call Click2Call API
        $apiResponse = callClick2CallAPI($payload);
        
        $status = $apiResponse['success'] ? 'initiated' : 'failed';
        
        // Save to call_logs
        $sql = "INSERT INTO call_logs 
                (caller_id, user_id, caller_number, user_number, driver_name, call_status, 
                 reference_id, api_response, call_time, created_at, updated_at) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), NOW())";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            $callerId,
            $driver['id'],
            $cleanTelecallerMobile,
            $cleanDriverMobile,
            $driver['name'],
            'pending',
            $referenceId,
            json_encode($apiResponse['data'])
        ]);
        
        $callLogId = $pdo->lastInsertId();
        
        // Prepare response
        if ($apiResponse['success']) {
            $message = '📞 IVR call initiated successfully via Click2Call!';
            $instructions = [
                'step1' => '📱 Driver phone (' . $cleanDriverMobile . ') will ring',
                'step2' => '🎵 IVR message will play to driver',
                'step3' => '📞 Telecaller phone (' . $cleanTelecallerMobile . ') will connect',
                'step4' => '✅ Call will be connected between both parties'
            ];
        } else {
            $message = '❌ Call initiation failed. Check Click2Call API response.';
            $instructions = [
                'error' => $apiResponse['data']['error'] ?? 'Unknown error'
            ];
        }
        
        $responseData = [
            'success' => true,
            'message' => $message,
            'data' => [
                'call_log_id' => $callLogId,
                'reference_id' => $referenceId,
                'status' => $status,
                'driver_name' => $driver['name'],
                'driver_number' => $cleanDriverMobile,
                'telecaller_name' => $telecaller['name'],
                'telecaller_number' => $cleanTelecallerMobile,
                'call_flow' => $instructions,
                'api_response' => $apiResponse['data']
            ],
            'timestamp' => date('Y-m-d H:i:s')
        ];
        
        error_log('📤 Sending response: ' . json_encode($responseData));
        echo json_encode($responseData);
        
    } catch(Exception $e) {
        http_response_code(500);
        error_log("Exception in initiateCall: " . $e->getMessage());
        error_log("Stack trace: " . $e->getTraceAsString());
        echo json_encode([
            'success' => false,
            'error' => 'Failed to initiate call: ' . $e->getMessage(),
            'file' => $e->getFile(),
            'line' => $e->getLine()
        ]);
    }
}

/**
 * Get call status by reference ID
 */
function getCallStatus($pdo) {
    $referenceId = $_GET['reference_id'] ?? '';
    
    if (empty($referenceId)) {
        echo json_encode(['success' => false, 'error' => 'Reference ID required']);
        return;
    }
    
    try {
        $sql = "SELECT 
                    cl.*,
                    u.name as driver_name,
                    u.mobile as driver_mobile,
                    tc.name as telecaller_name,
                    tc.mobile as telecaller_mobile
                FROM call_logs cl
                INNER JOIN users u ON cl.user_id = u.id
                INNER JOIN admins tc ON cl.caller_id = tc.id
                WHERE cl.reference_id = ?";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([$referenceId]);
        $callLog = $stmt->fetch();
        
        if (!$callLog) {
            echo json_encode(['success' => false, 'error' => 'Call log not found']);
            return;
        }
        
        echo json_encode([
            'success' => true,
            'data' => [
                'id' => $callLog['id'],
                'reference_id' => $callLog['reference_id'],
                'call_status' => $callLog['call_status'],
                'call_duration' => $callLog['call_duration'],
                'feedback' => $callLog['feedback'],
                'remarks' => $callLog['remarks'],
                'driver_name' => $callLog['driver_name'],
                'driver_mobile' => $callLog['driver_mobile'],
                'telecaller_name' => $callLog['telecaller_name'],
                'call_time' => $callLog['call_time'],
                'api_response' => json_decode($callLog['api_response'], true)
            ]
        ]);
        
    } catch(Exception $e) {
        echo json_encode(['success' => false, 'error' => 'Failed to get call status: ' . $e->getMessage()]);
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
    
    $input = json_decode(file_get_contents('php://input'), true);
    $referenceId = $input['reference_id'] ?? '';
    $callStatus = $input['call_status'] ?? 'pending';
    $feedback = $input['feedback'] ?? '';
    $remarks = $input['remarks'] ?? '';
    $callDuration = $input['call_duration'] ?? 0;
    
    if (empty($referenceId)) {
        echo json_encode(['success' => false, 'error' => 'Reference ID required']);
        return;
    }
    
    try {
        $sql = "UPDATE call_logs 
                SET call_status = ?, 
                    feedback = ?, 
                    remarks = ?,
                    call_duration = ?,
                    updated_at = NOW()
                WHERE reference_id = ?";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([$callStatus, $feedback, $remarks, $callDuration, $referenceId]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Call feedback updated successfully',
            'timestamp' => date('Y-m-d H:i:s')
        ]);
        
    } catch(Exception $e) {
        echo json_encode(['success' => false, 'error' => 'Failed to update feedback: ' . $e->getMessage()]);
    }
}

/**
 * Call Click2Call IVR API
 */
function callClick2CallAPI($payload) {
    error_log('🚀 Calling Click2Call API');
    error_log('📞 API URL: ' . CLICK2CALL_API_URL);
    error_log('📦 Payload: ' . json_encode($payload));
    
    $ch = curl_init(CLICK2CALL_API_URL);
    
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'Accept: application/json'
        ],
        CURLOPT_POSTFIELDS => json_encode($payload),
        CURLOPT_TIMEOUT => 30,
        CURLOPT_SSL_VERIFYPEER => false,  // Disable SSL verification for this API
        CURLOPT_SSL_VERIFYHOST => false
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    if ($error) {
        error_log('❌ Click2Call API Error: ' . $error);
        return [
            'success' => false,
            'data' => [
                'error' => $error,
                'message' => 'Failed to connect to Click2Call API'
            ]
        ];
    }
    
    $responseData = json_decode($response, true) ?? [];
    
    error_log('✅ Click2Call Response (HTTP ' . $httpCode . '): ' . json_encode($responseData));
    
    $success = $httpCode >= 200 && $httpCode < 300;
    
    if ($success) {
        error_log('🎉 Call initiated successfully via Click2Call!');
    } else {
        error_log('⚠️ Call initiation failed: ' . json_encode($responseData));
    }
    
    return [
        'success' => $success,
        'http_code' => $httpCode,
        'data' => $responseData
    ];
}
?>
