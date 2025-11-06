<?php
/**
 * Direct Phase 2 Call Feedback API - No dependencies
 */

error_reporting(E_ALL);
ini_set('display_errors', 0); // Don't display errors in response

header('Content-Type: application/json');

// Database connection
$host = '127.0.0.1';
$port = 3306;
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $conn = new mysqli($host, $username, $password, $dbname, $port);
    
    if ($conn->connect_error) {
        throw new Exception('Database connection failed: ' . $conn->connect_error);
    }
    
    $conn->set_charset('utf8mb4');
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Database error: ' . $e->getMessage()]);
    exit;
}

// Only handle POST
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

// Get and decode JSON
$rawData = file_get_contents('php://input');
$data = json_decode($rawData, true);

if (!$data) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Invalid JSON']);
    exit;
}

// Extract data
$callerId = isset($data['callerId']) ? (int)$data['callerId'] : 0;

if ($callerId === 0) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Caller ID required']);
    exit;
}

// Get TMIDs - treat empty strings as null
$transporterTmid = null;
if (isset($data['uniqueIdTransporter']) && trim($data['uniqueIdTransporter']) !== '') {
    $transporterTmid = $conn->real_escape_string(trim($data['uniqueIdTransporter']));
}

$driverTmid = '';
if (isset($data['uniqueIdDriver']) && trim($data['uniqueIdDriver']) !== '') {
    $driverTmid = $conn->real_escape_string(trim($data['uniqueIdDriver']));
}

// Lookup driver TMID if we have driverId but no TMID
$driverId = isset($data['driverId']) ? (int)$data['driverId'] : 0;
if (empty($driverTmid) && $driverId > 0) {
    $result = $conn->query("SELECT unique_id FROM users WHERE id = $driverId LIMIT 1");
    if ($result && $result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $driverTmid = $row['unique_id'] ?? '';
    }
}

// Validate
if (empty($transporterTmid) && empty($driverTmid)) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Either transporter or driver TMID required']);
    exit;
}

// Get other fields
$driverName = isset($data['driverName']) && trim($data['driverName']) !== '' 
    ? $conn->real_escape_string(trim($data['driverName'])) : null;
$transporterName = isset($data['transporterName']) && trim($data['transporterName']) !== '' 
    ? $conn->real_escape_string(trim($data['transporterName'])) : null;
$feedback = isset($data['feedback']) && trim($data['feedback']) !== '' 
    ? $conn->real_escape_string(trim($data['feedback'])) : null;
$matchStatus = isset($data['matchStatus']) && trim($data['matchStatus']) !== '' 
    ? $conn->real_escape_string(trim($data['matchStatus'])) : null;
$notes = isset($data['additionalNotes']) 
    ? $conn->real_escape_string($data['additionalNotes']) : '';
$jobId = isset($data['jobId']) && trim($data['jobId']) !== '' 
    ? $conn->real_escape_string(trim($data['jobId'])) : null;

// If we have jobId but no transporter TMID, look it up from the job
if (!$transporterTmid && !empty($jobId)) {
    $jobQuery = "SELECT j.transporter_id, u.unique_id, u.name 
                 FROM jobs j 
                 LEFT JOIN users u ON j.transporter_id = u.id 
                 WHERE j.job_id = '$jobId' LIMIT 1";
    $jobResult = $conn->query($jobQuery);
    if ($jobResult && $jobResult->num_rows > 0) {
        $jobRow = $jobResult->fetch_assoc();
        $transporterTmid = $jobRow['unique_id'] ?? '';
        if (!$transporterName) {
            $transporterName = $jobRow['name'] ?? null;
        }
    }
}

// Lookup transporter name if we have TMID but no name
if (!$transporterName && !empty($transporterTmid)) {
    $result = $conn->query("SELECT name FROM users WHERE unique_id = '$transporterTmid' AND role = 'transporter' LIMIT 1");
    if ($result && $result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $transporterName = $row['name'] ?? null;
    }
}

// Lookup driver name if we have TMID but no name
if (!$driverName && !empty($driverTmid)) {
    $result = $conn->query("SELECT name FROM users WHERE unique_id = '$driverTmid' AND role = 'driver' LIMIT 1");
    if ($result && $result->num_rows > 0) {
        $row = $result->fetch_assoc();
        $driverName = $row['name'] ?? null;
    }
}

if (!$feedback) {
    http_response_code(400);
    echo json_encode(['success' => false, 'message' => 'Feedback required']);
    exit;
}

// Build INSERT - convert null to empty string for NOT NULL columns
$sql = "INSERT INTO call_logs_match_making 
        (caller_id, unique_id_transporter, unique_id_driver, driver_name, transporter_name, feedback, match_status, remark, job_id, created_at, updated_at) 
        VALUES 
        ($callerId, 
         '" . ($transporterTmid ?? '') . "', 
         '" . ($driverTmid ?? '') . "', 
         " . ($driverName ? "'$driverName'" : "NULL") . ", 
         " . ($transporterName ? "'$transporterName'" : "NULL") . ", 
         '$feedback', 
         " . ($matchStatus ? "'$matchStatus'" : "NULL") . ", 
         " . (!empty($notes) ? "'$notes'" : "NULL") . ", 
         " . ($jobId ? "'$jobId'" : "NULL") . ", 
         NOW(), NOW())";

if ($conn->query($sql)) {
    echo json_encode([
        'success' => true,
        'message' => 'Feedback saved successfully',
        'data' => ['id' => $conn->insert_id]
    ]);
} else {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Database error: ' . $conn->error,
        'sql' => $sql
    ]);
}

$conn->close();
?>
