<?php
header('Content-Type: text/plain');
require_once 'config.php';

$uniqueId = 'TM2510BRDR10677';

echo "=== TESTING BOTH APIs FOR USER: {$uniqueId} ===\n\n";

// First, get the user_id from unique_id
$query = "SELECT id, name FROM users WHERE unique_id = '{$uniqueId}'";
$result = $conn->query($query);

if (!$result || $result->num_rows === 0) {
    echo "User not found\n";
    exit;
}

$user = $result->fetch_assoc();
$userId = $user['id'];
$userName = $user['name'];

echo "User: {$userName}\n";
echo "User ID: {$userId}\n";
echo "Unique ID: {$uniqueId}\n\n";

echo str_repeat("=", 80) . "\n";
echo "TEST 1: profile_completion_api.php\n";
echo str_repeat("=", 80) . "\n";

// Test profile_completion_api.php
$url1 = "https://truckmitr.com/truckmitr-app/api/profile_completion_api.php?action=get_profile_details&user_id={$userId}";
$response1 = file_get_contents($url1);
$data1 = json_decode($response1, true);

if ($data1 && $data1['success']) {
    $percentage1 = $data1['data']['profile_completion']['percentage'];
    $filled1 = $data1['data']['profile_completion']['filled_fields'];
    $total1 = $data1['data']['profile_completion']['total_fields'];
    echo "✓ SUCCESS\n";
    echo "Percentage: {$percentage1}%\n";
    echo "Filled: {$filled1} / {$total1}\n";
} else {
    echo "✗ FAILED\n";
    echo "Error: " . ($data1['error'] ?? 'Unknown error') . "\n";
}

echo "\n" . str_repeat("=", 80) . "\n";
echo "TEST 2: phase2_profile_completion_api.php\n";
echo str_repeat("=", 80) . "\n";

// Test phase2_profile_completion_api.php
$url2 = "https://truckmitr.com/truckmitr-app/api/phase2_profile_completion_api.php?user_id={$userId}&user_type=driver";
$response2 = file_get_contents($url2);
$data2 = json_decode($response2, true);

if ($data2 && $data2['success']) {
    $percentage2 = $data2['data']['percentage'];
    $filled2 = $data2['data']['filledFields'];
    $total2 = $data2['data']['totalFields'];
    echo "✓ SUCCESS\n";
    echo "Percentage: {$percentage2}%\n";
    echo "Filled: {$filled2} / {$total2}\n";
} else {
    echo "✗ FAILED\n";
    echo "Error: " . ($data2['message'] ?? 'Unknown error') . "\n";
}

echo "\n" . str_repeat("=", 80) . "\n";
echo "TEST 3: phase2_job_applicants_api.php\n";
echo str_repeat("=", 80) . "\n";

// Find a job this user applied to
$jobQuery = "SELECT j.job_id FROM applyjobs a 
              INNER JOIN jobs j ON a.job_id = j.id 
              WHERE a.driver_id = {$userId} LIMIT 1";
$jobResult = $conn->query($jobQuery);

if ($jobResult && $jobResult->num_rows > 0) {
    $jobRow = $jobResult->fetch_assoc();
    $jobId = $jobRow['job_id'];
    
    echo "Testing with job: {$jobId}\n";
    
    // Test phase2_job_applicants_api.php
    $url3 = "https://truckmitr.com/truckmitr-app/api/phase2_job_applicants_api.php?job_id={$jobId}";
    $response3 = file_get_contents($url3);
    $data3 = json_decode($response3, true);
    
    if ($data3 && $data3['success']) {
        // Find this user in the applicants list
        $applicants = $data3['data']['applicants'];
        $found = false;
        
        foreach ($applicants as $applicant) {
            if ($applicant['driverId'] == $userId) {
                $percentage3 = $applicant['profileCompletion'];
                echo "✓ SUCCESS\n";
                echo "Percentage: {$percentage3}%\n";
                $found = true;
                break;
            }
        }
        
        if (!$found) {
            echo "✗ User not found in applicants list\n";
        }
    } else {
        echo "✗ FAILED\n";
        echo "Error: " . ($data3['message'] ?? 'Unknown error') . "\n";
    }
} else {
    echo "✗ User has not applied to any jobs\n";
}

echo "\n" . str_repeat("=", 80) . "\n";
echo "COMPARISON RESULT\n";
echo str_repeat("=", 80) . "\n";

if (isset($percentage1) && isset($percentage2)) {
    if ($percentage1 == $percentage2) {
        echo "✓ MATCH: Both APIs return {$percentage1}%\n";
        
        if (isset($percentage3) && $percentage3 == $percentage1) {
            echo "✓ ALL THREE APIs MATCH: {$percentage1}%\n";
        } elseif (isset($percentage3)) {
            echo "✗ MISMATCH: Job applicants API returns {$percentage3}%\n";
        }
    } else {
        echo "✗ MISMATCH:\n";
        echo "  - profile_completion_api.php: {$percentage1}%\n";
        echo "  - phase2_profile_completion_api.php: {$percentage2}%\n";
        if (isset($percentage3)) {
            echo "  - phase2_job_applicants_api.php: {$percentage3}%\n";
        }
    }
}
?>
