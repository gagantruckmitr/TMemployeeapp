<?php
/**
 * Simplified Phase 2 Call Feedback API with detailed error logging
 */

require_once 'config.php';

// Enable error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');

// Log file for debugging
$logFile = __DIR__ . '/feedback_errors.log';

function logError($message) {
    global $logFile;
    $timestamp = date('Y-m-d H:i:s');
    file_put_contents($logFile, "[$timestamp] $message\n", FILE_APPEND);
}

function sendSuccess($data, $message = 'Success') {
    echo json_encode([
        'success' => true,
        'message' => $message,
        'data' => $data
    ]);
    exit;
}

function sendError($message, $code = 400) {
    logError("ERROR $code: $message");
    http_response_code($code);
    echo json_encode([
        'success' => false,
        'message' => $message
    ]);
    exit;
}

// Only handle POST requests
if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendError('Method not allowed. Use POST.', 405);
}

// Check database connection
if (!$conn) {
    sendError('Database connection failed', 500);
}

// Get raw POST data
$rawData = file_get_contents('php://input');
logError("Raw POST data: " . $rawData);

// Decode JSON
$data = json_decode($rawData, true);

if (!$data) {
    sendError('Invalid JSON data: ' . json_last_error_msg(), 400);
}

logError("Decoded data: " . print_r($data, true));

try {
    // Extract and validate data
    $callerId = isset($data['callerId']) ? (int)$data['callerId'] : 0;
    
    if ($callerId === 0) {
        sendError('Caller ID is required', 400);
    }
    
    // Get IDs - handle empty strings
    $uniqueIdTransporter = '';
    if (isset($data['uniqueIdTransporter']) && trim($data['uniqueIdTransporter']) !== '') {
        $uniqueIdTransporter = $conn->real_escape_string(trim($data['uniqueIdTransporter']));
    }
    
    $uniqueIdDriver = '';
    if (isset($data['uniqueIdDriver']) && trim($data['uniqueIdDriver']) !== '') {
        $uniqueIdDriver = $conn->real_escape_string(trim($data['uniqueIdDriver']));
    }
    
    // If no driver TMID but we have driverId, look it up
    $driverId = isset($data['driverId']) ? (int)$data['driverId'] : 0;
    if (empty($uniqueIdDriver) && $driverId > 0) {
        $driverQuery = "SELECT unique_id FROM users WHERE id = $driverId LIMIT 1";
        $driverResult = $conn->query($driverQuery);
        if ($driverResult && $driverResult->num_rows > 0) {
            $driverRow = $driverResult->fetch_assoc();
            $uniqueIdDriver = $driverRow['unique_id'] ?? '';
        }
    }
    
    // Validate at least one ID
    if (empty($uniqueIdTransporter) && empty($uniqueIdDriver)) {
        sendError('Either transporter TMID or driver TMID is required', 400);
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
    $additionalNotes = isset($data['additionalNotes']) 
        ? $conn->real_escape_string($data['additionalNotes']) : '';
    $jobId = isset($data['jobId']) && trim($data['jobId']) !== '' 
        ? $conn->real_escape_string(trim($data['jobId'])) : null;
    
    if (!$feedback) {
        sendError('Feedback is required', 400);
    }
    
    // Build INSERT query
    $query = "INSERT INTO call_logs_match_making 
              (caller_id, unique_id_transporter, unique_id_driver, driver_name, transporter_name, feedback, match_status, remark, job_id, created_at, updated_at) 
              VALUES 
              ($callerId, 
               '$uniqueIdTransporter', 
               '$uniqueIdDriver', 
               " . ($driverName ? "'$driverName'" : "NULL") . ", 
               " . ($transporterName ? "'$transporterName'" : "NULL") . ", 
               '$feedback', 
               " . ($matchStatus ? "'$matchStatus'" : "NULL") . ", 
               " . (!empty($additionalNotes) ? "'$additionalNotes'" : "NULL") . ", 
               " . ($jobId ? "'$jobId'" : "NULL") . ", 
               NOW(), NOW())";
    
    logError("SQL Query: " . $query);
    
    if ($conn->query($query)) {
        $insertId = $conn->insert_id;
        logError("SUCCESS: Inserted feedback with ID: $insertId");
        sendSuccess(['id' => $insertId], 'Call feedback saved successfully');
    } else {
        $error = $conn->error;
        logError("SQL Error: " . $error);
        sendError('Database error: ' . $error, 500);
    }
    
} catch (Exception $e) {
    logError("Exception: " . $e->getMessage());
    sendError('Exception: ' . $e->getMessage(), 500);
}
?>
