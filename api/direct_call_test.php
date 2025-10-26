<?php
/**
 * Direct MyOperator Call Test - No database, just API call
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

// Get numbers from GET parameters
$number1 = $_GET['number1'] ?? '';
$number2 = $_GET['number2'] ?? '';

if (empty($number1) || empty($number2)) {
    echo json_encode([
        'error' => 'Usage: ?number1=9999999999&number2=8888888888',
        'example' => 'direct_call_test.php?number1=9876543210&number2=9876543211'
    ]);
    exit;
}

// Clean numbers
$number1 = preg_replace('/[^0-9]/', '', $number1);
$number2 = preg_replace('/[^0-9]/', '', $number2);

// Ensure 10 digits
if (strlen($number1) > 10) $number1 = substr($number1, -10);
if (strlen($number2) > 10) $number2 = substr($number2, -10);

// Add +91 prefix (MyOperator format)
$number1 = '+91' . $number1;
$number2 = '+91' . $number2;

// MyOperator credentials
$companyId = $config['MYOPERATOR_COMPANY_ID'] ?? '';
$secretToken = $config['MYOPERATOR_SECRET_TOKEN'] ?? '';
$ivrId = $config['MYOPERATOR_IVR_ID'] ?? '';
$apiKey = $config['MYOPERATOR_API_KEY'] ?? '';
$callerId = $config['MYOPERATOR_CALLER_ID'] ?? '';
$apiUrl = $config['MYOPERATOR_API_URL'] ?? 'https://obd-api.myoperator.co/obd-api-v1';

// Clean caller_id - remove + and any non-digits
$callerId = preg_replace('/[^0-9]/', '', $callerId);

// Check configuration
if (empty($companyId) || $companyId === 'your_company_id') {
    echo json_encode([
        'error' => 'MyOperator not configured',
        'message' => 'Update .env file with real MyOperator credentials'
    ]);
    exit;
}

// Prepare payload - Required fields for MyOperator Click-to-Call
$payload = [
    'company_id' => (string)$companyId,
    'secret_token' => (string)$secretToken,
    'type' => '1', // REQUIRED: 1 = Click to Call
    'number' => (string)$number1, // Called first
    'number_2' => (string)$number2, // Called second  
    'public_ivr_id' => (string)$ivrId,
    'reference_id' => 'test_' . time()
];

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

// Return result
$responseBody = json_decode($response, true) ?? ['raw' => $response];

$result = [
    'request' => [
        'api_url' => $apiUrl,
        'number_1' => $number1,
        'number_2' => $number2,
        'company_id' => substr($companyId, 0, 8) . '...',
        'ivr_id' => substr($ivrId, 0, 8) . '...',
        'payload_sent' => $payload
    ],
    'response' => [
        'http_code' => $httpCode,
        'success' => $httpCode >= 200 && $httpCode < 300,
        'curl_error' => $error,
        'body' => $responseBody
    ],
    'message' => '',
    'troubleshooting' => []
];

if ($result['response']['success']) {
    $result['message'] = '✅ API call successful!';
    
    // Check if MyOperator actually initiated the call
    if (isset($responseBody['status']) && $responseBody['status'] === 'success') {
        $result['message'] .= ' Call should be ringing now.';
        $result['troubleshooting'][] = 'If no ring: 1) Check MyOperator account balance 2) Verify numbers are valid 3) Check IVR is active';
    } else {
        $result['message'] .= ' But MyOperator returned: ' . ($responseBody['status'] ?? 'unknown status');
        $result['troubleshooting'][] = 'Check MyOperator dashboard for call logs';
    }
} else {
    $result['message'] = '❌ API call failed.';
    
    if ($httpCode == 400) {
        $result['troubleshooting'][] = 'Bad Request - Check if all parameters are correct';
    } elseif ($httpCode == 401) {
        $result['troubleshooting'][] = 'Unauthorized - Check API credentials in .env';
    } elseif ($httpCode == 403) {
        $result['troubleshooting'][] = 'Forbidden - Check account permissions';
    } elseif ($httpCode == 500) {
        $result['troubleshooting'][] = 'Server Error - MyOperator API issue';
    }
    
    if (isset($responseBody['details'])) {
        $result['troubleshooting'][] = 'MyOperator says: ' . $responseBody['details'];
    }
}

echo json_encode($result, JSON_PRETTY_PRINT);
?>
