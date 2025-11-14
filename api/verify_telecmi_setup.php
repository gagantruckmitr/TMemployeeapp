<?php
/**
 * Verify TeleCMI Setup - Check all requirements
 */

require_once 'config.php';

echo "<h1>🔍 TeleCMI Setup Verification</h1>";
echo "<hr>";

$allGood = true;

// Check 1: Environment Variables
echo "<h2>1. Environment Variables</h2>";

function loadEnv() {
    // Try multiple possible locations for .env file
    $possiblePaths = [
        __DIR__ . '/../.env',           // Parent directory
        __DIR__ . '/../../.env',        // Two levels up
        dirname(dirname(__DIR__)) . '/.env',  // Root
        $_SERVER['DOCUMENT_ROOT'] . '/../.env', // Document root parent
    ];
    
    $envFile = null;
    foreach ($possiblePaths as $path) {
        if (file_exists($path)) {
            $envFile = $path;
            break;
        }
    }
    
    if (!$envFile) {
        echo "<p style='color:orange;'>⚠️ .env file not found. Checking paths:</p>";
        echo "<ul>";
        foreach ($possiblePaths as $path) {
            echo "<li>" . htmlspecialchars($path) . " - " . (file_exists($path) ? "EXISTS" : "NOT FOUND") . "</li>";
        }
        echo "</ul>";
        return false;
    }
    
    echo "<p style='color:green;'>✅ .env file found at: " . htmlspecialchars($envFile) . "</p>";
    
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

if (loadEnv()) {
    $appId = getenv('TELECMI_APP_ID');
    $appSecret = getenv('TELECMI_APP_SECRET');
    $sdkBase = getenv('TELECMI_SDK_BASE');
    $restBase = getenv('TELECMI_REST_BASE');
    
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
    echo "<tr><th>Variable</th><th>Status</th><th>Value</th></tr>";
    
    if ($appId) {
        echo "<tr><td>TELECMI_APP_ID</td><td style='color:green;'>✅</td><td>$appId</td></tr>";
    } else {
        echo "<tr><td>TELECMI_APP_ID</td><td style='color:red;'>❌</td><td>Missing</td></tr>";
        $allGood = false;
    }
    
    if ($appSecret) {
        echo "<tr><td>TELECMI_APP_SECRET</td><td style='color:green;'>✅</td><td>" . substr($appSecret, 0, 15) . "...</td></tr>";
    } else {
        echo "<tr><td>TELECMI_APP_SECRET</td><td style='color:red;'>❌</td><td>Missing</td></tr>";
        $allGood = false;
    }
    
    if ($sdkBase) {
        echo "<tr><td>TELECMI_SDK_BASE</td><td style='color:green;'>✅</td><td>$sdkBase</td></tr>";
    } else {
        echo "<tr><td>TELECMI_SDK_BASE</td><td style='color:red;'>❌</td><td>Missing</td></tr>";
        $allGood = false;
    }
    
    if ($restBase) {
        echo "<tr><td>TELECMI_REST_BASE</td><td style='color:green;'>✅</td><td>$restBase</td></tr>";
    } else {
        echo "<tr><td>TELECMI_REST_BASE</td><td style='color:red;'>❌</td><td>Missing</td></tr>";
        $allGood = false;
    }
    
    echo "</table>";
} else {
    echo "<p style='color:red;'>❌ .env file not found</p>";
    $allGood = false;
}

// Check 2: Database Table
echo "<hr><h2>2. Database Table</h2>";

$result = $conn->query("SHOW TABLES LIKE 'call_logs'");
if ($result->num_rows > 0) {
    echo "<p style='color:green;'>✅ Table 'call_logs' exists</p>";
    
    // Check for provider column
    $result = $conn->query("SHOW COLUMNS FROM call_logs LIKE 'provider'");
    if ($result->num_rows > 0) {
        echo "<p style='color:green;'>✅ Column 'provider' exists</p>";
    } else {
        echo "<p style='color:orange;'>⚠️ Column 'provider' missing. Adding it now...</p>";
        $conn->query("ALTER TABLE call_logs ADD COLUMN provider VARCHAR(50) DEFAULT 'telecmi' AFTER duration");
        echo "<p style='color:green;'>✅ Column 'provider' added successfully</p>";
    }
    
    // Show table structure
    echo "<h3>Table Structure:</h3>";
    $result = $conn->query("DESCRIBE call_logs");
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
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
    echo "<p style='color:red;'>❌ Table 'call_logs' does not exist</p>";
    $allGood = false;
}

// Check 3: API File
echo "<hr><h2>3. API Files</h2>";

$apiFile = __DIR__ . '/telecmi_api.php';
if (file_exists($apiFile)) {
    echo "<p style='color:green;'>✅ telecmi_api.php exists</p>";
    echo "<p>File size: " . number_format(filesize($apiFile)) . " bytes</p>";
} else {
    echo "<p style='color:red;'>❌ telecmi_api.php not found</p>";
    $allGood = false;
}

// Check 4: Test API Endpoint
echo "<hr><h2>4. API Endpoint Test</h2>";

$apiUrl = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/telecmi_api.php?action=sdk_token";
echo "<p><strong>Testing:</strong> $apiUrl</p>";

$testPayload = json_encode(['user_id' => 'test_verification_' . time()]);

$ch = curl_init();
curl_setopt_array($ch, [
    CURLOPT_URL => $apiUrl,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_TIMEOUT => 10,
    CURLOPT_POST => true,
    CURLOPT_POSTFIELDS => $testPayload,
    CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

if ($error) {
    echo "<p style='color:red;'>❌ cURL Error: $error</p>";
    $allGood = false;
} else {
    echo "<p><strong>HTTP Code:</strong> $httpCode</p>";
    
    if ($httpCode == 200) {
        $data = json_decode($response, true);
        if (isset($data['success'])) {
            if ($data['success']) {
                echo "<p style='color:green;'>✅ API endpoint is working!</p>";
                echo "<details><summary>View Response</summary><pre>" . json_encode($data, JSON_PRETTY_PRINT) . "</pre></details>";
            } else {
                echo "<p style='color:orange;'>⚠️ API returned error: " . ($data['message'] ?? 'Unknown error') . "</p>";
                echo "<details><summary>View Response</summary><pre>" . json_encode($data, JSON_PRETTY_PRINT) . "</pre></details>";
            }
        } else {
            echo "<p style='color:red;'>❌ Invalid API response format</p>";
            $allGood = false;
        }
    } else {
        echo "<p style='color:red;'>❌ API returned HTTP $httpCode</p>";
        echo "<pre>$response</pre>";
        $allGood = false;
    }
}

// Check 5: PHP Extensions
echo "<hr><h2>5. PHP Extensions</h2>";

$extensions = ['curl', 'json', 'mysqli'];
echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
echo "<tr><th>Extension</th><th>Status</th></tr>";

foreach ($extensions as $ext) {
    $loaded = extension_loaded($ext);
    $status = $loaded ? "<span style='color:green;'>✅ Loaded</span>" : "<span style='color:red;'>❌ Missing</span>";
    echo "<tr><td>$ext</td><td>$status</td></tr>";
    if (!$loaded) $allGood = false;
}

echo "</table>";

// Final Summary
echo "<hr><h2>📊 Summary</h2>";

if ($allGood) {
    echo "<div style='background:#d4edda; border:2px solid #28a745; padding:20px; border-radius:10px;'>";
    echo "<h3 style='color:#155724; margin:0;'>✅ All Systems Ready!</h3>";
    echo "<p style='color:#155724;'>Your TeleCMI API is fully configured and ready to use.</p>";
    echo "</div>";
    
    echo "<h3>Next Steps:</h3>";
    echo "<ol>";
    echo "<li>Test with real phone numbers: <a href='telecmi_demo.html'>Open Demo</a></li>";
    echo "<li>Run full test suite: <a href='test_telecmi_api.php'>Run Tests</a></li>";
    echo "<li>Integrate in Flutter app (see documentation)</li>";
    echo "<li>Configure webhook in TeleCMI dashboard</li>";
    echo "</ol>";
} else {
    echo "<div style='background:#f8d7da; border:2px solid #dc3545; padding:20px; border-radius:10px;'>";
    echo "<h3 style='color:#721c24; margin:0;'>⚠️ Setup Incomplete</h3>";
    echo "<p style='color:#721c24;'>Please fix the issues marked with ❌ above.</p>";
    echo "</div>";
    
    echo "<h3>Troubleshooting:</h3>";
    echo "<ul>";
    echo "<li>Check .env file has TeleCMI credentials</li>";
    echo "<li>Verify database connection in config.php</li>";
    echo "<li>Ensure PHP extensions are installed</li>";
    echo "<li>Check file permissions</li>";
    echo "</ul>";
}

echo "<hr>";
echo "<p><strong>Documentation:</strong> <a href='../TELECMI_API_SETUP.md'>Full Setup Guide</a> | <a href='../TELECMI_QUICK_START.md'>Quick Start</a></p>";

$conn->close();
