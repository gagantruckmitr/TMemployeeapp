<?php
// Test script to verify backlog API with bearer token
// This simulates what the Flutter app does

// First, login to get a token
$loginUrl = 'https://truckmitr.com/api/telehead/login';
$loginData = [
    'mobile' => '9999999999', // Replace with actual test mobile
    'password' => 'password123' // Replace with actual test password
];

echo "=== STEP 1: Login to get Bearer Token ===\n";
$ch = curl_init($loginUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($loginData));
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json'
]);

$loginResponse = curl_exec($ch);
$loginHttpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "Login Response Code: $loginHttpCode\n";
echo "Login Response:\n";
$loginData = json_decode($loginResponse, true);
print_r($loginData);

if (!isset($loginData['token'])) {
    echo "\n❌ ERROR: No token received from login\n";
    exit(1);
}

$token = $loginData['token'];
echo "\n✅ Token received: " . substr($token, 0, 20) . "...\n";

// Now use the token to fetch backlog leads
echo "\n=== STEP 2: Fetch Backlog Leads with Bearer Token ===\n";
$backlogUrl = 'https://truckmitr.com/api/telehead/backlog-leads';

$ch = curl_init($backlogUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json',
    'Authorization: Bearer ' . $token
]);

$backlogResponse = curl_exec($ch);
$backlogHttpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "Backlog Response Code: $backlogHttpCode\n";
echo "Backlog Response:\n";
$backlogData = json_decode($backlogResponse, true);

if ($backlogHttpCode === 200 && isset($backlogData['success']) && $backlogData['success']) {
    echo "✅ SUCCESS! Backlog data retrieved\n";
    echo "Total backlog leads: " . count($backlogData['data'] ?? []) . "\n";
    
    if (!empty($backlogData['data'])) {
        echo "\nFirst lead sample:\n";
        $firstLead = $backlogData['data'][0];
        echo "- ID: " . ($firstLead['id'] ?? 'N/A') . "\n";
        echo "- Name: " . ($firstLead['name'] ?? 'N/A') . "\n";
        echo "- Mobile: " . ($firstLead['mobile'] ?? 'N/A') . "\n";
        echo "- TMID: " . ($firstLead['tmid'] ?? 'N/A') . "\n";
        echo "- Role: " . ($firstLead['role'] ?? 'N/A') . "\n";
        echo "- Call Status: " . ($firstLead['call_status'] ?? 'N/A') . "\n";
    }
} else {
    echo "❌ ERROR: Failed to fetch backlog data\n";
    print_r($backlogData);
}

echo "\n=== Test Complete ===\n";
?>
