<?php
// Test what caller_id the app is actually sending
header('Content-Type: application/json');

$caller_id = $_GET['caller_id'] ?? 'NOT_PROVIDED';
$limit = $_GET['limit'] ?? 'NOT_PROVIDED';
$action = $_GET['action'] ?? 'NOT_PROVIDED';

$result = [
    'message' => 'This shows what the app is sending',
    'received_params' => [
        'caller_id' => $caller_id,
        'limit' => $limit,
        'action' => $action
    ],
    'all_get_params' => $_GET,
    'timestamp' => date('Y-m-d H:i:s'),
    'instructions' => [
        'If caller_id is 3 for both telecallers, the app is not sending the correct ID',
        'If caller_id is different (3 and 4), then the database assignments are wrong'
    ]
];

echo json_encode($result, JSON_PRETTY_PRINT);
?>
