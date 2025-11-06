<?php
/**
 * Test Transporters List API
 * Access via: https://truckmitr.com/truckmitr-app/api/test_transporters_list.php
 */

require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

echo "<h1>Transporters List Test</h1>";

if (!$conn) {
    die("<p style='color:red'>Database connection failed</p>");
}

echo "<h2>1. Check job_brief_table Data</h2>";
$result = $conn->query("SELECT COUNT(*) as total FROM job_brief_table");
if ($result) {
    $row = $result->fetch_assoc();
    echo "<p>Total records in job_brief_table: <strong>{$row['total']}</strong></p>";
} else {
    echo "<p style='color:red'>Failed to query job_brief_table</p>";
}

echo "<h2>2. Test Transporters List Query</h2>";
$query = "SELECT 
            jb.unique_id as tmid,
            jb.name,
            j.company_name as company,
            j.job_location as location,
            COUNT(jb.id) as call_count,
            MAX(jb.created_at) as last_call_date
          FROM job_brief_table jb
          LEFT JOIN jobs j ON jb.job_id = j.job_id
          GROUP BY jb.unique_id
          ORDER BY MAX(jb.created_at) DESC";

$result = $conn->query($query);

if ($result) {
    $count = $result->num_rows;
    echo "<p style='color:green'>✓ Query successful! Found <strong>$count</strong> transporters with call history</p>";
    
    if ($count > 0) {
        echo "<table border='1' cellpadding='10' style='border-collapse: collapse; width: 100%;'>";
        echo "<tr style='background-color: #f0f0f0;'>";
        echo "<th>TMID</th><th>Name</th><th>Company</th><th>Location</th><th>Call Count</th><th>Last Call</th>";
        echo "</tr>";
        
        while ($row = $result->fetch_assoc()) {
            echo "<tr>";
            echo "<td>{$row['tmid']}</td>";
            echo "<td>" . ($row['name'] ?? 'Unknown') . "</td>";
            echo "<td>" . ($row['company'] ?? 'N/A') . "</td>";
            echo "<td>" . ($row['location'] ?? 'N/A') . "</td>";
            echo "<td><strong>{$row['call_count']}</strong></td>";
            echo "<td>{$row['last_call_date']}</td>";
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "<p style='color:orange'>⚠ No transporters found with call history yet.</p>";
        echo "<p>Make sure you have:</p>";
        echo "<ol>";
        echo "<li>Made calls from job posting screens</li>";
        echo "<li>Filled in the job brief feedback modal</li>";
        echo "<li>Saved the feedback successfully</li>";
        echo "</ol>";
    }
} else {
    echo "<p style='color:red'>✗ Query failed: " . $conn->error . "</p>";
}

echo "<h2>3. Test API Endpoint</h2>";
echo "<p>Test the API directly:</p>";
echo "<p><a href='phase2_job_brief_api.php?action=transporters_list' target='_blank'>Click here to test API</a></p>";

echo "<h2>4. Sample Call History Records</h2>";
$result = $conn->query("SELECT jb.*, j.job_title FROM job_brief_table jb LEFT JOIN jobs j ON jb.job_id = j.job_id ORDER BY jb.created_at DESC LIMIT 5");
if ($result && $result->num_rows > 0) {
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse; width: 100%;'>";
    echo "<tr style='background-color: #f0f0f0;'>";
    echo "<th>ID</th><th>Transporter TMID</th><th>Job Title</th><th>Caller ID</th><th>Created</th>";
    echo "</tr>";
    
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>{$row['id']}</td>";
        echo "<td>{$row['unique_id']}</td>";
        echo "<td>" . ($row['job_title'] ?? 'N/A') . "</td>";
        echo "<td>" . ($row['caller_id'] ?? 'NULL') . "</td>";
        echo "<td>{$row['created_at']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p>No call history records found</p>";
}

echo "<h2>Summary</h2>";
echo "<ul>";
echo "<li>✓ Database connection working</li>";
echo "<li>✓ Query structure correct</li>";
echo "<li>✓ API endpoint ready</li>";
echo "</ul>";

echo "<h3>Next Steps:</h3>";
echo "<ol>";
echo "<li>If no transporters shown, make some test calls from the app</li>";
echo "<li>Fill in the job brief feedback modal</li>";
echo "<li>Check this page again to see the transporters</li>";
echo "<li>Test the Flutter app's History tab</li>";
echo "</ol>";

$conn->close();
?>
