<?php
/**
 * Test actual jobs API response
 */

// Simulate API call
$userId = isset($_GET['user_id']) ? (int)$_GET['user_id'] : 1;
$filter = isset($_GET['filter']) ? $_GET['filter'] : 'all';

echo "<h2>Testing Jobs API Response</h2>";
echo "User ID: $userId<br>";
echo "Filter: $filter<br><br>";

// Make actual API call
$apiUrl = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/phase2_jobs_api.php?user_id=$userId&filter=$filter";

echo "<h3>API URL:</h3>";
echo "<a href='$apiUrl' target='_blank'>$apiUrl</a><br><br>";

// Fetch the response
$response = file_get_contents($apiUrl);
$data = json_decode($response, true);

if ($data && isset($data['data'])) {
    echo "<h3>Response Status:</h3>";
    echo "Success: " . ($data['success'] ? 'Yes' : 'No') . "<br>";
    echo "Total Jobs: " . count($data['data']) . "<br><br>";
    
    // Find the specific job with TMID TM2511MPTR16401
    $targetTmid = 'TM2511MPTR16401';
    $foundJob = null;
    
    foreach ($data['data'] as $job) {
        if ($job['transporterTmid'] === $targetTmid) {
            $foundJob = $job;
            break;
        }
    }
    
    if ($foundJob) {
        echo "<h3>Found Job for $targetTmid:</h3>";
        echo "<table border='1' cellpadding='5'>";
        echo "<tr><th>Field</th><th>Value</th></tr>";
        echo "<tr><td>Job ID</td><td>" . $foundJob['jobId'] . "</td></tr>";
        echo "<tr><td>Transporter Name</td><td>" . $foundJob['transporterName'] . "</td></tr>";
        echo "<tr><td>Transporter TMID</td><td>" . $foundJob['transporterTmid'] . "</td></tr>";
        echo "<tr><td><strong>transporterCreatedAt</strong></td><td><strong>" . ($foundJob['transporterCreatedAt'] ?? 'NOT SET') . "</strong></td></tr>";
        echo "<tr><td>Profile Completion</td><td>" . $foundJob['transporterProfileCompletion'] . "%</td></tr>";
        echo "</table>";
        
        if (empty($foundJob['transporterCreatedAt'])) {
            echo "<br><span style='color: red; font-size: 16px; font-weight: bold;'>❌ transporterCreatedAt is EMPTY - This is why it shows N/A!</span><br>";
        } else {
            echo "<br><span style='color: green; font-size: 16px; font-weight: bold;'>✓ transporterCreatedAt has value: " . $foundJob['transporterCreatedAt'] . "</span><br>";
        }
    } else {
        echo "<h3>Job with TMID $targetTmid not found in response</h3>";
        echo "Available TMIDs in response:<br>";
        foreach ($data['data'] as $job) {
            echo "- " . $job['transporterTmid'] . " (" . $job['transporterName'] . ")<br>";
        }
    }
    
    echo "<br><h3>Full Response (first job as sample):</h3>";
    echo "<pre>" . json_encode($data['data'][0] ?? [], JSON_PRETTY_PRINT) . "</pre>";
    
} else {
    echo "<h3>Error or No Data:</h3>";
    echo "<pre>" . htmlspecialchars($response) . "</pre>";
}
?>
