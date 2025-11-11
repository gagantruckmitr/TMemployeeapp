<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

echo "=== Testing Job Brief API ===\n\n";

// Test 1: Get all job briefs
echo "Test 1: Getting all job briefs...\n";
$response = file_get_contents('http://localhost/truckmitr-app/api/phase2_job_brief_api.php?action=get_job_briefs');
$data = json_decode($response, true);

if ($data && $data['success']) {
    echo "✓ Success! Found " . count($data['data']) . " job briefs\n\n";
    
    // Show first 5 with names
    echo "First 5 job briefs:\n";
    echo str_repeat("-", 80) . "\n";
    foreach (array_slice($data['data'], 0, 5) as $brief) {
        echo "ID: {$brief['id']}\n";
        echo "  TMID: {$brief['uniqueId']}\n";
        echo "  Name: " . ($brief['name'] ?: 'NULL') . "\n";
        echo "  Job ID: {$brief['jobId']}\n";
        echo "  Location: " . ($brief['jobLocation'] ?: 'N/A') . "\n";
        echo "  Created: {$brief['createdAt']}\n\n";
    }
} else {
    echo "❌ Failed: " . ($data['message'] ?? 'Unknown error') . "\n";
}

// Test 2: Get transporters list
echo "\n\nTest 2: Getting transporters list...\n";
$response = file_get_contents('http://localhost/truckmitr-app/api/phase2_job_brief_api.php?action=get_transporters_list');
$data = json_decode($response, true);

if ($data && $data['success']) {
    echo "✓ Success! Found " . count($data['data']) . " transporters\n\n";
    
    // Show first 5
    echo "First 5 transporters:\n";
    echo str_repeat("-", 80) . "\n";
    foreach (array_slice($data['data'], 0, 5) as $transporter) {
        echo "TMID: {$transporter['tmid']}\n";
        echo "  Name: {$transporter['name']}\n";
        echo "  Location: " . ($transporter['location'] ?: 'N/A') . "\n";
        echo "  Call Count: {$transporter['callCount']}\n";
        echo "  Last Call: {$transporter['lastCallDate']}\n\n";
    }
} else {
    echo "❌ Failed: " . ($data['message'] ?? 'Unknown error') . "\n";
}

// Test 3: Get call history for a specific transporter
echo "\n\nTest 3: Getting call history for TM2510RJTR12680...\n";
$response = file_get_contents('http://localhost/truckmitr-app/api/phase2_job_brief_api.php?action=get_call_history&unique_id=TM2510RJTR12680');
$data = json_decode($response, true);

if ($data && $data['success']) {
    echo "✓ Success! Found " . count($data['data']) . " calls\n\n";
    
    foreach ($data['data'] as $call) {
        echo "Call ID: {$call['id']}\n";
        echo "  Name: " . ($call['name'] ?: 'NULL') . "\n";
        echo "  Job ID: {$call['jobId']}\n";
        echo "  Status: {$call['callStatusFeedback']}\n";
        echo "  Created: {$call['createdAt']}\n\n";
    }
} else {
    echo "❌ Failed: " . ($data['message'] ?? 'Unknown error') . "\n";
}
?>
