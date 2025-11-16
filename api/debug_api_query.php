<?php
/**
 * Debug API Query - Compare diagnosis query vs API query
 */

require_once 'config.php';

$telecaller_id = 8; // Sonam

echo "<h2>Debugging API Query for Telecaller ID: $telecaller_id</h2>";
echo "<hr>";

// Query 1: Diagnosis query (the one that works)
echo "<h3>Query 1: Diagnosis Query (Shows 19 subscriptions)</h3>";
$query1 = "
    SELECT COUNT(*) as count
    FROM call_logs cl
    JOIN payments p ON cl.user_id = p.user_id
    WHERE p.payment_status = 'captured'
    AND p.created_at > cl.call_time
    AND cl.caller_id = $telecaller_id
";

echo "<pre>" . htmlspecialchars($query1) . "</pre>";
$result = $conn->query($query1);
$row = $result->fetch_assoc();
echo "<p><strong>Result:</strong> " . $row['count'] . " records</p>";

echo "<hr>";

// Query 2: API query (the one that returns 0)
echo "<h3>Query 2: API Query (Returns 0)</h3>";
$query2 = "
    SELECT 
        COUNT(DISTINCT p.id) as total_subscriptions,
        SUM(p.amount) as total_revenue
    FROM call_logs cl
    JOIN payments p ON cl.user_id = p.user_id
    WHERE p.payment_status = 'captured'
    AND p.created_at > cl.call_time
    AND cl.caller_id = $telecaller_id
";

echo "<pre>" . htmlspecialchars($query2) . "</pre>";
$result = $conn->query($query2);
$row = $result->fetch_assoc();
echo "<p><strong>Result:</strong> " . $row['total_subscriptions'] . " subscriptions, ₹" . $row['total_revenue'] . " revenue</p>";

echo "<hr>";

// Let's see the actual data
echo "<h3>Actual Data for Telecaller $telecaller_id</h3>";
$query3 = "
    SELECT 
        cl.id as call_log_id,
        cl.user_id as driver_id,
        cl.call_time,
        p.id as payment_id,
        p.created_at as payment_created_at,
        p.amount,
        CASE WHEN p.created_at > cl.call_time THEN 'YES' ELSE 'NO' END as valid
    FROM call_logs cl
    JOIN payments p ON cl.user_id = p.user_id
    WHERE p.payment_status = 'captured'
    AND cl.caller_id = $telecaller_id
    ORDER BY cl.call_time DESC
    LIMIT 20
";

$result = $conn->query($query3);
echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
echo "<tr><th>Call Log ID</th><th>Driver ID</th><th>Call Time</th><th>Payment ID</th><th>Payment Time</th><th>Amount</th><th>Valid?</th></tr>";

$valid_count = 0;
while ($row = $result->fetch_assoc()) {
    $style = $row['valid'] == 'YES' ? 'background: #d4edda;' : 'background: #f8d7da;';
    if ($row['valid'] == 'YES') $valid_count++;
    
    echo "<tr style='$style'>";
    echo "<td>" . $row['call_log_id'] . "</td>";
    echo "<td>" . $row['driver_id'] . "</td>";
    echo "<td>" . $row['call_time'] . "</td>";
    echo "<td>" . $row['payment_id'] . "</td>";
    echo "<td>" . $row['payment_created_at'] . "</td>";
    echo "<td>₹" . $row['amount'] . "</td>";
    echo "<td><strong>" . $row['valid'] . "</strong></td>";
    echo "</tr>";
}

echo "</table>";
echo "<p><strong>Valid subscriptions in sample:</strong> $valid_count</p>";

echo "<hr>";

// Check if there's a timezone or date format issue
echo "<h3>Check Date/Time Formats</h3>";
$query4 = "
    SELECT 
        cl.call_time,
        p.created_at as payment_created_at,
        cl.call_time < p.created_at as comparison_result,
        UNIX_TIMESTAMP(cl.call_time) as call_unix,
        UNIX_TIMESTAMP(p.created_at) as payment_unix
    FROM call_logs cl
    JOIN payments p ON cl.user_id = p.user_id
    WHERE p.payment_status = 'captured'
    AND cl.caller_id = $telecaller_id
    LIMIT 5
";

$result = $conn->query($query4);
echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
echo "<tr><th>Call Time</th><th>Payment Time</th><th>Comparison (call < payment)</th><th>Call Unix</th><th>Payment Unix</th></tr>";

while ($row = $result->fetch_assoc()) {
    echo "<tr>";
    echo "<td>" . $row['call_time'] . "</td>";
    echo "<td>" . $row['payment_created_at'] . "</td>";
    echo "<td>" . ($row['comparison_result'] ? 'TRUE (payment after)' : 'FALSE (payment before)') . "</td>";
    echo "<td>" . $row['call_unix'] . "</td>";
    echo "<td>" . $row['payment_unix'] . "</td>";
    echo "</tr>";
}

echo "</table>";

echo "<hr>";
echo "<p><em>Debug completed at " . date('Y-m-d H:i:s') . "</em></p>";
