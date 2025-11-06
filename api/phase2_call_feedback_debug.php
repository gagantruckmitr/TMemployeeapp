<?php
/**
 * Debug version - logs everything
 */

error_reporting(E_ALL);
ini_set('display_errors', 0);

header('Content-Type: application/json');

// Database connection
$host = '127.0.0.1';
$port = 3306;
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

$logFile = __DIR__ . '/feedback_debug.log';

function logDebug($message) {
    global $logFile;
    file_put_contents($logFile, date('Y-m-d H:i:s') . " - " . $message . "\n", FILE_APPEND);
}

try {
    $conn = new mysqli($host, $username, $password, $dbname, $port);
    if ($conn->connect_error) {
        throw new Exception('DB connection failed');
    }
    $conn->set_charset('utf8mb4');
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error']);
    exit;
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

$rawData = file_get_contents('php://input');
logDebug("RAW DATA: " . $rawData);

$data = json_decode($rawData, true);
logDebug("DECODED DATA: " . print_r($data, true));

if (!$data) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid JSON']);
    exit;
}

$callerId = isset($data['callerId']) ? (int)$data['callerId'] : 0;
logDebug("Caller ID: $callerId");

if ($callerId === 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Caller ID required']);
    exit;
}

// Get TMIDs
$transporterTmid = '';
if (isset($data['uniqueIdTransporter'])) {
    logDebug("uniqueIdTransporter exists: " . $data['uniqueIdTransporter']);
    if (trim($data['uniqueIdTransporter']) !== '') {
        $transporterTmid = $conn->real_escape_string(trim($data['uniqueIdTransporter']));
        logDebug("Transporter TMID set to: $transporterTmid");
    } else {
        logDebug("uniqueIdTransporter is empty string");
    }
} else {
    logDebug("uniqueIdTransporter NOT in request");
}

$driverTmid = '';
if (isset($data['uniqueIdDriver']) && trim($data['uniqueIdDriver']) !== '') {
    $driverTmid = $conn->real_escape_string(trim($data['uniqueIdDriver']));
    logDebug("Driver TMID: $driverTmid");
}

$driverId = isset($data['driverId']) ? (int)$data['driverId'] : 0;
if (empty($driverTmid) && $driverId > 0) {
    $result = $conn->query("SELECT unique_id FROM users WHERE id = $driverId LIMIT 1");
    if ($result && $result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $driverTmid = $row['unique_id'] ?? '';
        logDebug("Looked up driver TMID from ID: $driverTmid");
    }
}

if (empty($transporterTmid) && empty($driverTmid)) {
    logDebug("ERROR: Both TMIDs are empty");
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Either transporter or driver TMID required']);
    exit;
}

$driverName = isset($data['driverName']) && trim($data['driverName']) !== '' 
    ? $conn->real_escape_string(trim($data['driverName'])) : null;
$transporterName = isset($data['transporterName']) && trim($data['transporterName']) !== '' 
    ? $conn->real_escape_string(trim($data['transporterName'])) : null;
$feedback = isset($data['feedback']) && trim($data['feedback']) !== '' 
    ? $conn->real_escape_string(trim($data['feedback'])) : null;

logDebug("Driver Name: " . ($driverName ?? 'NULL'));
logDebug("Transporter Name: " . ($transporterName ?? 'NULL'));
logDebug("Feedback: " . ($feedback ?? 'NULL'));

// Lookup names if missing
if (!$transporterName && !empty($transporterTmid)) {
    $result = $conn->query("SELECT name FROM transporters WHERE unique_id = '$transporterTmid' LIMIT 1");
    if ($result && $result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $transporterName = $row['name'] ?? null;
        logDebug("Looked up transporter name: " . ($transporterName ?? 'NULL'));
    } else {
        logDebug("No transporter found for TMID: $transporterTmid");
    }
}

if (!$driverName && !empty($driverTmid)) {
    $result = $conn->query("SELECT name FROM users WHERE unique_id = '$driverTmid' LIMIT 1");
    if ($result && $result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $driverName = $row['name'] ?? null;
        logDebug("Looked up driver name: " . ($driverName ?? 'NULL'));
    }
}

$matchStatus = isset($data['matchStatus']) && trim($data['matchStatus']) !== '' 
    ? $conn->real_escape_string(trim($data['matchStatus'])) : null;
$notes = isset($data['additionalNotes']) 
    ? $conn->real_escape_string($data['additionalNotes']) : '';
$jobId = isset($data['jobId']) && trim($data['jobId']) !== '' 
    ? $conn->real_escape_string(trim($data['jobId'])) : null;

if (!$feedback) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Feedback required']);
    exit;
}

$sql = "INSERT INTO call_logs_match_making 
        (caller_id, unique_id_transporter, unique_id_driver, driver_name, transporter_name, feedback, match_status, remark, job_id, created_at, updated_at) 
        VALUES 
        ($callerId, 
         '$transporterTmid', 
         '$driverTmid', 
         " . ($driverName ? "'$driverName'" : "NULL") . ", 
         " . ($transporterName ? "'$transporterName'" : "NULL") . ", 
         '$feedback', 
         " . ($matchStatus ? "'$matchStatus'" : "NULL") . ", 
         " . (!empty($notes) ? "'$notes'" : "NULL") . ", 
         " . ($jobId ? "'$jobId'" : "NULL") . ", 
         NOW(), NOW())";

logDebug("SQL: $sql");

if ($conn->query($sql)) {
    $insertId = $conn->insert_id;
    logDebug("SUCCESS: Inserted ID $insertId");
    echo json_encode([
        'success' => true,
        'message' => 'Feedback saved successfully',
        'data' => ['id' => $insertId]
    ]);
} else {
    $error = $conn->error;
    logDebug("SQL ERROR: $error");
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $error
    ]);
}

$conn->close();
?>
