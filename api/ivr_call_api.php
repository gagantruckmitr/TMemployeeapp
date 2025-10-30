<?php
/**
 * IVR Smart Calling API
 * Integrates with MyOperator for automated calling
 */

// Suppress all errors from being displayed (they'll still be logged)
error_reporting(0);
ini_set('display_errors', '0');

// Clean any output buffer that might have errors
if (ob_get_level()) {
    ob_end_clean();
}
ob_start();

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

// Handle preflight OPTIONS requests
if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

// Database configuration - From .env
$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

// Load .env file
$envFile = __DIR__ . '/../.env';
$envVars = [];
if (file_exists($envFile)) {
    // Read all lines without skipping empty ones to ensure we get everything
    $lines = file($envFile, FILE_IGNORE_NEW_LINES);
    foreach ($lines as $line) {
        $line = trim($line);
        // Skip empty lines and comments
        if (empty($line) || strpos($line, '#') === 0) continue;
        if (strpos($line, '=') === false) continue;
        list($key, $value) = explode('=', $line, 2);
        $envVars[trim($key)] = trim($value);
    }
}

// MyOperator API Configuration - From .env
$rawCallerId = $envVars['MYOPERATOR_CALLER_ID'] ?? '911234567890';
// Clean caller_id - remove + and any non-digits
$cleanCallerId = preg_replace('/[^0-9]/', '', $rawCallerId);

define('MYOPERATOR_COMPANY_ID', $envVars['MYOPERATOR_COMPANY_ID'] ?? 'your_company_id');
define('MYOPERATOR_SECRET_TOKEN', $envVars['MYOPERATOR_SECRET_TOKEN'] ?? 'your_secret_token');
define('MYOPERATOR_IVR_ID', $envVars['MYOPERATOR_IVR_ID'] ?? 'your_ivr_id');
define('MYOPERATOR_API_KEY', $envVars['MYOPERATOR_API_KEY'] ?? 'your_api_key');
define('MYOPERATOR_CALLER_ID', $cleanCallerId);
define('MYOPERATOR_API_URL', $envVars['MYOPERATOR_API_URL'] ?? 'https://obd-api.myoperator.co/obd-api-v1');

// Log configuration for debugging
error_log('🔧 MyOperator Config Loaded:');
error_log('Company ID: ' . (MYOPERATOR_COMPANY_ID !== 'your_company_id' ? 'SET' : 'NOT SET'));
error_log('Caller ID: ' . MYOPERATOR_CALLER_ID);
error_log('API URL: ' . MYOPERATOR_API_URL);

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $pdo->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
} catch(PDOException $e) {
    // Clean output buffer before sending response
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
        initiateCall($pdo);
        break;
    case 'call_status':
        getCallStatus($pdo);
        break;
    case 'update_feedback':
        updateCallFeedback($pdo);
        break;
    default:
        echo json_encode(['success' => false, 'error' => 'Invalid action']);
}

// Clean and send output
$output = ob_get_clean();
echo $output;

/**
 * Initiate IVR call through MyOperator
 */
function initiateCall($pdo) {
    // Accept both POST and GET for flexibility (GET for testing, POST for production)
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        // Get raw POST data
        $rawInput = file_get_contents('php://input');
        $input = json_decode($rawInput, true);
        
        // Log for debugging
        error_log('POST Raw input: ' . $rawInput);
        error_log('POST Parsed input: ' . json_encode($input));
    } else if ($_SERVER['REQUEST_METHOD'] === 'GET') {
        // For testing via browser
        $input = $_GET;
        error_log('GET input: ' . json_encode($input));
    } else {
        echo json_encode(['success' => false, 'error' => 'Method not allowed. Use POST or GET.']);
        return;
    }
    
    $driverMobile = $input['driver_mobile'] ?? '';
    $callerId = (int)($input['caller_id'] ?? 0);
    $driverId = (int)($input['driver_id'] ?? 0);
    
    // Debug log
    error_log("Driver Mobile: $driverMobile, Caller ID: $callerId, Driver ID: $driverId");
    
    if (empty($driverMobile) || empty($callerId)) {
        echo json_encode([
            'success' => false, 
            'error' => 'Driver mobile and caller ID required',
            'received' => [
                'driver_mobile' => $driverMobile,
                'caller_id' => $callerId,
                'driver_id' => $driverId
            ],
            'debug' => 'Check if data is being sent correctly from app'
        ]);
        return;
    }
    
    try {
        // Get telecaller info from admins table
        $stmt = $pdo->prepare("SELECT mobile, name FROM admins WHERE id = ?");
        $stmt->execute([$callerId]);
        $telecaller = $stmt->fetch();
        
        if (!$telecaller) {
            echo json_encode([
                'success' => false,
                'error' => 'Telecaller not found in database',
                'caller_id' => $callerId,
                'debug' => 'Please ensure telecaller exists in admins table'
            ]);
            return;
        }
        
        // Get user info from database (driver or transporter)
        $stmt = $pdo->prepare("SELECT id, name, mobile, role FROM users WHERE mobile = ? AND role IN ('driver', 'transporter')");
        $stmt->execute([$driverMobile]);
        $driver = $stmt->fetch();
        
        if (!$driver) {
            echo json_encode([
                'success' => false,
                'error' => 'User not found in database',
                'driver_mobile' => $driverMobile,
                'debug' => 'Please ensure user exists in users table with role=driver or transporter'
            ]);
            return;
        }
        
        // Prepare phone numbers in MyOperator format: +91XXXXXXXXXX
        $driverMobile = preg_replace('/[^0-9]/', '', $driver['mobile']);
        $telecallerMobile = preg_replace('/[^0-9]/', '', $telecaller['mobile']);
        
        // Ensure 10 digits
        if (strlen($driverMobile) > 10) {
            $driverMobile = substr($driverMobile, -10);
        }
        if (strlen($telecallerMobile) > 10) {
            $telecallerMobile = substr($telecallerMobile, -10);
        }
        
        // Add +91 prefix (MyOperator requires this format)
        $driverNumber = '+91' . $driverMobile;
        $telecallerNumber = '+91' . $telecallerMobile;
        
        // Log the numbers being used
        error_log('📞 Call Setup: Driver=' . $driverNumber . ', Telecaller=' . $telecallerNumber);
        
        // Generate unique reference ID
        $referenceId = 'TM_' . time() . '_' . $callerId . '_' . $driver['id'];
        
        // Prepare MyOperator Progressive Dialing API payload (Type 2)
        // Type 2 = Progressive Dialing - Calls driver FIRST, then connects to agent when driver picks up
        // This is the CORRECT method for telecaller workflow
        // IMPORTANT: ALL values must be strings for MyOperator API
        $payload = [
            'company_id' => (string)MYOPERATOR_COMPANY_ID,
            'secret_token' => (string)MYOPERATOR_SECRET_TOKEN,
            'type' => '2', // Type 2 = Progressive Dialing (Driver first!)
            'number' => (string)$driverNumber, // Driver called FIRST
            'agent_number' => (string)$telecallerNumber, // Telecaller connected when driver picks up
            'caller_id' => (string)MYOPERATOR_CALLER_ID, // Caller ID shown to driver
            'reference_id' => (string)$referenceId,
            'dtmf' => '0', // DTMF digit (optional)
            'retry' => '0', // No auto-retry
            'max_ring_time' => '30' // Ring for 30 seconds
        ];
        
        // Call MyOperator API for Progressive Dialing
        $apiResponse = callMyOperatorAPI($payload);
        
        $status = $apiResponse['success'] ? 'initiated' : 'failed';
        $isSimulation = isset($apiResponse['data']['simulation']) && $apiResponse['data']['simulation'];
        
        // Save to call_logs (using caller_id only)
        $sql = "INSERT INTO call_logs 
                (caller_id, user_id, caller_number, user_number, driver_name, call_status, 
                 reference_id, api_response, call_time, created_at, updated_at) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), NOW())";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            $callerId,
            $driver['id'],
            $telecallerNumber,
            $driverNumber,
            $driver['name'],
            'pending',
            $referenceId,
            json_encode($apiResponse['data'])
        ]);
        
        $callLogId = $pdo->lastInsertId();
        
        // Prepare response message based on call status
        if ($apiResponse['success']) {
            $message = '📞 REAL IVR call initiated successfully!';
            $instructions = [
                'step1' => '📱 Driver phone (' . $driverNumber . ') rings FIRST',
                'step2' => '🎵 When driver picks up, they hear IVR message',
                'step3' => '📞 Your phone (' . $telecallerNumber . ') rings NEXT',
                'step4' => '✅ When you pick up - INSTANT connection to driver!'
            ];
        } else {
            $message = '❌ Call initiation failed. Check MyOperator credentials.';
            $instructions = [
                'step1' => 'Verify MyOperator credentials in .env file',
                'step2' => 'Check MyOperator account balance',
                'step3' => 'Ensure phone numbers are valid',
                'step4' => 'Contact MyOperator support if issue persists'
            ];
        }
        
        // Clean output buffer and send response
        $responseData = [
            'success' => true,
            'message' => $message,
            'simulation_mode' => $isSimulation,
            'data' => [
                'call_log_id' => $callLogId,
                'reference_id' => $referenceId,
                'status' => $status,
                'driver_name' => $driver['name'],
                'driver_number' => $driverNumber,
                'telecaller_name' => $telecaller['name'],
                'telecaller_number' => $telecallerNumber,
                'call_flow' => $instructions,
                'api_response' => $apiResponse['data']
            ],
            'timestamp' => date('Y-m-d H:i:s')
        ];
        
        // Log the response for debugging
        error_log('📤 Sending response: ' . json_encode($responseData));
        
        echo json_encode($responseData);
        
    } catch(Exception $e) {
        echo json_encode([
            'success' => false,
            'error' => 'Failed to initiate call: ' . $e->getMessage()
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
 * Call MyOperator Progressive Dialing API
 * This calls driver FIRST, then connects telecaller when driver picks up
 * 
 * WORKS ON BOTH LOCAL AND PRODUCTION - Makes REAL calls via MyOperator
 */
function callMyOperatorAPI($payload) {
    // Check if MyOperator credentials are properly configured
    $myOperatorConfigured = (
        MYOPERATOR_COMPANY_ID !== 'your_company_id' && 
        MYOPERATOR_SECRET_TOKEN !== 'your_secret_token' &&
        MYOPERATOR_API_KEY !== 'your_api_key' &&
        !empty(MYOPERATOR_COMPANY_ID) &&
        !empty(MYOPERATOR_SECRET_TOKEN) &&
        !empty(MYOPERATOR_API_KEY)
    );
    
    // If MyOperator is not configured, return error
    if (!$myOperatorConfigured) {
        error_log('⚠️ MyOperator not configured properly');
        error_log('📝 Please update .env with valid MyOperator credentials');
        
        return [
            'success' => false,
            'http_code' => 500,
            'data' => [
                'status' => 'error',
                'message' => 'MyOperator not configured. Please contact administrator.',
                'error' => 'Missing or invalid MyOperator credentials',
                'simulation' => false,
                'note' => 'Update .env file with valid MyOperator credentials from myoperator.com'
            ]
        ];
    }
    
    // Make REAL MyOperator API call (works on both local and production)
    $environment = (DB_HOST === '127.0.0.1' || DB_HOST === 'localhost') ? 'LOCAL' : 'PRODUCTION';
    error_log('🚀 ' . $environment . ' SERVER: Initiating REAL MyOperator call');
    error_log('📞 MyOperator Progressive Dialing (Type 2)');
    error_log('Driver (called FIRST): ' . $payload['number']);
    error_log('Telecaller (connected when driver picks up): ' . $payload['agent_number']);
    error_log('Reference: ' . $payload['reference_id']);
    error_log('API URL: ' . MYOPERATOR_API_URL);
    error_log('Company ID: ' . MYOPERATOR_COMPANY_ID);
    error_log('Payload: ' . json_encode($payload));
    
    $ch = curl_init(MYOPERATOR_API_URL);
    
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => [
            'x-api-key: ' . MYOPERATOR_API_KEY,
            'Content-Type: application/json'
        ],
        CURLOPT_POSTFIELDS => json_encode($payload),
        CURLOPT_TIMEOUT => 30,
        CURLOPT_SSL_VERIFYPEER => true,
        CURLOPT_SSL_VERIFYHOST => 2
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    if ($error) {
        error_log('❌ MyOperator API Error: ' . $error);
        return [
            'success' => false,
            'data' => [
                'error' => $error,
                'message' => 'Failed to connect to MyOperator API',
                'troubleshooting' => 'Check internet connection and MyOperator credentials'
            ]
        ];
    }
    
    $responseData = json_decode($response, true) ?? [];
    
    // Log the response for debugging
    error_log('✅ MyOperator Response (HTTP ' . $httpCode . '): ' . json_encode($responseData));
    
    $success = $httpCode >= 200 && $httpCode < 300;
    
    if ($success) {
        error_log('🎉 Call initiated successfully!');
        error_log('📱 Driver will receive call FIRST, telecaller connected when driver picks up');
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
