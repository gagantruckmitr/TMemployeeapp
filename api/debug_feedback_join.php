<?php
/**
 * Debug feedback join issue
 */

require_once 'config.php';

$jobId = 'TMJB00418';

echo "Debugging feedback join for job: $jobId\n";
echo "=========================================\n\n";

// First, get feedback records for this job
echo "1. Feedback records for this job:\n";
echo "-----------------------------------\n";
$feedbackQuery = "SELECT unique_id_driver, driver_name, feedback, match_status, created_at 
                  FROM call_logs_match_making 
                  WHERE job_id = '$jobId' 
                  ORDER BY created_at DESC";
$feedbackResult = $conn->query($feedbackQuery);

$feedbackDrivers = [];
if ($feedbackResult && $feedbackResult->num_rows > 0) {
    while ($row = $feedbackResult->fetch_assoc()) {
        echo "Driver TMID: " . $row['unique_id_driver'] . "\n";
        echo "  Name: " . $row['driver_name'] . "\n";
        echo "  Feedback: " . $row['feedback'] . "\n";
        echo "  Match Status: " . ($row['match_status'] ?? 'NULL') . "\n";
        echo "  Created: " . $row['created_at'] . "\n\n";
        $feedbackDrivers[] = $row['unique_id_driver'];
    }
} else {
    echo "No feedback records found.\n\n";
}

// Get the numeric job ID
$jobQuery = "SELECT id FROM jobs WHERE job_id = '$jobId' LIMIT 1";
$jobResult = $conn->query($jobQuery);
$jobRow = $jobResult->fetch_assoc();
$numericJobId = $jobRow['id'];

echo "\n2. Applicants for this job:\n";
echo "----------------------------\n";
$applicantsQuery = "SELECT u.unique_id, u.name 
                    FROM applyjobs a
                    INNER JOIN users u ON a.driver_id = u.id
                    WHERE a.job_id = $numericJobId
                    LIMIT 10";
$applicantsResult = $conn->query($applicantsQuery);

if ($applicantsResult && $applicantsResult->num_rows > 0) {
    while ($row = $applicantsResult->fetch_assoc()) {
        $hasFeedback = in_array($row['unique_id'], $feedbackDrivers) ? 'YES' : 'NO';
        echo "Driver TMID: " . $row['unique_id'] . " - " . $row['name'] . " (Has feedback: $hasFeedback)\n";
    }
}

echo "\n\n3. Testing the LEFT JOIN query:\n";
echo "--------------------------------\n";
$testQuery = "SELECT 
    u.unique_id,
    u.name,
    cl.feedback,
    cl.match_status,
    cl.remark
FROM applyjobs a
INNER JOIN users u ON a.driver_id = u.id
LEFT JOIN (
    SELECT cl1.*
    FROM call_logs_match_making cl1
    INNER JOIN (
        SELECT unique_id_driver, job_id, MAX(created_at) as max_created
        FROM call_logs_match_making
        WHERE unique_id_driver IS NOT NULL AND unique_id_driver != ''
        GROUP BY unique_id_driver, job_id
    ) cl2 ON cl1.unique_id_driver = cl2.unique_id_driver 
          AND cl1.job_id = cl2.job_id 
          AND cl1.created_at = cl2.max_created
) cl ON u.unique_id = cl.unique_id_driver AND cl.job_id = '$jobId'
WHERE a.job_id = $numericJobId
LIMIT 10";

$testResult = $conn->query($testQuery);

if ($testResult && $testResult->num_rows > 0) {
    while ($row = $testResult->fetch_assoc()) {
        echo "Driver: " . $row['name'] . " (" . $row['unique_id'] . ")\n";
        echo "  Feedback: " . ($row['feedback'] ?? 'NULL') . "\n";
        echo "  Match Status: " . ($row['match_status'] ?? 'NULL') . "\n\n";
    }
}
