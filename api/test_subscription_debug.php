<?php
/**
 * Debug script to check subscription data
 */

header('Content-Type: application/json');
require_once 'config.php';

$telecaller_id = $_GET['user_id'] ?? 8; // Default to telecaller 8 for testing

echo json_encode([
    'telecaller_id' => $telecaller_id,
    'checks' => [
        // Check 1: Users with assigned_telecaller
        'users_assigned' => checkUsersAssigned($conn, $telecaller_id),
        
        // Check 2: All captured payments
        'captured_payments' => checkCapturedPayments($conn),
        
        // Check 3: Users with assigned_telecaller AND captured payments
        'users_with_payments' => checkUsersWithPayments($conn, $telecaller_id),
        
        // Check 4: Check if assigned_telecaller column exists
        'column_check' => checkColumnExists($conn),
        
        // Check 5: Sample users data
        'sample_users' => getSampleUsers($conn, $telecaller_id),
        
        // Check 6: Sample payments data
        'sample_payments' => getSamplePayments($conn),
    ]
], JSON_PRETTY_PRINT);

function checkUsersAssigned($conn, $telecaller_id) {
    $query = "SELECT COUNT(*) as count FROM users WHERE assigned_telecaller = " . intval($telecaller_id);
    $result = $conn->query($query);
    $row = $result->fetch_assoc();
    return [
        'count' => $row['count'],
        'query' => $query
    ];
}

function checkCapturedPayments($conn) {
    $query = "SELECT COUNT(*) as count FROM payments WHERE payment_status = 'captured'";
    $result = $conn->query($query);
    $row = $result->fetch_assoc();
    return [
        'count' => $row['count'],
        'query' => $query
    ];
}

function checkUsersWithPayments($conn, $telecaller_id) {
    $query = "
        SELECT COUNT(*) as count
        FROM users u
        JOIN payments p ON u.id = p.user_id
        WHERE u.assigned_telecaller = " . intval($telecaller_id) . "
        AND p.payment_status = 'captured'
    ";
    $result = $conn->query($query);
    $row = $result->fetch_assoc();
    return [
        'count' => $row['count'],
        'query' => $query
    ];
}

function checkColumnExists($conn) {
    $query = "SHOW COLUMNS FROM users LIKE 'assigned_telecaller'";
    $result = $conn->query($query);
    return [
        'exists' => $result->num_rows > 0,
        'query' => $query
    ];
}

function getSampleUsers($conn, $telecaller_id) {
    $query = "
        SELECT id, name, mobile, unique_id, assigned_telecaller 
        FROM users 
        WHERE assigned_telecaller = " . intval($telecaller_id) . "
        LIMIT 5
    ";
    $result = $conn->query($query);
    $users = [];
    while ($row = $result->fetch_assoc()) {
        $users[] = $row;
    }
    return [
        'count' => count($users),
        'data' => $users,
        'query' => $query
    ];
}

function getSamplePayments($conn) {
    $query = "
        SELECT p.id, p.user_id, p.amount, p.payment_status, p.created_at,
               u.name, u.assigned_telecaller
        FROM payments p
        LEFT JOIN users u ON p.user_id = u.id
        WHERE p.payment_status = 'captured'
        LIMIT 5
    ";
    $result = $conn->query($query);
    $payments = [];
    while ($row = $result->fetch_assoc()) {
        $payments[] = $row;
    }
    return [
        'count' => count($payments),
        'data' => $payments,
        'query' => $query
    ];
}
