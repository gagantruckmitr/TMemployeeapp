<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

echo "=== Testing Transporters List Query ===\n\n";

// Test the exact query from getTransportersList()
$query = "SELECT 
            jb.unique_id as tmid,
            COALESCE(u.Transport_Name, u.name_eng, u.name, 'Unknown') as name,
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
          GROUP BY jb.unique_id, COALESCE(u.Transport_Name, u.name_eng, u.name, 'Unknown')
          ORDER BY last_call_date DESC
          LIMIT 10";

$result = $conn->query($query);

if (!$result) {
    echo "❌ Query failed: " . $conn->error . "\n";
    exit(1);
}

echo "✓ Query executed successfully\n";
echo "Results:\n";
echo str_repeat("-", 80) . "\n";

$count = 0;
while ($row = $result->fetch_assoc()) {
    $count++;
    echo "\nTransporter #$count:\n";
    echo "  TMID: {$row['tmid']}\n";
    echo "  Name: {$row['name']}\n";
    echo "  Location: " . ($row['location'] ?: 'N/A') . "\n";
    echo "  Call Count: {$row['call_count']}\n";
    echo "  Last Call: {$row['last_call_date']}\n";
}

if ($count === 0) {
    echo "\n⚠ No results found\n";
}

// Now test without GROUP BY to see raw data
echo "\n\n=== Testing Without GROUP BY ===\n\n";

$query2 = "SELECT 
            jb.unique_id as tmid,
            u.unique_id as user_unique_id,
            u.Transport_Name,
            u.name_eng,
            u.name,
            COALESCE(u.Transport_Name, u.name_eng, u.name, 'Unknown') as final_name
          FROM job_brief_table jb
          LEFT JOIN users u ON jb.unique_id = u.unique_id AND u.role = 'transporter'
          LIMIT 10";

$result2 = $conn->query($query2);

if ($result2) {
    while ($row = $result2->fetch_assoc()) {
        echo "\nTMID: {$row['tmid']}\n";
        echo "  User TMID: " . ($row['user_unique_id'] ?: 'NULL') . "\n";
        echo "  Transport_Name: " . ($row['Transport_Name'] ?: 'NULL') . "\n";
        echo "  name_eng: " . ($row['name_eng'] ?: 'NULL') . "\n";
        echo "  name: " . ($row['name'] ?: 'NULL') . "\n";
        echo "  Final Name: {$row['final_name']}\n";
    }
}

$conn->close();
?>
