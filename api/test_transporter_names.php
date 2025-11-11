<?php
/**
 * Test script to check transporter names
 * This helps identify why some transporters show as "Unknown"
 */

require_once 'config.php';

echo "<h2>Transporter Names Debug</h2>";

// Step 1: Check transporters in job_brief_table
echo "<h3>Step 1: Transporters in job_brief_table</h3>";
$query1 = "SELECT 
            unique_id,
            name,
            COUNT(*) as record_count,
            MAX(created_at) as last_call
           FROM job_brief_table
           GROUP BY unique_id
           ORDER BY MAX(created_at) DESC
           LIMIT 10";

$result1 = $conn->query($query1);

if ($result1 && $result1->num_rows > 0) {
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>TMID</th><th>Name in job_brief</th><th>Records</th><th>Last Call</th></tr>";
    while ($row = $result1->fetch_assoc()) {
        $nameStatus = empty($row['name']) ? '❌ EMPTY' : '✓ ' . $row['name'];
        echo "<tr>";
        echo "<td>{$row['unique_id']}</td>";
        echo "<td>$nameStatus</td>";
        echo "<td>{$row['record_count']}</td>";
        echo "<td>{$row['last_call']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "No records found<br>";
}

// Step 2: Check if transporter_table exists
echo "<h3>Step 2: Check transporter_table</h3>";
$tableCheck = $conn->query("SHOW TABLES LIKE 'transporter_table'");
if ($tableCheck && $tableCheck->num_rows > 0) {
    echo "✓ transporter_table exists<br><br>";
    
    // Get sample transporters
    $query2 = "SELECT unique_id, name, company_name FROM transporter_table LIMIT 10";
    $result2 = $conn->query($query2);
    
    if ($result2 && $result2->num_rows > 0) {
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>TMID</th><th>Name</th><th>Company Name</th></tr>";
        while ($row = $result2->fetch_assoc()) {
            echo "<tr>";
            echo "<td>{$row['unique_id']}</td>";
            echo "<td>" . ($row['name'] ?? 'NULL') . "</td>";
            echo "<td>" . ($row['company_name'] ?? 'NULL') . "</td>";
            echo "</tr>";
        }
        echo "</table>";
    }
} else {
    echo "❌ transporter_table does NOT exist<br>";
    echo "This is the main issue - we need the transporter master table<br>";
}

// Step 3: Test the new query
echo "<h3>Step 3: Test New Query (with JOIN)</h3>";
$query3 = "SELECT 
            jb.unique_id as tmid,
            COALESCE(
                t.name,
                t.company_name,
                (SELECT name 
                 FROM job_brief_table 
                 WHERE unique_id = jb.unique_id 
                 AND name IS NOT NULL 
                 AND name != '' 
                 AND name != 'null'
                 ORDER BY created_at DESC 
                 LIMIT 1),
                jb.unique_id
            ) as name,
            COALESCE(t.company_name, '') as company,
            COUNT(jb.id) as call_count
          FROM job_brief_table jb
          LEFT JOIN transporter_table t ON jb.unique_id = t.unique_id
          GROUP BY jb.unique_id, t.name, t.company_name
          ORDER BY MAX(jb.created_at) DESC
          LIMIT 10";

$result3 = $conn->query($query3);

if ($result3) {
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>TMID</th><th>Display Name</th><th>Company</th><th>Calls</th><th>Status</th></tr>";
    while ($row = $result3->fetch_assoc()) {
        $status = ($row['name'] == $row['tmid']) ? '⚠️ Using TMID' : '✓ Has Name';
        echo "<tr>";
        echo "<td>{$row['tmid']}</td>";
        echo "<td>{$row['name']}</td>";
        echo "<td>" . ($row['company'] ?: 'N/A') . "</td>";
        echo "<td>{$row['call_count']}</td>";
        echo "<td>$status</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "Query failed: " . $conn->error . "<br>";
}

// Step 4: Recommendations
echo "<h3>Step 4: Recommendations</h3>";
echo "<ol>";
echo "<li>If transporter_table doesn't exist, create it or use an existing transporter master table</li>";
echo "<li>Ensure job_brief_table has the 'name' field populated when saving</li>";
echo "<li>Consider adding a foreign key relationship between job_brief_table and transporter_table</li>";
echo "<li>Update existing records with empty names by fetching from transporter master table</li>";
echo "</ol>";

// Step 5: Quick fix query
echo "<h3>Step 5: Quick Fix (if transporter_table exists)</h3>";
echo "<p>Run this query to update empty names in job_brief_table:</p>";
echo "<pre>";
echo "UPDATE job_brief_table jb
LEFT JOIN transporter_table t ON jb.unique_id = t.unique_id
SET jb.name = COALESCE(t.name, t.company_name, jb.unique_id)
WHERE jb.name IS NULL OR jb.name = '' OR jb.name = 'null';
</pre>";

$conn->close();
?>
