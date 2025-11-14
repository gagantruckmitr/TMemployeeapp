<?php
header('Content-Type: text/plain; charset=utf-8');

echo "==============================================\n";
echo "   TELECMI LIVE CALL TEST\n";
echo "==============================================\n\n";

// Load environment
require_once 'config.php';

// Database connection
$conn = new mysqli(DB_HOST, DB_USER, DB_PASS, DB_NAME);
if ($conn->connect_error) {
    die("DATABASE ERROR: " . $conn->connect_error . "\n");
}

echo "✓ Database connected\n\n";

// Load .env file
$envFile = dirname(__DIR__) . '/.env';
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (strpos(trim($line), '#') === 0) continue;
        if (strpos($line, '=') !== false) {
            list($key, $value) = explode('=', $line, 2);
            $key = trim($key);
            $value = trim($value);
            putenv("$key=$value");
            $_ENV[$key] = $value;
        }
    }
}

// TeleCMI credentials
$appid = getenv('TELECMI_APP_ID') ?: $_ENV['TELECMI_APP_ID'] ?? null;
$secret = getenv('TELECMI_APP_SECRET') ?: $_ENV['TELECMI_APP_SECRET'] ?? null;

if (!$appid || !$secret) {
    die("ERROR: TeleCMI credentials not found\nApp ID: $appid\nSecret: $secret\n");
}

echo "✓ TeleCMI credentials loaded\n\n";

// Call details
$caller_id = 3; // Pooja
$driver_phone = '916394756798'; // Your number
$driver_name = 'Test Driver';
$driver_id = 999;

echo "MAKING CALL TO: +$driver_phone\n\n";

// Insert into database
$stmt = $conn->prepare("
    INSERT INTO call_logs (
        user_id, driver_id, driver_name, driver_phone,
        call_type, call_status, call_direction,
        created_at, updated_at
    ) VALUES (?, ?, ?, ?, 'telecmi_ivr', 'initiated', 'outbound', NOW(), NOW())
");

$stmt->bind_param("iiss", $caller_id, $driver_id, $driver_name, $driver_phone);
$stmt->execute();
$call_log_id = $conn->insert_id;

echo "✓ Database entry created (ID: $call_log_id)\n\n";

// Make TeleCMI API call
$url = 'https://rest.telecmi.com/v2/call';

$data = [
    'appid' => $appid,
    'secret' => $secret,
    'from' => '04448124111',
    'to' => $driver_phone,
    'cmiuui' => (string)$call_log_id
];

echo "Calling TeleCMI API...\n";

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $http_code\n";
echo "Response: $response\n\n";

$result = json_decode($response, true);

if ($result && isset($result['code']) && $result['code'] == 200) {
    echo "==============================================\n";
    echo "   ✓✓✓ SUCCESS! YOUR PHONE IS RINGING! ✓✓✓\n";
    echo "==============================================\n\n";
    
    $call_uuid = $result['data']['cmiuui'] ?? $call_log_id;
    
    $conn->query("UPDATE call_logs SET 
        call_status = 'ringing',
        call_uuid = '$call_uuid',
        notes = 'TeleCMI call initiated'
        WHERE id = $call_log_id
    ");
    
    echo "Call Log ID: $call_log_id\n";
    echo "Call UUID: $call_uuid\n\n";
    
} else {
    echo "==============================================\n";
    echo "   ✗✗✗ CALL FAILED ✗✗✗\n";
    echo "==============================================\n\n";
    
    $error_msg = $result['message'] ?? 'Unknown error';
    echo "Error: $error_msg\n\n";
    
    $conn->query("UPDATE call_logs SET 
        call_status = 'failed',
        notes = 'Error: $error_msg'
        WHERE id = $call_log_id
    ");
}

$conn->close();
echo "Test complete!\n";
?>
