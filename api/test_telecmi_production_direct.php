<?php
header('Content-Type: text/plain; charset=utf-8');
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "==============================================\n";
echo "   TEST TELECMI PRODUCTION API\n";
echo "==============================================\n\n";

// Simulate Flutter app request
$requestData = [
    'caller_id' => 3,
    'driver_id' => '99999',
    'driver_mobile' => '6394756798'
];

echo "Simulating Flutter request:\n";
echo json_encode($requestData, JSON_PRETTY_PRINT) . "\n\n";

// Make request to production API
$url = 'http://truckmitr.com/api/telecmi_production_api.php?action=click_to_call';

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($requestData));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true); // Follow redirects

echo "Calling: $url\n\n";

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curl_error = curl_error($ch);
curl_close($ch);

echo "HTTP Code: $http_code\n";

if ($curl_error) {
    echo "CURL Error: $curl_error\n";
}

echo "Response:\n";
echo $response . "\n\n";

if ($http_code == 200) {
    $data = json_decode($response, true);
    if ($data && isset($data['success']) && $data['success']) {
        echo "==============================================\n";
        echo "   ✓✓✓ SUCCESS! ✓✓✓\n";
        echo "==============================================\n";
    } else {
        echo "==============================================\n";
        echo "   ✗✗✗ FAILED ✗✗✗\n";
        echo "==============================================\n";
        if (isset($data['message'])) {
            echo "Error: " . $data['message'] . "\n";
        }
    }
} else {
    echo "==============================================\n";
    echo "   ✗✗✗ HTTP ERROR ✗✗✗\n";
    echo "==============================================\n";
}
?>
