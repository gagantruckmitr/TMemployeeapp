<?php
// Test backlog filtering by telecaller

$token = '84|bkv6gfO9YDW2cOTg3oN3Z0R14LyItZbjxXSgImR099a7ce90';

// Test the enhanced backlog API
$ch = curl_init('https://truckmitr.com/api/telehead_backlog_enhanced.php');
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
echo "Response:\n";
echo $response;
echo "\n\n";

// Decode and show summary
$data = json_decode($response, true);
if ($data) {
    echo "Summary:\n";
    echo "Status: " . ($data['status'] ? 'true' : 'false') . "\n";
    echo "Total Backlog: " . ($data['total_backlog'] ?? 'N/A') . "\n";
    echo "Filtered by Telecaller: " . ($data['filtered_by_telecaller'] ?? 'N/A') . "\n";
    echo "Leads Count: " . count($data['data'] ?? []) . "\n\n";
    
    if (!empty($data['data'])) {
        echo "First 3 leads:\n";
        foreach (array_slice($data['data'], 0, 3) as $lead) {
            echo "- ID: {$lead['id']}, Name: {$lead['name']}, Role: {$lead['role']}\n";
        }
    }
}
?>
