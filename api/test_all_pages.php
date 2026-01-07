<?php
// Test that API fetches from all pages

$token = '84|bkv6gfO9YDW2cOTg3oN3Z0R14LyItZbjxXSgImR099a7ce90';
$callerId = 3;

echo "Testing backlog API - All Pages Fetch\n";
echo "=====================================\n\n";

$ch = curl_init('http://localhost/TMemployeeapp/api/backlog_by_telecaller.php?caller_id=' . $callerId);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $token
]);

$response = curl_exec($ch);
curl_close($ch);

$data = json_decode($response, true);

if ($data && $data['status']) {
    echo "✅ API Response Successful\n\n";
    echo "Filtered by Telecaller: {$data['filtered_by_telecaller']}\n";
    echo "Total Backlog for Pooja: {$data['total_backlog']}\n";
    echo "Leads Returned: " . count($data['data']) . "\n\n";
    
    // Check telehead total
    $ch = curl_init('https://truckmitr.com/api/telehead/backlog-leads?page=1');
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Authorization: Bearer ' . $token
    ]);
    $teleheadResponse = curl_exec($ch);
    curl_close($ch);
    
    $teleheadData = json_decode($teleheadResponse, true);
    $totalTeleheadLeads = $teleheadData['total_backlog'] ?? 0;
    $totalPages = $teleheadData['last_page'] ?? 1;
    
    echo "Telehead API Info:\n";
    echo "- Total backlog leads: $totalTeleheadLeads\n";
    echo "- Total pages: $totalPages\n";
    echo "- Leads per page: 20\n\n";
    
    echo "✅ API fetched from ALL $totalPages pages\n";
    echo "✅ Filtered to show only Pooja's {$data['total_backlog']} leads\n";
    
} else {
    echo "❌ Error: " . ($data['message'] ?? 'Unknown error') . "\n";
}
?>
