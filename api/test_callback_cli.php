<?php
/**
 * Command Line Test for Callback Requests API
 */

echo "=================================================\n";
echo "   Callback Requests API - CLI Test Suite\n";
echo "=================================================\n\n";

$baseUrl = 'http://localhost/api/callback_requests_api.php';

// Test 1: List Callback Requests
echo "TEST 1: List Callback Requests\n";
echo "-----------------------------------\n";
$response1 = file_get_contents($baseUrl . '?action=list&user_id=1');
echo "Response: " . $response1 . "\n";
$data1 = json_decode($response1, true);
echo "Success: " . ($data1['success'] ? 'YES' : 'NO') . "\n";
echo "Data Count: " . count($data1['data'] ?? []) . "\n\n";

// Test 2: Add Callback Request
echo "TEST 2: Add Callback Request\n";
echo "-----------------------------------\n";
$payload = json_encode([
    'driver_name' => 'Test Driver',
    'phone_number' => '9876543210',
    'preferred_time' => date('Y-m-d H:i:s', strtotime('+1 hour')),
    'notes' => 'CLI Test callback request',
    'user_id' => 1
]);

$options = [
    'http' => [
        'header'  => "Content-Type: application/json\r\n",
        'method'  => 'POST',
        'content' => $payload
    ]
];
$context = stream_context_create($options);
$response2 = file_get_contents($baseUrl . '?action=add', false, $context);
echo "Payload: " . $payload . "\n";
echo "Response: " . $response2 . "\n";
$data2 = json_decode($response2, true);
echo "Success: " . ($data2['success'] ? 'YES' : 'NO') . "\n\n";

// Test 3: Update Callback Status
echo "TEST 3: Update Callback Status\n";
echo "-----------------------------------\n";
$payload3 = json_encode([
    'callback_id' => 1,
    'status' => 'completed'
]);

$options3 = [
    'http' => [
        'header'  => "Content-Type: application/json\r\n",
        'method'  => 'POST',
        'content' => $payload3
    ]
];
$context3 = stream_context_create($options3);
$response3 = file_get_contents($baseUrl . '?action=update_status', false, $context3);
echo "Payload: " . $payload3 . "\n";
echo "Response: " . $response3 . "\n";
$data3 = json_decode($response3, true);
echo "Success: " . ($data3['success'] ? 'YES' : 'NO') . "\n\n";

// Test 4: Invalid Action
echo "TEST 4: Invalid Action (Error Handling)\n";
echo "-----------------------------------\n";
$response4 = @file_get_contents($baseUrl . '?action=invalid');
echo "Response: " . ($response4 ?: 'Error (Expected)') . "\n";
if ($response4) {
    $data4 = json_decode($response4, true);
    echo "Success: " . ($data4['success'] ? 'YES' : 'NO') . "\n";
    echo "Error: " . ($data4['error'] ?? 'N/A') . "\n";
}

echo "\n=================================================\n";
echo "   All Tests Completed!\n";
echo "=================================================\n";
?>
