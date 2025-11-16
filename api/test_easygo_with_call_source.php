<?php
/**
 * Test EasyGo IVR API with call_source parameter
 */

// Enable error reporting
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "<h1>EasyGo IVR API Test with call_source</h1>";

$apiUrl = 'https://truckmitr.com/truckmitr-app/api/easygo_ivr_api.php?action=initiate_call';

$testData = [
    'exten' => '7678361231',
    'number' => '8688432311',
    'caller_id' => '4',
    'contact_id' => '17593',
    'contact_type' => 'driver',
    'driver_name' => 'Nanaji',
    'duration' => '',
    'call_source' => null // Test with null call_source
];

echo "<h2>Test 1: With call_source = null</h2>";
echo "<pre>Request Data: " . json_encode($testData, JSON_PRETTY_PRINT) . "</pre>";

$ch = curl_init($apiUrl);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($testData));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json'
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

echo "<h3>Response:</h3>";
echo "<p><strong>HTTP Code:</strong> $httpCode</p>";
if ($error) {
    echo "<p style='color: red;'><strong>cURL Error:</strong> $error</p>";
}
echo "<pre>Response Body: " . ($response ?: '(empty)') . "</pre>";

if ($httpCode == 200) {
    $data = json_decode($response, true);
    if ($data && isset($data['success']) && $data['success']) {
        echo "<p style='color: green;'>✅ Test 1 PASSED: Call initiated successfully</p>";
        echo "<pre>Call Log ID: " . ($data['call_log_id'] ?? 'N/A') . "</pre>";
        echo "<pre>Reference ID: " . ($data['reference_id'] ?? 'N/A') . "</pre>";
    } else {
        echo "<p style='color: red;'>❌ Test 1 FAILED: " . ($data['error'] ?? 'Unknown error') . "</p>";
    }
} else {
    echo "<p style='color: red;'>❌ Test 1 FAILED: HTTP $httpCode</p>";
}

// Test 2: With call_source = 'job_posting'
echo "<hr>";
echo "<h2>Test 2: With call_source = 'job_posting'</h2>";

$testData['call_source'] = 'job_posting';
echo "<pre>Request Data: " . json_encode($testData, JSON_PRETTY_PRINT) . "</pre>";

$ch = curl_init($apiUrl);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($testData));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json'
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

echo "<h3>Response:</h3>";
echo "<p><strong>HTTP Code:</strong> $httpCode</p>";
if ($error) {
    echo "<p style='color: red;'><strong>cURL Error:</strong> $error</p>";
}
echo "<pre>Response Body: " . ($response ?: '(empty)') . "</pre>";

if ($httpCode == 200) {
    $data = json_decode($response, true);
    if ($data && isset($data['success']) && $data['success']) {
        echo "<p style='color: green;'>✅ Test 2 PASSED: Call initiated successfully with call_source</p>";
        echo "<pre>Call Log ID: " . ($data['call_log_id'] ?? 'N/A') . "</pre>";
        echo "<pre>Reference ID: " . ($data['reference_id'] ?? 'N/A') . "</pre>";
    } else {
        echo "<p style='color: red;'>❌ Test 2 FAILED: " . ($data['error'] ?? 'Unknown error') . "</p>";
    }
} else {
    echo "<p style='color: red;'>❌ Test 2 FAILED: HTTP $httpCode</p>";
}

// Check PHP error log
echo "<hr>";
echo "<h2>Recent PHP Errors</h2>";
echo "<p><em>Check your server's PHP error log for detailed error messages</em></p>";
echo "<p>Common locations:</p>";
echo "<ul>";
echo "<li>/var/log/php_errors.log</li>";
echo "<li>/var/log/apache2/error.log</li>";
echo "<li>/var/log/nginx/error.log</li>";
echo "</ul>";

?>
