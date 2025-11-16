<?php
/**
 * Test EasyGo IVR Call and Feedback Flow
 */

require_once 'config.php';

echo "=== EasyGo IVR Call & Feedback Test ===\n\n";

// Test 1: Initiate a call
echo "1. Initiating EasyGo IVR call...\n";

$callData = [
    'action' => 'initiate_call',
    'exten' => '9876543210',  // Telecaller phone
    'number' => '9123456789', // Client phone
    'duration' => '',
    'caller_id' => 1,
    'contact_id' => 123,
    'contact_type' => 'driver'
];

$ch = curl_init('http://localhost/api/easygo_ivr_api.php?action=initiate_call');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($callData));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

$response = curl_exec($ch);
curl_close($ch);

$result = json_decode($response, true);
echo "Response: " . json_encode($result, JSON_PRETTY_PRINT) . "\n\n";

if (!$result['success']) {
    echo "❌ Call initiation failed!\n";
    exit;
}

$referenceId = $result['reference_id'];
$callLogId = $result['call_log_id'];

echo "✅ Call initiated successfully!\n";
echo "   Reference ID: $referenceId\n";
echo "   Call Log ID: $callLogId\n\n";

// Test 2: Verify the call log was saved
echo "2. Verifying call log in database...\n";

$stmt = $conn->prepare("SELECT * FROM call_logs WHERE id = ?");
$stmt->bind_param('i', $callLogId);
$stmt->execute();
$result = $stmt->get_result();
$callLog = $result->fetch_assoc();
$stmt->close();

if ($callLog) {
    echo "✅ Call log found in database!\n";
    echo "   ID: " . $callLog['id'] . "\n";
    echo "   Reference ID: " . $callLog['reference_id'] . "\n";
    echo "   Call Status: " . $callLog['call_status'] . "\n";
    echo "   Caller Number: " . $callLog['caller_number'] . "\n";
    echo "   User Number: " . $callLog['user_number'] . "\n\n";
} else {
    echo "❌ Call log not found in database!\n";
    exit;
}

// Test 3: Update feedback using reference_id
echo "3. Updating feedback using reference_id...\n";

$feedbackData = [
    'reference_id' => $referenceId,
    'call_status' => 'connected',
    'feedback' => 'Agree for Subscription (Today)',
    'remarks' => 'Test feedback',
    'call_duration' => 120
];

$ch = curl_init('http://localhost/api/easygo_ivr_api.php?action=update_feedback');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($feedbackData));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

$response = curl_exec($ch);
curl_close($ch);

$result = json_decode($response, true);
echo "Response: " . json_encode($result, JSON_PRETTY_PRINT) . "\n\n";

if ($result['success']) {
    echo "✅ Feedback updated successfully!\n\n";
} else {
    echo "❌ Feedback update failed!\n\n";
}

// Test 4: Verify feedback was saved
echo "4. Verifying feedback in database...\n";

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
    
    if ($updatedLog['feedback'] === 'Agree for Subscription (Today)') {
        echo "✅ ALL TESTS PASSED! 🎉\n";
    } else {
        echo "❌ Feedback not saved correctly!\n";
    }
} else {
    echo "❌ Could not find updated call log!\n";
}

$conn->close();
?>
