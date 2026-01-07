<?php
/**
 * Debug script to check subscription data
 */

header('Content-Type: application/json');
require_once 'config.php';

$telecaller_id = $_GET['user_id'] ?? 8;

$debug = [];

// Check 1: Does assigned_telecaller column exist?
$column_check = $conn->query("SHOW COLUMNS FROM users LIKE 'assigned_telecaller'");
$debug['has_assigned_telecaller_column'] = $column_check && $column_check->num_rows > 0;

// Check 2: Count users with assigned_telecaller
if ($debug['has_assigned_telecaller_column']) {
    $result = $conn->query("SELECT COUNT(*) as count FROM users WHERE assigned_telecaller = " . intval($telecaller_id));
    $row = $result->fetch_assoc();
    $debug['users_assigned_to_telecaller'] = $row['count'];
    
    // Get sample users
    $result = $conn->query("SELECT id, name, mobile, assigned_telecaller FROM users WHERE assigned_telecaller = " . intval($telecaller_id) . " LIMIT 3");
    $debug['sample_users'] = [];
    while ($row = $result->fetch_assoc()) {
        $debug['sample_users'][] = $row;
    }
} else {
    $debug['users_assigned_to_telecaller'] = 'Column does not exist';
}

// Check 3: Count captured payments
$result = $conn->query("SELECT COUNT(*) as count FROM payments WHERE payment_status = 'captured'");
$row = $result->fetch_assoc();
$debug['total_captured_payments'] = $row['count'];

// Check 4: Sample captured payments with user info
$result = $conn->query("
    SELECT p.id, p.user_id, p.amount, p.payment_status, u.name, u.assigned_telecaller
    FROM payments p
    LEFT JOIN users u ON p.user_id = u.id
    WHERE p.payment_status = 'captured'
    LIMIT 5
");
$debug['sample_payments'] = [];
while ($row = $result->fetch_assoc()) {
    $debug['sample_payments'][] = $row;
}

// Check 5: Try the join query
if ($debug['has_assigned_telecaller_column']) {
    $result = $conn->query("
        SELECT COUNT(*) as count
        FROM users u
        JOIN payments p ON u.id = p.user_id
        WHERE u.assigned_telecaller = " . intval($telecaller_id) . "
        AND p.payment_status = 'captured'
    ");
    $row = $result->fetch_assoc();
    $debug['subscriptions_with_assigned_telecaller'] = $row['count'];
} else {
    $debug['subscriptions_with_assigned_telecaller'] = 'Column does not exist';
}

// Check 6: Alternative - count using call_logs
$result = $conn->query("
    SELECT COUNT(DISTINCT p.id) as count
    FROM payments p
    WHERE p.payment_status = 'captured'
    AND EXISTS (
        SELECT 1 FROM call_logs cl
        WHERE cl.user_id = p.user_id
        AND cl.caller_id = " . intval($telecaller_id) . "
        AND cl.created_at < p.created_at
    )
");
$row = $result->fetch_assoc();
$debug['subscriptions_with_call_logs'] = $row['count'];

echo json_encode($debug, JSON_PRETTY_PRINT);
