<?php
/**
 * Test TeleCMI Production API with Real Data
 * This test uses actual driver data from the database
 */

require_once 'config.php';

echo "<h1>TeleCMI Production API Test - With Real Data</h1>";
echo "<hr>";

// Get a real driver from the database
echo "<h2>Step 1: Get Real Driver Data</h2>";

$stmt = $conn->prepare("
    SELECT id, unique_id, name, mobile 
    FROM users 
    WHERE role IN ('driver', 'transporter') 
    AND mobile IS NOT NULL 
    AND mobile != ''
    LIMIT 1
");
$stmt->execute();
$result = $stmt->get_result();
$driver = $result->fetch_assoc();
$stmt->close();

if (!$driver) {
    echo "<p style='color: red;'>❌ No drivers found in database!</p>";
    exit;
}

echo "<p><strong>✅ Found Driver:</strong></p>";
echo "<pre>";
print_r($driver);
echo "</pre>";

// Test 1: Initiate TeleCMI Call with Pooja's account
echo "<hr>";
echo "<h2>Test 1: Initiate TeleCMI Call (Pooja - user_id: 3)</h2>";

$testCallData = [
    'caller_id' => 3, // Pooja
    'driver_id' => $driver['id'],
    'driver_mobile' => $driver['mobile']
];

echo "<p><strong>Request Data:</strong></p>";
echo "<pre>";
print_r($testCallData);
echo "</pre>";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://truckmitr.com/api/telecmi_production_api.php?action=click_to_call');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($testCallData));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "<p><strong>Response (HTTP $httpCode):</strong></p>";
echo "<pre>";
$responseData = json_decode($response, true);
echo json_encode($responseData, JSON_PRETTY_PRINT);
echo "</pre>";

if ($httpCode == 200 && isset($responseData['success']) && $responseData['success']) {
    echo "<p style='color: green;'><strong>✅ Test 1 PASSED: Call initiated successfully!</strong></p>";
    $callId = $responseData['data']['call_id'] ?? null;
    
    // Test 2: Update Feedback
    if ($callId) {
        echo "<hr>";
        echo "<h2>Test 2: Update Call Feedback</h2>";
        
        $feedbackData = [
            'reference_id' => $callId,
            'status' => 'completed',
            'feedback' => 'Interested',
            'remarks' => 'Test call - Driver is interested in job opportunities',
            'call_duration' => 120
        ];
        
        echo "<p><strong>Request Data:</strong></p>";
        echo "<pre>";
        print_r($feedbackData);
        echo "</pre>";
        
        $ch = curl_init();
        curl_setopt($ch, CURLOPT_URL, 'http://truckmitr.com/api/telecmi_production_api.php?action=update_feedback');
        curl_setopt($ch, CURLOPT_POST, true);
        curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($feedbackData));
        curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
        curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
        $response2 = curl_exec($ch);
        $httpCode2 = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        curl_close($ch);
        
        echo "<p><strong>Response (HTTP $httpCode2):</strong></p>";
        echo "<pre>";
        $responseData2 = json_decode($response2, true);
        echo json_encode($responseData2, JSON_PRETTY_PRINT);
        echo "</pre>";
        
        if ($httpCode2 == 200 && isset($responseData2['success']) && $responseData2['success']) {
            echo "<p style='color: green;'><strong>✅ Test 2 PASSED: Feedback updated successfully!</strong></p>";
        } else {
            echo "<p style='color: red;'><strong>❌ Test 2 FAILED</strong></p>";
        }
    }
} else {
    echo "<p style='color: red;'><strong>❌ Test 1 FAILED</strong></p>";
}

// Test 3: Unauthorized User
echo "<hr>";
echo "<h2>Test 3: Unauthorized User (Should Fail with 403)</h2>";

$unauthorizedData = [
    'caller_id' => 999, // Not Pooja
    'driver_id' => $driver['id'],
    'driver_mobile' => $driver['mobile']
];

echo "<p><strong>Request Data:</strong></p>";
echo "<pre>";
print_r($unauthorizedData);
echo "</pre>";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://truckmitr.com/api/telecmi_production_api.php?action=click_to_call');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($unauthorizedData));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
$response3 = curl_exec($ch);
$httpCode3 = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "<p><strong>Response (HTTP $httpCode3):</strong></p>";
echo "<pre>";
$responseData3 = json_decode($response3, true);
echo json_encode($responseData3, JSON_PRETTY_PRINT);
echo "</pre>";

if ($httpCode3 == 403) {
    echo "<p style='color: green;'><strong>✅ Test 3 PASSED: Unauthorized access correctly blocked!</strong></p>";
} else {
    echo "<p style='color: red;'><strong>❌ Test 3 FAILED: Should have returned 403 Forbidden</strong></p>";
}

// Test 4: Check Database Entry
echo "<hr>";
echo "<h2>Test 4: Verify Database Entry</h2>";

$stmt = $conn->prepare("
    SELECT * FROM call_logs 
    WHERE caller_id = 3 
    AND user_id = ? 
    AND call_type = 'ivr'
    ORDER BY created_at DESC 
    LIMIT 1
");
$stmt->bind_param('i', $driver['id']);
$stmt->execute();
$result = $stmt->get_result();
$callLog = $result->fetch_assoc();
$stmt->close();

if ($callLog) {
    echo "<p style='color: green;'><strong>✅ Test 4 PASSED: Call logged to database!</strong></p>";
    echo "<pre>";
    print_r($callLog);
    echo "</pre>";
} else {
    echo "<p style='color: red;'><strong>❌ Test 4 FAILED: No call log found in database</strong></p>";
}

// Summary
echo "<hr>";
echo "<h2>📊 Test Summary</h2>";
echo "<ul>";
echo "<li><strong>Test 1:</strong> Initiate Call (Pooja) - " . ($httpCode == 200 ? "✅ PASSED" : "❌ FAILED") . "</li>";
echo "<li><strong>Test 2:</strong> Update Feedback - " . (isset($httpCode2) && $httpCode2 == 200 ? "✅ PASSED" : "⏭️ SKIPPED") . "</li>";
echo "<li><strong>Test 3:</strong> Unauthorized Access - " . ($httpCode3 == 403 ? "✅ PASSED" : "❌ FAILED") . "</li>";
echo "<li><strong>Test 4:</strong> Database Logging - " . ($callLog ? "✅ PASSED" : "❌ FAILED") . "</li>";
echo "</ul>";

echo "<hr>";
echo "<p><strong>✅ All Tests Complete!</strong></p>";
?>
