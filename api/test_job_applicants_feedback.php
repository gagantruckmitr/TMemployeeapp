<?php
/**
 * Test Job Applicants API - Check if feedback is being returned
 */

// Test with a specific job ID
$jobId = 'TMJB00418'; // Replace with actual job ID from your system

$apiUrl = 'http://localhost/api/phase2_job_applicants_api.php?job_id=' . urlencode($jobId);

echo "Testing Job Applicants API\n";
echo "==========================\n\n";
echo "Job ID: $jobId\n";
echo "API URL: $apiUrl\n\n";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $apiUrl);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HEADER, false);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Status: $httpCode\n\n";

if ($response) {
    $data = json_decode($response, true);
    
    if (isset($data['data']['applicants'])) {
        $applicants = $data['data']['applicants'];
        echo "Total Applicants: " . count($applicants) . "\n\n";
        
        foreach ($applicants as $index => $applicant) {
            echo "Applicant #" . ($index + 1) . ":\n";
            echo "  Name: " . ($applicant['name'] ?? 'N/A') . "\n";
            echo "  Driver TMID: " . ($applicant['driverTmid'] ?? 'N/A') . "\n";
            echo "  Transporter TMID: " . ($applicant['transporterTmid'] ?? 'N/A') . "\n";
            echo "  Transporter Name: " . ($applicant['transporterName'] ?? 'N/A') . "\n";
            echo "  Call Feedback: " . ($applicant['callFeedback'] ?? 'NULL') . "\n";
            echo "  Match Status: " . ($applicant['matchStatus'] ?? 'NULL') . "\n";
            echo "  Feedback Notes: " . ($applicant['feedbackNotes'] ?? 'NULL') . "\n";
            echo "\n";
        }
    } else {
        echo "No applicants data found\n";
        echo "Response: " . print_r($data, true) . "\n";
    }
} else {
    echo "Failed to get response from API\n";
}
