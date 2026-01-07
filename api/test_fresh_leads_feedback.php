<?php
/**
 * Test script to debug fresh leads feedback submission
 * This will help identify why feedback is not being properly saved to call_history
 */

require_once 'config.php';

header('Content-Type: application/json');

// Test scenario: Simulate feedback submission from fresh leads screen
$testReferenceId = 'test_ref_' . time();
$testUserId = 1; // Replace with actual user ID
$testCallerId = 1; // Replace with actual caller ID

echo "=== FRESH LEADS FEEDBACK TEST ===\n\n";

// Step 1: Check if call_logs record exists
echo "Step 1: Checking call_logs table...\n";
$callLogsQuery = "SELECT * FROM call_logs WHERE reference_id = ? OR user_id = ? ORDER BY id DESC LIMIT 1";
$stmt = $conn->prepare($callLogsQuery);
$stmt->bind_param('si', $testReferenceId, $testUserId);
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    $callLog = $result->fetch_assoc();
    echo "✅ Found call_logs record:\n";
    echo json_encode($callLog, JSON_PRETTY_PRINT) . "\n\n";
    
    $actualCallLogId = $callLog['id'];
    $actualUserId = $callLog['user_id'];
    $actualCallerId = $callLog['caller_id'];
} else {
    echo "❌ No call_logs record found\n";
    echo "Creating test call_logs record...\n";
    
    // Create a test call_logs record
    $insertStmt = $conn->prepare("
        INSERT INTO call_logs 
        (caller_id, tc_for, user_id, driver_name, call_status, exten, number, reference_id, created_at, updated_at)
        VALUES (?, 'welcome-call', ?, 'Test Driver', 'pending', '1234', '9999999999', ?, NOW(), NOW())
    ");
    $insertStmt->bind_param('iis', $testCallerId, $testUserId, $testReferenceId);
    $insertStmt->execute();
    $actualCallLogId = $insertStmt->insert_id;
    $actualUserId = $testUserId;
    $actualCallerId = $testCallerId;
    echo "✅ Created test call_logs record with ID: $actualCallLogId\n\n";
    $insertStmt->close();
}
$stmt->close();

// Step 2: Check if call_history record exists
echo "Step 2: Checking call_history table...\n";
$historyQuery = "SELECT * FROM call_history WHERE user_id = ? AND assigned_to = ? ORDER BY id DESC LIMIT 1";
$historyStmt = $conn->prepare($historyQuery);
$historyStmt->bind_param('ii', $actualUserId, $actualCallerId);
$historyStmt->execute();
$historyResult = $historyStmt->get_result();

if ($historyResult->num_rows > 0) {
    $callHistory = $historyResult->fetch_assoc();
    echo "✅ Found call_history record:\n";
    echo json_encode($callHistory, JSON_PRETTY_PRINT) . "\n\n";
    $historyRecordId = $callHistory['id'];
} else {
    echo "❌ No call_history record found\n";
    echo "This is the problem! call_history record should exist after call initiation.\n\n";
    
    // Create a test call_history record
    echo "Creating test call_history record...\n";
    $insertHistoryStmt = $conn->prepare("
        INSERT INTO call_history 
        (assigned_to, user_id, user_unique_id, user_name, user_mobile, call_status, call_feedback, tc_for, created_at, updated_at)
        VALUES (?, ?, 'TM001', 'Test Driver', '9999999999', 'not_connected', '', 'welcome-call', NOW(), NOW())
    ");
    $insertHistoryStmt->bind_param('ii', $actualCallerId, $actualUserId);
    $insertHistoryStmt->execute();
    $historyRecordId = $insertHistoryStmt->insert_id;
    echo "✅ Created test call_history record with ID: $historyRecordId\n\n";
    $insertHistoryStmt->close();
}
$historyStmt->close();

// Step 3: Simulate feedback update
echo "Step 3: Simulating feedback update...\n";
$testFeedback = 'Agree For Subscription';
$testStatus = 'connected';
$testRemarks = 'Test remarks from fresh leads';

// Update call_logs
$updateCallLogsStmt = $conn->prepare("
    UPDATE call_logs 
    SET call_status = ?, feedback = ?, remarks = ?, updated_at = NOW()
    WHERE id = ?
");
$updateCallLogsStmt->bind_param('sssi', $testStatus, $testFeedback, $testRemarks, $actualCallLogId);
$updateCallLogsStmt->execute();
echo "✅ Updated call_logs record (affected rows: " . $updateCallLogsStmt->affected_rows . ")\n";
$updateCallLogsStmt->close();

// Update call_history
$updateHistoryStmt = $conn->prepare("
    UPDATE call_history 
    SET call_status = ?, call_feedback = ?, remarks = ?, updated_at = NOW()
    WHERE user_id = ? AND assigned_to = ?
    ORDER BY id DESC LIMIT 1
");
$updateHistoryStmt->bind_param('sssii', $testStatus, $testFeedback, $testRemarks, $actualUserId, $actualCallerId);
$updateHistoryStmt->execute();
echo "✅ Updated call_history record (affected rows: " . $updateHistoryStmt->affected_rows . ")\n\n";
$updateHistoryStmt->close();

// Step 4: Verify the updates
echo "Step 4: Verifying updates...\n";

// Check call_logs
$verifyCallLogsStmt = $conn->prepare("SELECT * FROM call_logs WHERE id = ?");
$verifyCallLogsStmt->bind_param('i', $actualCallLogId);
$verifyCallLogsStmt->execute();
$verifyCallLogsResult = $verifyCallLogsStmt->get_result();
$updatedCallLog = $verifyCallLogsResult->fetch_assoc();
echo "call_logs record after update:\n";
echo json_encode($updatedCallLog, JSON_PRETTY_PRINT) . "\n\n";
$verifyCallLogsStmt->close();

// Check call_history
$verifyHistoryStmt = $conn->prepare("SELECT * FROM call_history WHERE id = ?");
$verifyHistoryStmt->bind_param('i', $historyRecordId);
$verifyHistoryStmt->execute();
$verifyHistoryResult = $verifyHistoryStmt->get_result();
$updatedHistory = $verifyHistoryResult->fetch_assoc();
echo "call_history record after update:\n";
echo json_encode($updatedHistory, JSON_PRETTY_PRINT) . "\n\n";
$verifyHistoryStmt->close();

// Step 5: Check for duplicate records
echo "Step 5: Checking for duplicate records...\n";
$duplicateQuery = "SELECT COUNT(*) as count FROM call_history WHERE user_id = ? AND assigned_to = ?";
$duplicateStmt = $conn->prepare($duplicateQuery);
$duplicateStmt->bind_param('ii', $actualUserId, $actualCallerId);
$duplicateStmt->execute();
$duplicateResult = $duplicateStmt->get_result();
$duplicateCount = $duplicateResult->fetch_assoc()['count'];
echo "Number of call_history records for this user/caller: $duplicateCount\n";
if ($duplicateCount > 1) {
    echo "⚠️ WARNING: Multiple call_history records found! This might be the 'multiple columns' issue.\n";
}
$duplicateStmt->close();

echo "\n=== TEST COMPLETE ===\n";
