<?php
require_once 'config.php';

$jobId = 'TMJB00419'; // From your log

echo "<h2>Testing Job Lookup for $jobId</h2>";

$jobQuery = "SELECT j.transporter_id, u.unique_id, u.name 
             FROM jobs j 
             LEFT JOIN users u ON j.transporter_id = u.id 
             WHERE j.job_id = '$jobId' LIMIT 1";

echo "<h3>Query:</h3><pre>$jobQuery</pre>";

$jobResult = $conn->query($jobQuery);

if ($jobResult) {
    echo "<h3>Result:</h3>";
    if ($jobResult->num_rows > 0) {
        $jobRow = $jobResult->fetch_assoc();
        echo "<pre>";
        print_r($jobRow);
        echo "</pre>";
        
        echo "<p><strong>Transporter ID:</strong> " . ($jobRow['transporter_id'] ?? 'NULL') . "</p>";
        echo "<p><strong>Transporter TMID:</strong> " . ($jobRow['unique_id'] ?? 'NULL') . "</p>";
        echo "<p><strong>Transporter Name:</strong> " . ($jobRow['name'] ?? 'NULL') . "</p>";
    } else {
        echo "<p style='color:red'>No job found with ID: $jobId</p>";
    }
} else {
    echo "<p style='color:red'>Query failed: " . $conn->error . "</p>";
}

// Also check if job exists
echo "<h3>Check if job exists:</h3>";
$checkQuery = "SELECT * FROM jobs WHERE job_id = '$jobId' LIMIT 1";
$checkResult = $conn->query($checkQuery);
if ($checkResult && $checkResult->num_rows > 0) {
    $job = $checkResult->fetch_assoc();
    echo "<p>Job found! Transporter ID: " . $job['transporter_id'] . "</p>";
    echo "<pre>" . print_r($job, true) . "</pre>";
} else {
    echo "<p style='color:red'>Job not found!</p>";
}
?>
