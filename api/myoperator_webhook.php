<?php
/**
 * MyOperator Webhook Handler
 * Receives real-time call status updates from MyOperator
 * 
 * MyOperator sends webhooks for:
 * - Call initiated
 * - Call ringing
 * - Call answered
 * - Call completed
 * - Call failed
 * - Recording available
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

// Database configuration
$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    error_log('Database connection failed: ' . $e->getMessage());
    http_response_code(500);
    echo json_encode(['success' => false, 'error' => 'Database error']);
    exit;
}

// Get webhook data from MyOperator
$webhookData = json_decode(file_get_contents('php://input'), true);

// Log the webhook for debugging
error_log('📞 MyOperator Webhook Received: ' . json_encode($webhookData));

// Extract call information
$referenceId = $webhookData['reference_id'] ?? '';
$callStatus = $webhookData['status'] ?? '';
$callDuration = $webhookData['duration'] ?? 0;
$recordingUrl = $webhookData['recording_url'] ?? null;
$callStartTime = $webhookData['start_time'] ?? null;
$callEndTime = $webhookData['end_time'] ?? null;
$uniqueId = $webhookData['unique_id'] ?? '';

if (empty($referenceId)) {
    error_log('⚠️ Webhook missing reference_id');
    echo json_encode(['success' => false, 'error' => 'Missing reference_id']);
    exit;
}

try {
    // Update call log with real-time status
    $sql = "UPDATE call_logs 
            SET call_status = ?,
                call_duration = ?,
                recording_url = ?,
                call_start_time = ?,
                call_end_time = ?,
                myoperator_unique_id = ?,
                webhook_data = ?,
                updated_at = NOW()
            WHERE reference_id = ?";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        $callStatus,
        $callDuration,
        $recordingUrl,
        $callStartTime,
        $callEndTime,
        $uniqueId,
        json_encode($webhookData),
        $referenceId
    ]);
    
    error_log("✅ Call log updated: $referenceId - Status: $callStatus - Duration: {$callDuration}s");
    
    echo json_encode([
        'success' => true,
        'message' => 'Webhook processed successfully',
        'reference_id' => $referenceId,
        'status' => $callStatus
    ]);
    
} catch(Exception $e) {
    error_log('❌ Webhook processing error: ' . $e->getMessage());
    echo json_encode(['success' => false, 'error' => $e->getMessage()]);
}
?>
