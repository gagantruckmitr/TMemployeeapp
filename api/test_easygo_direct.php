<?php
/**
 * Direct Test of EasyGo IVR Functions
 */

require_once 'config.php';

// Manually include the functions from easygo_ivr_api.php
define('EASYGO_USERNAME', 'admin@truckmitr.com');
define('EASYGO_PASSWORD', '6515a6cb823fcbe20f7287bd4659d5ba');
define('EASYGO_DID', '6882742');
define('EASYGO_TOKEN_URL', 'https://client.easygoivr.com/masterapiJwt/gentoken');
define('EASYGO_DIAL_URL', 'https://client.easygoivr.com/easygoapiJwt/request/dial');
define('EASYGO_MANUAL_TOKEN', 'CONTACT_EASYGO_SUPPORT_FOR_TOKEN');

echo "=== Direct EasyGo IVR Test ===\n\n";

// Test 1: Generate reference_id and insert into database
echo "1. Creating call log entry...\n";

$referenceId = 'easygo_' . uniqid() . '_' . time();
$callerId = 1;
$contactId = 123;
$contactType = 'driver';
$exten = '9876543210';
$number = '9123456789';
$callStatus = 'pending';
$tcFor = 'easygo_ivr_' . $contactType;
$userId = intval($contactId);
$responseJson = json_encode(['test' => 'data']);

$stmt = $conn->prepare("
    INSERT INTO call_logs 
    (caller_id, tc_for, user_id, call_status, caller_number, user_number,
     reference_id, api_response, call_initiated_at, created_at, updated_at)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW(), NOW())
");

$stmt->bind_param('isisssss', 
    $callerId,
    $tcFor,
    $userId,
    $callStatus,
    $exten,
    $number,
    $referenceId,
    $responseJson
);

if ($stmt->execute()) {
    $callLogId = $conn->insert_id;
    echo "✅ Call log created!\n";
    echo "   Call Log ID: $callLogId\n";
    echo "   Reference ID: $referenceId\n\n";
} else {
    echo "❌ Failed to create call log: " . $stmt->error . "\n";
    exit;
}
$stmt->close();

// Test 2: Verify it was saved
echo "2. Verifying call log...\n";

$stmt = $conn->prepare("SELECT * FROM call_logs WHERE reference_id = ?");
$stmt->bind_param('s', $referenceId);
$stmt->execute();
$result = $stmt->get_result();
$callLog = $result->fetch_assoc();
$stmt->close();

if ($callLog) {
    echo "✅ Call log found!\n";
    echo "   ID: " . $callLog['id'] . "\n";
    echo "   Reference ID: " . $callLog['reference_id'] . "\n";
    echo "   Call Status: " . $callLog['call_status'] . "\n\n";
} else {
    echo "❌ Call log not found!\n";
    exit;
}

// Test 3: Update feedback
echo "3. Updating feedback...\n";

$feedback = 'Agree for Subscription (Today)';
$newStatus = 'connected';
$duration = 120;
$remarks = 'Test remarks';

$stmt = $conn->prepare("
    UPDATE call_logs 
    SET feedback = ?, call_status = ?, call_duration = ?, remarks = ?, updated_at = NOW()
    WHERE reference_id = ?
");

$stmt->bind_param('ssiss', $feedback, $newStatus, $duration, $remarks, $referenceId);

if ($stmt->execute()) {
    $affectedRows = $stmt->affected_rows;
    echo "✅ Feedback updated!\n";
    echo "   Affected rows: $affectedRows\n\n";
} else {
    echo "❌ Failed to update feedback: " . $stmt->error . "\n";
    exit;
}
$stmt->close();

// Test 4: Verify feedback was saved
echo "4. Verifying feedback...\n";

$stmt = $conn->prepare("SELECT * FROM call_logs WHERE reference_id = ?");
$stmt->bind_param('s', $referenceId);
$stmt->execute();
$result = $stmt->get_result();
$updatedLog = $result->fetch_assoc();
$stmt->close();

if ($updatedLog) {
    echo "✅ Updated call log found!\n";
    echo "   Call Status: " . $updatedLog['call_status'] . "\n";
    echo "   Feedback: " . $updatedLog['feedback'] . "\n";
    echo "   Remarks: " . $updatedLog['remarks'] . "\n";
    echo "   Call Duration: " . $updatedLog['call_duration'] . " seconds\n\n";
    
    if ($updatedLog['feedback'] === $feedback && $updatedLog['call_status'] === $newStatus) {
        echo "✅✅✅ ALL TESTS PASSED! 🎉\n";
        echo "\nThe database operations are working correctly!\n";
        echo "Reference ID is being saved and feedback updates are working.\n";
    } else {
        echo "❌ Data mismatch!\n";
    }
} else {
    echo "❌ Could not find updated call log!\n";
}

$conn->close();
?>
