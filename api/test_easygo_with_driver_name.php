<?php
/**
 * Test EasyGo IVR with Driver Name
 */

require_once 'config.php';

echo "=== EasyGo IVR Test with Driver Name ===\n\n";

// Test 1: Create call log with driver name
echo "1. Creating call log with driver name...\n";

$referenceId = 'easygo_' . uniqid() . '_' . time();
$callerId = 1;
$contactId = 123;
$contactType = 'driver';
$driverName = 'Test Driver Name';
$exten = '9876543210';
$number = '9123456789';
$callStatus = 'pending';
$tcFor = 'easygo_ivr_' . $contactType;
$userId = intval($contactId);
$responseJson = json_encode(['test' => 'data']);

$stmt = $conn->prepare("
    INSERT INTO call_logs 
    (caller_id, tc_for, user_id, driver_name, call_status, caller_number, user_number,
     reference_id, api_response, call_initiated_at, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), NOW())
");

$stmt->bind_param('isissssss', 
    $callerId,
    $tcFor,
    $userId,
    $driverName,
    $callStatus,
    $exten,
    $number,
    $referenceId,
    $responseJson
);

if ($stmt->execute()) {
    $callLogId = $conn->insert_id;
    echo "✅ Call log created with driver name!\n";
    echo "   Call Log ID: $callLogId\n";
    echo "   Reference ID: $referenceId\n";
    echo "   Driver Name: $driverName\n\n";
} else {
    echo "❌ Failed to create call log: " . $stmt->error . "\n";
    exit;
}
$stmt->close();

// Test 2: Update feedback with all fields
echo "2. Updating feedback with driver_name, feedback, remarks, call_status...\n";

$newDriverName = 'Updated Driver Name';
$feedback = 'Agree for Subscription (Today)';
$newStatus = 'connected';
$duration = 120;
$remarks = 'Test remarks from feedback modal';

$stmt = $conn->prepare("
    UPDATE call_logs 
    SET driver_name = ?, feedback = ?, call_status = ?, call_duration = ?, remarks = ?, updated_at = NOW()
    WHERE reference_id = ?
");

$stmt->bind_param('sssiss', $newDriverName, $feedback, $newStatus, $duration, $remarks, $referenceId);

if ($stmt->execute()) {
    $affectedRows = $stmt->affected_rows;
    echo "✅ Feedback updated with all fields!\n";
    echo "   Affected rows: $affectedRows\n\n";
} else {
    echo "❌ Failed to update feedback: " . $stmt->error . "\n";
    exit;
}
$stmt->close();

// Test 3: Verify all fields were saved
echo "3. Verifying all fields in database...\n";

$stmt = $conn->prepare("SELECT * FROM call_logs WHERE reference_id = ?");
$stmt->bind_param('s', $referenceId);
$stmt->execute();
$result = $stmt->get_result();
$updatedLog = $result->fetch_assoc();
$stmt->close();

if ($updatedLog) {
    echo "✅ All fields verified!\n";
    echo "   Driver Name: " . $updatedLog['driver_name'] . "\n";
    echo "   Call Status: " . $updatedLog['call_status'] . "\n";
    echo "   Feedback: " . $updatedLog['feedback'] . "\n";
    echo "   Remarks: " . $updatedLog['remarks'] . "\n";
    echo "   Call Duration: " . $updatedLog['call_duration'] . " seconds\n\n";
    
    // Verify all fields match
    $allMatch = (
        $updatedLog['driver_name'] === $newDriverName &&
        $updatedLog['feedback'] === $feedback &&
        $updatedLog['call_status'] === $newStatus &&
        $updatedLog['call_duration'] == $duration &&
        $updatedLog['remarks'] === $remarks
    );
    
    if ($allMatch) {
        echo "✅✅✅ ALL TESTS PASSED! 🎉\n\n";
        echo "All fields are being saved correctly:\n";
        echo "✓ driver_name\n";
        echo "✓ feedback\n";
        echo "✓ remarks\n";
        echo "✓ call_status\n";
        echo "✓ call_duration\n";
    } else {
        echo "❌ Some fields don't match!\n";
        echo "Expected driver_name: $newDriverName, Got: " . $updatedLog['driver_name'] . "\n";
        echo "Expected feedback: $feedback, Got: " . $updatedLog['feedback'] . "\n";
        echo "Expected status: $newStatus, Got: " . $updatedLog['call_status'] . "\n";
    }
} else {
    echo "❌ Could not find updated call log!\n";
}

$conn->close();
?>
