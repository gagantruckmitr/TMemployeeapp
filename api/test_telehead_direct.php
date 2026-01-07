<?php
// Test telehead API directly to see what it returns

$token = '84|bkv6gfO9YDW2cOTg3oN3Z0R14LyItZbjxXSgImR099a7ce90';

// Decode token to see caller_id
$tokenParts = explode('.', $token);
echo "Token parts count: " . count($tokenParts) . "\n";

if (count($tokenParts) === 3) {
    $payload = json_decode(base64_decode($tokenParts[1]), true);
    echo "Caller ID from token: " . ($payload['sub'] ?? 'Not found') . "\n\n";
}

// Test the telehead backlog API
$ch = curl_init('https://truckmitr.com/api/telehead/backlog-leads');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json',
    'Authorization: Bearer ' . $token
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $httpCode\n\n";

$data = json_decode($response, true);
if ($data) {
    echo "Status: " . ($data['status'] ? 'true' : 'false') . "\n";
    echo "Total Backlog: " . ($data['total_backlog'] ?? 'N/A') . "\n";
    echo "Current Page: " . ($data['current_page'] ?? 'N/A') . "\n";
    echo "Last Page: " . ($data['last_page'] ?? 'N/A') . "\n";
    echo "Leads Count: " . count($data['data'] ?? []) . "\n\n";
    
    if (!empty($data['data'])) {
        echo "First 5 leads:\n";
        foreach (array_slice($data['data'], 0, 5) as $lead) {
            echo "- ID: {$lead['id']}, Name: {$lead['name']}, Role: {$lead['role']}, TMID: {$lead['tmid']}\n";
        }
    }
} else {
    echo "Response:\n$response\n";
}
?>
