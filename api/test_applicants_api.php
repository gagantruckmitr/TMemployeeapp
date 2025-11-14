<?php
header('Content-Type: text/plain');

echo "=== TESTING JOB APPLICANTS API ===\n\n";

// Test with a known job
$testJobId = 'TMJB00466';

echo "Testing with job_id: {$testJobId}\n";
echo str_repeat("=", 80) . "\n\n";

$url = "https://truckmitr.com/truckmitr-app/api/phase2_job_applicants_api.php?job_id={$testJobId}";
echo "URL: {$url}\n\n";

$response = @file_get_contents($url);

if ($response === false) {
    echo "ERROR: Failed to connect to API\n";
    $error = error_get_last();
    echo "Error details: " . print_r($error, true) . "\n";
} else {
    echo "Response received:\n";
    echo str_repeat("-", 80) . "\n";
    
    // Try to decode as JSON
    $data = json_decode($response, true);
    
    if ($data === null) {
        echo "Raw response (not valid JSON):\n";
        echo $response . "\n";
    } else {
        echo "JSON Response:\n";
        echo json_encode($data, JSON_PRETTY_PRINT) . "\n";
        
        if (isset($data['success'])) {
            if ($data['success']) {
                echo "\n✓ SUCCESS\n";
                if (isset($data['data']['applicants'])) {
                    echo "Number of applicants: " . count($data['data']['applicants']) . "\n";
                }
            } else {
                echo "\n✗ FAILED\n";
                echo "Error message: " . ($data['message'] ?? 'Unknown error') . "\n";
            }
        }
    }
}

echo "\n" . str_repeat("=", 80) . "\n";
echo "Check server error logs for more details\n";
?>
