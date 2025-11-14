<?php
header('Content-Type: text/plain; charset=utf-8');

echo "==============================================\n";
echo "   TELECMI LIVE CALL TEST\n";
echo "==============================================\n\n";

// Database connection
require_once 'config.php';

echo "✓ Database connected\n\n";

// TeleCMI credentials - HARDCODED (using working secret from telecmi_test_call.php)
$appid = '33336628';
$secret = 'bb0b92ca-3d8a-405b-87aa-fc035fe1cdc6';

echo "✓ TeleCMI credentials loaded\n";
echo "  App ID: $appid\n\n";

// Call details
$caller_id = 3; // Pooja
$driver_phone = '916394756798'; // Your number
$driver_name = 'Test Driver';
$tc_for = 'driver'; // What the call is for

// Use the registered TeleCMI user_id (from your working example)
$telecmi_user_id = '5003'; // The registered user in TeleCMI

echo "MAKING CALL TO: +$driver_phone\n";
echo "Using TeleCMI User: $telecmi_user_id\n\n";

// Insert into database using CORRECT columns
try {
    $stmt = $conn->prepare("
        INSERT INTO call_logs (
            caller_id, user_id, tc_for, driver_name, user_number,
            call_status, notes,
            created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, 'pending', 'TeleCMI call initiated', NOW(), NOW())
    ");
    
    if (!$stmt) {
        die("Prepare failed: " . $conn->error . "\n");
    }
    
    $stmt->bind_param("iisss", $caller_id, $caller_id, $tc_for, $driver_name, $driver_phone);
    
    if (!$stmt->execute()) {
        die("Execute failed: " . $stmt->error . "\n");
    }
    
    $call_log_id = $conn->insert_id;
    
    if ($call_log_id == 0) {
        die("Insert failed - no ID returned\n");
    }
    
    echo "✓ Database entry created (ID: $call_log_id)\n\n";
    
} catch (Exception $e) {
    die("Database error: " . $e->getMessage() . "\n");
}

// Make TeleCMI API call - Using WebRTC Click2Call (requires registered user)
$url = 'https://rest.telecmi.com/v2/webrtc/click2call';

// Format user_id with app_id (using registered TeleCMI user)
$user_id = $telecmi_user_id . '_' . $appid; // 5003_33336628

$data = [
    'user_id' => $user_id,
    'secret' => $secret,
    'to' => (int)$driver_phone, // Must be integer
    'webrtc' => false,
    'followme' => true
];

echo "Calling TeleCMI API...\n";
echo "URL: $url\n";
echo "Data: " . json_encode($data) . "\n\n";

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);

$response = curl_exec($ch);
$http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curl_error = curl_error($ch);
curl_close($ch);

echo "HTTP Code: $http_code\n";

if ($curl_error) {
    echo "CURL Error: $curl_error\n\n";
    $conn->query("UPDATE call_logs SET call_status = 'failed', notes = 'CURL Error' WHERE id = $call_log_id");
    die("CALL FAILED!\n");
}

echo "Response: $response\n\n";

$result = json_decode($response, true);

if ($result && isset($result['code']) && $result['code'] == 200) {
    echo "==============================================\n";
    echo "   ✓✓✓ SUCCESS! YOUR PHONE IS RINGING! ✓✓✓\n";
    echo "==============================================\n\n";
    
    $call_uuid = $result['data']['cmiuui'] ?? $call_log_id;
    
    $conn->query("UPDATE call_logs SET 
        call_status = 'connected',
        reference_id = '$call_uuid',
        notes = 'TeleCMI call connected successfully',
        call_initiated_at = NOW()
        WHERE id = $call_log_id
    ");
    
    echo "Call Log ID: $call_log_id\n";
    echo "Call UUID: $call_uuid\n\n";
    echo "Check database: SELECT * FROM call_logs WHERE id = $call_log_id;\n\n";
    
} else {
    echo "==============================================\n";
    echo "   ✗✗✗ CALL FAILED ✗✗✗\n";
    echo "==============================================\n\n";
    
    $error_msg = $result['message'] ?? 'Unknown error';
    echo "Error: $error_msg\n\n";
    
    if (isset($result['code'])) {
        echo "Error Code: " . $result['code'] . "\n";
    }
    
    $conn->query("UPDATE call_logs SET 
        call_status = 'failed',
        notes = 'TeleCMI Error: $error_msg'
        WHERE id = $call_log_id
    ");
}

$conn->close();
echo "Test complete!\n";
?>
