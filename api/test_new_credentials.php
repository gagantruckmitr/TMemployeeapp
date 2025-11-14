<?php
/**
 * Test New TeleCMI Credentials
 */

echo "<!DOCTYPE html>";
echo "<html><head>";
echo "<title>Testing New Credentials</title>";
echo "<style>
    body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); }
    .container { background: white; padding: 40px; border-radius: 20px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); }
    h1 { color: #333; margin-bottom: 20px; }
    .success { background: #d4edda; border-left: 4px solid #28a745; padding: 20px; margin: 20px 0; border-radius: 5px; color: #155724; }
    .error { background: #f8d7da; border-left: 4px solid #dc3545; padding: 20px; margin: 20px 0; border-radius: 5px; color: #721c24; }
    .info { background: #d1ecf1; border-left: 4px solid #17a2b8; padding: 20px; margin: 20px 0; border-radius: 5px; color: #0c5460; }
    pre { background: #f4f4f4; padding: 15px; border-radius: 5px; overflow-x: auto; }
    .btn { display: inline-block; padding: 15px 30px; background: #667eea; color: white; text-decoration: none; border-radius: 10px; margin: 10px 5px; font-weight: 600; }
    .btn:hover { background: #5568d3; }
    .loading { text-align: center; padding: 20px; }
</style>";
echo "</head><body><div class='container'>";

echo "<h1>🔄 Testing New TeleCMI Credentials</h1>";

// Load environment
function loadEnv() {
    $paths = [
        '/var/www/vhosts/truckmitr.com/httpdocs/.env',
        __DIR__ . '/../.env',
        __DIR__ . '/../../.env',
    ];
    
    foreach ($paths as $path) {
        if (file_exists($path)) {
            $lines = file($path, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
            foreach ($lines as $line) {
                if (strpos(trim($line), '#') === 0) continue;
                if (strpos($line, '=') === false) continue;
                
                list($name, $value) = explode('=', $line, 2);
                $name = trim($name);
                $value = trim($value);
                
                if (!array_key_exists($name, $_ENV)) {
                    $_ENV[$name] = $value;
                    putenv("$name=$value");
                }
            }
            return $path;
        }
    }
    return false;
}

loadEnv();

$appId = getenv('TELECMI_APP_ID');
$appSecret = getenv('TELECMI_APP_SECRET');
$sdkBase = getenv('TELECMI_SDK_BASE') ?: 'https://piopiy.telecmi.com/v1/agentLogin';

echo "<div class='info'>";
echo "<p><strong>Testing with credentials:</strong></p>";
echo "<p>APP_ID: <code>$appId</code></p>";
echo "<p>APP_SECRET: <code>" . substr($appSecret, 0, 20) . "...</code></p>";
echo "</div>";

// Test connection
$testUser = 'test_' . time();
$payload = [
    'app_id' => $appId,
    'app_secret' => $appSecret,
    'user' => $testUser,
];

echo "<h2>Sending Request to TeleCMI...</h2>";
echo "<pre>" . json_encode($payload, JSON_PRETTY_PRINT) . "</pre>";

$ch = curl_init();
curl_setopt_array($ch, [
    CURLOPT_URL => $sdkBase,
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

echo "<h2>Response:</h2>";
echo "<p><strong>HTTP Code:</strong> $httpCode</p>";

if ($curlError) {
    echo "<div class='error'>";
    echo "<h3>❌ Connection Error</h3>";
    echo "<p>$curlError</p>";
    echo "</div>";
} else {
    $data = json_decode($response, true);
    
    if ($httpCode == 200 && isset($data['token'])) {
        echo "<div class='success'>";
        echo "<h3>🎉 SUCCESS! Authentication Working!</h3>";
        echo "<p>Your TeleCMI credentials are correct and working perfectly!</p>";
        echo "<p><strong>SDK Token received:</strong> " . substr($data['token'], 0, 50) . "...</p>";
        echo "</div>";
        
        echo "<h3>✅ Your API is Now Fully Operational!</h3>";
        echo "<p>You can now:</p>";
        echo "<ul>";
        echo "<li>Make calls from your Flutter app</li>";
        echo "<li>Generate SDK tokens for WebRTC</li>";
        echo "<li>Use click-to-call functionality</li>";
        echo "</ul>";
        
        echo "<h3>Next Steps:</h3>";
        echo "<p>";
        echo "<a href='telecmi_demo.html' class='btn'>📞 Try Interactive Demo</a> ";
        echo "<a href='telecmi_status.php' class='btn'>📊 View Status Dashboard</a>";
        echo "</p>";
        
        echo "<h3>API Endpoints Ready:</h3>";
        $baseUrl = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']);
        echo "<pre>";
        echo "SDK Token: $baseUrl/telecmi_api.php?action=sdk_token\n";
        echo "Click-to-Call: $baseUrl/telecmi_api.php?action=click_to_call\n";
        echo "Webhook: $baseUrl/telecmi_api.php?action=webhook";
        echo "</pre>";
        
    } else {
        echo "<div class='error'>";
        echo "<h3>❌ Authentication Still Failing</h3>";
        echo "<p><strong>Response:</strong></p>";
        echo "<pre>" . json_encode($data, JSON_PRETTY_PRINT) . "</pre>";
        echo "<p>Please verify your credentials are correct in your TeleCMI dashboard.</p>";
        echo "</div>";
        
        echo "<p><a href='diagnose_telecmi_error.php' class='btn'>🔍 Run Full Diagnosis</a></p>";
    }
}

echo "</div></body></html>";
?>
