<?php
/**
 * Simple TeleCMI API - Minimal working version
 * This is the simplest possible implementation that works
 */

require_once 'config.php';

// Get action
$action = $_GET['action'] ?? '';

if ($action !== 'click_to_call') {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid action']);
    exit;
}

// Get POST data
$input = json_decode(file_get_contents('php://input'), true);

if (!$input || !isset($input['caller_id']) || !isset($input['driver_mobile'])) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Missing required fields']);
    exit;
}

$callerId = (int)$input['caller_id'];
$driverMobile = $input['driver_mobile'];
$driverId = $input['driver_id'] ?? 'unknown';

// Security: Only Pooja (user_id: 3)
if ($callerId !== 3) {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'Only Pooja can make TeleCMI calls']);
    exit;
}

// TeleCMI credentials (working ones)
$appid = '33336628';
$secret = 'bb0b92ca-3d8a-405b-87aa-fc035fe1cdc6';
$userId = '5003_' . $appid;

// Make TeleCMI API call
$url = 'https://rest.telecmi.com/v2/webrtc/click2call';

$payload = [
    'user_id' => $userId,
    'secret' => $secret,
    'to' => (int)$driverMobile,
    'webrtc' => false,
    'followme' => true
];

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

if ($httpCode == 200) {
    $data = json_decode($response, true);
    
    if ($data && isset($data['code']) && $data['code'] == 200) {
        $callId = $data['request_id'] ?? uniqid('telecmi_');
        
        // Log to database
        $stmt = $conn->prepare("
            INSERT INTO call_logs (
                caller_id, user_id, tc_for, driver_name, user_number,
                call_status, reference_id, notes,
                created_at, updated_at, call_initiated_at
            ) VALUES (?, ?, 'TeleCMI', 'Driver', ?, 'pending', ?, 'TeleCMI call initiated', NOW(), NOW(), NOW())
        ");
        
        $stmt->bind_param('iiss', $callerId, $driverId, $driverMobile, $callId);
        $stmt->execute();
        $stmt->close();
        
        // Success response
        http_response_code(200);
        echo json_encode([
            'success' => true,
            'message' => 'TeleCMI call initiated successfully',
            'data' => [
                'call_id' => $callId,
                'request_id' => $callId,
                'status' => 'initiated',
                'message' => 'Your phone will ring shortly'
            ]
        ]);
    } else {
        http_response_code(500);
        echo json_encode([
            'success' => false,
            'message' => $data['msg'] ?? 'TeleCMI API error'
        ]);
    }
} else {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Failed to connect to TeleCMI'
    ]);
}
?>
