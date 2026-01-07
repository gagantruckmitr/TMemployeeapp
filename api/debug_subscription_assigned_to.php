<?php
/**
 * Debug script to check assigned_to column and subscription data
 */

header('Content-Type: application/json');
require_once 'config.php';

$telecaller_id = $_GET['user_id'] ?? 8;

$debug = [];
$debug['telecaller_id'] = $telecaller_id;

// Check 1: Does assigned_to column exist?
$result = $conn->query("SHOW COLUMNS FROM users LIKE 'assigned_to'");
$debug['assigned_to_column_exists'] = $result && $result->num_rows > 0;

// Check 2: Sample users table structure
$result = $conn->query("SHOW COLUMNS FROM users");
$columns = [];
while ($row = $result->fetch_assoc()) {
    $columns[] = $row['Field'];
}
$debug['users_table_columns'] = $columns;

// Check 3: Count users with assigned_to value
$result = $conn->query("SELECT COUNT(*) as count FROM users WHERE assigned_to IS NOT NULL");
$row = $result->fetch_assoc();
$debug['users_with_assigned_to'] = $row['count'];

// Check 4: Count users assigned to this telecaller
$result = $conn->query("SELECT COUNT(*) as count FROM users WHERE assigned_to = " . intval($telecaller_id));
$row = $result->fetch_assoc();
$debug['users_assigned_to_telecaller'] = $row['count'];

// Check 5: Sample users assigned to this telecaller
$result = $conn->query("
    SELECT id, name, mobile, COALESCE(unique_id, tmid) as tmid, assigned_to 
    FROM users 
    WHERE assigned_to = " . intval($telecaller_id) . " 
    LIMIT 5
");
$debug['sample_assigned_users'] = [];
while ($row = $result->fetch_assoc()) {
    $debug['sample_assigned_users'][] = $row;
}

// Check 6: Count captured payments
$result = $conn->query("SELECT COUNT(*) as count FROM payments WHERE payment_status = 'captured'");
$row = $result->fetch_assoc();
$debug['total_captured_payments'] = $row['count'];

// Check 7: Sample captured payments
$result = $conn->query("
    SELECT p.id, p.user_id, p.amount, p.payment_status, p.created_at,
           u.name, u.assigned_to
    FROM payments p
    LEFT JOIN users u ON p.user_id = u.id
    WHERE p.payment_status = 'captured'
    LIMIT 5
");
$debug['sample_captured_payments'] = [];
while ($row = $result->fetch_assoc()) {
    $debug['sample_captured_payments'][] = $row;
}

// Check 8: The actual join query
$result = $conn->query("
    SELECT COUNT(*) as count
    FROM users u
    JOIN payments p ON u.id = p.user_id
    WHERE u.assigned_to = " . intval($telecaller_id) . "
    AND p.payment_status = 'captured'
");
$row = $result->fetch_assoc();
$debug['subscriptions_count'] = $row['count'];

// Check 9: Sample subscriptions
$result = $conn->query("
    SELECT 
        p.id as payment_id,
        p.user_id,
        u.name,
        u.assigned_to,
        p.amount,
        p.payment_status,
        p.created_at
    FROM users u
    JOIN payments p ON u.id = p.user_id
    WHERE u.assigned_to = " . intval($telecaller_id) . "
    AND p.payment_status = 'captured'
    LIMIT 5
");
$debug['sample_subscriptions'] = [];
while ($row = $result->fetch_assoc()) {
    $debug['sample_subscriptions'][] = $row;
}

// Check 10: Check if there are ANY users with payments
$result = $conn->query("
    SELECT COUNT(*) as count
    FROM users u
    JOIN payments p ON u.id = p.user_id
    WHERE p.payment_status = 'captured'
");
$row = $result->fetch_assoc();
$debug['total_users_with_payments'] = $row['count'];

echo json_encode($debug, JSON_PRETTY_PRINT);
