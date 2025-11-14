<?php
header('Content-Type: text/html; charset=utf-8');

// Test with a specific job - CHANGE THIS to your actual job ID
$jobId = 'TMJB00418';

$url = "https://truckmitr.com/truckmitr-app/api/phase2_job_applicants_api.php?job_id=" . urlencode($jobId);

echo "<h2>Job Applicants API Response Test</h2>";
echo "<p><strong>Testing URL:</strong> <a href='$url' target='_blank'>$url</a></p>";
echo "<hr>";

$response = @file_get_contents($url);

if ($response === false) {
    echo "<p style='color: red;'>Failed to fetch data from API</p>";
    exit;
}

$data = json_decode($response, true);

if (json_last_error() !== JSON_ERROR_NONE) {
    echo "<p style='color: red;'>JSON decode error: " . json_last_error_msg() . "</p>";
    echo "<pre>" . htmlspecialchars($response) . "</pre>";
    exit;
}

echo "<h3>Response Structure:</h3>";
echo "<pre style='background: #f5f5f5; padding: 15px; overflow-x: auto;'>";
echo htmlspecialchars(json_encode($data, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES));
echo "</pre>";

if (isset($data['data']['applicants'])) {
    echo "<hr>";
    echo "<h3>Profile Image URLs:</h3>";
    foreach ($data['data']['applicants'] as $index => $applicant) {
        echo "<div style='border: 1px solid #ddd; padding: 10px; margin: 10px 0; background: #fff;'>";
        echo "<strong>" . htmlspecialchars($applicant['name']) . "</strong> (ID: " . $applicant['driverId'] . ")<br>";
        
        if (isset($applicant['profileImageUrl']) && !empty($applicant['profileImageUrl'])) {
            echo "✅ <strong>profileImageUrl:</strong> " . htmlspecialchars($applicant['profileImageUrl']) . "<br>";
            echo "<img src='" . htmlspecialchars($applicant['profileImageUrl']) . "' style='max-width: 150px; margin-top: 10px; border: 2px solid #4CAF50;' onerror='this.style.border=\"2px solid red\"; this.alt=\"Image failed to load\"'>";
        } else {
            echo "❌ <strong style='color: red;'>No profileImageUrl field or empty!</strong>";
        }
        echo "</div>";
    }
}
?>
