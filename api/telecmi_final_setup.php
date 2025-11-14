<?php
/**
 * TeleCMI Final Setup - One-Click Complete Setup
 * This script will verify and fix everything needed for TeleCMI to work
 */

require_once 'config.php';

echo "<!DOCTYPE html>";
echo "<html><head>";
echo "<title>TeleCMI Final Setup</title>";
echo "<style>
    body { font-family: Arial, sans-serif; max-width: 1000px; margin: 20px auto; padding: 20px; background: #f5f5f5; }
    .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    h1 { color: #333; border-bottom: 3px solid #667eea; padding-bottom: 10px; }
    h2 { color: #667eea; margin-top: 30px; }
    .success { background: #d4edda; border-left: 4px solid #28a745; padding: 15px; margin: 10px 0; border-radius: 5px; }
    .error { background: #f8d7da; border-left: 4px solid #dc3545; padding: 15px; margin: 10px 0; border-radius: 5px; }
    .warning { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 10px 0; border-radius: 5px; }
    .info { background: #d1ecf1; border-left: 4px solid #17a2b8; padding: 15px; margin: 10px 0; border-radius: 5px; }
    table { width: 100%; border-collapse: collapse; margin: 15px 0; }
    th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }
    th { background: #667eea; color: white; }
    tr:hover { background: #f5f5f5; }
    .btn { display: inline-block; padding: 12px 24px; background: #667eea; color: white; text-decoration: none; border-radius: 5px; margin: 5px; }
    .btn:hover { background: #5568d3; }
    code { background: #f4f4f4; padding: 2px 6px; border-radius: 3px; font-family: monospace; }
    pre { background: #f4f4f4; padding: 15px; border-radius: 5px; overflow-x: auto; }
</style>";
echo "</head><body><div class='container'>";

echo "<h1>🚀 TeleCMI Final Setup</h1>";
echo "<p>This script will verify and configure everything needed for TeleCMI API.</p>";

$allGood = true;
$issues = [];
$fixes = [];

// Step 1: Load Environment Variables
echo "<h2>Step 1: Environment Variables</h2>";

function loadEnv() {
    $possiblePaths = [
        __DIR__ . '/../.env',
        __DIR__ . '/../../.env',
        dirname(dirname(__DIR__)) . '/.env',
        $_SERVER['DOCUMENT_ROOT'] . '/../.env',
    ];
    
    foreach ($possiblePaths as $path) {
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

$envPath = loadEnv();

if ($envPath) {
    echo "<div class='success'>✅ .env file found at: <code>" . htmlspecialchars($envPath) . "</code></div>";
    
    $appId = getenv('TELECMI_APP_ID');
    $appSecret = getenv('TELECMI_APP_SECRET');
    $sdkBase = getenv('TELECMI_SDK_BASE');
    $restBase = getenv('TELECMI_REST_BASE');
    
    echo "<table>";
    echo "<tr><th>Variable</th><th>Status</th><th>Value</th></tr>";
    
    if ($appId) {
        echo "<tr><td>TELECMI_APP_ID</td><td>✅</td><td><code>$appId</code></td></tr>";
    } else {
        echo "<tr><td>TELECMI_APP_ID</td><td>❌</td><td>Missing</td></tr>";
        $allGood = false;
        $issues[] = "TELECMI_APP_ID not set in .env";
    }
    
    if ($appSecret) {
        echo "<tr><td>TELECMI_APP_SECRET</td><td>✅</td><td><code>" . substr($appSecret, 0, 15) . "...</code></td></tr>";
    } else {
        echo "<tr><td>TELECMI_APP_SECRET</td><td>❌</td><td>Missing</td></tr>";
        $allGood = false;
        $issues[] = "TELECMI_APP_SECRET not set in .env";
    }
    
    if ($sdkBase) {
        echo "<tr><td>TELECMI_SDK_BASE</td><td>✅</td><td><code>$sdkBase</code></td></tr>";
    } else {
        echo "<tr><td>TELECMI_SDK_BASE</td><td>⚠️</td><td>Using default</td></tr>";
    }
    
    if ($restBase) {
        echo "<tr><td>TELECMI_REST_BASE</td><td>✅</td><td><code>$restBase</code></td></tr>";
    } else {
        echo "<tr><td>TELECMI_REST_BASE</td><td>⚠️</td><td>Using default</td></tr>";
    }
    
    echo "</table>";
} else {
    echo "<div class='error'>❌ .env file not found in any expected location</div>";
    $allGood = false;
    $issues[] = ".env file not found";
}

// Step 2: Database Table
echo "<h2>Step 2: Database Table</h2>";

$result = $conn->query("SHOW TABLES LIKE 'call_logs'");
if ($result->num_rows > 0) {
    echo "<div class='success'>✅ Table 'call_logs' exists</div>";
    
    // Check for provider column
    $result = $conn->query("SHOW COLUMNS FROM call_logs LIKE 'provider'");
    if ($result->num_rows > 0) {
        echo "<div class='success'>✅ Column 'provider' exists</div>";
    } else {
        echo "<div class='warning'>⚠️ Column 'provider' missing. Adding it now...</div>";
        if ($conn->query("ALTER TABLE call_logs ADD COLUMN provider VARCHAR(50) DEFAULT 'telecmi' AFTER duration")) {
            echo "<div class='success'>✅ Column 'provider' added successfully!</div>";
            $fixes[] = "Added 'provider' column to call_logs table";
        } else {
            echo "<div class='error'>❌ Failed to add 'provider' column: " . $conn->error . "</div>";
            $allGood = false;
            $issues[] = "Could not add 'provider' column";
        }
    }
    
    // Show current structure
    $result = $conn->query("DESCRIBE call_logs");
    echo "<table>";
    echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr><td>{$row['Field']}</td><td>{$row['Type']}</td><td>{$row['Null']}</td><td>{$row['Key']}</td></tr>";
    }
    echo "</table>";
} else {
    echo "<div class='error'>❌ Table 'call_logs' does not exist</div>";
    $allGood = false;
    $issues[] = "call_logs table missing";
}

// Step 3: API Files
echo "<h2>Step 3: API Files</h2>";

$requiredFiles = [
    'telecmi_api.php' => 'Main API endpoint',
    'test_telecmi_api.php' => 'Test suite',
    'telecmi_demo.html' => 'Interactive demo',
];

echo "<table>";
echo "<tr><th>File</th><th>Purpose</th><th>Status</th></tr>";

foreach ($requiredFiles as $file => $purpose) {
    $exists = file_exists(__DIR__ . '/' . $file);
    $status = $exists ? '✅ Exists' : '❌ Missing';
    echo "<tr><td><code>$file</code></td><td>$purpose</td><td>$status</td></tr>";
    
    if (!$exists) {
        $allGood = false;
        $issues[] = "File $file is missing";
    }
}

echo "</table>";

// Step 4: Test API Connection
echo "<h2>Step 4: API Connection Test</h2>";

if ($appId && $appSecret) {
    echo "<div class='info'>Testing connection to TeleCMI servers...</div>";
    
    $testUserId = 'setup_test_' . time();
    $payload = json_encode([
        'app_id' => $appId,
        'app_secret' => $appSecret,
        'user' => $testUserId,
    ]);
    
    $ch = curl_init();
    curl_setopt_array($ch, [
        CURLOPT_URL => $sdkBase ?: 'https://piopiy.telecmi.com/v1/agentLogin',
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 10,
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => $payload,
        CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    if ($error) {
        echo "<div class='error'>❌ Connection Error: $error</div>";
        $allGood = false;
        $issues[] = "Cannot connect to TeleCMI servers";
    } elseif ($httpCode == 200) {
        $data = json_decode($response, true);
        if (isset($data['token'])) {
            echo "<div class='success'>✅ Successfully connected to TeleCMI! Token received.</div>";
        } else {
            echo "<div class='success'>✅ Connected to TeleCMI (HTTP 200)</div>";
        }
    } else {
        echo "<div class='warning'>⚠️ TeleCMI returned HTTP $httpCode</div>";
        $data = json_decode($response, true);
        if (isset($data['msg'])) {
            echo "<div class='warning'>Message: {$data['msg']}</div>";
        }
    }
} else {
    echo "<div class='warning'>⚠️ Skipping connection test (credentials missing)</div>";
}

// Final Summary
echo "<h2>📊 Setup Summary</h2>";

if ($allGood) {
    echo "<div class='success'>";
    echo "<h3 style='margin-top:0;'>✅ Setup Complete!</h3>";
    echo "<p>Your TeleCMI API is fully configured and ready to use.</p>";
    echo "</div>";
    
    if (!empty($fixes)) {
        echo "<div class='info'>";
        echo "<h4>Fixes Applied:</h4>";
        echo "<ul>";
        foreach ($fixes as $fix) {
            echo "<li>$fix</li>";
        }
        echo "</ul>";
        echo "</div>";
    }
    
    echo "<h3>🎯 Next Steps:</h3>";
    echo "<ol>";
    echo "<li><strong>Test the API:</strong> <a href='test_telecmi_live.php' class='btn'>Run Live Test</a></li>";
    echo "<li><strong>Try Interactive Demo:</strong> <a href='telecmi_demo.html' class='btn'>Open Demo</a></li>";
    echo "<li><strong>Integrate in Flutter:</strong> See documentation below</li>";
    echo "<li><strong>Configure Webhook:</strong> Add webhook URL in TeleCMI dashboard</li>";
    echo "</ol>";
    
    echo "<h3>📱 Flutter Integration:</h3>";
    echo "<pre><code>// Make a call
final response = await http.post(
  Uri.parse('http://192.168.29.149/api/telecmi_api.php?action=click_to_call'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    'to': '919876543210',
    'callerid': '919123456789',
  }),
);

if (response.statusCode == 200) {
  final data = jsonDecode(response.body);
  if (data['success']) {
    print('Call initiated!');
  }
}</code></pre>";
    
} else {
    echo "<div class='error'>";
    echo "<h3 style='margin-top:0;'>⚠️ Setup Issues Found</h3>";
    echo "<p>Please fix the following issues:</p>";
    echo "<ul>";
    foreach ($issues as $issue) {
        echo "<li>$issue</li>";
    }
    echo "</ul>";
    echo "</div>";
    
    echo "<h3>🔧 How to Fix:</h3>";
    echo "<ol>";
    
    if (in_array(".env file not found", $issues)) {
        echo "<li>Create a .env file in your project root with TeleCMI credentials</li>";
    }
    
    if (in_array("TELECMI_APP_ID not set in .env", $issues) || in_array("TELECMI_APP_SECRET not set in .env", $issues)) {
        echo "<li>Add these lines to your .env file:<br><pre>TELECMI_APP_ID=33336628
TELECMI_APP_SECRET=a7003cba-292c-4853-9792-66fe0f31270f
TELECMI_SDK_BASE=https://piopiy.telecmi.com/v1/agentLogin
TELECMI_REST_BASE=https://rest.telecmi.com/v2/click2call</pre></li>";
    }
    
    if (in_array("call_logs table missing", $issues)) {
        echo "<li>Run <a href='setup_telecmi_table.php'>setup_telecmi_table.php</a> to create the database table</li>";
    }
    
    echo "<li>Refresh this page after making changes</li>";
    echo "</ol>";
}

echo "<hr>";
echo "<h3>📚 Documentation & Resources:</h3>";
echo "<p>";
echo "<a href='test_telecmi_live.php' class='btn'>Live Connection Test</a> ";
echo "<a href='verify_telecmi_setup.php' class='btn'>Detailed Verification</a> ";
echo "<a href='telecmi_demo.html' class='btn'>Interactive Demo</a> ";
echo "<a href='../TELECMI_API_SETUP.md' class='btn'>Full Documentation</a>";
echo "</p>";

echo "</div></body></html>";

$conn->close();
