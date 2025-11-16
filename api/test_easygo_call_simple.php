<?php
/**
 * Simple EasyGo IVR Call Test
 * Test calling between two phone numbers
 */

require_once 'config.php';

// Test phone numbers
$telecallerPhone = '08303154516'; // Your telecaller phone number
$clientPhone = '06265760864';     // Client phone number to call

echo "<h1>EasyGo IVR Call Test</h1>";
echo "<p>Testing call between two numbers...</p>";

echo "<div style='background: #f0f0f0; padding: 15px; border-radius: 5px; margin: 20px 0;'>";
echo "<h3>Test Configuration:</h3>";
echo "<p><strong>Telecaller Phone:</strong> $telecallerPhone</p>";
echo "<p><strong>Client Phone:</strong> $clientPhone</p>";
echo "<p><strong>DID:</strong> 6882742</p>";
echo "</div>";

// Prepare request
$url = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/easygo_ivr_api.php?action=initiate_call";

$data = [
    'exten' => $telecallerPhone,
    'number' => $clientPhone,
    'caller_id' => 1,  // Test caller ID
    'contact_id' => 'TEST_CONTACT',
    'contact_type' => 'driver',
    'duration' => ''
];

echo "<h3>Step 1: Initiating Call...</h3>";
echo "<p>Sending request to: <code>$url</code></p>";
echo "<pre>" . json_encode($data, JSON_PRETTY_PRINT) . "</pre>";

// Make API call
$ch = curl_init($url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
curl_close($ch);

echo "<h3>Step 2: API Response</h3>";
echo "<p><strong>HTTP Code:</strong> $httpCode</p>";

if ($curlError) {
    echo "<div style='background: #ffebee; padding: 15px; border-radius: 5px; color: #c62828;'>";
    echo "<h4>❌ cURL Error:</h4>";
    echo "<p>$curlError</p>";
    echo "</div>";
    exit;
}

echo "<p><strong>Response:</strong></p>";
echo "<pre style='background: #fff; padding: 15px; border: 1px solid #ddd; border-radius: 5px;'>";
echo htmlspecialchars($response);
echo "</pre>";

$result = json_decode($response, true);

if ($result && $result['success']) {
    echo "<div style='background: #e8f5e9; padding: 15px; border-radius: 5px; color: #2e7d32; margin: 20px 0;'>";
    echo "<h3>✅ Call Initiated Successfully!</h3>";
    echo "<p><strong>Reference ID:</strong> " . ($result['reference_id'] ?? 'N/A') . "</p>";
    echo "<p><strong>Call Log ID:</strong> " . ($result['call_log_id'] ?? 'N/A') . "</p>";
    echo "<p><strong>Status:</strong> Both phones should ring now!</p>";
    echo "</div>";
    
    $callLogId = $result['call_log_id'] ?? null;
    
    // Check database entry
    if ($callLogId) {
        echo "<h3>Step 3: Database Entry</h3>";
        $stmt = $conn->prepare("SELECT * FROM call_logs WHERE id = ?");
        $stmt->bind_param('i', $callLogId);
        $stmt->execute();
        $dbResult = $stmt->get_result();
        
        if ($row = $dbResult->fetch_assoc()) {
            echo "<table border='1' cellpadding='10' style='border-collapse: collapse; width: 100%; background: #fff;'>";
            echo "<tr><th style='background: #007BFF; color: white;'>Field</th><th style='background: #007BFF; color: white;'>Value</th></tr>";
            foreach ($row as $key => $value) {
                if ($key === 'api_response') {
                    $value = '<pre>' . htmlspecialchars(json_encode(json_decode($value), JSON_PRETTY_PRINT)) . '</pre>';
                }
                echo "<tr><td><strong>$key</strong></td><td>$value</td></tr>";
            }
            echo "</table>";
        }
        $stmt->close();
    }
    
    echo "<div style='background: #fff3cd; padding: 15px; border-radius: 5px; color: #856404; margin: 20px 0;'>";
    echo "<h3>📞 What Should Happen:</h3>";
    echo "<ol>";
    echo "<li>Telecaller phone ($telecallerPhone) should ring</li>";
    echo "<li>Client phone ($clientPhone) should ring</li>";
    echo "<li>When either party answers, both are connected</li>";
    echo "<li>Call duration is tracked</li>";
    echo "</ol>";
    echo "</div>";
    
} else {
    echo "<div style='background: #ffebee; padding: 15px; border-radius: 5px; color: #c62828; margin: 20px 0;'>";
    echo "<h3>❌ Call Failed!</h3>";
    echo "<p><strong>Error:</strong> " . ($result['error'] ?? 'Unknown error') . "</p>";
    echo "</div>";
    
    // Debug information
    echo "<h3>Debug Information:</h3>";
    
    // Check token
    $tokenResult = $conn->query("SELECT token, expires_at FROM easygo_tokens ORDER BY created_at DESC LIMIT 1");
    if ($tokenResult && $row = $tokenResult->fetch_assoc()) {
        echo "<p><strong>Token Expires:</strong> {$row['expires_at']}</p>";
        $isExpired = strtotime($row['expires_at']) < time();
        echo "<p><strong>Token Status:</strong> " . ($isExpired ? '❌ EXPIRED' : '✅ Valid') . "</p>";
    } else {
        echo "<p style='color: red;'>❌ No token found in database</p>";
    }
    
    // Check credentials
    echo "<h4>Configuration Check:</h4>";
    echo "<p>✅ Username: admin@truckmitr.com</p>";
    echo "<p>✅ DID: 6882742</p>";
    echo "<p>✅ API Endpoint: https://client.easygoivr.com/easygoapiJwt/request/dial</p>";
}

// Show recent call logs
echo "<hr><h3>Recent Call Logs (Last 5)</h3>";
$logsResult = $conn->query("
    SELECT id, caller_id, contact_id, contact_type, contact_phone, 
           call_type, call_status, reference_id, created_at
    FROM call_logs 
    WHERE call_type = 'easygo_ivr'
    ORDER BY created_at DESC 
    LIMIT 5
");

if ($logsResult && $logsResult->num_rows > 0) {
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse; width: 100%; background: #fff;'>";
    echo "<tr style='background: #007BFF; color: white;'>";
    echo "<th>ID</th><th>Caller ID</th><th>Contact ID</th><th>Type</th><th>Phone</th><th>Status</th><th>Created</th>";
    echo "</tr>";
    while ($row = $logsResult->fetch_assoc()) {
        echo "<tr>";
        echo "<td>{$row['id']}</td>";
        echo "<td>{$row['caller_id']}</td>";
        echo "<td>{$row['contact_id']}</td>";
        echo "<td>{$row['contact_type']}</td>";
        echo "<td>{$row['contact_phone']}</td>";
        echo "<td>{$row['call_status']}</td>";
        echo "<td>{$row['created_at']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p>No EasyGo IVR calls found in database yet.</p>";
}

$conn->close();

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
    border-radius: 5px;
    overflow-x: auto;
}
code {
    background: #f0f0f0;
    padding: 2px 6px;
    border-radius: 3px;
    font-family: 'Courier New', monospace;
}
table {
    margin: 20px 0;
}
th {
    text-align: left;
}
</style>

<script>
// Auto-refresh every 30 seconds to see status updates
setTimeout(function() {
    console.log('Page will refresh in 30 seconds to check call status...');
}, 1000);
</script>
