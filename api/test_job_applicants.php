<?php
// Test the job applicants API
require_once 'config.php';

echo "Testing Job Applicants API\n\n";

// Test 1: Check if we can get a job
$jobQuery = "SELECT job_id, id FROM jobs LIMIT 1";
$result = $conn->query($jobQuery);

if ($result && $result->num_rows > 0) {
    $job = $result->fetch_assoc();
    echo "Found test job: " . $job['job_id'] . " (ID: " . $job['id'] . ")\n\n";
    
    // Test 2: Check if there are applicants
    $applicantsQuery = "SELECT COUNT(*) as count FROM applyjobs WHERE job_id = " . $job['id'];
    $applicantsResult = $conn->query($applicantsQuery);
    $applicantsCount = $applicantsResult->fetch_assoc()['count'];
    
    echo "Number of applicants: $applicantsCount\n\n";
    
    // Test 3: Try to call the API
    echo "Testing API call with job_id: " . $job['job_id'] . "\n";
    echo "URL: phase2_job_applicants_api.php?job_id=" . $job['job_id'] . "\n\n";
    
    // Simulate the API call
    $_GET['job_id'] = $job['job_id'];
    
    // Include the API file
    include 'phase2_job_applicants_api.php';
} else {
    echo "No jobs found in database\n";
}
?>
