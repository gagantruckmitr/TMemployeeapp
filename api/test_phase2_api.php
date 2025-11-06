<?php
/**
 * Test Phase 2 API Connection
 * This file tests if the database connection and queries work
 */

require_once 'config.php';

echo "<h1>Phase 2 API Test</h1>";

// Test 1: Database Connection
echo "<h2>Test 1: Database Connection</h2>";
try {
    $testConn = getDBConnection();
    echo "✓ Database connection successful<br>";
    echo "Database: " . DB_NAME . "<br>";
} catch (Exception $e) {
    echo "✗ Database connection failed: " . $e->getMessage() . "<br>";
    exit;
}

// Test 2: Check if jobs table exists
echo "<h2>Test 2: Jobs Table</h2>";
$result = $conn->query("SHOW TABLES LIKE 'jobs'");
if ($result->num_rows > 0) {
    echo "✓ Jobs table exists<br>";
    
    // Count jobs
    $countResult = $conn->query("SELECT COUNT(*) as count FROM jobs");
    $count = $countResult->fetch_assoc()['count'];
    echo "Total jobs in database: $count<br>";
} else {
    echo "✗ Jobs table does not exist<br>";
}

// Test 3: Check jobs table structure
echo "<h2>Test 3: Jobs Table Structure</h2>";
$result = $conn->query("DESCRIBE jobs");
if ($result) {
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . $row['Field'] . "</td>";
        echo "<td>" . $row['Type'] . "</td>";
        echo "<td>" . $row['Null'] . "</td>";
        echo "<td>" . $row['Key'] . "</td>";
        echo "</tr>";
    }
    echo "</table>";
}

// Test 4: Sample job data
echo "<h2>Test 4: Sample Job Data</h2>";
$result = $conn->query("SELECT * FROM jobs LIMIT 1");
if ($result && $result->num_rows > 0) {
    $job = $result->fetch_assoc();
    echo "<pre>";
    print_r($job);
    echo "</pre>";
} else {
    echo "No jobs found in database<br>";
}

// Test 5: Test dashboard stats query
echo "<h2>Test 5: Dashboard Stats Query</h2>";
try {
    $totalJobsQuery = "SELECT COUNT(*) as count FROM jobs";
    $totalJobs = $conn->query($totalJobsQuery)->fetch_assoc()['count'];
    echo "Total jobs: $totalJobs<br>";
    
    $approvedJobsQuery = "SELECT COUNT(*) as count FROM jobs WHERE status = 1";
    $approvedJobs = $conn->query($approvedJobsQuery)->fetch_assoc()['count'];
    echo "Approved jobs: $approvedJobs<br>";
    
    $pendingJobsQuery = "SELECT COUNT(*) as count FROM jobs WHERE status = 0";
    $pendingJobs = $conn->query($pendingJobsQuery)->fetch_assoc()['count'];
    echo "Pending jobs: $pendingJobs<br>";
    
    echo "✓ Dashboard stats queries working<br>";
} catch (Exception $e) {
    echo "✗ Error: " . $e->getMessage() . "<br>";
}

// Test 6: Check transporters table
echo "<h2>Test 6: Transporters Table</h2>";
$result = $conn->query("SHOW TABLES LIKE 'transporters'");
if ($result->num_rows > 0) {
    echo "✓ Transporters table exists<br>";
    $countResult = $conn->query("SELECT COUNT(*) as count FROM transporters");
    $count = $countResult->fetch_assoc()['count'];
    echo "Total transporters: $count<br>";
} else {
    echo "✗ Transporters table does not exist<br>";
}

// Test 7: Check lead_assignment_new table
echo "<h2>Test 7: Lead Assignment Table</h2>";
$result = $conn->query("SHOW TABLES LIKE 'lead_assignment_new'");
if ($result->num_rows > 0) {
    echo "✓ lead_assignment_new table exists<br>";
    $countResult = $conn->query("SELECT COUNT(*) as count FROM lead_assignment_new");
    $count = $countResult->fetch_assoc()['count'];
    echo "Total assignments: $count<br>";
} else {
    echo "✗ lead_assignment_new table does not exist<br>";
}

echo "<h2>All Tests Complete</h2>";
