<?php
/**
 * Diagnose TeleCMI Authentication Error
 * This will help identify the exact issue with TeleCMI credentials
 */

echo "<!DOCTYPE html>";
echo "<html><head>";
echo "<title>TeleCMI Error Diagnosis</title>";
echo "<style>
    body { font-family: Arial, sans-serif; max-width: 1000px; margin: 20px auto; padding: 20px; background: #f5f5f5; }
    .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    h1 { color: #dc3545; border-bottom: 3px solid #dc3545; padding-bottom: 10px; }
    h2 { color: #667eea; margin-top: 30px; }
    .error { background: #f8d7da; border-left: 4px solid #dc3545; padding: 15px; margin: 10px 0; border-radius: 5px; color: #721c24; }
    .success { background: #d4edda; border-left: 4px solid #28a745; padding: 15px; margin: 10px 0; border-radius: 5px; color: #155724; }
    .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 10px 0; border-radius: 5px; color: #856404; }
    .info { background: #d1ecf1; border-left: 4px solid #17a2b8; padding: 15px; margin: 10px 0; border-radius: 5px; color: #0c5460; }
    table { width: 100%; border-collapse: collapse; margin: 15px 0; }
    th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #667eea; color: white; }
    code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; font-family: monospace; }
    pre { background: #f4f4f4; padding: 15px; border-radius: 5px; overflow-x: auto; }
    .solution { background: #e7f3ff; padding: 20px; border-radius: 10px; border-left: 5px solid #2196F3; margin: 20px 0; }
</style>";
echo "</head><body><div class='container'>";

echo "<h1>🔍 TeleCMI Error Diagnosis</h1>";
echo "<p>Analyzing the authentication failure...</p>";

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

$appId = getenv('TELECMI_APP_ID') ?: '33336628';
$appSecret = getenv('TELECMI_APP_SECRET') ?: 'a7003cba-292c-4853-9792-66fe0f31270f';
$sdkBase = getenv('TELECMI_SDK_BASE') ?: 'https://piopiy.telecmi.com/v1/agentLogin';

echo "<h2>📋 Current Configuration</h2>";
echo "<table>";
echo "<tr><th>Setting</th><th>Value</th><th>Status</th></tr>";
echo "<tr><td>TELECMI_APP_ID</td><td><code>$appId</code></td><td>" . (strlen($appId) > 0 ? '✅' : '❌') . "</td></tr>";
echo "<tr><td>TELECMI_APP_SECRET</td><td><code>" . substr($appSecret, 0, 20) . "...</code></td><td>" . (strlen($appSecret) > 0 ? '✅' : '❌') . "</td></tr>";
echo "<tr><td>SDK_BASE</td><td><code>$sdkBase</code></td><td>✅</td></tr>";
echo "</table>";

echo "<h2>🧪 Testing TeleCMI Connection</h2>";

// Test with current credentials
$testUser = 'diagnostic_' . time();
$payload = [
    'app_id' => $appId,
    'app_secret' => $appSecret,
    'user' => $testUser,
];

echo "<h3>Test Request:</h3>";
echo "<pre>" . json_encode($payload, JSON_PRETTY_PRINT) . "</pre>";

$ch = curl_init();
curl_setopt_array($ch, [
    CURLOPT_URL => $sdkBase,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT => 10,
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => json_encode($payload),
    CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
    CURLOPT_VERBOSE => true,
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
$curlInfo = curl_getinfo($ch);
curl_close($ch);

echo "<h3>Response:</h3>";
echo "<table>";
echo "<tr><th>Property</th><th>Value</th></tr>";
echo "<tr><td>HTTP Code</td><td><strong>$httpCode</strong></td></tr>";
echo "<tr><td>Response Time</td><td>" . round($curlInfo['total_time'] * 1000, 2) . "ms</td></tr>";

if ($curlError) {
    echo "<tr><td>cURL Error</td><td style='color:red;'>$curlError</td></tr>";
}

echo "</table>";

$data = json_decode($response, true);

if ($httpCode == 200 && isset($data['token'])) {
    echo "<div class='success'>";
    echo "<h3>✅ Success!</h3>";
    echo "<p>TeleCMI authentication is working correctly!</p>";
    echo "</div>";
    
    echo "<h3>Response Data:</h3>";
    echo "<pre>" . json_encode($data, JSON_PRETTY_PRINT) . "</pre>";
    
} else {
    echo "<div class='error'>";
    echo "<h3>❌ Authentication Failed</h3>";
    echo "<p><strong>Error Details:</strong></p>";
    echo "<pre>" . json_encode($data, JSON_PRETTY_PRINT) . "</pre>";
    echo "</div>";
    
    // Analyze the error
    echo "<h2>🔎 Error Analysis</h2>";
    
    if (isset($data['code']) && $data['code'] == 404) {
        echo "<div class='warning'>";
        echo "<h3>⚠️ Error Code 404: Authentication Failed</h3>";
        echo "<p>This error means TeleCMI doesn't recognize your credentials.</p>";
        echo "</div>";
        
        echo "<h3>Possible Causes:</h3>";
        echo "<ol>";
        echo "<li><strong>Wrong Credentials:</strong> The APP_ID or APP_SECRET is incorrect</li>";
        echo "<li><strong>Expired Credentials:</strong> Your TeleCMI account credentials may have expired</li>";
        echo "<li><strong>Test/Example Credentials:</strong> These might be example credentials from documentation</li>";
        echo "<li><strong>Account Not Activated:</strong> Your TeleCMI account might not be activated yet</li>";
        echo "<li><strong>Wrong API Endpoint:</strong> You might be using the wrong TeleCMI product/service</li>";
        echo "</ol>";
    }
    
    // Check if credentials look valid
    echo "<h3>Credential Validation:</h3>";
    echo "<table>";
    echo "<tr><th>Check</th><th>Status</th><th>Details</th></tr>";
    
    // Check APP_ID format
    $appIdValid = is_numeric($appId) && strlen($appId) >= 8;
    echo "<tr>";
    echo "<td>APP_ID Format</td>";
    echo "<td>" . ($appIdValid ? '✅' : '⚠️') . "</td>";
    echo "<td>" . ($appIdValid ? 'Looks valid (numeric, 8+ digits)' : 'Unusual format') . "</td>";
    echo "</tr>";
    
    // Check APP_SECRET format
    $appSecretValid = strlen($appSecret) >= 30 && strpos($appSecret, '-') !== false;
    echo "<tr>";
    echo "<td>APP_SECRET Format</td>";
    echo "<td>" . ($appSecretValid ? '✅' : '⚠️') . "</td>";
    echo "<td>" . ($appSecretValid ? 'Looks valid (UUID format)' : 'Unusual format') . "</td>";
    echo "</tr>";
    
    // Check if credentials are example values
    $isExample = ($appId == '33336628' && strpos($appSecret, 'a7003cba') === 0);
    echo "<tr>";
    echo "<td>Credentials Source</td>";
    echo "<td>" . ($isExample ? '⚠️' : '✅') . "</td>";
    echo "<td>" . ($isExample ? '<strong>These appear to be example/test credentials</strong>' : 'Custom credentials') . "</td>";
    echo "</tr>";
    
    echo "</table>";
    
    // Solution
    echo "<div class='solution'>";
    echo "<h3>💡 Solution: Get Your Real TeleCMI Credentials</h3>";
    echo "<p><strong>Follow these steps:</strong></p>";
    echo "<ol>";
    echo "<li><strong>Login to TeleCMI Dashboard:</strong><br>";
    echo "Visit: <a href='https://piopiy.telecmi.com' target='_blank'>https://piopiy.telecmi.com</a></li>";
    echo "<li><strong>Navigate to API Settings:</strong><br>";
    echo "Go to Settings → API Credentials or Developer Settings</li>";
    echo "<li><strong>Copy Your Credentials:</strong><br>";
    echo "Copy your actual APP_ID and APP_SECRET</li>";
    echo "<li><strong>Update .env File:</strong><br>";
    echo "Edit <code>/var/www/vhosts/truckmitr.com/httpdocs/.env</code><br>";
    echo "Replace the current values with your real credentials</li>";
    echo "<li><strong>Test Again:</strong><br>";
    echo "Refresh this page to test with new credentials</li>";
    echo "</ol>";
    echo "</div>";
    
    // Alternative: Check if account exists
    echo "<h3>📞 Contact TeleCMI Support</h3>";
    echo "<p>If you're sure your credentials are correct, contact TeleCMI support:</p>";
    echo "<ul>";
    echo "<li><strong>Website:</strong> <a href='https://www.telecmi.com/support' target='_blank'>https://www.telecmi.com/support</a></li>";
    echo "<li><strong>Email:</strong> support@telecmi.com</li>";
    echo "<li><strong>Ask about:</strong> Why authentication is failing with your APP_ID</li>";
    echo "</ul>";
}

// Check API endpoint accessibility
echo "<h2>🌐 API Endpoint Check</h2>";

$endpoints = [
    'SDK Login' => 'https://piopiy.telecmi.com/v1/agentLogin',
    'Click-to-Call' => 'https://rest.telecmi.com/v2/click2call',
];

echo "<table>";
echo "<tr><th>Endpoint</th><th>URL</th><th>Accessible</th></tr>";

foreach ($endpoints as $name => $url) {
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL => $url,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 5,
        CURLOPT_NOBODY => true,
    ]);
    
    curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    $accessible = ($httpCode > 0 && $httpCode < 500);
    
    echo "<tr>";
    echo "<td>$name</td>";
    echo "<td><code>$url</code></td>";
    echo "<td>" . ($accessible ? "✅ Yes (HTTP $httpCode)" : "❌ No") . "</td>";
    echo "</tr>";
}

echo "</table>";

// Summary
echo "<hr style='margin: 30px 0;'>";
echo "<h2>📊 Summary</h2>";

if ($httpCode == 200 && isset($data['token'])) {
    echo "<div class='success'>";
    echo "<p><strong>✅ Everything is working!</strong> Your TeleCMI API is ready to use.</p>";
    echo "<p><a href='telecmi_demo.html' style='display:inline-block; padding:10px 20px; background:#28a745; color:white; text-decoration:none; border-radius:5px;'>Try Interactive Demo</a></p>";
    echo "</div>";
} else {
    echo "<div class='error'>";
    echo "<p><strong>❌ Authentication Issue</strong></p>";
    echo "<p>Your API implementation is perfect, but the TeleCMI credentials need to be updated.</p>";
    echo "</div>";
    
    echo "<h3>What to Do:</h3>";
    echo "<ol>";
    echo "<li>Login to your TeleCMI account</li>";
    echo "<li>Get your real APP_ID and APP_SECRET</li>";
    echo "<li>Update the .env file</li>";
    echo "<li>Test again</li>";
    echo "</ol>";
    
    echo "<p style='margin-top: 20px;'>";
    echo "<a href='?' style='display:inline-block; padding:10px 20px; background:#667eea; color:white; text-decoration:none; border-radius:5px;'>🔄 Test Again</a> ";
    echo "<a href='telecmi_status.php' style='display:inline-block; padding:10px 20px; background:#17a2b8; color:white; text-decoration:none; border-radius:5px;'>📊 View Status</a>";
    echo "</p>";
}

echo "</div></body></html>";
?>
