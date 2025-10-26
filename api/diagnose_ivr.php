<?php
/**
 * IVR Diagnostic Tool
 * Checks why IVR calls are not working
 */
header('Content-Type: text/html; charset=utf-8');

echo "<h1>🔍 IVR Call Diagnostic Tool</h1>";

// Load .env file
$envFile = __DIR__ . '/../.env';
$envVars = [];
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos(trim($line), '#') === 0) continue;
        if (strpos($line, '=') === false) continue;
        list($key, $value) = explode('=', $line, 2);
        $envVars[trim($key)] = trim($value);
    }
}

// Check MyOperator Configuration
echo "<h2>1. MyOperator Configuration Status</h2>";
echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
echo "<tr><th>Setting</th><th>Value</th><th>Status</th></tr>";

$companyId = $envVars['MYOPERATOR_COMPANY_ID'] ?? 'your_company_id';
$secretToken = $envVars['MYOPERATOR_SECRET_TOKEN'] ?? 'your_secret_token';
$apiKey = $envVars['MYOPERATOR_API_KEY'] ?? 'your_api_key';
$callerId = $envVars['MYOPERATOR_CALLER_ID'] ?? '911234567890';
$apiUrl = $envVars['MYOPERATOR_API_URL'] ?? 'https://obd-api.myoperator.co/obd-api-v1';

$isConfigured = true;

// Company ID
$companyIdStatus = $companyId !== 'your_company_id' && !empty($companyId);
echo "<tr>";
echo "<td>MYOPERATOR_COMPANY_ID</td>";
echo "<td>" . ($companyIdStatus ? substr($companyId, 0, 10) . '...' : '❌ NOT SET') . "</td>";
echo "<td style='color: " . ($companyIdStatus ? 'green' : 'red') . ";'>" . ($companyIdStatus ? '✅ OK' : '❌ MISSING') . "</td>";
echo "</tr>";
if (!$companyIdStatus) $isConfigured = false;

// Secret Token
$secretTokenStatus = $secretToken !== 'your_secret_token' && !empty($secretToken);
echo "<tr>";
echo "<td>MYOPERATOR_SECRET_TOKEN</td>";
echo "<td>" . ($secretTokenStatus ? substr($secretToken, 0, 10) . '...' : '❌ NOT SET') . "</td>";
echo "<td style='color: " . ($secretTokenStatus ? 'green' : 'red') . ";'>" . ($secretTokenStatus ? '✅ OK' : '❌ MISSING') . "</td>";
echo "</tr>";
if (!$secretTokenStatus) $isConfigured = false;

// API Key
$apiKeyStatus = $apiKey !== 'your_api_key' && !empty($apiKey);
echo "<tr>";
echo "<td>MYOPERATOR_API_KEY</td>";
echo "<td>" . ($apiKeyStatus ? substr($apiKey, 0, 10) . '...' : '❌ NOT SET') . "</td>";
echo "<td style='color: " . ($apiKeyStatus ? 'green' : 'red') . ";'>" . ($apiKeyStatus ? '✅ OK' : '❌ MISSING') . "</td>";
echo "</tr>";
if (!$apiKeyStatus) $isConfigured = false;

// Caller ID
echo "<tr>";
echo "<td>MYOPERATOR_CALLER_ID</td>";
echo "<td>$callerId</td>";
echo "<td style='color: green;'>✅ OK</td>";
echo "</tr>";

// API URL
echo "<tr>";
echo "<td>MYOPERATOR_API_URL</td>";
echo "<td>$apiUrl</td>";
echo "<td style='color: green;'>✅ OK</td>";
echo "</tr>";

echo "</table>";

// Overall Status
echo "<h2>2. Overall Configuration Status</h2>";
if ($isConfigured) {
    echo "<p style='color: green; font-size: 20px; font-weight: bold;'>✅ MyOperator is CONFIGURED</p>";
    echo "<p>Your MyOperator credentials are set. Real calls should work.</p>";
} else {
    echo "<p style='color: red; font-size: 20px; font-weight: bold;'>❌ MyOperator is NOT CONFIGURED</p>";
    echo "<p>The system is running in SIMULATION MODE.</p>";
    echo "<p><strong>To enable real calls:</strong></p>";
    echo "<ol>";
    echo "<li>Sign up at <a href='https://myoperator.com' target='_blank'>myoperator.com</a></li>";
    echo "<li>Get your API credentials from the dashboard</li>";
    echo "<li>Update the .env file with your credentials</li>";
    echo "<li>Restart your server</li>";
    echo "</ol>";
}

// Check database connection
echo "<h2>3. Database Connection</h2>";
try {
    $pdo = new PDO("mysql:host=127.0.0.1;dbname=truckmitr;charset=utf8mb4", "truckmitr", "825Redp&4");
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "<p style='color: green;'>✅ Database connection successful</p>";
    
    // Check call_logs table
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM call_logs");
    $result = $stmt->fetch();
    echo "<p>Call logs in database: <strong>{$result['count']}</strong></p>";
    
    // Check recent calls
    $stmt = $pdo->query("SELECT * FROM call_logs ORDER BY created_at DESC LIMIT 5");
    $recentCalls = $stmt->fetchAll();
    
    if (count($recentCalls) > 0) {
        echo "<h3>Recent Call Attempts:</h3>";
        echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
        echo "<tr><th>Time</th><th>Driver</th><th>Status</th><th>Reference ID</th></tr>";
        foreach ($recentCalls as $call) {
            echo "<tr>";
            echo "<td>" . $call['created_at'] . "</td>";
            echo "<td>" . $call['driver_name'] . " (" . $call['user_number'] . ")</td>";
            echo "<td>" . $call['call_status'] . "</td>";
            echo "<td>" . $call['reference_id'] . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
    
} catch(PDOException $e) {
    echo "<p style='color: red;'>❌ Database connection failed: " . $e->getMessage() . "</p>";
}

// Check cURL availability
echo "<h2>4. cURL Status</h2>";
if (function_exists('curl_version')) {
    $curlVersion = curl_version();
    echo "<p style='color: green;'>✅ cURL is available (Version: {$curlVersion['version']})</p>";
    echo "<p>SSL Version: {$curlVersion['ssl_version']}</p>";
} else {
    echo "<p style='color: red;'>❌ cURL is NOT available</p>";
    echo "<p>cURL is required for making API calls to MyOperator.</p>";
}

// Test API connectivity (if configured)
if ($isConfigured) {
    echo "<h2>5. MyOperator API Connectivity Test</h2>";
    echo "<p>Testing connection to MyOperator API...</p>";
    
    $ch = curl_init($apiUrl);
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 10,
        CURLOPT_NOBODY => true, // HEAD request
    ]);
    
    $result = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    if ($error) {
        echo "<p style='color: red;'>❌ Cannot reach MyOperator API</p>";
        echo "<p>Error: $error</p>";
        echo "<p><strong>Possible issues:</strong></p>";
        echo "<ul>";
        echo "<li>No internet connection</li>";
        echo "<li>Firewall blocking outgoing connections</li>";
        echo "<li>DNS resolution issues</li>";
        echo "</ul>";
    } else {
        echo "<p style='color: green;'>✅ MyOperator API is reachable (HTTP $httpCode)</p>";
    }
}

// Recommendations
echo "<h2>6. Recommendations</h2>";
if (!$isConfigured) {
    echo "<div style='background: #fff3cd; padding: 15px; border-left: 4px solid #ffc107;'>";
    echo "<strong>⚠️ Action Required:</strong> Configure MyOperator credentials in .env file";
    echo "</div>";
} else {
    echo "<div style='background: #d4edda; padding: 15px; border-left: 4px solid #28a745;'>";
    echo "<strong>✅ System Ready:</strong> MyOperator is configured and should work for real calls";
    echo "</div>";
    echo "<p><strong>If calls are still not working:</strong></p>";
    echo "<ul>";
    echo "<li>Verify your MyOperator account is active and has credits</li>";
    echo "<li>Check if the phone numbers are in correct format (+91XXXXXXXXXX)</li>";
    echo "<li>Ensure your MyOperator API key has the correct permissions</li>";
    echo "<li>Check MyOperator dashboard for any error logs</li>";
    echo "<li>Contact MyOperator support if issues persist</li>";
    echo "</ul>";
}

echo "<hr>";
echo "<p><em>Diagnostic completed at " . date('Y-m-d H:i:s') . "</em></p>";
?>
