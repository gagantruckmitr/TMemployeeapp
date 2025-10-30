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
    
    if (empty($driverMobile) || empty($callerId)) {
        echo json_encode([
            'success' => false, 
            'error' => 'Driver mobile and caller ID required',
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
        
        // Get driver info
        $stmt = $pdo->prepare("SELECT id, name, mobile, role FROM users WHERE mobile = ? AND role IN ('driver', 'transporter')");
        $stmt->execute([$driverMobile]);
        $driver = $stmt->fetch();
        
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
        
        // Save to call_logs (same structure as IVR)
        $sql = "INSERT INTO call_logs 
                (caller_id, user_id, caller_number, user_number, driver_name, call_status, 
                 reference_id, api_response, call_time, created_at, updated_at) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), NOW())";
        
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
?>
