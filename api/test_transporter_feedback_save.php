<?php
/**
 * Test Transporter Feedback Save
 * This test verifies that transporter feedback from dynamic job cards is being saved correctly
 */

require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

echo "<h1>Transporter Feedback Save Test</h1>";
echo "<p>Testing the complete flow of saving transporter feedback from dynamic job cards</p>";

// Test data
$testData = [
    'uniqueId' => 'TM12345',
    'jobId' => 'JOB001',
    'callerId' => 1,
    'name' => 'Test Transporter',
    'callStatusFeedback' => 'Connected: Call Back Later - Notes: Will call back tomorrow at 10 AM',
    'callRecording' => null
];

echo "<h2>Test 1: Save Feedback with Notes</h2>";
echo "<pre>";
echo "Request Data:\n";
print_r($testData);
echo "</pre>";

// Make direct API call (simulating what the app does)
$_SERVER['REQUEST_METHOD'] = 'POST';
$_SERVER['CONTENT_TYPE'] = 'application/json';

// Simulate the POST data
file_put_contents('php://input', json_encode($testData));

// Capture output
ob_start();
try {
    // Include the API file directly
    $originalInput = file_get_contents('php://input');
    
    // Create a temporary file with the test data
    $tempFile = tempnam(sys_get_temp_dir(), 'test_');
    file_put_contents($tempFile, json_encode($testData));
    
    // Mock the input stream
    $_POST = $testData;
    
    // Call the API directly
    require_once 'phase2_job_brief_api.php';
    
    $response = ob_get_clean();
    $httpCode = 200;
    
    // Clean up
    if (file_exists($tempFile)) {
        unlink($tempFile);
    }
} catch (Exception $e) {
    $response = json_encode(['success' => false, 'message' => $e->getMessage()]);
    $httpCode = 500;
    ob_end_clean();
}

echo "<h3>Response (HTTP $httpCode):</h3>";
echo "<pre>";
$responseData = json_decode($response, true);
print_r($responseData);
echo "</pre>";

if ($responseData && $responseData['success']) {
    echo "<p style='color: green;'>✓ Test 1 PASSED: Feedback saved successfully</p>";
    $savedId = $responseData['data']['id'];
    
    // Verify the data was saved correctly
    echo "<h2>Test 2: Verify Saved Data</h2>";
    $query = "SELECT * FROM job_brief_table WHERE id = $savedId";
    $result = $conn->query($query);
    
    if ($result && $result->num_rows > 0) {
        $row = $result->fetch_assoc();
        echo "<pre>";
        print_r($row);
        echo "</pre>";
        
        // Check if all fields are saved correctly
        $checks = [
            'unique_id' => $testData['uniqueId'],
            'job_id' => $testData['jobId'],
            'caller_id' => $testData['callerId'],
            'name' => $testData['name'],
            'call_status_feedback' => $testData['callStatusFeedback']
        ];
        
        $allPassed = true;
        foreach ($checks as $field => $expectedValue) {
            if ($row[$field] == $expectedValue) {
                echo "<p style='color: green;'>✓ Field '$field' matches: {$row[$field]}</p>";
            } else {
                echo "<p style='color: red;'>✗ Field '$field' mismatch. Expected: $expectedValue, Got: {$row[$field]}</p>";
                $allPassed = false;
            }
        }
        
        if ($allPassed) {
            echo "<p style='color: green; font-weight: bold;'>✓ Test 2 PASSED: All fields saved correctly</p>";
        } else {
            echo "<p style='color: red; font-weight: bold;'>✗ Test 2 FAILED: Some fields don't match</p>";
        }
    } else {
        echo "<p style='color: red;'>✗ Test 2 FAILED: Could not retrieve saved data</p>";
    }
    
    // Test 3: Update existing feedback
    echo "<h2>Test 3: Update Existing Feedback</h2>";
    $updateData = [
        'uniqueId' => 'TM12345',
        'jobId' => 'JOB001',
        'callerId' => 1,
        'name' => 'Test Transporter',
        'callStatusFeedback' => 'Connected: Details Received - Notes: Got all job details',
        'callRecording' => 'https://example.com/recording.mp3'
    ];
    
    echo "<pre>";
    echo "Update Request Data:\n";
    print_r($updateData);
    echo "</pre>";
    
    // Make direct API call for update
    $_POST = $updateData;
    
    ob_start();
    try {
        // Reset and call API again
        require 'phase2_job_brief_api.php';
        $response = ob_get_clean();
        $httpCode = 200;
    } catch (Exception $e) {
        $response = json_encode(['success' => false, 'message' => $e->getMessage()]);
        $httpCode = 500;
        ob_end_clean();
    }
    
    echo "<h3>Update Response (HTTP $httpCode):</h3>";
    echo "<pre>";
    $updateResponseData = json_decode($response, true);
    print_r($updateResponseData);
    echo "</pre>";
    
    if ($updateResponseData && $updateResponseData['success'] && $updateResponseData['data']['updated']) {
        echo "<p style='color: green;'>✓ Test 3 PASSED: Feedback updated successfully</p>";
        
        // Verify the update
        $query = "SELECT * FROM job_brief_table WHERE id = $savedId";
        $result = $conn->query($query);
        
        if ($result && $result->num_rows > 0) {
            $row = $result->fetch_assoc();
            echo "<h4>Updated Data:</h4>";
            echo "<pre>";
            print_r($row);
            echo "</pre>";
            
            if ($row['call_status_feedback'] == $updateData['callStatusFeedback'] && 
                $row['call_recording'] == $updateData['callRecording']) {
                echo "<p style='color: green;'>✓ Update verification PASSED</p>";
            } else {
                echo "<p style='color: red;'>✗ Update verification FAILED</p>";
            }
        }
    } else {
        echo "<p style='color: red;'>✗ Test 3 FAILED: Could not update feedback</p>";
    }
    
    // Cleanup
    echo "<h2>Cleanup</h2>";
    $deleteQuery = "DELETE FROM job_brief_table WHERE id = $savedId";
    if ($conn->query($deleteQuery)) {
        echo "<p style='color: green;'>✓ Test data cleaned up successfully</p>";
    } else {
        echo "<p style='color: orange;'>⚠ Could not clean up test data (ID: $savedId)</p>";
    }
    
} else {
    echo "<p style='color: red;'>✗ Test 1 FAILED: Could not save feedback</p>";
    if (isset($responseData['message'])) {
        echo "<p>Error: {$responseData['message']}</p>";
    }
}

echo "<hr>";
echo "<h2>Summary</h2>";
echo "<p>This test verifies that:</p>";
echo "<ul>";
echo "<li>Transporter feedback can be saved with call status and notes</li>";
echo "<li>All fields (uniqueId, jobId, callerId, name, callStatusFeedback) are saved correctly</li>";
echo "<li>Existing feedback can be updated</li>";
echo "<li>Call recordings can be attached to feedback</li>";
echo "</ul>";

$conn->close();
?>
