<?php
header('Content-Type: text/plain; charset=utf-8');

echo "==============================================\n";
echo "   REGISTER TELECMI USER\n";
echo "==============================================\n\n";

require_once 'config.php';

// TeleCMI credentials
$appid = '33336628';
$secret = 'a7003cba-292c-4853-9792-66fe0f31270f';

echo "✓ TeleCMI credentials loaded\n";
echo "  App ID: $appid\n\n";

// User to register (Pooja)
$user_id = '3'; // Pooja's user_id
$full_user_id = $user_id . '_' . $appid;
$name = 'Pooja';
$phone = '916394756798'; // Your phone number

echo "REGISTERING USER:\n";
echo "User ID: $full_user_id\n";
echo "Name: $name\n";
echo "Phone: $phone\n\n";

// Register user in TeleCMI
$url = 'https://rest.telecmi.com/v2/webrtc/user';

$data = [
    'user_id' => $full_user_id,
    'secret' => $secret,
    'name' => $name,
    'phone' => (int)$phone
];

echo "Calling TeleCMI User Registration API...\n";
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
    die("REGISTRATION FAILED!\n");
}

echo "Response: $response\n\n";

$result = json_decode($response, true);

if ($http_code == 200 || $http_code == 201) {
    echo "==============================================\n";
    echo "   ✓✓✓ USER REGISTERED SUCCESSFULLY! ✓✓✓\n";
    echo "==============================================\n\n";
    
    echo "User $full_user_id is now registered in TeleCMI!\n";
    echo "You can now make calls using this user.\n\n";
    
    echo "Next step: Run telecmi_call_now.php to make a call\n";
    
} else {
    echo "==============================================\n";
    echo "   ✗✗✗ REGISTRATION FAILED ✗✗✗\n";
    echo "==============================================\n\n";
    
    $error_msg = $result['msg'] ?? $result['message'] ?? 'Unknown error';
    echo "Error: $error_msg\n\n";
    
    if (isset($result['code'])) {
        echo "Error Code: " . $result['code'] . "\n";
    }
    
    // If user already exists, that's okay
    if (strpos($error_msg, 'already') !== false || strpos($error_msg, 'exist') !== false) {
        echo "\nNote: User might already be registered. Try making a call anyway.\n";
    }
}

echo "\nTest complete!\n";
?>
