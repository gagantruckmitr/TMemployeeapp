<?php
/**
 * Debug Subscription Data
 * Check what data exists in call_logs and payments tables
 */

require_once 'config.php';

echo "<h2>Debug Subscription Data</h2>";
echo "<hr>";

// Test 1: Check call_logs table
echo "<h3>Test 1: Check call_logs table</h3>";
$query = "SELECT COUNT(*) as count FROM call_logs";
$result = $conn->query($query);
$row = $result->fetch_assoc();
echo "<p>Total records in call_logs: <strong>" . $row['count'] . "</strong></p>";

if ($row['count'] > 0) {
    echo "<p>Sample records:</p>";
    $query = "SELECT id, user_id, caller_id, call_time, driver_name, user_number FROM call_logs ORDER BY id DESC LIMIT 5";
    $result = $conn->query($query);
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>ID</th><th>User ID (Driver)</th><th>Caller ID (TC)</th><th>Call Time</th><th>Driver Name</th><th>User Number</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . $row['id'] . "</td>";
        echo "<td>" . $row['user_id'] . "</td>";
        echo "<td>" . $row['caller_id'] . "</td>";
        echo "<td>" . $row['call_time'] . "</td>";
        echo "<td>" . ($row['driver_name'] ?? 'NULL') . "</td>";
        echo "<td>" . ($row['user_number'] ?? 'NULL') . "</td>";
        echo "</tr>";
    }
    echo "</table>";
}

echo "<hr>";

// Test 2: Check payments table
echo "<h3>Test 2: Check payments table</h3>";
$query = "SELECT COUNT(*) as count FROM payments WHERE payment_status = 'captured'";
$result = $conn->query($query);
$row = $result->fetch_assoc();
echo "<p>Total captured payments: <strong>" . $row['count'] . "</strong></p>";

if ($row['count'] > 0) {
    echo "<p>Sample records:</p>";
    $query = "SELECT id, user_id, amount, payment_status, created_at, FROM_UNIXTIME(start_at) as start_time FROM payments WHERE payment_status = 'captured' ORDER BY id DESC LIMIT 5";
    $result = $conn->query($query);
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>ID</th><th>User ID (Driver)</th><th>Amount</th><th>Status</th><th>Created At</th><th>Start Time</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . $row['id'] . "</td>";
        echo "<td>" . $row['user_id'] . "</td>";
        echo "<td>₹" . $row['amount'] . "</td>";
        echo "<td>" . $row['payment_status'] . "</td>";
        echo "<td>" . $row['created_at'] . "</td>";
        echo "<td>" . $row['start_time'] . "</td>";
        echo "</tr>";
    }
    echo "</table>";
}

echo "<hr>";

// Test 3: Check for matching records
echo "<h3>Test 3: Check for matching records (call_logs + payments)</h3>";
$query = "
    SELECT 
        cl.id as call_log_id,
        cl.user_id as driver_id,
        cl.caller_id as telecaller_id,
        cl.call_time,
        p.id as payment_id,
        p.created_at as payment_created_at,
        p.amount,
        TIMESTAMPDIFF(MINUTE, cl.call_time, p.created_at) as minutes_after_call
    FROM call_logs cl
    JOIN payments p ON cl.user_id = p.user_id
    WHERE p.payment_status = 'captured'
    AND p.created_at > cl.call_time
    ORDER BY cl.call_time DESC
    LIMIT 10
";

$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    echo "<p style='color: green;'><strong>✓ Found " . $result->num_rows . " matching records!</strong></p>";
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>Call Log ID</th><th>Driver ID</th><th>Telecaller ID</th><th>Call Time</th><th>Payment ID</th><th>Payment Time</th><th>Amount</th><th>Minutes After</th></tr>";
    
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . $row['call_log_id'] . "</td>";
        echo "<td>" . $row['driver_id'] . "</td>";
        echo "<td>" . $row['telecaller_id'] . "</td>";
        echo "<td>" . $row['call_time'] . "</td>";
        echo "<td>" . $row['payment_id'] . "</td>";
        echo "<td>" . $row['payment_created_at'] . "</td>";
        echo "<td>₹" . $row['amount'] . "</td>";
        echo "<td>" . $row['minutes_after_call'] . " min</td>";
        echo "</tr>";
    }
    
    echo "</table>";
} else {
    echo "<p style='color: red;'><strong>✗ No matching records found!</strong></p>";
    echo "<p>Possible reasons:</p>";
    echo "<ul>";
    echo "<li>No calls in call_logs table</li>";
    echo "<li>No payments with status 'captured'</li>";
    echo "<li>No user_id match between call_logs and payments</li>";
    echo "<li>All payments were made BEFORE the calls (payment.created_at <= call_logs.call_time)</li>";
    echo "</ul>";
}

echo "<hr>";

// Test 4: Check telecaller IDs
echo "<h3>Test 4: Check available telecaller IDs</h3>";
$query = "SELECT DISTINCT caller_id FROM call_logs WHERE caller_id IS NOT NULL ORDER BY caller_id";
$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    echo "<p>Available telecaller IDs in call_logs:</p>";
    echo "<ul>";
    while ($row = $result->fetch_assoc()) {
        echo "<li>Telecaller ID: " . $row['caller_id'] . "</li>";
    }
    echo "</ul>";
} else {
    echo "<p style='color: red;'>No telecaller IDs found in call_logs!</p>";
}

echo "<hr>";

// Test 5: Check admins table
echo "<h3>Test 5: Check admins table</h3>";
$query = "SELECT id, name, email FROM admins ORDER BY id LIMIT 10";
$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    echo "<p>Available admins/telecallers:</p>";
    echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
    echo "<tr><th>ID</th><th>Name</th><th>Email</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . $row['id'] . "</td>";
        echo "<td>" . $row['name'] . "</td>";
        echo "<td>" . $row['email'] . "</td>";
        echo "</tr>";
    }
    echo "</table>";
}

echo "<hr>";
echo "<p><em>Debug completed at " . date('Y-m-d H:i:s') . "</em></p>";
