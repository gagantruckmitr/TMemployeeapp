<?php
// Debug script to simulate saving a job brief
$url = 'http://localhost/TMemployeeapp/api/phase2_job_brief_api.php';
$data = [
    'uniqueId' => 'TEST_TMID_999',
    'jobId' => 'TEST_JOB_999',
    'callerId' => 1,
    'callStatusFeedback' => 'Ringing',
    'name' => 'Debug Transporter',
    'jobLocation' => 'Debug City',
    'salaryFixed' => 20000,
    'fastTagRoadKharcha' => 500
];

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
curl_close($ch);

echo "HTTP Code: $httpCode\n";
echo "Response:\n$response\n";
?>
