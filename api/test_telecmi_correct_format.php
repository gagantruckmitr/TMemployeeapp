<?php
/**
 * Test TeleCMI with Correct API Format
 */

echo "<!DOCTYPE html>";
echo "<html><head>";
echo "<title>TeleCMI Correct Format Test</title>";
echo "<style>
    body { font-family: Arial, sans-serif; max-width: 900px; margin: 50px auto; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
    .container { background: white; padding: 40px; border-radius: 20px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }
    h1 { color: #333; margin-bottom: 20px; }
    .success { background: #d4edda; border-left: 4px solid #28a745; padding: 20px; margin: 20px 0; border-radius: 8px; color: #155724; }
    .error { background: #f8d7da; border-left: 4px solid #dc3545; padding: 20px; margin: 20px 0; border-radius: 8px; color: #721c24; }
    .info { background: #d1ecf1; border-left: 4px solid #17a2b8; padding: 20px; margin: 20px 0; border-radius: 8px; color: #0c5460; }
    pre { background: #f4f4f4; padding: 15px; border-radius: 5px; overflow-x: auto; font-size: 13px; }
    code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; font-family: monospace; }
    .btn { display: inline-block; padding: 15px 30px; background: #667eea; color: white; text-decoration: none; border-radius: 10px; margin: 10px 5px; font-weight: 600; }
    table { width: 100%; border-collapse: collapse; margin: 15px 0; }
    th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #667eea; color: white; }
</style>";
echo "</head><body><div class='container'>";

echo "<h1>🔄 Testing TeleCMI with Correct Format</h1>";

// Credentials
$appId = '33336628';
$appSecret = 'bb0b92ca-3d8a-405b-87aa-fc035fe1cdc6';
$userId = '5003';
$fullUserId = $userId . '_' . $appId;

echo "<div class='info'>";
echo "<h3>Using Correct TeleCMI API Format</h3>";
echo "<p>Based on TeleCMI documentation:</p>";
echo "<ul>";
echo "<li>Endpoint: <code>https://rest.telecmi.com/v2/webrtc/click2call</code></li>";
echo "<li>User ID Format: <code>{user_id}_{app_id}</code></li>";
echo "<li>Authentication: <code>secret</code> parameter</li>";
echo "</ul>";
echo "</div>";

echo "<h2>Test 1: Click-to-Call</h2>";

$payload = [
    'user_id'  => $fullUserId,
    'secret'   => $appSecret,
    'to'       => 918448079624,  // Must be integer, not string
    'webrtc'   => false,
    'followme' => true
];

echo "<h3>Request:</h3>";
echo "<table>";
echo "<tr><th>Parameter</th><th>Value</th></tr>";
echo "<tr><td>URL</td><td><code>https://rest.telecmi.com/v2/webrtc/click2call</code></td></tr>";
echo "<tr><td>user_id</td><td><code>$fullUserId</code></td></tr>";
echo "<tr><td>secret</td><td><code>" . substr($appSecret, 0, 20) . "...</code></td></tr>";
echo "<tr><td>to</td><td><code>918448079624</code></td></tr>";
echo "<tr><td>webrtc</td><td><code>false</code></td></tr>";
echo "<tr><td>followme</td><td><code>true</code></td></tr>";
echo "</table>";

echo "<h3>Full Payload:</h3>";
echo "<pre>" . json_encode($payload, JSON_PRETTY_PRINT) . "</pre>";

$ch = curl_init();
curl_setopt_array($ch, [
    CURLOPT_URL => 'https://rest.telecmi.com/v2/webrtc/click2call',
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT => 10,
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => json_encode($payload),
    CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
curl_close($ch);

echo "<h3>Response:</h3>";
echo "<p><strong>HTTP Code:</strong> $httpCode</p>";

if ($curlError) {
    echo "<div class='error'>";
    echo "<h3>❌ Connection Error</h3>";
    echo "<p>$curlError</p>";
    echo "</div>";
} else {
    $data = json_decode($response, true);
    
    echo "<pre>" . json_encode($data, JSON_PRETTY_PRINT) . "</pre>";
    
    if ($httpCode == 200 && (!isset($data['error']) || $data['error'] === false)) {
        echo "<div class='success'>";
        echo "<h3>🎉 SUCCESS! Click-to-Call Working!</h3>";
        echo "<p>Your TeleCMI API is working with the correct format!</p>";
        echo "</div>";
        
        echo "<h3>✅ Your API is Now Operational!</h3>";
        echo "<p>You can now use the updated API endpoints.</p>";
        
        echo "<h3>Next Steps:</h3>";
        echo "<p>";
        echo "<a href='telecmi_demo.html' class='btn'>📞 Try Interactive Demo</a> ";
        echo "<a href='telecmi_status.php' class='btn'>📊 View Status</a>";
        echo "</p>";
        
    } else {
        echo "<div class='error'>";
        echo "<h3>❌ API Call Failed</h3>";
        
        if (isset($data['msg'])) {
            echo "<p><strong>Error:</strong> {$data['msg']}</p>";
        }
        
        if (isset($data['code'])) {
            echo "<p><strong>Error Code:</strong> {$data['code']}</p>";
        }
        
        // Check for subscription issue
        if (isset($data['msg']) && (strpos($data['msg'], 'subscription') !== false || strpos($data['msg'], 'expired') !== false)) {
            echo "<div class='info' style='margin-top: 20px;'>";
            echo "<h4>⚠️ Subscription Issue Detected</h4>";
            echo "<p>Please renew your TeleCMI subscription to use the API.</p>";
            echo "</div>";
        }
        
        echo "</div>";
    }
}

echo "<hr style='margin: 30px 0;'>";

echo "<h2>Updated API Documentation</h2>";

echo "<h3>Click-to-Call Endpoint:</h3>";
echo "<pre>";
echo "POST http://truckmitr.com/api/telecmi_api.php?action=click_to_call\n";
echo "Content-Type: application/json\n\n";
echo json_encode([
    'user_id' => '5003',
    'to' => '918448079624',
    'webrtc' => false,
    'followme' => true
], JSON_PRETTY_PRINT);
echo "</pre>";

echo "<h3>Flutter Integration:</h3>";
echo "<pre><code>";
echo "final response = await http.post(\n";
echo "  Uri.parse('http://truckmitr.com/api/telecmi_api.php?action=click_to_call'),\n";
echo "  headers: {'Content-Type': 'application/json'},\n";
echo "  body: jsonEncode({\n";
echo "    'user_id': '5003',\n";
echo "    'to': '918448079624',\n";
echo "    'webrtc': false,\n";
echo "    'followme': true,\n";
echo "  }),\n";
echo ");";
echo "</code></pre>";

echo "</div></body></html>";
?>
