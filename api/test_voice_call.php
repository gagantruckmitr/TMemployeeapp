<?php
/**
 * IVR Smart Calling API
 * Integrates with MyOperator for automated calling
 */
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
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos(trim($line), '#') === 0) continue;
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
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Database connection failed: ' . $e->getMessage()]);
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

/**
 * Initiate IVR call through MyOperator
 */
function initiateCall($pdo) {
    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        echo json_encode(['success' => false, 'error' => 'Method not allowed']);
        return;
    }
    
    // Get raw POST data
    $rawInput = file_get_contents('php://input');
    $input = json_decode($rawInput, true);
    
    // Log for debugging
    error_log('Raw input: ' . $rawInput);
    error_log('Parsed input: ' . json_encode($input));
    
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
            // If telecaller not found, use default values for testing
            $telecaller = [
                'mobile' => '9999999999',
                'name' => 'Test Telecaller'
            ];
            error_log('⚠️ Telecaller not found, using test values');
        }
        
        // Get driver info - try to find in database first
        $stmt = $pdo->prepare("SELECT id, name, mobile FROM users WHERE mobile = ? AND role = 'driver'");
        $stmt->execute([$driverMobile]);
        $driver = $stmt->fetch();
        
        if (!$driver) {
            // If driver not found, create temporary driver data for testing
            $driver = [
                'id' => 0,
                'name' => 'Test Driver',
                'mobile' => $driverMobile
            ];
            error_log('⚠️ Driver not found in database, using provided mobile: ' . $driverMobile);
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
        
        // Generate unique reference ID
        $referenceId = 'TM_' . time() . '_' . $callerId . '_' . $driver['id'];
        
        // Prepare MyOperator Click-to-Call API payload
        // This connects driver and telecaller for two-way voice conversation
        // IMPORTANT: ALL values must be strings for MyOperator API
        $payload = [
            'company_id' => (string)MYOPERATOR_COMPANY_ID,
            'secret_token' => (string)MYOPERATOR_SECRET_TOKEN,
            'type' => '1', // Type 1 = Click to Call (connects two numbers)
            'number' => (string)$driverNumber, // Driver's number (called first) - MUST be string
            'number_2' => (string)$telecallerNumber, // Telecaller's number (called second) - MUST be string
            'public_ivr_id' => (string)MYOPERATOR_IVR_ID, // IVR flow for voice prompts
            'reference_id' => (string)$referenceId,
            'caller_id' => (string)MYOPERATOR_CALLER_ID, // Your MyOperator number
            'dtmf' => '1', // Auto-accept call (no need to press 1)
            'retry' => '1', // Retry if busy
            'max_ring_time' => '45' // Ring for 45 seconds
        ];
        
        // Call MyOperator API for Click-to-Call
        $apiResponse = callMyOperatorAPI($payload);
        
        $status = $apiResponse['success'] ? 'initiated' : 'failed';
        $isSimulation = isset($apiResponse['data']['simulation']) && $apiResponse['data']['simulation'];
        
        // Save to call_logs
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
        
        // Prepare response message
        if ($isSimulation) {
            $message = 'SIMULATION MODE: Configure MyOperator in .env for real voice calls';
            $instructions = [
                'step1' => 'Sign up at myoperator.com',
                'step2' => 'Get API credentials from dashboard',
                'step3' => 'Update .env file with credentials',
                'step4' => 'Restart server and try again'
            ];
        } else {
            $message = 'Call initiated! Driver will receive call first, then you will be connected.';
            $instructions = [
                'step1' => 'Driver phone will ring first',
                'step2' => 'Driver hears: "Hello, this is TruckMitr calling..."',
                'step3' => 'Your phone will ring next',
                'step4' => 'Both connected - you can talk!'
            ];
        }
        
        echo json_encode([
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
        ]);
        
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
 * Call MyOperator Click-to-Call API
 * This connects telecaller and driver for two-way voice conversation
 */
function callMyOperatorAPI($payload) {
    // Check if MyOperator is properly configured
    if (MYOPERATOR_COMPANY_ID === 'your_company_id' || 
        MYOPERATOR_SECRET_TOKEN === 'your_secret_token' ||
        MYOPERATOR_API_KEY === 'your_api_key') {
        
        // Return simulated success for testing when MyOperator is not configured
        error_log('⚠️ MyOperator not configured - returning simulated response');
        error_log('📝 To enable real voice calls, update .env with MyOperator credentials');
        
        return [
            'success' => true,
            'http_code' => 200,
            'data' => [
                'status' => 'success',
                'message' => 'SIMULATION MODE - Configure MyOperator for real voice calls',
                'call_id' => 'sim_' . uniqid(),
                'call_duration' => rand(30, 180),
                'simulation' => true,
                'note' => 'Update .env file with MyOperator credentials to enable real calls'
            ]
        ];
    }
    
    // Log the API call
    error_log('📞 Initiating MyOperator Click-to-Call');
    error_log('Driver: ' . $payload['number']);
    error_log('Telecaller: ' . $payload['number_2']);
    error_log('Reference: ' . $payload['reference_id']);
    
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
        error_log('📱 Driver will receive call first, then telecaller');
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
