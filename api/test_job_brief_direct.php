<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

echo "=== Testing Job Brief Queries Directly ===\n\n";

// Test 1: Get job briefs with JOIN
echo "Test 1: Getting job briefs with transporter names...\n";
$query = "SELECT 
            jb.*,
            COALESCE(jb.name, u.Transport_Name, u.name_eng, u.name) as transporter_name
          FROM job_brief_table jb
          LEFT JOIN users u ON jb.unique_id = u.unique_id AND u.role = 'transporter'
          ORDER BY jb.created_at DESC 
          LIMIT 10";

$result = $conn->query($query);

if (!$result) {
    echo "❌ Query failed: " . $conn->error . "\n";
} else {
    echo "✓ Query successful! Found " . $result->num_rows . " rows\n\n";
    echo str_repeat("-", 80) . "\n";
    
    while ($row = $result->fetch_assoc()) {
        echo "ID: {$row['id']}\n";
        echo "  TMID: {$row['unique_id']}\n";
        echo "  Original name field: " . ($row['name'] ?: 'NULL') . "\n";
        echo "  Transporter name (joined): " . ($row['transporter_name'] ?: 'NULL') . "\n";
        echo "  Job ID: {$row['job_id']}\n";
        echo "  Location: " . ($row['job_location'] ?: 'N/A') . "\n";
        echo "  Created: {$row['created_at']}\n\n";
    }
}

// Test 2: Check if there's a syntax error in the updated API
echo "\n\nTest 2: Checking API file for syntax errors...\n";
$output = [];
$return_var = 0;
exec('php -l api/phase2_job_brief_api.php 2>&1', $output, $return_var);

if ($return_var === 0) {
    echo "✓ No syntax errors in phase2_job_brief_api.php\n";
} else {
    echo "❌ Syntax errors found:\n";
    echo implode("\n", $output) . "\n";
}

$conn->close();
?>
