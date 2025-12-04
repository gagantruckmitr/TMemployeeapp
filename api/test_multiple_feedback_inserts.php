<?php
/**
 * Test Multiple Feedback Inserts
 * Verify that each call creates a new record instead of updating
 */

header('Content-Type: text/html; charset=utf-8');

echo "<h1>Test Multiple Feedback Inserts</h1>";
echo "<p>Testing that each call creates a NEW record (not update)</p>";

$testTransporter = 'TM_MULTI_TEST_' . time();
$testJob = 'JOB_MULTI_TEST_' . time();

echo "<h2>Test Data</h2>";
echo "<p>Transporter: <strong>$testTransporter</strong></p>";
echo "<p>Job: <strong>$testJob</strong></p>";

$calls = [
    [
        'callStatusFeedback' => 'Not Connected: Ringing / Call Busy',
        'notes' => 'First call attempt'
    ],
    [
        'callStatusFeedback' => 'Not Connected: Switched Off / Not Reachable',
        'notes' => 'Second call attempt'
    ],
    [
        'callStatusFeedback' => 'Connected: Call Back Later - Notes: Will call tomorrow',
        'notes' => 'Third call attempt - connected'
    ],
];

$insertedIds = [];

foreach ($calls as $index => $call) {
    $callNum = $index + 1;
    echo "<h2>Call #$callNum</h2>";
    
    $testData = [
        'uniqueId' => $testTransporter,
        'jobId' => $testJob,
        'callerId' => 1,
        'name' => 'Test Transporter',
        'callStatusFeedback' => $call['callStatusFeedback']
    ];
    
    echo "<pre>";
    print_r($testData);
    echo "</pre>";
    
    $url = 'https://truckmitr.com/truckmitr-app/api/phase2_job_brief_api.php';
    
    $ch = curl_init($url);
    curl_setopt($ch, CURLOPT_POST, 1);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($testData));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    
    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "<p>HTTP Code: <strong>$httpCode</strong></p>";
    
    $responseData = json_decode($response, true);
    if ($responseData && isset($responseData['success']) && $responseData['success']) {
        $id = $responseData['data']['id'];
        $insertedIds[] = $id;
        echo "<p style='color: green;'>✓ Call #$callNum saved successfully (ID: $id)</p>";
    } else {
        echo "<p style='color: red;'>✗ Call #$callNum failed</p>";
        echo "<pre>" . htmlspecialchars($response) . "</pre>";
    }
    
    // Small delay between calls
    usleep(100000); // 0.1 second
}

echo "<hr>";
echo "<h2>Verification</h2>";

if (count($insertedIds) === count($calls)) {
    echo "<p style='color: green; font-weight: bold;'>✓ All " . count($calls) . " calls were saved!</p>";
    
    // Check if all IDs are unique
    $uniqueIds = array_unique($insertedIds);
    if (count($uniqueIds) === count($insertedIds)) {
        echo "<p style='color: green; font-weight: bold;'>✓ All IDs are unique - each call created a NEW record!</p>";
        echo "<p>Inserted IDs: " . implode(', ', $insertedIds) . "</p>";
    } else {
        echo "<p style='color: red; font-weight: bold;'>✗ Some IDs are duplicated - records were updated instead of inserted!</p>";
    }
    
    // Verify in database
    require_once 'config.php';
    
    $query = "SELECT id, call_status_feedback, created_at 
              FROM job_brief_table 
              WHERE unique_id = '$testTransporter' AND job_id = '$testJob'
              ORDER BY created_at ASC";
    
    $result = $conn->query($query);
    
    echo "<h3>Database Records:</h3>";
    if ($result && $result->num_rows > 0) {
        echo "<table border='1' cellpadding='5' cellspacing='0'>";
        echo "<tr><th>ID</th><th>Feedback</th><th>Created At</th></tr>";
        while ($row = $result->fetch_assoc()) {
            echo "<tr>";
            echo "<td>{$row['id']}</td>";
            echo "<td>{$row['call_status_feedback']}</td>";
            echo "<td>{$row['created_at']}</td>";
            echo "</tr>";
        }
        echo "</table>";
        
        if ($result->num_rows === count($calls)) {
            echo "<p style='color: green; font-weight: bold;'>✓ Database has " . $result->num_rows . " records - Perfect!</p>";
        } else {
            echo "<p style='color: red; font-weight: bold;'>✗ Expected " . count($calls) . " records but found " . $result->num_rows . "</p>";
        }
    }
    
    // Cleanup
    echo "<h3>Cleanup</h3>";
    $deleteQuery = "DELETE FROM job_brief_table WHERE unique_id = '$testTransporter' AND job_id = '$testJob'";
    if ($conn->query($deleteQuery)) {
        echo "<p style='color: green;'>✓ Test data cleaned up (deleted " . $conn->affected_rows . " records)</p>";
    }
    
    $conn->close();
} else {
    echo "<p style='color: red; font-weight: bold;'>✗ Some calls failed to save</p>";
}

echo "<hr>";
echo "<h2>Summary</h2>";
echo "<p>This test verifies that:</p>";
echo "<ul>";
echo "<li>✓ Multiple calls to the same transporter/job create separate records</li>";
echo "<li>✓ Each call gets a unique ID</li>";
echo "<li>✓ Records are inserted, not updated</li>";
echo "<li>✓ Call history is properly tracked</li>";
echo "</ul>";
?>
