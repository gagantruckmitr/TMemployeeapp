<?php
/**
 * Direct MyOperator API Test
 * Tests if MyOperator API is working correctly
 */

// Load .env file
$envFile = __DIR__ . '/../.env';
$envVars = [];
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos(trim($line), '#') === 0) continue;
        if (strpos($line, '=') === false) continue;
        list($key, $value) = explode('=', $line, 2);
        $envVars[trim($key)] = trim($value);
    }
}

// MyOperator Configuration
$companyId = $envVars['MYOPERATOR_COMPANY_ID'] ?? 'your_company_id';
$secretToken = $envVars['MYOPERATOR_SECRET_TOKEN'] ?? 'your_secret_token';
$apiKey = $envVars['MYOPERATOR_API_KEY'] ?? 'your_api_key';
$callerId = preg_replace('/[^0-9]/', '', $envVars['MYOPERATOR_CALLER_ID'] ?? '911234567890');
$apiUrl = $envVars['MYOPERATOR_API_URL'] ?? 'https://obd-api.myoperator.co/obd-api-v1';

echo "<h1>MyOperator API Test</h1>";
echo "<h2>Configuration Check</h2>";
echo "<pre>";
echo "Company ID: " . ($companyId !== 'your_company_id' ? '✅ SET' : '❌ NOT SET') . "\n";
echo "Secret Token: " . ($secretToken !== 'your_secret_token' ? '✅ SET' : '❌ NOT SET') . "\n";
echo "API Key: " . ($apiKey !== 'your_api_key' ? '✅ SET' : '❌ NOT SET') . "\n";
echo "Caller ID: $callerId\n";
echo "API URL: $apiUrl\n";
echo "</pre>";

// Check if configured
if ($companyId === 'your_company_id' || $secretToken === 'your_secret_token' || $apiKey === 'your_api_key') {
    echo "<h2 style='color: red;'>❌ MyOperator Not Configured</h2>";
    echo "<p>Please update .env file with your MyOperator credentials:</p>";
    echo "<pre>";
    echo "MYOPERATOR_COMPANY_ID=your_company_id_here\n";
    echo "MYOPERATOR_SECRET_TOKEN=your_secret_token_here\n";
    echo "MYOPERATOR_API_KEY=your_api_key_here\n";
    echo "MYOPERATOR_CALLER_ID=911234567890\n";
    echo "</pre>";
    exit;
}

echo "<h2>Test Call Parameters</h2>";
echo "<pre>";

// Test numbers (replace with your actual numbers)
$testDriverNumber = '+918383971722'; // Driver to call
$testTelecallerNumber = '+918960094898'; // Telecaller (agent)

echo "Driver Number: $testDriverNumber\n";
echo "Telecaller Number: $testTelecallerNumber\n";
echo "</pre>";

// Prepare API payload for Progressive Dialing (Type 2)
$payload = [
    'company_id' => (string)$companyId,
    'secret_token' => (string)$secretToken,
    'type' => '2', // Progressive Dialing
    'number' => (string)$testDriverNumber,
    'agent_number' => (string)$testTelecallerNumber,
    'reference_id' => 'TEST_' . time(),
    'caller_id' => (string)$callerId,
    'dtmf' => '0',
    'retry' => '0',
    'max_ring_time' => '30'
];

echo "<h2>API Request</h2>";
echo "<pre>";
echo "URL: $apiUrl\n";
echo "Method: POST\n";
echo "Headers:\n";
echo "  x-api-key: " . substr($apiKey, 0, 10) . "...\n";
echo "  Content-Type: application/json\n";
echo "\nPayload:\n";
echo json_encode($payload, JSON_PRETTY_PRINT);
echo "</pre>";

// Make API call
$ch = curl_init($apiUrl);
curl_setopt_array($ch, [
    CURLOPT_POST => true,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'x-api-key: ' . $apiKey,
        'Content-Type: application/json'
    ],
    CURLOPT_POSTFIELDS => json_encode($payload),
    CURLOPT_TIMEOUT => 30,
    CURLOPT_SSL_VERIFYPEER => true,
    CURLOPT_SSL_VERIFYHOST => 2
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

echo "<h2>API Response</h2>";
echo "<pre>";
echo "HTTP Code: $httpCode\n";

if ($error) {
    echo "cURL Error: $error\n";
} else {
    echo "Response:\n";
    $responseData = json_decode($response, true);
    if ($responseData) {
        echo json_encode($responseData, JSON_PRETTY_PRINT);
    } else {
        echo $response;
    }
}
echo "</pre>";

// Interpretation
echo "<h2>Result Interpretation</h2>";
if ($httpCode >= 200 && $httpCode < 300) {
    echo "<p style='color: green; font-weight: bold;'>✅ API call successful!</p>";
    echo "<p>If you see a success response, MyOperator should be calling the numbers now.</p>";
    echo "<p><strong>Expected flow:</strong></p>";
    echo "<ol>";
    echo "<li>Telecaller phone ($testTelecallerNumber) will ring first</li>";
    echo "<li>Telecaller answers</li>";
    echo "<li>Driver phone ($testDriverNumber) rings</li>";
    echo "<li>When driver answers, both are connected</li>";
    echo "</ol>";
} else {
    echo "<p style='color: red; font-weight: bold;'>❌ API call failed</p>";
    echo "<p>Check the error message above and verify your MyOperator credentials.</p>";
}

echo "<hr>";
echo "<p><strong>Note:</strong> This is a REAL test call. If successful, actual phones will ring!</p>";
?>
