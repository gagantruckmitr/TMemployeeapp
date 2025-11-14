<?php
/**
 * Test TeleCMI Production API
 * Run this file to test the production API endpoints
 */

echo "<h1>TeleCMI Production API Test</h1>";
echo "<hr>";

// Test 1: Click to Call
echo "<h2>Test 1: Initiate TeleCMI Call</h2>";
$testCallData = [
    'caller_id' => 3, // Pooja
    'driver_id' => 'test_driver_123',
    'driver_mobile' => '919876543210'
];

echo "<pre>";
echo "Request Data:\n";
print_r($testCallData);
echo "</pre>";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://truckmitr.com/api/telecmi_production_api.php?action=click_to_call');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($testCallData));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true); // Follow redirects
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "<p><strong>Response (HTTP $httpCode):</strong></p>";
echo "<pre>";
echo json_encode(json_decode($response), JSON_PRETTY_PRINT);
echo "</pre>";

echo "<hr>";

// Test 2: Unauthorized User
echo "<h2>Test 2: Unauthorized User (Should Fail)</h2>";
$unauthorizedData = [
    'caller_id' => 999, // Not Pooja
    'driver_id' => 'test_driver_123',
    'driver_mobile' => '919876543210'
];

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, 'http://truckmitr.com/api/telecmi_production_api.php?action=click_to_call');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($unauthorizedData));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true); // Follow redirects
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "<p><strong>Response (HTTP $httpCode):</strong></p>";
echo "<pre>";
echo json_encode(json_decode($response), JSON_PRETTY_PRINT);
echo "</pre>";

echo "<hr>";
echo "<p><strong>✅ Tests Complete</strong></p>";
