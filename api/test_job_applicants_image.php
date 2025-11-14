<?php
/**
 * Test Job Applicants API - Check Image URL
 */

require_once 'config.php';

// Test with a specific job
$jobId = 'TMJB00418'; // Replace with actual job ID

$url = "https://truckmitr.com/truckmitr-app/api/phase2_job_applicants_api.php?job_id=" . urlencode($jobId);

echo "<h2>Testing Job Applicants API - Image URLs</h2>";
echo "<p><strong>URL:</strong> $url</p>";
echo "<hr>";

$response = file_get_contents($url);
$data = json_decode($response, true);

if ($data && isset($data['applicants'])) {
    echo "<h3>Found " . count($data['applicants']) . " applicants</h3>";
    
    foreach ($data['applicants'] as $index => $applicant) {
        echo "<div style='border: 1px solid #ccc; padding: 15px; margin: 10px 0;'>";
        echo "<h4>Applicant #" . ($index + 1) . ": " . htmlspecialchars($applicant['name']) . "</h4>";
        echo "<p><strong>Driver ID:</strong> " . $applicant['driverId'] . "</p>";
        echo "<p><strong>Driver TMID:</strong> " . htmlspecialchars($applicant['driverTmid']) . "</p>";
        
        if (isset($applicant['profileImageUrl'])) {
            echo "<p><strong>Profile Image URL:</strong> " . htmlspecialchars($applicant['profileImageUrl']) . "</p>";
            echo "<img src='" . htmlspecialchars($applicant['profileImageUrl']) . "' style='max-width: 200px; border: 2px solid #007BFF;' onerror='this.style.border=\"2px solid red\"; this.alt=\"Failed to load\"'>";
        } else {
            echo "<p style='color: red;'><strong>No profileImageUrl field!</strong></p>";
        }
        
        echo "<p><strong>Profile Completion:</strong> " . $applicant['profileCompletion'] . "%</p>";
        echo "</div>";
    }
} else {
    echo "<pre style='background: #f5f5f5; padding: 15px;'>";
    echo "Response:\n";
    print_r($data);
    echo "</pre>";
}
?>
