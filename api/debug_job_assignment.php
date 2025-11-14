<?php
header('Content-Type: text/plain');
require_once 'config.php';

$jobId = 'TMJB00461';
$userId3 = 3; // Puja
$userId4 = 4; // Tanisha

echo "=== DEBUGGING JOB ASSIGNMENT: {$jobId} ===\n\n";

// Check database directly
echo "1. DATABASE CHECK:\n";
echo str_repeat("=", 80) . "\n";

$query = "SELECT 
    j.id,
    j.job_id,
    j.job_title,
    j.assigned_to,
    a.id as admin_id,
    a.name as admin_name
FROM jobs j
LEFT JOIN admins a ON j.assigned_to = a.id
WHERE j.job_id = '{$jobId}'";

$result = $conn->query($query);

if ($result && $result->num_rows > 0) {
    $job = $result->fetch_assoc();
    echo "Job ID: {$job['job_id']}\n";
    echo "Job Title: {$job['job_title']}\n";
    echo "assigned_to (raw): " . ($job['assigned_to'] ?? 'NULL') . "\n";
    echo "assigned_to (type): " . gettype($job['assigned_to']) . "\n";
    echo "Admin ID: " . ($job['admin_id'] ?? 'NULL') . "\n";
    echo "Admin Name: " . ($job['admin_name'] ?? 'NULL') . "\n\n";
    
    $assignedTo = $job['assigned_to'];
    
    // Check all admins
    echo "2. ALL ADMINS:\n";
    echo str_repeat("=", 80) . "\n";
    $adminsQuery = "SELECT id, name FROM admins ORDER BY id";
    $adminsResult = $conn->query($adminsQuery);
    while ($admin = $adminsResult->fetch_assoc()) {
        $isAssigned = ($admin['id'] == $assignedTo) ? " <-- ASSIGNED" : "";
        echo "ID: {$admin['id']} | Name: {$admin['name']}{$isAssigned}\n";
    }
    echo "\n";
    
    // Test API for user 3 (Puja)
    echo "3. API RESPONSE FOR USER 3 (Puja):\n";
    echo str_repeat("=", 80) . "\n";
    
    $apiQuery = "SELECT 
        j.*,
        a.name as assigned_to_name,
        CASE 
            WHEN j.assigned_to = {$userId3} THEN 1
            WHEN j.assigned_to IS NULL THEN 0
            ELSE 0
        END as is_assigned_to_me
    FROM jobs j
    LEFT JOIN admins a ON j.assigned_to = a.id
    WHERE j.job_id = '{$jobId}'";
    
    $apiResult = $conn->query($apiQuery);
    if ($apiResult && $apiResult->num_rows > 0) {
        $apiJob = $apiResult->fetch_assoc();
        echo "assigned_to: " . ($apiJob['assigned_to'] ?? 'NULL') . "\n";
        echo "assigned_to_name: " . ($apiJob['assigned_to_name'] ?? 'NULL') . "\n";
        echo "is_assigned_to_me: " . ($apiJob['is_assigned_to_me'] ?? 'NULL') . "\n";
        echo "Comparison: j.assigned_to ({$apiJob['assigned_to']}) = {$userId3} ? " . 
             ($apiJob['assigned_to'] == $userId3 ? 'TRUE' : 'FALSE') . "\n\n";
    }
    
    // Test API for user 4 (Tanisha)
    echo "4. API RESPONSE FOR USER 4 (Tanisha):\n";
    echo str_repeat("=", 80) . "\n";
    
    $apiQuery4 = "SELECT 
        j.*,
        a.name as assigned_to_name,
        CASE 
            WHEN j.assigned_to = {$userId4} THEN 1
            WHEN j.assigned_to IS NULL THEN 0
            ELSE 0
        END as is_assigned_to_me
    FROM jobs j
    LEFT JOIN admins a ON j.assigned_to = a.id
    WHERE j.job_id = '{$jobId}'";
    
    $apiResult4 = $conn->query($apiQuery4);
    if ($apiResult4 && $apiResult4->num_rows > 0) {
        $apiJob4 = $apiResult4->fetch_assoc();
        echo "assigned_to: " . ($apiJob4['assigned_to'] ?? 'NULL') . "\n";
        echo "assigned_to_name: " . ($apiJob4['assigned_to_name'] ?? 'NULL') . "\n";
        echo "is_assigned_to_me: " . ($apiJob4['is_assigned_to_me'] ?? 'NULL') . "\n";
        echo "Comparison: j.assigned_to ({$apiJob4['assigned_to']}) = {$userId4} ? " . 
             ($apiJob4['assigned_to'] == $userId4 ? 'TRUE' : 'FALSE') . "\n\n";
    }
    
    // Test actual search API call
    echo "5. ACTUAL SEARCH API CALL (User 3):\n";
    echo str_repeat("=", 80) . "\n";
    $searchUrl = "https://truckmitr.com/truckmitr-app/api/phase2_search_jobs_api.php?user_id=3&query=461";
    echo "URL: {$searchUrl}\n\n";
    
    $searchResponse = file_get_contents($searchUrl);
    $searchData = json_decode($searchResponse, true);
    
    if ($searchData && $searchData['success']) {
        foreach ($searchData['data'] as $job) {
            if ($job['jobId'] == $jobId) {
                echo "Found job in search results:\n";
                echo "jobId: {$job['jobId']}\n";
                echo "assignedTo: " . ($job['assignedTo'] ?? 'NULL') . "\n";
                echo "assignedToName: " . ($job['assignedToName'] ?? 'NULL') . "\n";
                echo "isAssignedToMe: " . ($job['isAssignedToMe'] ? 'TRUE' : 'FALSE') . "\n";
                break;
            }
        }
    }
    
} else {
    echo "Job not found in database\n";
}
?>
