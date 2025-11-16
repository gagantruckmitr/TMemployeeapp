<?php
/**
 * Test EasyGo IVR Integration
 */

require_once 'config.php';

echo "<h1>EasyGo IVR Integration Test</h1>";

// Test 1: Generate Token
echo "<h2>Test 1: Generate Token</h2>";
$tokenUrl = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/easygo_ivr_api.php?action=generate_token";
echo "<p>Testing: <code>$tokenUrl</code></p>";

$ch = curl_init($tokenUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "<p><strong>HTTP Code:</strong> $httpCode</p>";
echo "<p><strong>Response:</strong></p>";
echo "<pre>" . htmlspecialchars($response) . "</pre>";

$tokenData = json_decode($response, true);
if ($tokenData && $tokenData['success']) {
    echo "<p style='color: green;'>✅ Token generated successfully!</p>";
    $token = $tokenData['token'];
} else {
    echo "<p style='color: red;'>❌ Token generation failed!</p>";
    exit;
}

// Test 2: Initiate Call
echo "<hr><h2>Test 2: Initiate Call</h2>";
$callUrl = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/easygo_ivr_api.php?action=initiate_call";
echo "<p>Testing: <code>$callUrl</code></p>";

$testData = [
    'exten' => '08303154516',  // Telecaller phone
    'number' => '06265760864', // Client phone
    'duration' => ''
];

echo "<p><strong>Request Data:</strong></p>";
echo "<pre>" . json_encode($testData, JSON_PRETTY_PRINT) . "</pre>";

$ch = curl_init($callUrl);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($testData));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "<p><strong>HTTP Code:</strong> $httpCode</p>";
echo "<p><strong>Response:</strong></p>";
echo "<pre>" . htmlspecialchars($response) . "</pre>";

$callData = json_decode($response, true);
if ($callData && $callData['success']) {
    echo "<p style='color: green;'>✅ Call initiated successfully!</p>";
    echo "<p><strong>Reference ID:</strong> " . ($callData['reference_id'] ?? 'N/A') . "</p>";
} else {
    echo "<p style='color: red;'>❌ Call initiation failed!</p>";
    echo "<p><strong>Error:</strong> " . ($callData['error'] ?? 'Unknown error') . "</p>";
}

// Test 3: Get Call Logs
echo "<hr><h2>Test 3: Get Call Logs</h2>";
$logsUrl = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/easygo_ivr_api.php?action=get_call_logs&limit=10";
echo "<p>Testing: <code>$logsUrl</code></p>";

$ch = curl_init($logsUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "<p><strong>HTTP Code:</strong> $httpCode</p>";
echo "<p><strong>Response:</strong></p>";
echo "<pre>" . htmlspecialchars($response) . "</pre>";

$logsData = json_decode($response, true);
if ($logsData && $logsData['success']) {
    echo "<p style='color: green;'>✅ Call logs retrieved successfully!</p>";
    echo "<p><strong>Total Logs:</strong> " . count($logsData['data']) . "</p>";
} else {
    echo "<p style='color: red;'>❌ Failed to retrieve call logs!</p>";
}

// Test 4: Check Database Tables
echo "<hr><h2>Test 4: Check Database Tables</h2>";

// Check easygo_tokens table
$result = $conn->query("SELECT COUNT(*) as count FROM easygo_tokens");
if ($result) {
    $row = $result->fetch_assoc();
    echo "<p>✅ <strong>easygo_tokens</strong> table exists with {$row['count']} records</p>";
} else {
    echo "<p style='color: red;'>❌ <strong>easygo_tokens</strong> table not found!</p>";
}

// Check easygo_call_logs table
$result = $conn->query("SELECT COUNT(*) as count FROM easygo_call_logs");
if ($result) {
    $row = $result->fetch_assoc();
    echo "<p>✅ <strong>easygo_call_logs</strong> table exists with {$row['count']} records</p>";
} else {
    echo "<p style='color: red;'>❌ <strong>easygo_call_logs</strong> table not found!</p>";
}

// Show latest token
$result = $conn->query("SELECT token, expires_at, created_at FROM easygo_tokens ORDER BY created_at DESC LIMIT 1");
if ($result && $row = $result->fetch_assoc()) {
    echo "<h3>Latest Token:</h3>";
    echo "<p><strong>Token:</strong> " . substr($row['token'], 0, 50) . "...</p>";
    echo "<p><strong>Expires At:</strong> {$row['expires_at']}</p>";
    echo "<p><strong>Created At:</strong> {$row['created_at']}</p>";
}

// Show latest call logs
$result = $conn->query("SELECT * FROM easygo_call_logs ORDER BY created_at DESC LIMIT 5");
if ($result && $result->num_rows > 0) {
    echo "<h3>Latest Call Logs:</h3>";
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>Reference ID</th><th>Telecaller</th><th>Client</th><th>Status</th><th>Created At</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>{$row['reference_id']}</td>";
        echo "<td>{$row['telecaller_phone']}</td>";
        echo "<td>{$row['client_phone']}</td>";
        echo "<td>{$row['status']}</td>";
        echo "<td>{$row['created_at']}</td>";
        echo "</tr>";
    }
    echo "</table>";
}

$conn->close();

echo "<hr><h2>Summary</h2>";
echo "<p>All tests completed. Check the results above.</p>";
?>

<style>
body {
    font-family: Arial, sans-serif;
    max-width: 1200px;
    margin: 20px auto;
    padding: 20px;
    background: #f5f5f5;
}
h1, h2, h3 {
    color: #333;
}
pre {
    background: #fff;
    padding: 15px;
    border: 1px solid #ddd;
    border-radius: 4px;
    overflow-x: auto;
}
code {
    background: #f0f0f0;
    padding: 2px 6px;
    border-radius: 3px;
}
table {
    background: #fff;
    width: 100%;
}
th {
    background: #007BFF;
    color: white;
    text-align: left;
}
</style>
