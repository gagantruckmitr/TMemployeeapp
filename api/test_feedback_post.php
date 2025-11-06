<?php
/**
 * Test POST to feedback API
 */

$url = 'https://truckmitr.com/truckmitr-app/api/phase2_call_feedback_direct.php';

$data = [
    'callerId' => 1,
    'uniqueIdTransporter' => 'TM2510HRTR11180',
    'uniqueIdDriver' => 'TM2511HRTR14722',
    'driverId' => 14722,
    'driverName' => 'Test Driver',
    'transporterName' => 'Test Transporter',
    'feedback' => 'Interview Done',
    'matchStatus' => 'Selected',
    'additionalNotes' => 'Test feedback from PHP',
    'jobId' => 'TMJB00418'
];

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

header('Content-Type: text/html');
echo "<h2>Test Feedback POST</h2>";
echo "<h3>Request Data:</h3>";
echo "<pre>" . json_encode($data, JSON_PRETTY_PRINT) . "</pre>";
echo "<h3>Response (HTTP $httpCode):</h3>";
if ($error) {
    echo "<p style='color:red'>cURL Error: $error</p>";
}
echo "<pre>" . htmlspecialchars($response) . "</pre>";
echo "<hr>";
echo "<p><a href='view_feedback_errors.php'>View Error Log</a></p>";
?>
