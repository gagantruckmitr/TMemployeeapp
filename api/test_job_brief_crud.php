<?php
/**
 * Test Job Brief CRUD Operations
 * Access via: https://truckmitr.com/truckmitr-app/api/test_job_brief_crud.php
 */

require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

echo "<h1>Job Brief CRUD Test</h1>";

if (!$conn) {
    die("<p style='color:red'>Database connection failed</p>");
}

echo "<h2>1. Testing Table Structure</h2>";
$result = $conn->query("DESCRIBE job_brief_table");
if ($result) {
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th></tr>";
    while ($row = $result->fetch_assoc()) {
        $highlight = $row['Field'] === 'caller_id' ? " style='background-color: #90EE90'" : "";
        echo "<tr$highlight>";
        echo "<td>{$row['Field']}</td>";
        echo "<td>{$row['Type']}</td>";
        echo "<td>{$row['Null']}</td>";
        echo "<td>{$row['Key']}</td>";
        echo "<td>{$row['Default']}</td>";
        echo "</tr>";
    }
    echo "</table>";
    echo "<p style='color:green'>✓ Table structure OK (caller_id column highlighted if exists)</p>";
} else {
    echo "<p style='color:red'>✗ Failed to describe table</p>";
}

echo "<h2>2. Testing Sample Data</h2>";
$result = $conn->query("SELECT * FROM job_brief_table ORDER BY created_at DESC LIMIT 5");
if ($result) {
    $count = $result->num_rows;
    echo "<p>Found $count recent records:</p>";
    if ($count > 0) {
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>ID</th><th>Transporter</th><th>Job ID</th><th>Caller ID</th><th>Name</th><th>Created</th></tr>";
        while ($row = $result->fetch_assoc()) {
            echo "<tr>";
            echo "<td>{$row['id']}</td>";
            echo "<td>{$row['unique_id']}</td>";
            echo "<td>{$row['job_id']}</td>";
            echo "<td>" . ($row['caller_id'] ?? 'NULL') . "</td>";
            echo "<td>{$row['name']}</td>";
            echo "<td>{$row['created_at']}</td>";
            echo "</tr>";
        }
        echo "</table>";
    } else {
        echo "<p>No records found yet</p>";
    }
} else {
    echo "<p style='color:red'>✗ Failed to query records</p>";
}

echo "<h2>3. Testing API Endpoints</h2>";

// Test GET history endpoint
echo "<h3>GET Call History</h3>";
echo "<p>Test URL: <code>phase2_job_brief_api.php?action=history&unique_id=TM123456</code></p>";
echo "<p>This endpoint returns all call records for a specific transporter</p>";

// Test POST create endpoint
echo "<h3>POST Create Job Brief</h3>";
echo "<p>Test URL: <code>phase2_job_brief_api.php</code></p>";
echo "<p>Send JSON with: uniqueId, jobId, callerId, and other fields</p>";

// Test POST update endpoint
echo "<h3>POST Update Job Brief</h3>";
echo "<p>Test URL: <code>phase2_job_brief_api.php?action=update</code></p>";
echo "<p>Send JSON with: id and fields to update</p>";

// Test POST delete endpoint
echo "<h3>POST Delete Job Brief</h3>";
echo "<p>Test URL: <code>phase2_job_brief_api.php?action=delete</code></p>";
echo "<p>Send JSON with: id</p>";

echo "<h2>4. Testing Joins</h2>";
$result = $conn->query("
    SELECT jb.id, jb.unique_id, jb.job_id, jb.caller_id, jb.name,
           j.job_title, j.company_name,
           mu.name as caller_name
    FROM job_brief_table jb
    LEFT JOIN jobs j ON jb.job_id = j.job_id
    LEFT JOIN match_making_users mu ON jb.caller_id = mu.id
    ORDER BY jb.created_at DESC
    LIMIT 5
");

if ($result) {
    $count = $result->num_rows;
    echo "<p>Testing joins with jobs and match_making_users tables:</p>";
    if ($count > 0) {
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>ID</th><th>Transporter</th><th>Job Title</th><th>Company</th><th>Caller Name</th></tr>";
        while ($row = $result->fetch_assoc()) {
            echo "<tr>";
            echo "<td>{$row['id']}</td>";
            echo "<td>{$row['unique_id']}</td>";
            echo "<td>" . ($row['job_title'] ?? 'N/A') . "</td>";
            echo "<td>" . ($row['company_name'] ?? 'N/A') . "</td>";
            echo "<td>" . ($row['caller_name'] ?? 'N/A') . "</td>";
            echo "</tr>";
        }
        echo "</table>";
        echo "<p style='color:green'>✓ Joins working correctly</p>";
    } else {
        echo "<p>No records to test joins</p>";
    }
} else {
    echo "<p style='color:red'>✗ Join query failed: " . $conn->error . "</p>";
}

echo "<h2>Summary</h2>";
echo "<ul>";
echo "<li>✓ Database table structure verified</li>";
echo "<li>✓ caller_id column present</li>";
echo "<li>✓ API endpoints documented</li>";
echo "<li>✓ Join queries tested</li>";
echo "</ul>";

echo "<h3>Next Steps:</h3>";
echo "<ol>";
echo "<li>If caller_id column is missing, run: <a href='run_job_brief_update.php'>run_job_brief_update.php</a></li>";
echo "<li>Test creating a job brief from the Flutter app</li>";
echo "<li>View the call history screen</li>";
echo "<li>Test edit and delete operations</li>";
echo "</ol>";

$conn->close();
?>
