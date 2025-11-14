<?php
/**
 * Test TeleCMI API Integration
 * Run this file to test TeleCMI functionality
 */

echo "<h1>TeleCMI API Test Suite</h1>";
echo "<hr>";

// Load environment
require_once 'config.php';

function loadEnv() {
    // Try multiple possible locations for .env file
    $possiblePaths = [
        __DIR__ . '/../.env',
        __DIR__ . '/../../.env',
        dirname(dirname(__DIR__)) . '/.env',
        $_SERVER['DOCUMENT_ROOT'] . '/../.env',
    ];
    
    $envFile = null;
    foreach ($possiblePaths as $path) {
        if (file_exists($path)) {
            $envFile = $path;
            break;
        }
    }
    
    if (!$envFile) {
        echo "<p style='color:red;'>❌ .env file not found</p>";
        return false;
    }
    
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
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
    return true;
}

loadEnv();

// Test 1: Check Configuration
echo "<h2>Test 1: Configuration Check</h2>";
$appId = getenv('TELECMI_APP_ID');
$appSecret = getenv('TELECMI_APP_SECRET');
$sdkBase = getenv('TELECMI_SDK_BASE');
$restBase = getenv('TELECMI_REST_BASE');

echo "<table border='1' cellpadding='10'>";
echo "<tr><th>Config</th><th>Value</th><th>Status</th></tr>";

echo "<tr><td>TELECMI_APP_ID</td><td>" . ($appId ?: 'Not Set') . "</td><td>" . ($appId ? '✅' : '❌') . "</td></tr>";
echo "<tr><td>TELECMI_APP_SECRET</td><td>" . ($appSecret ? substr($appSecret, 0, 10) . '...' : 'Not Set') . "</td><td>" . ($appSecret ? '✅' : '❌') . "</td></tr>";
echo "<tr><td>TELECMI_SDK_BASE</td><td>" . ($sdkBase ?: 'Not Set') . "</td><td>" . ($sdkBase ? '✅' : '❌') . "</td></tr>";
echo "<tr><td>TELECMI_REST_BASE</td><td>" . ($restBase ?: 'Not Set') . "</td><td>" . ($restBase ? '✅' : '❌') . "</td></tr>";

echo "</table>";

if (!$appId || !$appSecret) {
    echo "<p style='color:red;'>❌ TeleCMI credentials missing. Please add them to .env file</p>";
    exit;
}

echo "<p style='color:green;'>✅ Configuration looks good!</p>";

// Test 2: SDK Token Request
echo "<hr><h2>Test 2: SDK Token Request</h2>";
echo "<p>Testing SDK token generation for user: <strong>test_user_123</strong></p>";

$sdkPayload = [
    'app_id'     => $appId,
    'app_secret' => $appSecret,
    'user'       => 'test_user_123',
];

echo "<h3>Request:</h3>";
echo "<pre>" . json_encode($sdkPayload, JSON_PRETTY_PRINT) . "</pre>";

$ch = curl_init();
curl_setopt_array($ch, [
    CURLOPT_URL => $sdkBase,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT => 10,
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => json_encode($sdkPayload),
    CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

echo "<h3>Response:</h3>";
echo "<p><strong>HTTP Code:</strong> $httpCode</p>";

if ($error) {
    echo "<p style='color:red;'>❌ cURL Error: $error</p>";
} else {
    $data = json_decode($response, true);
    echo "<pre>" . json_encode($data, JSON_PRETTY_PRINT) . "</pre>";
    
    if ($httpCode == 200 && isset($data['token'])) {
        echo "<p style='color:green;'>✅ SDK Token generated successfully!</p>";
    } else {
        echo "<p style='color:red;'>❌ SDK Token generation failed</p>";
    }
}

// Test 3: API Endpoint Test
echo "<hr><h2>Test 3: API Endpoint Test</h2>";
echo "<p>Testing the telecmi_api.php endpoint</p>";

$apiUrl = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/telecmi_api.php?action=sdk_token";
echo "<p><strong>API URL:</strong> $apiUrl</p>";

$testPayload = ['user_id' => 'test_user_456'];

$ch = curl_init();
curl_setopt_array($ch, [
    CURLOPT_URL => $apiUrl,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT => 10,
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => json_encode($testPayload),
    CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

echo "<h3>Request:</h3>";
echo "<pre>" . json_encode($testPayload, JSON_PRETTY_PRINT) . "</pre>";

echo "<h3>Response:</h3>";
echo "<p><strong>HTTP Code:</strong> $httpCode</p>";

if ($error) {
    echo "<p style='color:red;'>❌ cURL Error: $error</p>";
} else {
    $data = json_decode($response, true);
    echo "<pre>" . json_encode($data, JSON_PRETTY_PRINT) . "</pre>";
    
    if ($httpCode == 200 && $data['success']) {
        echo "<p style='color:green;'>✅ API endpoint working correctly!</p>";
    } else {
        echo "<p style='color:red;'>❌ API endpoint test failed</p>";
    }
}

// Test 4: Database Check
echo "<hr><h2>Test 4: Database Check</h2>";
echo "<p>Checking if call_logs table exists...</p>";

$result = $conn->query("SHOW TABLES LIKE 'call_logs'");
if ($result->num_rows > 0) {
    echo "<p style='color:green;'>✅ call_logs table exists</p>";
    
    // Check table structure
    $result = $conn->query("DESCRIBE call_logs");
    echo "<h3>Table Structure:</h3>";
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>{$row['Field']}</td>";
        echo "<td>{$row['Type']}</td>";
        echo "<td>{$row['Null']}</td>";
        echo "<td>{$row['Key']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color:orange;'>⚠️ call_logs table does not exist. You may need to create it.</p>";
    echo "<p>Run the SQL below to create the table:</p>";
    echo "<pre>
CREATE TABLE IF NOT EXISTS call_logs (
    id INT AUTO_INCREMENT PRIMARY KEY,
    call_id VARCHAR(255) UNIQUE,
    from_number VARCHAR(20),
    to_number VARCHAR(20),
    status VARCHAR(50),
    duration INT DEFAULT 0,
    provider VARCHAR(50) DEFAULT 'telecmi',
    initiated_at DATETIME,
    answered_at DATETIME NULL,
    ended_at DATETIME NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
    </pre>";
}

echo "<hr>";
echo "<h2>Summary</h2>";
echo "<p>✅ All tests completed. Check results above.</p>";
echo "<p><strong>Next Steps:</strong></p>";
echo "<ul>";
echo "<li>If SDK token test passed, your TeleCMI credentials are correct</li>";
echo "<li>If API endpoint test passed, your API is ready to use</li>";
echo "<li>If call_logs table doesn't exist, create it using the SQL above</li>";
echo "<li>Test click-to-call from your Flutter app</li>";
echo "</ul>";
