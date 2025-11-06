<?php
/**
 * Phase 2 Transporter Call Recording Upload API
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
    
    if (empty($jobId) || empty($callerId) || empty($transporterTmid)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'job_id, caller_id, and transporter_tmid are required']);
        exit;
    }
    
    // Check if file was uploaded
    if (!isset($_FILES['recording']) || $_FILES['recording']['error'] !== UPLOAD_ERR_OK) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'No recording file uploaded or upload error']);
        exit;
    }
    
    $file = $_FILES['recording'];
    
    // Get file extension (allow all audio formats)
    $fileExtension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    
    // Basic validation - just ensure it has an extension
    if (empty($fileExtension)) {
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid file. File must have an extension.']);
        exit;
    }
    
    // Create filename: jobid_callerid_datetime.extension
    $datetime = date('YmdHis');
    $filename = "{$jobId}_{$callerId}_{$datetime}.{$fileExtension}";
    
    // Define upload directory - use absolute path from document root
    $uploadDir = $_SERVER['DOCUMENT_ROOT'] . '/truckmitr-app/Match-making_call_recording/transporter/';
    
    // Create directory if it doesn't exist
    if (!file_exists($uploadDir)) {
        if (!mkdir($uploadDir, 0755, true)) {
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Failed to create upload directory: ' . $uploadDir]);
            exit;
        }
    }
    
    $uploadPath = $uploadDir . $filename;
    
    // Move uploaded file
    if (!move_uploaded_file($file['tmp_name'], $uploadPath)) {
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to save recording file']);
        exit;
    }
    
    // Generate URL
    $recordingUrl = "https://truckmitr.com/truckmitr-app/Match-making_call_recording/transporter/{$filename}";
    
    // Update database - find the most recent job brief for this job and transporter
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
    
    if ($dbUpdateSuccess && $rowsAffected > 0) {
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
        // File uploaded but database update failed or no matching record found
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
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}
?>
