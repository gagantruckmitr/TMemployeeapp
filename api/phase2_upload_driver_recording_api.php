<?php
/**
 * Phase 2 Driver Call Recording Upload API
 * Uploads call recordings for driver calls in match-making system
 */

// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    exit;
}

require_once 'config.php';

// Log function for debugging
function logDebug($message) {
    $logFile = __DIR__ . '/upload_debug.log';
    $timestamp = date('Y-m-d H:i:s');
    file_put_contents($logFile, "[$timestamp] $message\n", FILE_APPEND | LOCK_EX);
}

logDebug("=== Recording Upload Request Started ===");
logDebug("Request Method: " . $_SERVER['REQUEST_METHOD']);
logDebug("POST Data: " . json_encode($_POST));
logDebug("FILES Data: " . json_encode($_FILES));

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    exit;
}

try {
    // Get parameters
    $jobId = $_POST['job_id'] ?? '';
    $callerId = $_POST['caller_id'] ?? '';
    $driverTmid = $_POST['driver_tmid'] ?? '';
    $transporterTmid = $_POST['transporter_tmid'] ?? '';
    
    logDebug("Parameters - Job ID: $jobId, Caller ID: $callerId, Driver TMID: $driverTmid, Transporter TMID: $transporterTmid");
    
    // Validate that at least one TMID is provided
    if (empty($jobId) || empty($callerId) || (empty($driverTmid) && empty($transporterTmid))) {
        logDebug("Missing required parameters");
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'job_id, caller_id, and either driver_tmid or transporter_tmid are required']);
        exit;
    }
    
    // Determine if this is a driver or transporter recording
    $isDriver = !empty($driverTmid);
    $userTmid = $isDriver ? $driverTmid : $transporterTmid;
    $userType = $isDriver ? 'driver' : 'transporter';
    logDebug("User Type: $userType, User TMID: $userTmid");
    
    // Check if file was uploaded
    if (!isset($_FILES['recording'])) {
        logDebug("No recording file in request");
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'No recording file uploaded']);
        exit;
    }
    
    $file = $_FILES['recording'];
    logDebug("File info - Name: " . $file['name'] . ", Size: " . $file['size'] . ", Error: " . $file['error']);
    
    if ($file['error'] !== UPLOAD_ERR_OK) {
        $errorMessages = [
            UPLOAD_ERR_INI_SIZE => 'File too large (exceeds upload_max_filesize)',
            UPLOAD_ERR_FORM_SIZE => 'File too large (exceeds MAX_FILE_SIZE)',
            UPLOAD_ERR_PARTIAL => 'File only partially uploaded',
            UPLOAD_ERR_NO_FILE => 'No file uploaded',
            UPLOAD_ERR_NO_TMP_DIR => 'Missing temporary folder',
            UPLOAD_ERR_CANT_WRITE => 'Failed to write file to disk',
            UPLOAD_ERR_EXTENSION => 'File upload stopped by extension'
        ];
        
        $errorMsg = $errorMessages[$file['error']] ?? 'Unknown upload error';
        logDebug("Upload error: $errorMsg");
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => $errorMsg]);
        exit;
    }
    
    // Validate file size (max 50MB)
    if ($file['size'] > 50 * 1024 * 1024) {
        logDebug("File too large: " . $file['size'] . " bytes");
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'File too large. Maximum size is 50MB.']);
        exit;
    }
    
    // Get file extension
    $fileExtension = strtolower(pathinfo($file['name'], PATHINFO_EXTENSION));
    
    // Validate audio file extensions
    $allowedExtensions = ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'flac', 'wma', 'amr', 'opus', '3gp'];
    if (!in_array($fileExtension, $allowedExtensions)) {
        logDebug("Invalid file extension: $fileExtension");
        http_response_code(400);
        echo json_encode(['success' => false, 'message' => 'Invalid file type. Allowed: ' . implode(', ', $allowedExtensions)]);
        exit;
    }
    
    // Create filename: jobid_callerid_datetime.extension
    $datetime = date('YmdHis');
    $filename = "{$jobId}_{$callerId}_{$datetime}.{$fileExtension}";
    logDebug("Generated filename: $filename");
    
    // Define upload directory based on user type - try multiple possible paths
    $subDir = $userType; // 'driver' or 'transporter'
    $possiblePaths = [
        $_SERVER['DOCUMENT_ROOT'] . "/truckmitr-app/Match-making_call_recording/{$subDir}/",
        __DIR__ . "/../Match-making_call_recording/{$subDir}/",
        __DIR__ . "/Match-making_call_recording/{$subDir}/",
        __DIR__ . "/uploads/recordings/{$subDir}/"
    ];
    
    $uploadDir = null;
    foreach ($possiblePaths as $path) {
        logDebug("Trying path: $path");
        if (is_dir(dirname($path)) || mkdir(dirname($path), 0755, true)) {
            $uploadDir = $path;
            break;
        }
    }
    
    if (!$uploadDir) {
        logDebug("Failed to find or create upload directory");
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to create upload directory']);
        exit;
    }
    
    // Create directory if it doesn't exist
    if (!file_exists($uploadDir)) {
        if (!mkdir($uploadDir, 0755, true)) {
            logDebug("Failed to create directory: $uploadDir");
            http_response_code(500);
            echo json_encode(['success' => false, 'message' => 'Failed to create upload directory: ' . $uploadDir]);
            exit;
        }
    }
    
    $uploadPath = $uploadDir . $filename;
    logDebug("Upload path: $uploadPath");
    
    // Check if directory is writable
    if (!is_writable($uploadDir)) {
        logDebug("Directory not writable: $uploadDir");
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Upload directory not writable']);
        exit;
    }
    
    // Move uploaded file
    if (!move_uploaded_file($file['tmp_name'], $uploadPath)) {
        logDebug("Failed to move uploaded file from " . $file['tmp_name'] . " to $uploadPath");
        http_response_code(500);
        echo json_encode(['success' => false, 'message' => 'Failed to save recording file']);
        exit;
    }
    
    logDebug("File uploaded successfully to: $uploadPath");
    
    // Generate URL based on user type
    $recordingUrl = "https://truckmitr.com/truckmitr-app/Match-making_call_recording/{$userType}/{$filename}";
    logDebug("Generated URL: $recordingUrl");
    
    // Try to update database
    $dbUpdateSuccess = false;
    $rowsAffected = 0;
    
    if (isset($conn)) {
        // Build the WHERE clause based on which TMID is provided
        $whereClause = "";
        $params = [];
        $types = "";
        
        if ($isDriver) {
            $whereClause = "unique_id_driver = ? AND caller_id = ?";
            $params = [$driverTmid, $callerId];
            $types = "si";
        } else {
            $whereClause = "unique_id_transporter = ? AND caller_id = ?";
            $params = [$transporterTmid, $callerId];
            $types = "si";
        }
        
        // Add job_id to the search if provided
        if (!empty($jobId)) {
            $whereClause .= " AND job_id = ?";
            $params[] = $jobId;
            $types .= "s";
        }
        
        // First, try to find existing call log (within last 10 minutes)
        $findQuery = "SELECT id FROM call_logs_match_making 
                      WHERE $whereClause 
                      AND created_at >= DATE_SUB(NOW(), INTERVAL 10 MINUTE)
                      ORDER BY created_at DESC 
                      LIMIT 1";
        
        $findStmt = $conn->prepare($findQuery);
        $findStmt->bind_param($types, ...$params);
        $findStmt->execute();
        $result = $findStmt->get_result();
        
        if ($result->num_rows > 0) {
            // Update existing record
            $row = $result->fetch_assoc();
            $existingId = $row['id'];
            
            $updateQuery = "UPDATE call_logs_match_making 
                            SET call_recording = ?, updated_at = NOW() 
                            WHERE id = ?";
            
            $stmt = $conn->prepare($updateQuery);
            $stmt->bind_param("si", $recordingUrl, $existingId);
            $dbUpdateSuccess = $stmt->execute();
            $rowsAffected = $stmt->affected_rows;
            logDebug("Database update - Success: " . ($dbUpdateSuccess ? 'true' : 'false') . ", Rows affected: $rowsAffected, ID: $existingId");
        } else {
            // Create new call log entry with recording
            if ($isDriver) {
                $insertQuery = "INSERT INTO call_logs_match_making 
                                (unique_id_driver, caller_id, job_id, call_recording, feedback, created_at, updated_at) 
                                VALUES (?, ?, ?, ?, 'pending', NOW(), NOW())";
                
                $stmt = $conn->prepare($insertQuery);
                $stmt->bind_param("siss", $driverTmid, $callerId, $jobId, $recordingUrl);
            } else {
                $insertQuery = "INSERT INTO call_logs_match_making 
                                (unique_id_transporter, caller_id, job_id, call_recording, feedback, created_at, updated_at) 
                                VALUES (?, ?, ?, ?, 'pending', NOW(), NOW())";
                
                $stmt = $conn->prepare($insertQuery);
                $stmt->bind_param("siss", $transporterTmid, $callerId, $jobId, $recordingUrl);
            }
            
            $dbUpdateSuccess = $stmt->execute();
            $rowsAffected = $stmt->affected_rows;
            logDebug("Database insert - Success: " . ($dbUpdateSuccess ? 'true' : 'false') . ", Rows affected: $rowsAffected");
        }
    } else {
        logDebug("Database connection not available");
    }
    
    // Return success response
    $response = [
        'success' => true,
        'message' => 'Recording uploaded successfully',
        'recording_url' => $recordingUrl, // For backward compatibility
        'data' => [
            'filename' => $filename,
            'url' => $recordingUrl,
            'recording_url' => $recordingUrl, // Duplicate for compatibility
            'size' => $file['size'],
            'upload_path' => $uploadPath,
            'database_updated' => $dbUpdateSuccess,
            'rows_affected' => $rowsAffected,
            'user_type' => $userType,
            'user_tmid' => $userTmid
        ]
    ];
    
    logDebug("Response: " . json_encode($response));
    echo json_encode($response);
    
} catch (Exception $e) {
    logDebug("Exception: " . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'message' => 'Server error: ' . $e->getMessage()]);
}

logDebug("=== Recording Upload Request Ended ===");
?>
