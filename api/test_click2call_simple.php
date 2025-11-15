<?php
/**
 * Simple Click2Call API Test
 * Run from command line: php test_click2call_simple.php
 */

echo "🧪 Click2Call IVR API Simple Test\n";
echo "==================================\n\n";

// Database configuration
$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "✅ Database connected\n\n";
} catch(PDOException $e) {
    echo "❌ Database connection failed: " . $e->getMessage() . "\n";
    exit(1);
}

// Get test data - only telecallers
$stmt = $pdo->query("SELECT id, name, mobile FROM admins WHERE role = 'telecaller' LIMIT 1");
$testTelecaller = $stmt->fetch();

$stmt = $pdo->query("SELECT id, name, mobile FROM users WHERE role IN ('driver', 'transporter') LIMIT 1");
$testDriver = $stmt->fetch();

if (!$testTelecaller || !$testDriver) {
    echo "❌ Missing test data\n";
    if (!$testTelecaller) {
        echo "   No telecaller found with role='telecaller' in admins table\n";
    }
    if (!$testDriver) {
        echo "   No driver/transporter found in users table\n";
    }
    exit(1);
}

echo "📋 Test Data:\n";
echo "   Telecaller: {$testTelecaller['name']} (ID: {$testTelecaller['id']}, Mobile: {$testTelecaller['mobile']})\n";
echo "   Driver: {$testDriver['name']} (ID: {$testDriver['id']}, Mobile: {$testDriver['mobile']})\n\n";

// Prepare API request
$apiUrl = 'http://127.0.0.1/truckmitr-app/api/click2call_ivr_api.php?action=initiate_call';
$payload = [
    'driver_mobile' => $testDriver['mobile'],
    'caller_id' => $testTelecaller['id'],
    'driver_id' => $testDriver['id']
];

echo "📤 Calling API: $apiUrl\n";
echo "   Payload: " . json_encode($payload) . "\n\n";

// Make API call
$ch = curl_init($apiUrl);
curl_setopt_array($ch, [
    CURLOPT_POST => true,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
    CURLOPT_POSTFIELDS => json_encode($payload),
    CURLOPT_TIMEOUT => 30
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

echo "📥 API Response:\n";
echo "   HTTP Code: $httpCode\n";

if ($error) {
    echo "   ❌ cURL Error: $error\n";
    exit(1);
}

$responseData = json_decode($response, true);

if ($responseData && isset($responseData['success'])) {
    if ($responseData['success']) {
        echo "   ✅ Success!\n";
        echo "   Reference ID: " . ($responseData['data']['reference_id'] ?? 'N/A') . "\n";
        echo "   Status: " . ($responseData['data']['status'] ?? 'N/A') . "\n";
        echo "   Driver: " . ($responseData['data']['driver_name'] ?? 'N/A') . "\n";
        echo "   Driver Number: " . ($responseData['data']['driver_number'] ?? 'N/A') . "\n";
        echo "   Telecaller: " . ($responseData['data']['telecaller_name'] ?? 'N/A') . "\n";
        echo "   Telecaller Number: " . ($responseData['data']['telecaller_number'] ?? 'N/A') . "\n";
        
        if (isset($responseData['data']['api_response'])) {
            echo "\n   Click2Call API Response:\n";
            echo "   " . json_encode($responseData['data']['api_response'], JSON_PRETTY_PRINT) . "\n";
        }
    } else {
        echo "   ❌ Failed\n";
        echo "   Error: " . ($responseData['error'] ?? 'Unknown error') . "\n";
    }
} else {
    echo "   ❌ Invalid response format\n";
    echo "   Raw response: $response\n";
}

echo "\n✅ Test complete!\n";
?>
