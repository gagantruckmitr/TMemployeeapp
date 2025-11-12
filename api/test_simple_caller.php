<?php
/**
 * Simple test for caller_id filtering
 */

require_once 'config.php';

header('Content-Type: text/plain');

echo "=== Testing Caller ID Filtering ===\n\n";

// Test the actual query
$callerId = 3;

$query = "SELECT 
            jb.unique_id as tmid,
            COALESCE(u.Transport_Name, u.name_eng, u.name, 'Unknown') as name,
            COUNT(jb.id) as call_count,
            MAX(jb.created_at) as last_call_date
          FROM job_brief_table jb
          LEFT JOIN users u ON jb.unique_id = u.unique_id AND u.role = 'transporter'
          WHERE jb.caller_id = $callerId
          GROUP BY jb.unique_id, COALESCE(u.Transport_Name, u.name_eng, u.name, 'Unknown')
          ORDER BY last_call_date DESC";

echo "Query:\n$query\n\n";

$result = $conn->query($query);

if (!$result) {
    echo "ERROR: " . $conn->error . "\n";
    exit;
}

echo "Results for Caller ID $callerId:\n";
echo "Count: " . $result->num_rows . " transporters\n\n";

while ($row = $result->fetch_assoc()) {
    echo "- {$row['name']} ({$row['tmid']}): {$row['call_count']} calls\n";
}

echo "\n\n=== All Records in Database ===\n";
$query2 = "SELECT caller_id, COUNT(*) as count FROM job_brief_table GROUP BY caller_id";
$result2 = $conn->query($query2);

while ($row = $result2->fetch_assoc()) {
    echo "Caller ID " . ($row['caller_id'] ?? 'NULL') . ": " . $row['count'] . " records\n";
}

$conn->close();
?>
