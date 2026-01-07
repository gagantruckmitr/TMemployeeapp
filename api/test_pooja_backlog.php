<?php
// Test backlog API for Pooja (caller_id=3)

$token = '84|bkv6gfO9YDW2cOTg3oN3Z0R14LyItZbjxXSgImR099a7ce90';
$callerId = 3; // Pooja's caller_id

// Test the filtered backlog API
$ch = curl_init('http://localhost/TMemployeeapp/api/backlog_by_telecaller.php?caller_id=' . $callerId);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json',
    'Accept: application/json',
    'Authorization: Bearer ' . $token
]);

echo "Testing Backlog API for Pooja (caller_id=$callerId)\n";
echo "URL: http://localhost/TMemployeeapp/api/backlog_by_telecaller.php?caller_id=$callerId\n\n";

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $httpCode\n\n";

$data = json_decode($response, true);
if ($data && isset($data['status'])) {
    echo "Status: " . ($data['status'] ? 'SUCCESS' : 'FAILED') . "\n";
    
    if ($data['status']) {
        echo "Total Backlog for Pooja: " . ($data['total_backlog'] ?? 0) . "\n";
        echo "Filtered by Telecaller: " . ($data['filtered_by_telecaller'] ?? 'N/A') . "\n";
        echo "Leads Count: " . count($data['data'] ?? []) . "\n\n";
        
        if (!empty($data['data'])) {
            echo "First 5 leads assigned to Pooja:\n";
            foreach (array_slice($data['data'], 0, 5) as $lead) {
                echo "- ID: {$lead['id']}, Name: {$lead['name']}, Role: {$lead['role']}\n";
            }
        } else {
            echo "No leads assigned to Pooja\n";
        }
    } else {
        echo "Error: " . ($data['message'] ?? 'Unknown error') . "\n";
    }
} else {
    echo "Response:\n$response\n";
}
?>
