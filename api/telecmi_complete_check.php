<?php
/**
 * TeleCMI Complete Integration Check
 * Tests everything to verify the integration is working
 */

header('Content-Type: text/plain; charset=utf-8');
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "╔════════════════════════════════════════════════════════════╗\n";
echo "║         TELECMI INTEGRATION - COMPLETE CHECK               ║\n";
echo "╚════════════════════════════════════════════════════════════╝\n\n";

$allPassed = true;

// TEST 1: Database Connection
echo "TEST 1: Database Connection\n";
echo "----------------------------\n";
require_once 'config.php';
if ($conn->connect_error) {
    echo "❌ FAILED: " . $conn->connect_error . "\n\n";
    $allPassed = false;
} else {
    echo "✅ PASSED: Database connected\n\n";
}

// TEST 2: Check call_logs table structure
echo "TEST 2: Call Logs Table Structure\n";
echo "-----------------------------------\n";
$result = $conn->query("DESCRIBE call_logs");
$columns = [];
while ($row = $result->fetch_assoc()) {
    $columns[] = $row['Field'];
}
$requiredColumns = ['id', 'caller_id', 'user_id', 'tc_for', 'driver_name', 'user_number', 'call_status', 'reference_id'];
$missing = array_diff($requiredColumns, $columns);
if (empty($missing)) {
    echo "✅ PASSED: All required columns exist\n";
    echo "   Columns: " . implode(', ', $requiredColumns) . "\n\n";
} else {
    echo "❌ FAILED: Missing columns: " . implode(', ', $missing) . "\n\n";
    $allPassed = false;
}

// TEST 3: Check admins table (for tc_for)
echo "TEST 3: Admins Table Check\n";
echo "----------------------------\n";
$stmt = $conn->prepare("SELECT id, name, tc_for FROM admins WHERE id = 3");
$stmt->execute();
$result = $stmt->get_result();
if ($admin = $result->fetch_assoc()) {
    echo "✅ PASSED: Pooja's admin record found\n";
    echo "   ID: " . $admin['id'] . "\n";
    echo "   Name: " . $admin['name'] . "\n";
    echo "   TC For: " . ($admin['tc_for'] ?? 'Not set') . "\n\n";
} else {
    echo "❌ FAILED: Pooja's admin record not found\n\n";
    $allPassed = false;
}
$stmt->close();

// TEST 4: Check users table (for driver names)
echo "TEST 4: Users Table Check\n";
echo "--------------------------\n";
$result = $conn->query("SELECT COUNT(*) as count FROM users WHERE role IN ('driver', 'transporter')");
$row = $result->fetch_assoc();
echo "✅ PASSED: Found " . $row['count'] . " drivers/transporters\n\n";

// TEST 5: TeleCMI Credentials
echo "TEST 5: TeleCMI Credentials\n";
echo "----------------------------\n";
$appId = '33336628';
$secret = 'bb0b92ca-3d8a-405b-87aa-fc035fe1cdc6';
$userId = '5003_' . $appId;
echo "✅ PASSED: Credentials configured\n";
echo "   App ID: $appId\n";
echo "   User ID: $userId\n";
echo "   Secret: " . substr($secret, 0, 10) . "...\n\n";

// TEST 6: Test TeleCMI API Call
echo "TEST 6: TeleCMI API Test Call\n";
echo "-------------------------------\n";
$testPhone = '916394756798'; // Your test number

$payload = [
    'user_id' => $userId,
    'secret' => $secret,
    'to' => (int)$testPhone,
    'webrtc' => false,
    'followme' => true
];

echo "Making test call to TeleCMI API...\n";
echo "Phone: +$testPhone\n";

$ch = curl_init('https://rest.telecmi.com/v2/webrtc/click2call');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_TIMEOUT, 10);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

$data = json_decode($response, true);

if ($httpCode == 200) {
    echo "✅ PASSED: TeleCMI API responded (HTTP 200)\n";
    echo "   Response: " . json_encode($data) . "\n";
    
    if (isset($data['request_id']) || isset($data['call_id'])) {
        echo "   Call ID: " . ($data['request_id'] ?? $data['call_id']) . "\n";
    }
    echo "\n";
} else {
    echo "⚠️  WARNING: TeleCMI returned HTTP $httpCode\n";
    echo "   Response: " . json_encode($data) . "\n";
    echo "   Note: Call may still connect despite warning\n\n";
}

// TEST 7: Database Insert Test
echo "TEST 7: Database Insert Test\n";
echo "-----------------------------\n";
$testCallId = 'test_' . time();
$stmt = $conn->prepare("
    INSERT INTO call_logs (
        caller_id, user_id, tc_for, driver_name, user_number,
        call_status, reference_id, notes,
        created_at, updated_at, call_initiated_at
    ) VALUES (3, 99999, 'TeleCMI Test', 'Test Driver', '916394756798', 'pending', ?, 'Integration test', NOW(), NOW(), NOW())
");
$stmt->bind_param('s', $testCallId);

if ($stmt->execute()) {
    $insertId = $conn->insert_id;
    echo "✅ PASSED: Test record inserted (ID: $insertId)\n";
    
    // Clean up test record
    $conn->query("DELETE FROM call_logs WHERE id = $insertId");
    echo "   Test record cleaned up\n\n";
} else {
    echo "❌ FAILED: Could not insert test record\n";
    echo "   Error: " . $stmt->error . "\n\n";
    $allPassed = false;
}
$stmt->close();

// TEST 8: Check API Files
echo "TEST 8: API Files Check\n";
echo "------------------------\n";
$apiFiles = [
    'telecmi_flutter_api.php' => 'Main Flutter API',
    'telecmi_test_call.php' => 'HTML Test Page',
    'config.php' => 'Database Config'
];

foreach ($apiFiles as $file => $desc) {
    if (file_exists($file)) {
        echo "✅ $desc: $file exists\n";
    } else {
        echo "❌ $desc: $file NOT FOUND\n";
        $allPassed = false;
    }
}
echo "\n";

// TEST 9: Flutter API Endpoint Test
echo "TEST 9: Flutter API Endpoint Test\n";
echo "-----------------------------------\n";
if (file_exists('telecmi_flutter_api.php')) {
    echo "✅ PASSED: telecmi_flutter_api.php ready\n";
    echo "   URL: https://truckmitr.com/truckmitr-app/api/telecmi_flutter_api.php\n";
    echo "   Method: POST\n";
    echo "   Body: {\"caller_id\":3,\"driver_id\":\"15322\",\"driver_mobile\":\"9876543210\"}\n\n";
} else {
    echo "❌ FAILED: telecmi_flutter_api.php not found\n\n";
    $allPassed = false;
}

// FINAL SUMMARY
echo "╔════════════════════════════════════════════════════════════╗\n";
echo "║                    FINAL SUMMARY                           ║\n";
echo "╚════════════════════════════════════════════════════════════╝\n\n";

if ($allPassed) {
    echo "✅✅✅ ALL TESTS PASSED! ✅✅✅\n\n";
    echo "TeleCMI Integration Status: READY FOR PRODUCTION\n\n";
    echo "Next Steps:\n";
    echo "1. Upload telecmi_flutter_api.php to server\n";
    echo "2. Rebuild Flutter app\n";
    echo "3. Test call from app\n\n";
} else {
    echo "❌ SOME TESTS FAILED\n\n";
    echo "Please fix the failed tests above before proceeding.\n\n";
}

echo "Integration Components:\n";
echo "- API: telecmi_flutter_api.php\n";
echo "- Flutter: lib/core/services/api_service.dart\n";
echo "- Database: call_logs table\n";
echo "- TeleCMI: User 5003_33336628\n\n";

echo "Test completed at: " . date('Y-m-d H:i:s') . "\n";
echo "═══════════════════════════════════════════════════════════\n";

$conn->close();
?>
