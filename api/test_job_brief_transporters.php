<?php
/**
 * Test script for job brief transporters list API
 */

error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

echo "=== Testing Job Brief Transporters List API ===\n\n";

// Test the query
$query = "SELECT 
            jb.unique_id as tmid,
            u.Transport_Name as name,
            (SELECT job_location 
             FROM job_brief_table 
             WHERE unique_id = jb.unique_id 
             AND job_location IS NOT NULL 
             AND job_location != ''
             ORDER BY created_at DESC 
             LIMIT 1) as location,
            COUNT(jb.id) as call_count,
            MAX(jb.created_at) as last_call_date
          FROM job_brief_table jb
          LEFT JOIN users u ON jb.unique_id = u.unique_id AND u.role = 'transporter'
          GROUP BY jb.unique_id, u.Transport_Name
          ORDER BY last_call_date DESC
          LIMIT 10";

$result = $conn->query($query);

if (!$result) {
    echo "❌ Query failed: " . $conn->error . "\n";
    exit(1);
}

echo "✓ Query executed successfully\n\n";
echo "Results:\n";
echo str_repeat("-", 80) . "\n";

$count = 0;
while ($row = $result->fetch_assoc()) {
    $count++;
    echo "Transporter #$count:\n";
    echo "  TMID: " . $row['tmid'] . "\n";
    echo "  Name: " . ($row['name'] ?? 'Unknown') . "\n";
    echo "  Location: " . ($row['location'] ?? 'N/A') . "\n";
    echo "  Call Count: " . $row['call_count'] . "\n";
    echo "  Last Call: " . $row['last_call_date'] . "\n";
    echo "\n";
}

echo str_repeat("-", 80) . "\n";
echo "Total transporters found: $count\n";

echo "\n=== Test Complete ===\n";
?>
