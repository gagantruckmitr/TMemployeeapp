<?php
header('Content-Type: text/plain; charset=utf-8');

echo "Testing Simple TeleCMI API...\n\n";

$requestData = [
    'caller_id' => 3,
    'driver_id' => '99999',
    'driver_mobile' => '6394756798'
];

$url = 'http://truckmitr.com/api/telecmi_simple_working.php?action=click_to_call';

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($requestData));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curl_error = curl_error($ch);
curl_close($ch);

echo "URL: $url\n";
echo "HTTP Code: $http_code\n";

if ($curl_error) {
    echo "CURL Error: $curl_error\n";
}

echo "\nResponse:\n";
echo $response . "\n\n";

if ($http_code == 200) {
    $data = json_decode($response, true);
    if ($data && isset($data['success']) && $data['success']) {
        echo "✓✓✓ SUCCESS! CALL INITIATED! ✓✓✓\n";
        echo "Call ID: " . ($data['data']['call_id'] ?? 'N/A') . "\n";
    } else {
        echo "✗✗✗ FAILED ✗✗✗\n";
        echo "Error: " . ($data['message'] ?? 'Unknown') . "\n";
    }
} else {
    echo "✗✗✗ HTTP ERROR ✗✗✗\n";
}
?>
