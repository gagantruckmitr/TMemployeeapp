<?php
/**
 * Test Social Media Feedback API
 */

header('Content-Type: application/json');

$testData = [
    'caller_id' => 1,
    'lead_id' => 1,
    'name' => 'Test User',
    'mobile' => '9999999999',
    'source' => 'Facebook',
    'role' => 'driver',
    'feedback' => 'Test Feedback',
    'remarks' => 'Test remarks'
];

$ch = curl_init('https://truckmitr.com/truckmitr-app/api/social_media_feedback_api.php');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($testData));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo json_encode([
    'http_code' => $httpCode,
    'response' => $response,
    'is_json' => json_decode($response) !== null,
    'test_data' => $testData
], JSON_PRETTY_PRINT);
?>
