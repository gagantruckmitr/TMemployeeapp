<?php
/**
 * Check MyOperator Configuration and Test API
 */
header('Content-Type: application/json');

// Load .env
$envFile = __DIR__ . '/../.env';
$config = [];

if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos(trim($line), '#') === 0) continue;
        if (strpos($line, '=') === false) continue;
        list($key, $value) = explode('=', $line, 2);
        $config[trim($key)] = trim($value);
    }
}

$companyId = $config['MYOPERATOR_COMPANY_ID'] ?? '';
$secretToken = $config['MYOPERATOR_SECRET_TOKEN'] ?? '';
$ivrId = $config['MYOPERATOR_IVR_ID'] ?? '';
$apiKey = $config['MYOPERATOR_API_KEY'] ?? '';
$callerId = $config['MYOPERATOR_CALLER_ID'] ?? '';

$result = [
    'configured' => false,
    'credentials' => [
        'company_id' => !empty($companyId) && $companyId !== 'your_company_id',
        'secret_token' => !empty($secretToken) && $secretToken !== 'your_secret_token',
        'ivr_id' => !empty($ivrId) && $ivrId !== 'your_ivr_id',
        'api_key' => !empty($apiKey) && $apiKey !== 'your_api_key',
        'caller_id' => !empty($callerId) && $callerId !== '+911234567890'
    ],
    'values' => [
        'company_id' => $companyId ? substr($companyId, 0, 8) . '...' : 'NOT SET',
        'secret_token' => $secretToken ? substr($secretToken, 0, 10) . '...' : 'NOT SET',
        'ivr_id' => $ivrId ? substr($ivrId, 0, 8) . '...' : 'NOT SET',
        'api_key' => $apiKey ? substr($apiKey, 0, 10) . '...' : 'NOT SET',
        'caller_id' => $callerId ?: 'NOT SET'
    ],
    'api_test' => null,
    'message' => ''
];

// Check if all credentials are set
$allSet = array_reduce($result['credentials'], function($carry, $item) {
    return $carry && $item;
}, true);

$result['configured'] = $allSet;

if (!$allSet) {
    $result['message'] = 'MyOperator is NOT properly configured. Update .env file with real credentials from myoperator.com';
    echo json_encode($result, JSON_PRETTY_PRINT);
    exit;
}

// Test API connectivity
$apiUrl = 'https://obd-api.myoperator.co/obd-api-v1';

$testPayload = [
    'company_id' => $companyId,
    'secret_token' => $secretToken,
    'type' => '1',
    'number' => '919999999999', // Test number
    'number_2' => '919999999998', // Test number
    'public_ivr_id' => $ivrId,
    'reference_id' => 'test_' . time(),
    'caller_id' => $callerId
];

$ch = curl_init($apiUrl);
curl_setopt_array($ch, [
    CURLOPT_POST => true,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => [
        'x-api-key: ' . $apiKey,
        'Content-Type: application/json'
    ],
    CURLOPT_POSTFIELDS => json_encode($testPayload),
    CURLOPT_TIMEOUT => 10,
    CURLOPT_SSL_VERIFYPEER => true,
    CURLOPT_SSL_VERIFYHOST => 2
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

if ($error) {
    $result['api_test'] = [
        'success' => false,
        'error' => $error,
        'message' => 'Failed to connect to MyOperator API'
    ];
} else {
    $responseData = json_decode($response, true);
    $result['api_test'] = [
        'success' => $httpCode >= 200 && $httpCode < 300,
        'http_code' => $httpCode,
        'response' => $responseData,
        'message' => $httpCode >= 200 && $httpCode < 300 ? 'API is reachable' : 'API returned error'
    ];
}

if ($result['api_test']['success']) {
    $result['message'] = '✅ MyOperator is configured and API is working! Real calls should work.';
} else {
    $result['message'] = '⚠️ MyOperator credentials are set but API test failed. Check: 1) Account has credits 2) IVR is active 3) Credentials are correct';
}

echo json_encode($result, JSON_PRETTY_PRINT);
?>
