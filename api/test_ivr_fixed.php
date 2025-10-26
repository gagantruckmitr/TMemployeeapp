<?php
/**
 * Test IVR Call API with Fixed Payload
 * This should now work exactly like direct_call_test.php
 */
header('Content-Type: application/json');

// Test data
$testData = [
    'driver_mobile' => '8383971722',
    'caller_id' => 1, // Telecaller ID from admins table
    'driver_id' => '99999' // Test driver ID
];

// Make POST request to ivr_call_api.php
$ch = curl_init('http://localhost/api/ivr_call_api.php?action=initiate_call');
curl_setopt_array($ch, [
    CURLOPT_POST => true,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
    CURLOPT_POSTFIELDS => json_encode($testData),
    CURLOPT_TIMEOUT => 30
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

echo json_encode([
    'test' => 'IVR Call API Test',
    'request' => $testData,
    'response' => [
        'http_code' => $httpCode,
        'curl_error' => $error,
        'body' => json_decode($response, true) ?? $response
    ],
    'status' => $httpCode == 200 ? '✅ SUCCESS' : '❌ FAILED',
    'note' => 'If successful, your phone should ring now!'
], JSON_PRETTY_PRINT);
?>
