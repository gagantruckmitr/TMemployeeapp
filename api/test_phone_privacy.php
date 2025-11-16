<?php
/**
 * Test Phone Number Privacy for IVR Calls
 */

require_once 'config.php';

echo "=== Testing Phone Number Privacy ===\n\n";

// Test 1: Create an IVR call log
echo "1. Creating EasyGo IVR call log...\n";

$stmt = $conn->prepare("
    INSERT INTO call_logs 
    (caller_id, tc_for, user_id, driver_name, call_status, caller_number, user_number,
     reference_id, call_initiated_at, created_at, updated_at)
    VALUES (1, 'easygo_ivr_driver', 123, 'Test Driver IVR', 'connected', '9876543210', '9123456789',
            'test_ivr_ref', NOW(), NOW(), NOW())
");

$stmt->execute();
$ivrCallId = $conn->insert_id;
$stmt->close();

echo "   Created IVR call log ID: $ivrCallId\n\n";

// Test 2: Create a manual call log
echo "2. Creating manual call log...\n";

$stmt = $conn->prepare("
    INSERT INTO call_logs 
    (caller_id, tc_for, user_id, driver_name, call_status, caller_number, user_number,
     reference_id, call_initiated_at, created_at, updated_at)
    VALUES (1, 'manual_call', 124, 'Test Driver Manual', 'connected', '9876543210', '9111111111',
            'test_manual_ref', NOW(), NOW(), NOW())
");

$stmt->execute();
$manualCallId = $conn->insert_id;
$stmt->close();

echo "   Created manual call log ID: $manualCallId\n\n";

// Test 3: Query with privacy logic
echo "3. Testing privacy query...\n\n";

$stmt = $conn->prepare("
    SELECT 
        id,
        driver_name,
        tc_for,
        user_number as actual_phone,
        CASE 
            WHEN tc_for LIKE '%ivr%' THEN ''
            ELSE user_number
        END as displayed_phone
    FROM call_logs
    WHERE id IN (?, ?)
    ORDER BY id
");

$stmt->bind_param('ii', $ivrCallId, $manualCallId);
$stmt->execute();
$result = $stmt->get_result();

while ($row = $result->fetch_assoc()) {
    echo "Call ID: " . $row['id'] . "\n";
    echo "  Driver: " . $row['driver_name'] . "\n";
    echo "  Type: " . $row['tc_for'] . "\n";
    echo "  Actual Phone: " . $row['actual_phone'] . "\n";
    echo "  Displayed Phone: " . ($row['displayed_phone'] ?: '[HIDDEN]') . "\n";
    
    if ($row['tc_for'] === 'easygo_ivr_driver') {
        if ($row['displayed_phone'] === '') {
            echo "  ✅ IVR call - Phone number correctly HIDDEN\n";
        } else {
            echo "  ❌ IVR call - Phone number should be HIDDEN!\n";
        }
    } else if ($row['tc_for'] === 'manual_call') {
        if ($row['displayed_phone'] !== '') {
            echo "  ✅ Manual call - Phone number correctly VISIBLE\n";
        } else {
            echo "  ❌ Manual call - Phone number should be VISIBLE!\n";
        }
    }
    echo "\n";
}

$stmt->close();

// Test 4: Test with different IVR types
echo "4. Testing different IVR call types...\n\n";

$ivrTypes = [
    'easygo_ivr_driver',
    'easygo_ivr_transporter',
    'click2call_ivr',
    'some_other_ivr_system',
    'manual_call',
    'direct_call'
];

foreach ($ivrTypes as $type) {
    $isIvr = (strpos($type, 'ivr') !== false);
    $shouldHide = $isIvr ? 'HIDDEN' : 'VISIBLE';
    
    $testQuery = "SELECT CASE WHEN '$type' LIKE '%ivr%' THEN '' ELSE '9999999999' END as phone";
    $result = $conn->query($testQuery);
    $row = $result->fetch_assoc();
    $phone = $row['phone'];
    
    $status = ($isIvr && $phone === '') || (!$isIvr && $phone !== '') ? '✅' : '❌';
    
    echo "$status $type => Phone should be $shouldHide => " . ($phone ?: '[HIDDEN]') . "\n";
}

echo "\n";

// Cleanup
echo "5. Cleaning up test data...\n";
$conn->query("DELETE FROM call_logs WHERE id IN ($ivrCallId, $manualCallId)");
echo "   Test data cleaned up\n\n";

echo "✅ Privacy test complete!\n";

$conn->close();
?>
