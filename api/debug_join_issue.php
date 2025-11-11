<?php
require_once 'config.php';

echo "=== Debugging JOIN Issue ===\n\n";

// Test one specific TMID that shows as Unknown
$testTmid = 'TM2510RJTR12680';

echo "Testing TMID: $testTmid\n\n";

// Check if it exists in job_brief_table
$query1 = "SELECT unique_id FROM job_brief_table WHERE unique_id = '$testTmid' LIMIT 1";
$result1 = $conn->query($query1);
if ($result1 && $result1->num_rows > 0) {
    echo "✓ Found in job_brief_table\n";
} else {
    echo "✗ NOT found in job_brief_table\n";
}

// Check if it exists in users table
$query2 = "SELECT unique_id, role, Transport_Name, name, name_eng FROM users WHERE unique_id = '$testTmid' LIMIT 1";
$result2 = $conn->query($query2);
if ($result2 && $result2->num_rows > 0) {
    $user = $result2->fetch_assoc();
    echo "✓ Found in users table:\n";
    echo "  - unique_id: " . $user['unique_id'] . "\n";
    echo "  - role: " . $user['role'] . "\n";
    echo "  - Transport_Name: " . ($user['Transport_Name'] ?? 'NULL') . "\n";
    echo "  - name: " . ($user['name'] ?? 'NULL') . "\n";
    echo "  - name_eng: " . ($user['name_eng'] ?? 'NULL') . "\n";
} else {
    echo "✗ NOT found in users table\n";
}

echo "\n--- Testing JOIN directly ---\n";

// Test the actual JOIN
$query3 = "SELECT 
            jb.unique_id,
            u.unique_id as user_unique_id,
            u.role,
            u.Transport_Name,
            u.name,
            u.name_eng,
            COALESCE(u.Transport_Name, u.name_eng, u.name, 'Unknown') as final_name
          FROM job_brief_table jb
          LEFT JOIN users u ON jb.unique_id = u.unique_id AND u.role = 'transporter'
          WHERE jb.unique_id = '$testTmid'
          LIMIT 1";

$result3 = $conn->query($query3);
if ($result3 && $result3->num_rows > 0) {
    $row = $result3->fetch_assoc();
    echo "JOIN Result:\n";
    echo "  - jb.unique_id: " . $row['unique_id'] . "\n";
    echo "  - u.unique_id: " . ($row['user_unique_id'] ?? 'NULL') . "\n";
    echo "  - u.role: " . ($row['role'] ?? 'NULL') . "\n";
    echo "  - u.Transport_Name: " . ($row['Transport_Name'] ?? 'NULL') . "\n";
    echo "  - u.name: " . ($row['name'] ?? 'NULL') . "\n";
    echo "  - u.name_eng: " . ($row['name_eng'] ?? 'NULL') . "\n";
    echo "  - final_name: " . $row['final_name'] . "\n";
} else {
    echo "✗ JOIN returned no results\n";
}

echo "\n=== Test Complete ===\n";
?>
