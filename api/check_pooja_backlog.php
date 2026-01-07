<?php
require_once 'config.php';

// Check how many backlog leads are assigned to Pooja (caller_id = 3)
$stmt = $pdo->prepare("
    SELECT COUNT(*) as count
    FROM users 
    WHERE assigned_to = 3 
    AND callback_later = 1
");
$stmt->execute();
$result = $stmt->fetch(PDO::FETCH_ASSOC);

echo "Pooja's backlog count (assigned_to=3, callback_later=1): {$result['count']}\n\n";

// Get sample leads
$stmt = $pdo->prepare("
    SELECT id, name, role, tmid, assigned_to, callback_later
    FROM users 
    WHERE assigned_to = 3 
    AND callback_later = 1
    LIMIT 10
");
$stmt->execute();
$leads = $stmt->fetchAll(PDO::FETCH_ASSOC);

echo "Sample leads:\n";
foreach ($leads as $lead) {
    echo "- ID: {$lead['id']}, Name: {$lead['name']}, Role: {$lead['role']}, TMID: {$lead['tmid']}, Assigned: {$lead['assigned_to']}\n";
}
?>
