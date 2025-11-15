<?php
/**
 * DRY RUN TEST - Click2Call IVR API
 * Tests API call without database dependencies
 * Telecaller: 6394756798
 * Driver: 8448079624
 */

header('Content-Type: text/plain; charset=utf-8');
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "╔════════════════════════════════════════════════════════════╗\n";
echo "║         Click2Call IVR - DRY RUN TEST                      ║\n";
echo "╚════════════════════════════════════════════════════════════╝\n\n";

// Test Configuration
$telecaller_mobile = '6394756798';
$driver_mobile = '8448079624';
$reference_id = 'DRYRUN_' . time();

echo "📋 Test Configuration:\n";
echo "   Telecaller Number: $telecaller_mobile\n";
echo "   Driver Number: $driver_mobile\n";
echo "   Reference ID: $reference_id\n";
echo "   Test Mode: DRY RUN (No database required)\n\n";

echo str_repeat("─", 60) . "\n\n";

// Step 1: Prepare API Payload
echo "📦 Step 1: Preparing Click2Call API Payload\n\n";

$payload = [
    'sourcetype' => '0',
    'customivr' => true,
    'credittype' => '2',
    'filetype' => '2',
    'ukey' => 'UFGMs6bXiXD4AIkjQGta8faKi',
    'serviceno' => '8037789293',
    'ivrtemplateid' => '345',
    'custcli' => '8037789293',
    'isrefno' => true,
    'msisdnlist' => [
        [
            'phoneno' => $driver_mobile,      // Driver will receive call
            'agentno' => $telecaller_mobile   // Telecaller will receive call
        ]
    ]
];

echo "Payload Details:\n";
echo "├─ Source Type: 0 (API)\n";
echo "├─ Custom IVR: Enabled\n";
echo "├─ Credit Type: 2\n";
echo "├─ File Type: 2\n";
echo "├─ Service Number: 8037789293\n";
echo "├─ IVR Template ID: 345\n";
echo "├─ Reference Number: Enabled\n";
echo "└─ Call List:\n";
echo "   ├─ Driver Phone: $driver_mobile\n";
echo "   └─ Agent Phone: $telecaller_mobile\n\n";

echo "Full JSON Payload:\n";
echo json_encode($payload, JSON_PRETTY_PRINT) . "\n\n";

echo str_repeat("─", 60) . "\n\n";

// Step 2: Call Click2Call API
echo "🌐 Step 2: Calling Click2Call IVR API\n\n";

$api_url = 'https://154.210.187.101/C2CAPI/webresources/Click2CallPost';
echo "API Endpoint: $api_url\n";
echo "Method: POST\n";
echo "Content-Type: application/json\n\n";

echo "Initiating API call...\n";

$ch = curl_init($api_url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, false);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);

$start_time = microtime(true);
$response = curl_exec($ch);
$end_time = microtime(true);
$duration = round(($end_time - $start_time) * 1000, 2);

$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curl_error = curl_error($ch);
curl_close($ch);

echo "Response Time: {$duration}ms\n";
echo "HTTP Status Code: $http_code\n\n";

if ($curl_error) {
    echo "❌ cURL Error: $curl_error\n\n";
    echo str_repeat("═", 60) . "\n";
    echo "TEST FAILED - Network Error\n";
    echo str_repeat("═", 60) . "\n";
    exit;
}

echo str_repeat("─", 60) . "\n\n";

// Step 3: Parse Response
echo "📨 Step 3: Analyzing API Response\n\n";

echo "Raw Response:\n";
echo $response . "\n\n";

$api_response = json_decode($response, true);

if (json_last_error() !== JSON_ERROR_NONE) {
    echo "⚠️  Warning: Response is not valid JSON\n";
    echo "JSON Error: " . json_last_error_msg() . "\n\n";
} else {
    echo "Parsed Response:\n";
    echo json_encode($api_response, JSON_PRETTY_PRINT) . "\n\n";
}

echo str_repeat("─", 60) . "\n\n";

// Step 4: Evaluate Result
echo "✅ Step 4: Test Result\n\n";

$success = false;

if ($http_code === 200) {
    echo "✓ HTTP Status: OK (200)\n";
    
    if ($api_response && isset($api_response['status'])) {
        if ($api_response['status'] === 'success') {
            echo "✓ API Status: SUCCESS\n";
            echo "✓ Message: " . ($api_response['message'] ?? 'Call initiated') . "\n\n";
            $success = true;
            
            echo "╔════════════════════════════════════════════════════════════╗\n";
            echo "║                    🎉 TEST PASSED! 🎉                      ║\n";
            echo "╚════════════════════════════════════════════════════════════╝\n\n";
            
            echo "📞 CALL INITIATED SUCCESSFULLY!\n\n";
            echo "What should happen now:\n";
            echo "1. Driver's phone ($driver_mobile) should ring\n";
            echo "2. Telecaller's phone ($telecaller_mobile) should ring\n";
            echo "3. Both parties can answer and talk\n";
            echo "4. IVR system manages the connection\n\n";
            
        } else {
            echo "✗ API Status: " . $api_response['status'] . "\n";
            if (isset($api_response['message'])) {
                echo "✗ Message: " . $api_response['message'] . "\n";
            }
            if (isset($api_response['error'])) {
                echo "✗ Error: " . $api_response['error'] . "\n";
            }
            echo "\n";
        }
    } else {
        echo "⚠️  Unexpected response format\n";
    }
} else {
    echo "✗ HTTP Status: Error ($http_code)\n";
    echo "✗ Response: $response\n\n";
}

echo str_repeat("─", 60) . "\n\n";

// Summary
echo "📊 TEST SUMMARY\n\n";
echo "Test Type: DRY RUN (No Database)\n";
echo "Telecaller: $telecaller_mobile\n";
echo "Driver: $driver_mobile\n";
echo "API Call: " . ($http_code === 200 ? "✓ Success" : "✗ Failed") . "\n";
echo "IVR Status: " . ($success ? "✓ Call Initiated" : "✗ Not Initiated") . "\n";
echo "Duration: {$duration}ms\n\n";

if ($success) {
    echo "╔════════════════════════════════════════════════════════════╗\n";
    echo "║  ✅ PRODUCTION READY - Click2Call IVR is working!         ║\n";
    echo "╚════════════════════════════════════════════════════════════╝\n\n";
    
    echo "Next Steps:\n";
    echo "1. ✓ API is working correctly\n";
    echo "2. ✓ Both phones should be ringing\n";
    echo "3. → Add telecaller to database (admins table)\n";
    echo "4. → Add driver to database (users table)\n";
    echo "5. → Test from Flutter app\n\n";
} else {
    echo "╔════════════════════════════════════════════════════════════╗\n";
    echo "║  ⚠️  TEST FAILED - Check configuration                    ║\n";
    echo "╚════════════════════════════════════════════════════════════╝\n\n";
    
    echo "Troubleshooting:\n";
    echo "1. Check if API credentials are correct\n";
    echo "2. Verify phone numbers are valid\n";
    echo "3. Check network connectivity\n";
    echo "4. Review API response above\n\n";
}

echo str_repeat("═", 60) . "\n";
echo "Test completed at: " . date('Y-m-d H:i:s') . "\n";
echo str_repeat("═", 60) . "\n";
