<?php
/**
 * Phase 2 Transporter Call Recording Upload API - DEBUG VERSION
 * Uploads call recordings for transporter calls in match-making system
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

require_once 'config.php';

// Log file for debugging
$logFile = $_SERVER['DOCUMENT_ROOT'] . '/truckmitr-app/transporter_upload_debug.log';

function logDebug($message) {
    global $logFile;
    $timestamp = date('Y-m-d H:i:s');
    file_put_contents($logFile, "[$timestamp] $message\n", FILE_APPEND);
}

logDebug("=== NEW TRANSPORTER UPLOAD REQUEST ===");
logDebug("Request Method: " . $_SERVER['REQUEST_METHOD']);

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

try {
    // Get parameters
    $jobId = $_POST['job_id'] ?? '';
    $callerId = $_POST['caller_id'] ?? '';
    $transporterTmid = $_POST['transporter_tmid'] ?? '';
    
    logDebug("Job ID: $jobId");
    logDebug("Caller ID: $callerId");
    logDebug("Transporter TMID: $transporterTmid");
    
    if (empty($jobId) || empty($callerId) || empty($transporterTmid)) {
        logDebug("ERROR: Missing required parameters");
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'job_id, caller_id, and transporter_tmid are required']);
        exit;
    }
    
    // Check if file was uploaded
    logDebug("FILES array: " . print_r($_FILES, true));
    
    if (!isset($_FILES['recording'])) {
        logDebug("ERROR: No recording file in request");
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'No recording file in request']);
        exit;
    }
    
    if ($_FILES['recording']['error'] !== UPLOAD_ERR_OK) {
        logDebug("ERROR: Upload error code: " . $_FILES['recording']['error']);
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Upload error: ' . $_FILES['recording']['error']]);
        exit;
    }
    
    $file = $_FILES['recording'];
    logDebug("File name: " . $file['name']);
    logDebug("File size: " . $file['size']);
    logDebug("File tmp_name: " . $file['tmp_name']);
    logDebug("File exists in tmp: " . (file_exists($file['tmp_name']) ? 'YES' : 'NO'));
    
    // Get file extension (allow all audio formats)
    $fileExtension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    logDebug("File extension: $fileExtension");
    
    // Basic validation - just ensure it has an extension
    if (empty($fileExtension)) {
        logDebug("ERROR: No file extension");
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid file. File must have an extension.']);
        exit;
    }
    
    // Create filename: jobid_callerid_datetime.extension
    $datetime = date('YmdHis');
    $filename = "{$jobId}_{$callerId}_{$datetime}.{$fileExtension}";
    logDebug("Generated filename: $filename");
    
    // Define upload directory - use absolute path from document root
    $uploadDir = $_SERVER['DOCUMENT_ROOT'] . '/truckmitr-app/Match-making_call_recording/transporter/';
    logDebug("Upload directory: $uploadDir");
    logDebug("Directory exists: " . (file_exists($uploadDir) ? 'YES' : 'NO'));
    logDebug("Directory writable: " . (is_writable($uploadDir) ? 'YES' : 'NO'));
    
    // Create directory if it doesn't exist
    if (!file_exists($uploadDir)) {
        logDebug("Creating directory...");
        if (!mkdir($uploadDir, 0755, true)) {
            logDebug("ERROR: Failed to create directory");
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Failed to create upload directory: ' . $uploadDir]);
            exit;
        }
        logDebug("Directory created successfully");
    }
    
    $uploadPath = $uploadDir . $filename;
    logDebug("Full upload path: $uploadPath");
    
    // Move uploaded file
    logDebug("Attempting to move file...");
    if (!move_uploaded_file($file['tmp_name'], $uploadPath)) {
        $error = error_get_last();
        logDebug("ERROR: Failed to move file. Error: " . print_r($error, true));
        http_response_code(500);
        echo json_encode([
            'success' => false, 
            'message' => 'Failed to save recording file',
            'debug' => [
                'upload_dir' => $uploadDir,
                'upload_path' => $uploadPath,
                'tmp_name' => $file['tmp_name'],
                'error' => $error
            ]
        ]);
        exit;
    }
    
    logDebug("File moved successfully");
    logDebug("File exists at destination: " . (file_exists($uploadPath) ? 'YES' : 'NO'));
    
    if (file_exists($uploadPath)) {
        $actualSize = filesize($uploadPath);
        logDebug("File size at destination: $actualSize bytes");
    }
    
    // Generate URL
    $recordingUrl = "https://truckmitr.com/truckmitr-app/Match-making_call_recording/transporter/{$filename}";
    logDebug("Generated URL: $recordingUrl");
    
    // Update database - find the most recent job brief for this job and transporter
    logDebug("Updating database...");
    $updateQuery = "UPDATE job_brief_table 
                    SET call_recording = ? 
                    WHERE unique_id = ? 
                    AND job_id = ? 
                    ORDER BY created_at DESC 
                    LIMIT 1";
    
    $stmt = $conn->prepare($updateQuery);
    $stmt->bind_param("sss", $recordingUrl, $transporterTmid, $jobId);
    
    $dbUpdateSuccess = $stmt->execute();
    $rowsAffected = $stmt->affected_rows;
    
    logDebug("DB Update Success: " . ($dbUpdateSuccess ? 'YES' : 'NO'));
    logDebug("Rows Affected: $rowsAffected");
    
    if ($dbUpdateSuccess && $rowsAffected > 0) {
        logDebug("SUCCESS: Upload complete and database updated");
        echo json_encode([
            'success' => true,
            'message' => 'Recording uploaded and database updated successfully',
            'data' => [
                'filename' => $filename,
                'url' => $recordingUrl,
                'size' => $file['size'],
                'upload_path' => $uploadPath,
                'rows_updated' => $rowsAffected
            ]
        ]);
    } else {
        logDebug("WARNING: File uploaded but database not updated");
        echo json_encode([
            'success' => true,
            'message' => 'Recording uploaded but database not updated (no matching job brief found)',
            'data' => [
                'filename' => $filename,
                'url' => $recordingUrl,
                'size' => $file['size'],
                'upload_path' => $uploadPath,
                'warning' => 'No matching job brief found for transporter_tmid=' . $transporterTmid . ', job_id=' . $jobId,
                'rows_affected' => $rowsAffected
            ]
        ]);
    }
    
} catch (Exception $e) {
    logDebug("EXCEPTION: " . $e->getMessage());
    logDebug("Stack trace: " . $e->getTraceAsString());
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}

logDebug("=== END REQUEST ===\n");
?>
