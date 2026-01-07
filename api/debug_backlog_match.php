<?php
require_once 'config.php';

$token = '84|bkv6gfO9YDW2cOTg3oN3Z0R14LyItZbjxXSgImR099a7ce90';

echo "=== DEBUGGING BACKLOG MATCH ===\n\n";

// 1. Get telehead backlog leads (first page)
$ch = curl_init('https://truckmitr.com/api/telehead/backlog-leads?page=1');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Authorization: Bearer ' . $token
]);
$response = curl_exec($ch);
curl_close($ch);

$teleheadData = json_decode($response, true);
$teleheadLeads = $teleheadData['data'] ?? [];
$teleheadIds = array_column($teleheadLeads, 'id');

echo "1. Telehead API returned " . count($teleheadLeads) . " backlog leads\n";
echo "   First 5 IDs: " . implode(', ', array_slice($teleheadIds, 0, 5)) . "\n\n";

// 2. Check which of these are in local database
if (!empty($teleheadIds)) {
    $placeholders = implode(',', array_fill(0, count($teleheadIds), '?'));
    $stmt = $pdo->prepare("
        SELECT id, name, assigned_to 
        FROM users 
        WHERE id IN ($placeholders)
    ");
    $stmt->execute($teleheadIds);
    $localUsers = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "2. Found " . count($localUsers) . " of these in local database\n\n";
    
    // 3. Check assignments
    $assignmentCounts = [];
    foreach ($localUsers as $user) {
        $assignedTo = $user['assigned_to'] ?? 'NULL';
        if (!isset($assignmentCounts[$assignedTo])) {
            $assignmentCounts[$assignedTo] = 0;
        }
        $assignmentCounts[$assignedTo]++;
    }
    
    echo "3. Assignment distribution:\n";
    foreach ($assignmentCounts as $telecaller => $count) {
        $name = ($telecaller == 3) ? ' (Pooja)' : '';
        echo "   Telecaller $telecaller$name: $count leads\n";
    }
    
    // 4. Show Pooja's leads if any
    $poojaLeads = array_filter($localUsers, function($user) {
        return $user['assigned_to'] == 3;
    });
    
    if (!empty($poojaLeads)) {
        echo "\n4. Pooja's backlog leads:\n";
        foreach ($poojaLeads as $lead) {
            echo "   - ID: {$lead['id']}, Name: {$lead['name']}\n";
        }
    } else {
        echo "\n4. No backlog leads assigned to Pooja in this batch\n";
    }
}

// 5. Check if Pooja has ANY assigned users with backlog status
echo "\n5. Checking Pooja's assigned users in local DB:\n";
$stmt = $pdo->query("
    SELECT COUNT(*) as count 
    FROM users 
    WHERE assigned_to = 3
");
$result = $stmt->fetch(PDO::FETCH_ASSOC);
echo "   Total users assigned to Pooja: {$result['count']}\n";

// Check if any of Pooja's users are in the telehead backlog
if (!empty($teleheadIds)) {
    $placeholders = implode(',', array_fill(0, count($teleheadIds), '?'));
    $stmt = $pdo->prepare("
        SELECT COUNT(*) as count 
        FROM users 
        WHERE assigned_to = 3 
        AND id IN ($placeholders)
    ");
    $stmt->execute($teleheadIds);
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    echo "   Pooja's users in telehead backlog (page 1): {$result['count']}\n";
}
?>
