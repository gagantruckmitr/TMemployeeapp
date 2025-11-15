<?php
/**
 * Production Test - Click2Call IVR API
 * Test with specific telecaller and driver numbers
 */

header('Content-Type: application/json');
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

echo "=== Click2Call IVR Production Test ===\n\n";

// Test numbers
$telecaller_mobile = '6394756798';
$driver_mobile = '8448079624';

echo "Test Configuration:\n";
echo "- Telecaller: $telecaller_mobile\n";
echo "- Driver: $driver_mobile\n\n";

// Step 1: Check database connection
echo "Step 1: Database Connection\n";
try {
    $pdo = new PDO(
        "mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4",
        DB_USER,
        DB_PASS,
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );
    echo "✅ Database connected\n\n";
} catch (PDOException $e) {
    echo "❌ Database connection failed: " . $e->getMessage() . "\n";
    exit;
}

// Step 2: Find telecaller in admins table
echo "Step 2: Find Telecaller\n";
$stmt = $pdo->prepare("SELECT id, name, mobile, role FROM admins WHERE mobile = ? AND role = 'telecaller' LIMIT 1");
$stmt->execute([$telecaller_mobile]);
$telecaller = $stmt->fetch(PDO::FETCH_ASSOC);

if ($telecaller) {
    echo "✅ Telecaller found:\n";
    echo "   ID: {$telecaller['id']}\n";
    echo "   Name: {$telecaller['name']}\n";
    echo "   Mobile: {$telecaller['mobile']}\n";
    echo "   Role: {$telecaller['role']}\n\n";
} else {
    echo "❌ Telecaller not found with mobile: $telecaller_mobile\n";
    echo "   Checking if number exists with different role...\n";
    $stmt = $pdo->prepare("SELECT id, name, mobile, role FROM admins WHERE mobile = ? LIMIT 1");
    $stmt->execute([$telecaller_mobile]);
    $admin = $stmt->fetch(PDO::FETCH_ASSOC);
    if ($admin) {
        echo "   Found admin with role: {$admin['role']}\n";
        echo "   ⚠️  Need to update role to 'telecaller' for testing\n\n";
    } else {
        echo "   Number not found in admins table\n";
        echo "   ⚠️  Need to add telecaller to database\n\n";
    }
    exit;
}

// Step 3: Find driver in users table
echo "Step 3: Find Driver\n";
$stmt = $pdo->prepare("SELECT id, name, mobile, role FROM users WHERE mobile = ? LIMIT 1");
$stmt->execute([$driver_mobile]);
$driver = $stmt->fetch(PDO::FETCH_ASSOC);

if ($driver) {
    echo "✅ Driver found:\n";
    echo "   ID: {$driver['id']}\n";
    echo "   Name: {$driver['name']}\n";
    echo "   Mobile: {$driver['mobile']}\n";
    echo "   Role: {$driver['role']}\n\n";
} else {
    echo "❌ Driver not found with mobile: $driver_mobile\n";
    echo "   ⚠️  Need to add driver to database\n\n";
    exit;
}

// Step 4: Prepare Click2Call API payload
echo "Step 4: Prepare Click2Call API Payload\n";

$reference_id = 'C2C_' . time() . '_' . $telecaller['id'] . '_' . $driver['id'];

$payload = [
    'sourcetype' => '0',
    'customivr' => true,
    'credittype' => '2',
    'filetype' => '2',
    'ukey' => 'UFGMs6bXiXD4AIkjQGta8faKi',
    'serviceno' => '8037789293',
    'ivrtemplateid' => '345',
    'custcli' => '8037789293',
    'isrefno' => true,
    'msisdnlist' => [
        [
            'phoneno' => $driver_mobile,
            'agentno' => $telecaller_mobile
        ]
    ]
];

echo "✅ Payload prepared:\n";
echo json_encode($payload, JSON_PRETTY_PRINT) . "\n\n";

// Step 5: Call Click2Call API
echo "Step 5: Call Click2Call API\n";
echo "API URL: https://154.210.187.101/C2CAPI/webresources/Click2CallPost\n";

$ch = curl_init('https://154.210.187.101/C2CAPI/webresources/Click2CallPost');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);
curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, false);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curl_error = curl_error($ch);
curl_close($ch);

if ($curl_error) {
    echo "❌ cURL Error: $curl_error\n\n";
    exit;
}

echo "HTTP Status: $http_code\n";
echo "Response: $response\n\n";

$api_response = json_decode($response, true);

// Step 6: Log call to database
echo "Step 6: Log Call to Database\n";

try {
    $stmt = $pdo->prepare("
        INSERT INTO call_logs (
            caller_id, 
            user_id, 
            caller_number, 
            user_number, 
            driver_name,
            call_status, 
            reference_id, 
            api_response,
            call_type,
            call_time
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, NOW())
    ");
    
    $stmt->execute([
        $telecaller['id'],
        $driver['id'],
        $telecaller_mobile,
        $driver_mobile,
        $driver['name'],
        'initiated',
        $reference_id,
        $response,
        'click2call_ivr',
    ]);
    
    $call_log_id = $pdo->lastInsertId();
    echo "✅ Call logged to database\n";
    echo "   Call Log ID: $call_log_id\n";
    echo "   Reference ID: $reference_id\n\n";
} catch (PDOException $e) {
    echo "❌ Failed to log call: " . $e->getMessage() . "\n\n";
}

// Step 7: Check API response
echo "Step 7: Analyze API Response\n";

if ($api_response && isset($api_response['status'])) {
    if ($api_response['status'] === 'success') {
        echo "✅ SUCCESS! Call initiated successfully\n";
        echo "   Status: {$api_response['status']}\n";
        echo "   Message: {$api_response['message']}\n\n";
        
        echo "📞 CALL IN PROGRESS\n";
        echo "   Both phones should ring now:\n";
        echo "   - Telecaller: $telecaller_mobile\n";
        echo "   - Driver: $driver_mobile\n\n";
        
        echo "Next Steps:\n";
        echo "1. Answer both phones\n";
        echo "2. Complete the call\n";
        echo "3. Submit feedback in the app\n\n";
    } else {
        echo "❌ API returned error status\n";
        echo "   Status: {$api_response['status']}\n";
        if (isset($api_response['message'])) {
            echo "   Message: {$api_response['message']}\n";
        }
        echo "\n";
    }
} else {
    echo "⚠️  Unexpected API response format\n";
    echo "   Raw response: $response\n\n";
}

echo "=== Test Complete ===\n";
