<?php
/**
 * Check feedback for specific job and its applicants
 */

require_once 'config.php';

$jobId = 'TMJB00437';

echo "Checking feedback for job: $jobId\n";
echo "====================================\n\n";

// Get numeric job ID
$jobQuery = "SELECT id FROM jobs WHERE job_id = '$jobId' LIMIT 1";
$jobResult = $conn->query($jobQuery);

if (!$jobResult || $jobResult->num_rows === 0) {
    echo "Job not found!\n";
    exit;
}

$jobRow = $jobResult->fetch_assoc();
$numericJobId = $jobRow['id'];

echo "Numeric Job ID: $numericJobId\n\n";

// Get all applicants for this job
echo "1. All Applicants:\n";
echo "-------------------\n";
$applicantsQuery = "SELECT u.unique_id, u.name, a.created_at as applied_at
                    FROM applyjobs a
                    INNER JOIN users u ON a.driver_id = u.id
                    WHERE a.job_id = $numericJobId
                    ORDER BY a.created_at DESC";
$applicantsResult = $conn->query($applicantsQuery);

$applicantTmids = [];
if ($applicantsResult && $applicantsResult->num_rows > 0) {
    echo "Total applicants: " . $applicantsResult->num_rows . "\n\n";
    while ($row = $applicantsResult->fetch_assoc()) {
        echo "- " . $row['name'] . " (" . $row['unique_id'] . ")\n";
        $applicantTmids[] = $row['unique_id'];
    }
} else {
    echo "No applicants found.\n";
}

// Check feedback for this job
echo "\n\n2. Feedback Records for this Job:\n";
echo "-----------------------------------\n";
$feedbackQuery = "SELECT * FROM call_logs_match_making WHERE job_id = '$jobId' ORDER BY created_at DESC";
$feedbackResult = $conn->query($feedbackQuery);

if ($feedbackResult && $feedbackResult->num_rows > 0) {
    echo "Total feedback records: " . $feedbackResult->num_rows . "\n\n";
    
    while ($row = $feedbackResult->fetch_assoc()) {
        $isApplicant = in_array($row['unique_id_driver'], $applicantTmids) ? '✓ APPLICANT' : '✗ NOT APPLICANT';
        echo "Driver: " . $row['driver_name'] . " (" . $row['unique_id_driver'] . ") $isApplicant\n";
        echo "  Feedback: " . $row['feedback'] . "\n";
        echo "  Match Status: " . ($row['match_status'] ?? 'NULL') . "\n";
        echo "  Created: " . $row['created_at'] . "\n\n";
    }
} else {
    echo "No feedback records found for this job.\n";
}

// Summary
echo "\n3. Summary:\n";
echo "-----------\n";
echo "Total Applicants: " . count($applicantTmids) . "\n";
echo "Total Feedback Records: " . ($feedbackResult ? $feedbackResult->num_rows : 0) . "\n";

if ($feedbackResult && $feedbackResult->num_rows > 0) {
    $feedbackResult->data_seek(0);
    $matchCount = 0;
    while ($row = $feedbackResult->fetch_assoc()) {
        if (in_array($row['unique_id_driver'], $applicantTmids)) {
            $matchCount++;
        }
    }
    echo "Applicants with Feedback: $matchCount\n";
    echo "Applicants without Feedback: " . (count($applicantTmids) - $matchCount) . "\n";
}
