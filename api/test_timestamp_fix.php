<?php
/**
 * Test Timestamp Fix
 * Verify that timestamps are now saved correctly in IST without adding extra 5:30 hours
 */

require_once 'config.php';

echo "=== Testing Timestamp Fix ===\n\n";

// 1. Check PHP timezone
echo "1. PHP Timezone: " . date_default_timezone_get() . "\n";
echo "   PHP Current Time: " . date('Y-m-d H:i:s') . "\n\n";

// 2. Check MySQL timezone
$result = $conn->query("SELECT @@session.time_zone as tz, NOW() as current_time");
$row = $result->fetch_assoc();
echo "2. MySQL Timezone: " . $row['tz'] . "\n";
echo "   MySQL NOW(): " . $row['current_time'] . "\n\n";

// 3. Test INSERT with NOW()
echo "3. Testing INSERT with NOW()...\n";
$testRef = 'TEST_' . time();
$sql = "INSERT INTO call_logs 
        (caller_id, user_id, caller_number, user_number, driver_name, call_status, 
         reference_id, api_response, call_time, created_at, updated_at) 
        VALUES (1, 1, '9999999999', '8888888888', 'Test Driver', 'pending', ?, '{}', NOW(), NOW(), NOW())";

$stmt = $conn->prepare($sql);
$stmt->bind_param('s', $testRef);
$stmt->execute();
$insertId = $conn->insert_id;
echo "   Inserted record ID: $insertId\n";

// 4. Fetch the inserted record
$sql = "SELECT created_at, updated_at FROM call_logs WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param('i', $insertId);
$stmt->execute();
$result = $stmt->get_result();
$record = $result->fetch_assoc();

echo "   Created At: " . $record['created_at'] . "\n";
echo "   Updated At: " . $record['updated_at'] . "\n\n";

// 5. Test UPDATE with NOW()
echo "4. Testing UPDATE with NOW()...\n";
sleep(2); // Wait 2 seconds to see time difference
$sql = "UPDATE call_logs SET call_status = 'connected', feedback = 'Test feedback', updated_at = NOW() WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param('i', $insertId);
$stmt->execute();

// 6. Fetch updated record
$sql = "SELECT created_at, updated_at FROM call_logs WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param('i', $insertId);
$stmt->execute();
$result = $stmt->get_result();
$record = $result->fetch_assoc();

echo "   Created At: " . $record['created_at'] . " (should be unchanged)\n";
echo "   Updated At: " . $record['updated_at'] . " (should be ~2 seconds later)\n\n";

// 7. Compare with current time
$currentTime = date('Y-m-d H:i:s');
echo "5. Verification:\n";
echo "   PHP Current Time: $currentTime\n";
echo "   DB Updated At:    " . $record['updated_at'] . "\n";

$phpTime = strtotime($currentTime);
$dbTime = strtotime($record['updated_at']);
$diff = abs($phpTime - $dbTime);

echo "   Time Difference: $diff seconds\n";

if ($diff < 10) {
    echo "   ✅ PASS: Timestamps are in sync (difference < 10 seconds)\n";
} else {
    echo "   ❌ FAIL: Timestamps are out of sync (difference = $diff seconds)\n";
}

// 8. Clean up test record
echo "\n6. Cleaning up test record...\n";
$sql = "DELETE FROM call_logs WHERE id = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param('i', $insertId);
$stmt->execute();
echo "   Test record deleted.\n";

echo "\n=== Test Complete ===\n";

$conn->close();
?>
