<?php
/**
 * Direct test of telecmi_flutter_api.php to see the 500 error
 */

$url = 'https://truckmitr.com/truckmitr-app/api/telecmi_flutter_api.php';

$data = [
    'caller_id' => 3,
    'driver_id' => '15311',
    'driver_mobile' => '7759943811'
];

echo "Testing TeleCMI Flutter API\n";
echo "URL: $url\n";
echo "Data: " . json_encode($data) . "\n";
echo str_repeat('=', 60) . "\n\n";

$ch = curl_init();
curl_setopt_array($ch, [
    CURLOPT_URL => $url,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => json_encode($data),
    CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
    CURLOPT_TIMEOUT => 30,
    CURLOPT_VERBOSE => true
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
curl_close($ch);

echo "HTTP Code: $httpCode\n";
echo "Response Length: " . strlen($response) . " bytes\n";
echo "Response: $response\n";

if ($curlError) {
    echo "cURL Error: $curlError\n";
}

echo "\n" . str_repeat('=', 60) . "\n";

// Check error log
$errorLogPath = __DIR__ . '/telecmi_flutter_errors.log';
if (file_exists($errorLogPath)) {
    echo "\nError Log Contents:\n";
    echo str_repeat('-', 60) . "\n";
    echo file_get_contents($errorLogPath);
} else {
    echo "\nNo error log found at: $errorLogPath\n";
}
?>
