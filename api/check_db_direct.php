<?php
require_once 'config.php';

echo "=== DATABASE CHECK ===\n\n";

$telecaller_id = 8; // Change this to test different telecaller

// Check 1: Users table columns
echo "1. Users table columns:\n";
$result = $conn->query("SHOW COLUMNS FROM users");
while ($row = $result->fetch_assoc()) {
    echo "   - {$row['Field']} ({$row['Type']})\n";
}

// Check 2: Count users with assigned_to
echo "\n2. Users with assigned_to = $telecaller_id:\n";
$result = $conn->query("SELECT COUNT(*) as count FROM users WHERE assigned_to = $telecaller_id");
$row = $result->fetch_assoc();
echo "   Count: {$row['count']}\n";

// Check 3: Sample users with assigned_to
echo "\n3. Sample users with assigned_to = $telecaller_id:\n";
$result = $conn->query("SELECT id, name, mobile, assigned_to FROM users WHERE assigned_to = $telecaller_id LIMIT 3");
if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        echo "   - ID: {$row['id']}, Name: {$row['name']}, Mobile: {$row['mobile']}, Assigned: {$row['assigned_to']}\n";
    }
} else {
    echo "   No users found\n";
}

// Check 4: Count captured payments
echo "\n4. Total captured payments:\n";
$result = $conn->query("SELECT COUNT(*) as count FROM payments WHERE payment_status = 'captured'");
$row = $result->fetch_assoc();
echo "   Count: {$row['count']}\n";

// Check 5: Sample captured payments
echo "\n5. Sample captured payments:\n";
$result = $conn->query("SELECT p.id, p.user_id, p.amount, u.name, u.assigned_to FROM payments p LEFT JOIN users u ON p.user_id = u.id WHERE p.payment_status = 'captured' LIMIT 3");
if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        echo "   - Payment ID: {$row['id']}, User: {$row['name']}, Amount: {$row['amount']}, Assigned: {$row['assigned_to']}\n";
    }
} else {
    echo "   No payments found\n";
}

// Check 6: Join query result
echo "\n6. Subscriptions (users.assigned_to = $telecaller_id AND payment_status = 'captured'):\n";
$result = $conn->query("
    SELECT COUNT(*) as count
    FROM users u
    JOIN payments p ON u.id = p.user_id
    WHERE u.assigned_to = $telecaller_id
    AND p.payment_status = 'captured'
");
$row = $result->fetch_assoc();
echo "   Count: {$row['count']}\n";

// Check 7: Sample subscriptions
echo "\n7. Sample subscriptions:\n";
$result = $conn->query("
    SELECT p.id, u.name, u.assigned_to, p.amount, p.created_at
    FROM users u
    JOIN payments p ON u.id = p.user_id
    WHERE u.assigned_to = $telecaller_id
    AND p.payment_status = 'captured'
    LIMIT 3
");
if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        echo "   - Payment ID: {$row['id']}, User: {$row['name']}, Amount: {$row['amount']}, Date: {$row['created_at']}\n";
    }
} else {
    echo "   No subscriptions found\n";
}

// Check 8: All users with ANY assigned_to value
echo "\n8. Users with ANY assigned_to value:\n";
$result = $conn->query("SELECT COUNT(*) as count FROM users WHERE assigned_to IS NOT NULL AND assigned_to != 0");
$row = $result->fetch_assoc();
echo "   Count: {$row['count']}\n";

// Check 9: Sample of assigned_to values
echo "\n9. Sample assigned_to values in users table:\n";
$result = $conn->query("SELECT DISTINCT assigned_to, COUNT(*) as count FROM users WHERE assigned_to IS NOT NULL GROUP BY assigned_to LIMIT 10");
if ($result->num_rows > 0) {
    while ($row = $result->fetch_assoc()) {
        echo "   - assigned_to = {$row['assigned_to']}: {$row['count']} users\n";
    }
} else {
    echo "   No assigned_to values found\n";
}

echo "\n=== END ===\n";
