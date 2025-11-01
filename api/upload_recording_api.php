<?php
// Call Recording Upload API
header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: POST');
header('Access-Control-Allow-Headers: Content-Type');

require_once 'config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    http_response_code(405);
    echo json_encode(['success' => false, 'error' => 'Method not allowed']);
    exit;
}

try {
    // Get form data
    $tmid = $_POST['tmid'] ?? '';
    $callerId = $_POST['caller_id'] ?? '';
    $callLogId = $_POST['call_log_id'] ?? '';
    
    if (empty($tmid) || empty($callerId)) {
        throw new Exception('TMID and Caller ID are required');
    }
    
    // Check if file was uploaded
    if (!isset($_FILES['recording']) || $_FILES['recording']['error'] !== UPLOAD_ERR_OK) {
        throw new Exception('No file uploaded or upload error occurred');
    }
    
    $file = $_FILES['recording'];
    
    // Validate file type (audio files only)
    $allowedTypes = ['audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/m4a', 'audio/aac', 'audio/ogg'];
    $finfo = finfo_open(FILEINFO_MIME_TYPE);
    $mimeType = finfo_file($finfo, $file['tmp_name']);
    finfo_close($finfo);
    
    if (!in_array($mimeType, $allowedTypes)) {
        throw new Exception('Invalid file type. Only audio files are allowed.');
    }
    
    // Validate file size (max 50MB)
    $maxSize = 50 * 1024 * 1024; // 50MB
    if ($file['size'] > $maxSize) {
        throw new Exception('File size exceeds 50MB limit');
    }
    
    // Get file extension
    $extension = pathinfo($file['name'], PATHINFO_EXTENSION);
    if (empty($extension)) {
        $extension = 'mp3'; // Default extension
    }
    
    // Generate filename: TMID_CallerID_DateTime.ext
    $dateTime = date('YmdHis');
    $filename = "{$tmid}_{$callerId}_{$dateTime}.{$extension}";
    
    // Upload directory
    $uploadDir = __DIR__ . '/../voice-recording/';
    
    // Create directory if it doesn't exist
    if (!file_exists($uploadDir)) {
        mkdir($uploadDir, 0755, true);
    }
    
    $uploadPath = $uploadDir . $filename;
    
    // Move uploaded file
    if (!move_uploaded_file($file['tmp_name'], $uploadPath)) {
        throw new Exception('Failed to save uploaded file');
    }
    
    // Generate URL
    $recordingUrl = 'https://truckmitr.com/truckmitr-app/voice-recording/' . $filename;
    
    // Update call_logs table if call_log_id is provided
    if (!empty($callLogId)) {
        $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
        $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        
        // Check if manual_call_recording_url column exists, if not add it
        try {
            $stmt = $pdo->query("SHOW COLUMNS FROM call_logs LIKE 'manual_call_recording_url'");
            if ($stmt->rowCount() === 0) {
                $pdo->exec("ALTER TABLE call_logs ADD COLUMN manual_call_recording_url VARCHAR(500) NULL AFTER recording_url");
            }
        } catch (Exception $e) {
            error_log('Column check error: ' . $e->getMessage());
        }
        
        // Update the call log with manual call recording URL
        $stmt = $pdo->prepare("UPDATE call_logs SET manual_call_recording_url = ? WHERE id = ?");
        $stmt->execute([$recordingUrl, $callLogId]);
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Recording uploaded successfully',
        'filename' => $filename,
        'url' => $recordingUrl,
        'size' => $file['size'],
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    
} catch (Exception $e) {
    http_response_code(400);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
