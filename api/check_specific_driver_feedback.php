<?php
/**
 * Check feedback for specific driver
 */

require_once 'config.php';

$driverTmid = 'TM2508UPDR05358';

echo "Checking feedback for driver: $driverTmid\n";
echo "==========================================\n\n";

// Check all feedback for this driver
$query = "SELECT * FROM call_logs_match_making WHERE unique_id_driver = '$driverTmid' ORDER BY created_at DESC";
$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    echo "Found " . $result->num_rows . " feedback records:\n\n";
    
    while ($row = $result->fetch_assoc()) {
        echo "ID: " . $row['id'] . "\n";
        echo "  Job ID: " . ($row['job_id'] ?? 'NULL') . "\n";
        echo "  Driver Name: " . ($row['driver_name'] ?? 'NULL') . "\n";
        echo "  Transporter TMID: " . ($row['unique_id_transporter'] ?? 'NULL') . "\n";
        echo "  Transporter Name: " . ($row['transporter_name'] ?? 'NULL') . "\n";
        echo "  Feedback: " . ($row['feedback'] ?? 'NULL') . "\n";
        echo "  Match Status: " . ($row['match_status'] ?? 'NULL') . "\n";
        echo "  Remark: " . ($row['remark'] ?? 'NULL') . "\n";
        echo "  Created: " . ($row['created_at'] ?? 'NULL') . "\n";
        echo "\n";
    }
} else {
    echo "No feedback records found for this driver.\n\n";
}

// Check which jobs this driver applied to
echo "\nJobs this driver applied to:\n";
echo "============================\n";
$jobsQuery = "SELECT j.job_id, j.job_title, a.created_at as applied_at
              FROM applyjobs a
              INNER JOIN users u ON a.driver_id = u.id
              INNER JOIN jobs j ON a.job_id = j.id
              WHERE u.unique_id = '$driverTmid'
              ORDER BY a.created_at DESC
              LIMIT 10";
$jobsResult = $conn->query($jobsQuery);

if ($jobsResult && $jobsResult->num_rows > 0) {
    while ($row = $jobsResult->fetch_assoc()) {
        echo "Job: " . $row['job_id'] . " - " . $row['job_title'] . "\n";
        echo "  Applied: " . $row['applied_at'] . "\n\n";
    }
} else {
    echo "No job applications found for this driver.\n";
}

// Check driver details
echo "\nDriver Details:\n";
echo "===============\n";
$driverQuery = "SELECT id, unique_id, name, mobile FROM users WHERE unique_id = '$driverTmid'";
$driverResult = $conn->query($driverQuery);

if ($driverResult && $driverResult->num_rows > 0) {
    $driver = $driverResult->fetch_assoc();
    echo "ID: " . $driver['id'] . "\n";
    echo "TMID: " . $driver['unique_id'] . "\n";
    echo "Name: " . $driver['name'] . "\n";
    echo "Mobile: " . $driver['mobile'] . "\n";
} else {
    echo "Driver not found in database.\n";
}
