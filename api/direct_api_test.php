<?php
/**
 * Direct API test - exactly what the app receives
 */

header('Content-Type: text/html; charset=utf-8');

$userId = 3; // Pooja Pal
$targetTmid = 'TM2510HRTR11180';

echo "<h2>Direct API Test for User ID: $userId</h2>";
echo "<h3>Target TMID: $targetTmid</h3>";

// Call the actual API
$apiUrl = "https://truckmitr.com/truckmitr-app/api/phase2_jobs_api.php?user_id=$userId&filter=all";

echo "<p>Calling: <a href='$apiUrl' target='_blank'>$apiUrl</a></p>";

$response = file_get_contents($apiUrl);
$data = json_decode($response, true);

if (!$data || !isset($data['success'])) {
    echo "<p style='color: red;'>Failed to get API response</p>";
    echo "<pre>" . htmlspecialchars($response) . "</pre>";
    exit;
}

echo "<p style='color: green;'>✓ API Response received</p>";
echo "<p>Total jobs: " . count($data['data']) . "</p>";

// Find the target job
$found = false;
foreach ($data['data'] as $job) {
    if ($job['transporterTmid'] === $targetTmid) {
        $found = true;
        echo "<hr>";
        echo "<h3>✓ FOUND JOB FOR $targetTmid</h3>";
        echo "<table border='1' cellpadding='10' style='border-collapse: collapse; width: 100%;'>";
        echo "<tr style='background: #f0f0f0;'><th style='width: 300px;'>Field</th><th>Value</th></tr>";
        
        echo "<tr><td><strong>Job ID</strong></td><td>" . $job['jobId'] . "</td></tr>";
        echo "<tr><td><strong>Job Title</strong></td><td>" . htmlspecialchars($job['jobTitle']) . "</td></tr>";
        echo "<tr><td><strong>Transporter Name</strong></td><td>" . $job['transporterName'] . "</td></tr>";
        echo "<tr><td><strong>Transporter TMID</strong></td><td>" . $job['transporterTmid'] . "</td></tr>";
        
        echo "<tr style='background: yellow;'><td><strong>transporterCreatedAt</strong></td><td><strong style='font-size: 16px;'>" . ($job['transporterCreatedAt'] ?? 'EMPTY/NULL') . "</strong></td></tr>";
        
        echo "<tr><td><strong>Profile Completion</strong></td><td>" . $job['transporterProfileCompletion'] . "%</td></tr>";
        echo "<tr><td><strong>isAssignedToMe</strong></td><td>" . ($job['isAssignedToMe'] ? 'true' : 'false') . "</td></tr>";
        echo "</table>";
        
        $subscriptionDate = $job['transporterCreatedAt'] ?? '';
        
        if (empty($subscriptionDate)) {
            echo "<br><div style='background: #f8d7da; padding: 20px; border: 3px solid #dc3545; border-radius: 10px;'>";
            echo "<h3 style='color: #721c24; margin: 0;'>❌ PROBLEM: transporterCreatedAt is EMPTY</h3>";
            echo "<p style='margin: 10px 0;'>This is why the app shows 'N/A'</p>";
            echo "<p><strong>The API is NOT returning the subscription date!</strong></p>";
            echo "</div>";
        } else {
            echo "<br><div style='background: #d4edda; padding: 20px; border: 3px solid #28a745; border-radius: 10px;'>";
            echo "<h3 style='color: #155724; margin: 0;'>✓ API is returning subscription date</h3>";
            echo "<p style='margin: 10px 0; font-size: 18px;'><strong>Date: $subscriptionDate</strong></p>";
            
            // Format the date
            try {
                $date = new DateTime($subscriptionDate);
                $formatted = $date->format('d M Y');
                echo "<p style='font-size: 20px; color: #155724;'><strong>Should display: Subscribed: $formatted</strong></p>";
            } catch (Exception $e) {
                echo "<p>Could not format date</p>";
            }
            
            echo "</div>";
        }
        
        echo "<br><h3>Full Job Object (JSON):</h3>";
        echo "<pre style='background: #f4f4f4; padding: 15px; overflow: auto; max-height: 400px;'>";
        echo json_encode($job, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE);
        echo "</pre>";
        
        break;
    }
}

if (!$found) {
    echo "<hr>";
    echo "<h3 style='color: red;'>❌ Job for $targetTmid NOT FOUND in API response</h3>";
    echo "<p>Jobs returned for user_id=$userId:</p>";
    echo "<ul>";
    foreach ($data['data'] as $job) {
        echo "<li>" . $job['transporterTmid'] . " - " . $job['transporterName'] . " (Job: " . $job['jobId'] . ")</li>";
    }
    echo "</ul>";
}
?>
