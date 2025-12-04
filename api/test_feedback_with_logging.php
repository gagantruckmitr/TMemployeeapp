<?php
/**
 * Test Feedback Submission with Logging
 * This will help us see exactly what's happening
 */

header('Content-Type: text/html; charset=utf-8');

echo "<h1>Test Feedback Submission with Logging</h1>";

// Test data
$testData = [
    'uniqueId' => 'TM_LOG_TEST_' . time(),
    'jobId' => 'JOB_LOG_TEST_' . time(),
    'callerId' => 1,
    'name' => 'Test Transporter',
    'callStatusFeedback' => 'Connected: Call Back Later - Notes: Testing with logging enabled'
];

echo "<h2>Sending Test Request</h2>";
echo "<pre>";
echo "Data:\n";
print_r($testData);
echo "</pre>";

// Make API call
$url = 'https://truckmitr.com/truckmitr-app/api/phase2_job_brief_api.php';
echo "<p>URL: $url</p>";

$ch = curl_init($url);
curl_setopt($ch, CURLOPT_POST, 1);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($testData));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, [
    'Content-Type: application/json'
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
curl_close($ch);

echo "<h2>Response</h2>";
echo "<p>HTTP Code: <strong>$httpCode</strong></p>";

if ($curlError) {
    echo "<p style='color: red;'>cURL Error: $curlError</p>";
}

echo "<h3>Response Body:</h3>";
echo "<pre>";
echo htmlspecialchars($response);
echo "</pre>";

$responseData = json_decode($response, true);
if ($responseData) {
    echo "<h3>Parsed Response:</h3>";
    echo "<pre>";
    print_r($responseData);
    echo "</pre>";
    
    if (isset($responseData['success']) && $responseData['success']) {
        echo "<p style='color: green; font-weight: bold;'>✓ SUCCESS!</p>";
        
        // Clean up
        if (isset($responseData['data']['id'])) {
            $id = $responseData['data']['id'];
            echo "<p>Cleaning up test data (ID: $id)...</p>";
            
            require_once 'config.php';
            $conn->query("DELETE FROM job_brief_table WHERE id = $id");
            echo "<p style='color: green;'>✓ Test data cleaned up</p>";
        }
    } else {
        echo "<p style='color: red; font-weight: bold;'>✗ FAILED</p>";
        if (isset($responseData['message'])) {
            echo "<p>Error: {$responseData['message']}</p>";
        }
    }
}

echo "<hr>";
echo "<h2>Check PHP Error Log</h2>";
echo "<p>To see detailed logs, check your PHP error log file. The location depends on your server configuration.</p>";
echo "<p>Common locations:</p>";
echo "<ul>";
echo "<li>/var/log/php_errors.log</li>";
echo "<li>/var/log/apache2/error.log</li>";
echo "<li>/var/log/nginx/error.log</li>";
echo "<li>Check php.ini for error_log setting</li>";
echo "</ul>";

echo "<h3>Recent Error Log Entries (if accessible):</h3>";
$errorLogPath = ini_get('error_log');
echo "<p>Error log path: " . ($errorLogPath ?: 'Not set') . "</p>";

if ($errorLogPath && file_exists($errorLogPath) && is_readable($errorLogPath)) {
    $lines = file($errorLogPath);
    $recentLines = array_slice($lines, -50); // Last 50 lines
    echo "<pre style='background: #f5f5f5; padding: 10px; max-height: 400px; overflow-y: scroll;'>";
    foreach ($recentLines as $line) {
        if (strpos($line, 'SAVE JOB BRIEF') !== false || 
            strpos($line, 'uniqueId') !== false ||
            strpos($line, 'jobId') !== false) {
            echo "<strong style='color: blue;'>" . htmlspecialchars($line) . "</strong>";
        } else {
            echo htmlspecialchars($line);
        }
    }
    echo "</pre>";
} else {
    echo "<p style='color: orange;'>Error log not accessible from this script.</p>";
}
?>
