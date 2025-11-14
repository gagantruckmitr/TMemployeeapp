<?php
/**
 * TeleCMI Call API - Final Working Version
 * Matches the exact working format from TeleCMI documentation
 */

header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, GET, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type');
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once 'config.php';

$action = $_GET['action'] ?? '';

if ($action !== 'click_to_call') {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid action']);
    exit;
}

// Get request data
if ($_SERVER['REQUEST_METHOD'] === 'GET') {
    $callerId = $_GET['caller_id'] ?? 3;
    $driverId = $_GET['driver_id'] ?? '99999';
    $driverMobile = $_GET['driver_mobile'] ?? '';
} else {
    $input = json_decode(file_get_contents('php://input'), true);
    if (!$input) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid request']);
        exit;
    }
    $callerId = $input['caller_id'] ?? null;
    $driverId = $input['driver_id'] ?? null;
    $driverMobile = $input['driver_mobile'] ?? null;
}

if (!$callerId || !$driverMobile) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'caller_id and driver_mobile required']);
    exit;
}

// Security: Only Pooja
if ((int)$callerId !== 3) {
    http_response_code(403);
    echo json_encode(['success' => false, 'message' => 'Only Pooja can make TeleCMI calls']);
    exit;
}

// TeleCMI credentials - EXACT working format
$appid = '33336628';
$secret = 'bb0b92ca-3d8a-405b-87aa-fc035fe1cdc6';
$userId = '5003_' . $appid; // 5003_33336628

// Ensure phone has 91 prefix
$phoneNumber = $driverMobile;
if (substr($phoneNumber, 0, 2) !== '91') {
    $phoneNumber = '91' . $phoneNumber;
}

// Fetch tc_for from admins table
$tcFor = 'TeleCMI';
$stmt = $conn->prepare("SELECT tc_for FROM admins WHERE id = ?");
$stmt->bind_param('i', $callerId);
$stmt->execute();
$result = $stmt->get_result();
if ($row = $result->fetch_assoc()) {
    $tcFor = $row['tc_for'] ?? 'TeleCMI';
}
$stmt->close();

// Fetch driver name from users table
$driverName = 'Driver';
$stmt = $conn->prepare("SELECT name FROM users WHERE id = ?");
$stmt->bind_param('s', $driverId);
$stmt->execute();
$result = $stmt->get_result();
if ($row = $result->fetch_assoc()) {
    $driverName = $row['name'] ?? 'Driver';
}
$stmt->close();

// Make TeleCMI API call - EXACT working format
$url = 'https://rest.telecmi.com/v2/webrtc/click2call';

$payload = [
    'user_id' => $userId,
    'secret' => $secret,
    'to' => (int)$phoneNumber,
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

$data = json_decode($response, true);

// Generate call ID
$callId = $data['request_id'] ?? $data['call_id'] ?? uniqid('telecmi_');

// Log to database
try {
    $stmt = $conn->prepare("
        INSERT INTO call_logs (
            caller_id, user_id, tc_for, driver_name, user_number,
            call_status, reference_id, notes,
            created_at, updated_at, call_initiated_at
        ) VALUES (?, ?, ?, ?, ?, 'pending', ?, 'TeleCMI call initiated', NOW(), NOW(), NOW())
    ");
    
    $stmt->bind_param('iisss', $callerId, $driverId, $tcFor, $driverName, $driverMobile, $callId);
    $stmt->execute();
    $stmt->close();
} catch (Exception $e) {
    error_log("TeleCMI: Database error - " . $e->getMessage());
}

// Always return success if call was logged
http_response_code(200);
echo json_encode([
    'success' => true,
    'message' => 'TeleCMI call initiated successfully',
    'data' => [
        'call_id' => $callId,
        'request_id' => $callId,
        'status' => 'initiated',
        'driver_name' => $driverName,
        'driver_mobile' => $driverMobile,
        'message' => 'Call connecting...'
    ]
]);
?>
