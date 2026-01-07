<?php
/**
 * Test callback request call log submission
 * Simulates what happens when feedback is submitted from the app
 */

header('Content-Type: application/json');

// Database configuration
$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    die(json_encode(['success' => false, 'error' => 'Database connection failed: ' . $e->getMessage()]));
}

$results = [];

// 1. Get a sample callback request with user mapping
$sql = "SELECT 
            cr.*,
            u.id as user_id,
            u.unique_id as tmid,
            u.name as user_name_from_users
        FROM callback_requests cr
        LEFT JOIN users u ON cr.unique_id = u.unique_id
        WHERE cr.status = 'Pending'
        AND u.id IS NOT NULL
        LIMIT 1";

$stmt = $pdo->query($sql);
$callbackRequest = $stmt->fetch(PDO::FETCH_ASSOC);

if (!$callbackRequest) {
    die(json_encode([
        'success' => false,
        'error' => 'No pending callback requests with valid user mapping found',
        'suggestion' => 'Create a callback request first or check user mapping'
    ]));
}

$results['callback_request'] = $callbackRequest;

// 2. Simulate call log insertion (what the app does)
$testCallLog = [
    'user_id' => $callbackRequest['user_id'], // CRITICAL: Use users.id, not callback_requests.id
    'caller_id' => 3, // Test telecaller ID
    'driver_name' => $callbackRequest['user_name'],
    'user_number' => $callbackRequest['mobile_number'],
    'caller_number' => '+917678361210',
    'call_status' => 'connected',
    'feedback' => 'Agree for Subscription (Today)',
    'remarks' => 'Test feedback from callback request',
    'notes' => 'Test feedback from callback request',
    'call_source' => 'callback_requests',
    'tc_for' => 'callback_requests',
    'reference_id' => 'TEST_CALLBACK_' . time() . '_3_' . $callbackRequest['user_id'],
    'call_time' => date('Y-m-d H:i:s'),
];

$results['test_call_log_data'] = $testCallLog;

// 3. Insert test call log
try {
    $sql = "INSERT INTO call_logs (
                user_id, caller_id, driver_name, user_number, caller_number,
                call_status, feedback, remarks, notes, call_source, tc_for,
                reference_id, call_time, created_at, updated_at
            ) VALUES (
                :user_id, :caller_id, :driver_name, :user_number, :caller_number,
                :call_status, :feedback, :remarks, :notes, :call_source, :tc_for,
                :reference_id, :call_time, NOW(), NOW()
            )";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute($testCallLog);
    
    $insertedId = $pdo->lastInsertId();
    $results['call_log_inserted'] = true;
    $results['call_log_id'] = $insertedId;
    
    // Fetch the inserted record
    $stmt = $pdo->prepare("SELECT * FROM call_logs WHERE id = ?");
    $stmt->execute([$insertedId]);
    $results['inserted_call_log'] = $stmt->fetch(PDO::FETCH_ASSOC);
    
} catch (Exception $e) {
    $results['call_log_error'] = $e->getMessage();
    $results['call_log_inserted'] = false;
}

// 4. Update callback request status (what the app does)
try {
    $sql = "UPDATE callback_requests 
            SET status = 'Interested', 
                notes = 'Test feedback from callback request',
                updated_at = NOW()
            WHERE id = ?";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$callbackRequest['id']]);
    
    $results['callback_request_updated'] = true;
    
    // Fetch updated request
    $stmt = $pdo->prepare("SELECT * FROM callback_requests WHERE id = ?");
    $stmt->execute([$callbackRequest['id']]);
    $results['updated_callback_request'] = $stmt->fetch(PDO::FETCH_ASSOC);
    
} catch (Exception $e) {
    $results['callback_update_error'] = $e->getMessage();
    $results['callback_request_updated'] = false;
}

// 5. Verify the call log is linked correctly
try {
    $sql = "SELECT 
                cl.*,
                u.unique_id as tmid,
                u.name as user_name,
                a.name as telecaller_name
            FROM call_logs cl
            LEFT JOIN users u ON cl.user_id = u.id
            LEFT JOIN admins a ON cl.caller_id = a.id
            WHERE cl.id = ?";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$insertedId]);
    $results['call_log_with_user_info'] = $stmt->fetch(PDO::FETCH_ASSOC);
    
} catch (Exception $e) {
    $results['verification_error'] = $e->getMessage();
}

// 6. Check if it appears in history
try {
    $sql = "SELECT 
                cr.*,
                u.id as user_id,
                cl.feedback as call_feedback,
                cl.remarks as call_remarks,
                cl.call_time as last_call_time
            FROM callback_requests cr
            LEFT JOIN users u ON cr.unique_id = u.unique_id
            LEFT JOIN call_logs cl ON cl.user_id = u.id 
                AND cl.call_source = 'callback_requests'
                AND cl.id = (
                    SELECT id FROM call_logs 
                    WHERE user_id = u.id 
                    AND call_source = 'callback_requests'
                    ORDER BY call_time DESC 
                    LIMIT 1
                )
            WHERE cr.id = ?
            AND cr.status IN ('Contacted', 'Resolved', 'Interested', 'Not Interested')";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute([$callbackRequest['id']]);
    $historyEntry = $stmt->fetch(PDO::FETCH_ASSOC);
    
    $results['appears_in_history'] = $historyEntry !== false;
    $results['history_entry'] = $historyEntry;
    
} catch (Exception $e) {
    $results['history_check_error'] = $e->getMessage();
}

// 7. Summary
$results['summary'] = [
    'test_passed' => $results['call_log_inserted'] && $results['callback_request_updated'] && $results['appears_in_history'],
    'callback_request_id' => $callbackRequest['id'],
    'user_id_used' => $callbackRequest['user_id'],
    'tmid' => $callbackRequest['tmid'],
    'call_log_created' => $results['call_log_inserted'] ?? false,
    'callback_updated' => $results['callback_request_updated'] ?? false,
    'in_history' => $results['appears_in_history'] ?? false,
];

// 8. Cleanup instructions
$results['cleanup'] = [
    'message' => 'To cleanup test data, run these SQL commands:',
    'sql' => [
        "DELETE FROM call_logs WHERE id = {$insertedId};",
        "UPDATE callback_requests SET status = 'Pending', notes = NULL, updated_at = NOW() WHERE id = {$callbackRequest['id']};"
    ]
];

echo json_encode($results, JSON_PRETTY_PRINT);
?>
