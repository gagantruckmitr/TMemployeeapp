<?php
/**
 * Test file for Webhook API
 * Tests both GET and POST operations
 */

echo "<h1>Webhook API Test</h1>";
echo "<hr>";

$baseUrl = 'http://localhost/api/webhook_api.php';

// Test 1: Create a new webhook (POST)
echo "<h2>Test 1: Create New Webhook (POST)</h2>";
$webhookData = [
    'client' => 'test_client',
    'call_type' => 'inbound',
    'Linkedid' => 'LINK123456',
    'extension_no' => '1001',
    'did' => '9876543210',
    'caller_id' => '1234567890',
    'ACD' => 'ACD001',
    'recfile' => 'https://example.com/recordings/call123.mp3',
    'exten_ring_time' => '2024-01-15 10:30:00',
    'exten_ans_time' => '2024-01-15 10:30:05',
    'durn' => 120,
    'billsec' => 115,
    'disposition' => 'ANSWERED',
    'action' => 'completed',
    'start_time' => '2024-01-15 10:30:00',
    'acd_durn' => 5,
    'acd_time' => '5',
    'end_time' => '2024-01-15 10:32:00',
    'dtmf' => '1',
    'agent_disconnect' => 0,
    'transfer' => 0,
    'feedback' => 'Call completed successfully',
    'conf' => 0,
    'endcall' => 1
];

$ch = curl_init($baseUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($webhookData));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "<strong>Request:</strong><br>";
echo "<pre>" . json_encode($webhookData, JSON_PRETTY_PRINT) . "</pre>";
echo "<strong>Response (HTTP $httpCode):</strong><br>";
echo "<pre>" . json_encode(json_decode($response), JSON_PRETTY_PRINT) . "</pre>";

$createdWebhook = json_decode($response, true);
$webhookId = $createdWebhook['data']['id'] ?? null;

echo "<hr>";

// Test 2: Get all webhooks (GET)
echo "<h2>Test 2: Get All Webhooks (GET)</h2>";
$ch = curl_init($baseUrl . '?action=list');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "<strong>Response (HTTP $httpCode):</strong><br>";
echo "<pre>" . json_encode(json_decode($response), JSON_PRETTY_PRINT) . "</pre>";

echo "<hr>";

// Test 3: Get single webhook by ID (GET)
if ($webhookId) {
    echo "<h2>Test 3: Get Single Webhook by ID (GET)</h2>";
    $ch = curl_init($baseUrl . "?action=get&id=$webhookId");
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "<strong>Response (HTTP $httpCode):</strong><br>";
    echo "<pre>" . json_encode(json_decode($response), JSON_PRETTY_PRINT) . "</pre>";
    
    echo "<hr>";
}

// Test 4: Get webhooks with filters (GET)
echo "<h2>Test 4: Get Webhooks with Filters (GET)</h2>";
$ch = curl_init($baseUrl . '?action=list&disposition=ANSWERED&limit=5');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "<strong>Response (HTTP $httpCode):</strong><br>";
echo "<pre>" . json_encode(json_decode($response), JSON_PRETTY_PRINT) . "</pre>";

echo "<hr>";

// Test 5: Create another webhook with different call type
echo "<h2>Test 5: Create Another Webhook (POST)</h2>";
$webhookData2 = [
    'client' => 'test_client_2',
    'call_type' => 'outbound',
    'Linkedid' => 'LINK789012',
    'extension_no' => '1002',
    'did' => '9876543211',
    'caller_id' => '9988776655',
    'disposition' => 'NO ANSWER',
    'durn' => 30,
    'billsec' => 0,
    'start_time' => '2024-01-15 11:00:00',
    'end_time' => '2024-01-15 11:00:30',
    'agent_disconnect' => 1,
    'endcall' => 1
];

$ch = curl_init($baseUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($webhookData2));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "<strong>Request:</strong><br>";
echo "<pre>" . json_encode($webhookData2, JSON_PRETTY_PRINT) . "</pre>";
echo "<strong>Response (HTTP $httpCode):</strong><br>";
echo "<pre>" . json_encode(json_decode($response), JSON_PRETTY_PRINT) . "</pre>";

echo "<hr>";
echo "<h3>All tests completed!</h3>";
?>
