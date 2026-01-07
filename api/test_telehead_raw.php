<?php
// Test what telehead API returns for Pooja's token

$token = '84|bkv6gfO9YDW2cOTg3oN3Z0R14LyItZbjxXSgImR099a7ce90';

echo "Testing Telehead API with Pooja's token\n\n";

// Test page 1
$ch = curl_init('https://truckmitr.com/api/telehead/backlog-leads?page=1');
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
if ($data && isset($data['status'])) {
    echo "Status: " . ($data['status'] ? 'true' : 'false') . "\n";
    echo "Total Backlog: " . ($data['total_backlog'] ?? 'N/A') . "\n";
    echo "Current Page: " . ($data['current_page'] ?? 'N/A') . "\n";
    echo "Last Page: " . ($data['last_page'] ?? 'N/A') . "\n";
    echo "Leads on this page: " . count($data['data'] ?? []) . "\n\n";
    
    if (!empty($data['data'])) {
        echo "First 5 leads from telehead API:\n";
        foreach (array_slice($data['data'], 0, 5) as $lead) {
            echo "- ID: {$lead['id']}, Name: {$lead['name']}, Role: {$lead['role']}\n";
        }
        
        // Now check which of these are assigned to Pooja (caller_id=3)
        require_once 'config.php';
        
        $userIds = array_column(array_slice($data['data'], 0, 10), 'id');
        if (!empty($userIds)) {
            $placeholders = implode(',', array_fill(0, count($userIds), '?'));
            $stmt = $pdo->prepare("SELECT id, name, assigned_to FROM users WHERE id IN ($placeholders)");
            $stmt->execute($userIds);
            $assignments = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            echo "\n\nAssignment check for first 10 leads:\n";
            foreach ($assignments as $user) {
                $assignedTo = $user['assigned_to'] ?? 'NULL';
                $match = ($assignedTo == 3) ? '✓ MATCH' : '✗ Not Pooja';
                echo "- ID: {$user['id']}, Name: {$user['name']}, Assigned to: $assignedTo $match\n";
            }
        }
    }
} else {
    echo "Response:\n$response\n";
}
?>
