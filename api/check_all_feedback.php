<?php
/**
 * Check all feedback data in call_logs_match_making table
 */

require_once 'config.php';

echo "Checking all feedback data\n";
echo "==========================\n\n";

// Get total count
$countQuery = "SELECT COUNT(*) as total FROM call_logs_match_making";
$countResult = $conn->query($countQuery);
$totalCount = $countResult->fetch_assoc()['total'];

echo "Total feedback records: $totalCount\n\n";

// Get recent records
$query = "SELECT * FROM call_logs_match_making ORDER BY created_at DESC LIMIT 10";
$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    echo "Recent 10 feedback records:\n\n";
    
    while ($row = $result->fetch_assoc()) {
        echo "ID: " . $row['id'] . "\n";
        echo "  Job ID: " . ($row['job_id'] ?? 'NULL') . "\n";
        echo "  Driver TMID: " . ($row['unique_id_driver'] ?? 'NULL') . "\n";
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
    echo "No feedback records found in the table.\n";
}

// Check which jobs have feedback
echo "\nJobs with feedback:\n";
echo "===================\n";
$jobsQuery = "SELECT DISTINCT job_id, COUNT(*) as count FROM call_logs_match_making WHERE job_id IS NOT NULL AND job_id != '' GROUP BY job_id ORDER BY count DESC LIMIT 20";
$jobsResult = $conn->query($jobsQuery);

if ($jobsResult && $jobsResult->num_rows > 0) {
    while ($row = $jobsResult->fetch_assoc()) {
        echo "Job " . $row['job_id'] . ": " . $row['count'] . " feedback records\n";
    }
} else {
    echo "No jobs with feedback found.\n";
}
