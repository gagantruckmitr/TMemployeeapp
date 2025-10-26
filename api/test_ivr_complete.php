<?php
/**
 * Complete IVR System Test
 * Tests MyOperator integration and call flow
 */
header('Content-Type: text/html; charset=utf-8');

echo "<h1>IVR System Complete Test</h1>";
echo "<style>
    body { font-family: Arial, sans-serif; padding: 20px; background: #f5f5f5; }
    .test { background: white; padding: 15px; margin: 10px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    .success { color: #10b981; font-weight: bold; }
    .error { color: #ef4444; font-weight: bold; }
    .warning { color: #f59e0b; font-weight: bold; }
    pre { background: #f9fafb; padding: 10px; border-radius: 4px; overflow-x: auto; font-size: 12px; }
    h2 { color: #1f2937; border-bottom: 2px solid #4f46e5; padding-bottom: 5px; }
    .btn { display: inline-block; padding: 10px 20px; background: #4f46e5; color: white; text-decoration: none; border-radius: 6px; margin: 5px; cursor: pointer; border: none; }
    .btn:hover { background: #4338ca; }
</style>";

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    echo "<div class='test'><span class='error'>✗ Database Connection Failed</span></div>";
    exit;
}

// Test 1: Check .env Configuration
echo "<div class='test'><h2>1. MyOperator Configuration</h2>";
$envFile = __DIR__ . '/../.env';
$myOperatorConfigured = false;

if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    $config = [];
    
    foreach ($lines as $line) {
        if (strpos(trim($line), '#') === 0) continue;
        if (strpos($line, '=') === false) continue;
        list($key, $value) = explode('=', $line, 2);
        $config[trim($key)] = trim($value);
    }
    
    $requiredKeys = ['MYOPERATOR_COMPANY_ID', 'MYOPERATOR_SECRET_TOKEN', 'MYOPERATOR_IVR_ID', 'MYOPERATOR_API_KEY', 'MYOPERATOR_CALLER_ID'];
    
    echo "<table style='width:100%; border-collapse: collapse;'>";
    echo "<tr style='background:#f3f4f6;'><th style='padding:8px; text-align:left;'>Setting</th><th style='padding:8px; text-align:left;'>Status</th><th style='padding:8px; text-align:left;'>Value</th></tr>";
    
    $allConfigured = true;
    foreach ($requiredKeys as $key) {
        $value = $config[$key] ?? '';
        $isConfigured = !empty($value) && !str_contains($value, 'your_');
        
        if (!$isConfigured) $allConfigured = false;
        
        $status = $isConfigured ? "<span class='success'>✓ Configured</span>" : "<span class='warning'>⚠ Not Set</span>";
        $displayValue = $isConfigured ? substr($value, 0, 20) . '...' : '<em>Not configured</em>';
        
        echo "<tr><td style='padding:8px;'>$key</td><td style='padding:8px;'>$status</td><td style='padding:8px;'>$displayValue</td></tr>";
    }
    echo "</table>";
    
    $myOperatorConfigured = $allConfigured;
    
    if ($allConfigured) {
        echo "<br><span class='success'>✓ MyOperator is fully configured</span>";
    } else {
        echo "<br><span class='warning'>⚠ MyOperator is NOT configured - IVR will run in SIMULATION MODE</span>";
        echo "<br><small>To enable real IVR calls, update the .env file with your MyOperator credentials from <a href='https://myoperator.com' target='_blank'>myoperator.com</a></small>";
    }
} else {
    echo "<span class='error'>✗ .env file not found</span>";
}
echo "</div>";

// Test 2: Check Database Setup
echo "<div class='test'><h2>2. Database Setup</h2>";

// Check telecallers
$stmt = $pdo->query("SELECT COUNT(*) as count FROM admins WHERE role = 'telecaller'");
$telecallerCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];

if ($telecallerCount > 0) {
    echo "<span class='success'>✓ Telecallers: $telecallerCount</span><br>";
    $stmt = $pdo->query("SELECT id, name, mobile FROM admins WHERE role = 'telecaller' LIMIT 1");
    $telecaller = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "Test Telecaller: <strong>{$telecaller['name']}</strong> (ID: {$telecaller['id']}, Mobile: {$telecaller['mobile']})<br>";
} else {
    echo "<span class='error'>✗ No telecallers found</span><br>";
}

// Check drivers
$stmt = $pdo->query("SELECT COUNT(*) as count FROM users WHERE role = 'driver'");
$driverCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];

if ($driverCount > 0) {
    echo "<span class='success'>✓ Drivers: $driverCount</span><br>";
    $stmt = $pdo->query("SELECT id, name, mobile FROM users WHERE role = 'driver' LIMIT 1");
    $driver = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "Test Driver: <strong>{$driver['name']}</strong> (ID: {$driver['id']}, Mobile: {$driver['mobile']})<br>";
} else {
    echo "<span class='error'>✗ No drivers found</span><br>";
}

echo "</div>";

// Test 3: Test IVR API Endpoint
if ($telecallerCount > 0 && $driverCount > 0) {
    echo "<div class='test'><h2>3. IVR API Test</h2>";
    
    $testPayload = [
        'driver_mobile' => $driver['mobile'],
        'caller_id' => $telecaller['id'],
        'driver_id' => $driver['id']
    ];
    
    echo "<strong>Test Payload:</strong><br>";
    echo "<pre>" . json_encode($testPayload, JSON_PRETTY_PRINT) . "</pre>";
    
    // Make API call
    $apiUrl = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/ivr_call_api.php?action=initiate_call";
    
    $ch = curl_init($apiUrl);
    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
        CURLOPT_POSTFIELDS => json_encode($testPayload),
        CURLOPT_TIMEOUT => 30
    ]);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $error = curl_error($ch);
    curl_close($ch);
    
    if ($error) {
        echo "<span class='error'>✗ API Call Failed: $error</span><br>";
    } else {
        echo "<strong>HTTP Status:</strong> $httpCode<br>";
        echo "<strong>Response:</strong><br>";
        echo "<pre>" . json_encode(json_decode($response), JSON_PRETTY_PRINT) . "</pre>";
        
        $data = json_decode($response, true);
        if ($data['success']) {
            echo "<span class='success'>✓ IVR Call API Working</span><br>";
            
            if (isset($data['data']['simulation']) && $data['data']['simulation']) {
                echo "<span class='warning'>⚠ Running in SIMULATION MODE</span><br>";
                echo "Configure MyOperator credentials in .env to enable real calls<br>";
            } else {
                echo "<span class='success'>✓ Real IVR call initiated</span><br>";
            }
        } else {
            echo "<span class='error'>✗ API returned error: " . ($data['error'] ?? 'Unknown error') . "</span><br>";
        }
    }
    
    echo "</div>";
}

// Test 4: Voice/Audio Configuration
echo "<div class='test'><h2>4. IVR Voice Configuration</h2>";
echo "<p>For IVR calls to have voice, you need to:</p>";
echo "<ol>";
echo "<li><strong>Configure IVR Flow in MyOperator Dashboard:</strong><br>";
echo "   - Login to <a href='https://myoperator.com' target='_blank'>myoperator.com</a><br>";
echo "   - Go to IVR Settings<br>";
echo "   - Create/Edit your IVR flow with voice prompts<br>";
echo "   - Add text-to-speech or upload audio files</li>";
echo "<li><strong>Set IVR ID in .env:</strong><br>";
echo "   - Copy your IVR ID from MyOperator dashboard<br>";
echo "   - Update MYOPERATOR_IVR_ID in .env file</li>";
echo "<li><strong>Test Call Flow:</strong><br>";
echo "   - Make a test call from MyOperator dashboard<br>";
echo "   - Verify voice prompts are working<br>";
echo "   - Then use this app to initiate calls</li>";
echo "</ol>";

if (!$myOperatorConfigured) {
    echo "<div style='background:#fef3c7; padding:10px; border-radius:6px; margin-top:10px;'>";
    echo "<strong>⚠ Important:</strong> Without MyOperator configuration, IVR calls will run in simulation mode with no actual voice calls.";
    echo "</div>";
}
echo "</div>";

// Test 5: Recommendations
echo "<div class='test'><h2>5. Next Steps</h2>";

if (!$myOperatorConfigured) {
    echo "<div style='background:#fee2e2; padding:10px; border-radius:6px; margin:5px 0;'>";
    echo "<strong>1. Configure MyOperator:</strong><br>";
    echo "   - Sign up at <a href='https://myoperator.com' target='_blank'>myoperator.com</a><br>";
    echo "   - Get your API credentials<br>";
    echo "   - Update .env file with credentials<br>";
    echo "</div>";
}

echo "<div style='background:#dbeafe; padding:10px; border-radius:6px; margin:5px 0;'>";
echo "<strong>2. Setup IVR Flow:</strong><br>";
echo "   - Create IVR flow with voice prompts in MyOperator dashboard<br>";
echo "   - Configure call routing and voice messages<br>";
echo "   - Test the IVR flow manually<br>";
echo "</div>";

echo "<div style='background:#d1fae5; padding:10px; border-radius:6px; margin:5px 0;'>";
echo "<strong>3. Test Integration:</strong><br>";
echo "   - Use this test page to verify API connectivity<br>";
echo "   - Make test calls from Flutter app<br>";
echo "   - Monitor call logs in database<br>";
echo "</div>";

echo "</div>";

echo "<div class='test'>";
echo "<h2>Quick Actions</h2>";
echo "<button class='btn' onclick='location.reload()'>Refresh Test</button>";
echo "<a href='comprehensive_test.php' class='btn' style='background:#10b981;'>Full System Test</a>";
echo "<a href='../api' class='btn' style='background:#f59e0b;'>Back to API</a>";
echo "</div>";

?>
