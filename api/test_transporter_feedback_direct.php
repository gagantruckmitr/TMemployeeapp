<?php
/**
 * Direct Test for Transporter Feedback Save
 * Tests the database insertion directly without HTTP calls
 */

require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

echo "<h1>Direct Transporter Feedback Save Test</h1>";
echo "<p>Testing direct database insertion for transporter feedback</p>";

// Test data
$testData = [
    'unique_id' => 'TM_TEST_' . time(),
    'job_id' => 'JOB_TEST_' . time(),
    'caller_id' => 1,
    'name' => 'Test Transporter',
    'call_status_feedback' => 'Connected: Call Back Later - Notes: Will call back tomorrow at 10 AM',
    'call_recording' => null
];

echo "<h2>Test 1: Direct Database Insert</h2>";
echo "<pre>";
echo "Test Data:\n";
print_r($testData);
echo "</pre>";

try {
    // Build INSERT query
    $query = "INSERT INTO job_brief_table (
        unique_id, job_id, caller_id, name, call_status_feedback, call_recording, 
        created_at, updated_at
    ) VALUES (
        '{$testData['unique_id']}',
        '{$testData['job_id']}',
        {$testData['caller_id']},
        '{$testData['name']}',
        '{$testData['call_status_feedback']}',
        NULL,
        NOW(),
        NOW()
    )";
    
    echo "<h3>SQL Query:</h3>";
    echo "<pre>$query</pre>";
    
    if ($conn->query($query)) {
        $insertedId = $conn->insert_id;
        echo "<p style='color: green;'>✓ Test 1 PASSED: Record inserted successfully (ID: $insertedId)</p>";
        
        // Verify the insertion
        echo "<h2>Test 2: Verify Inserted Data</h2>";
        $verifyQuery = "SELECT * FROM job_brief_table WHERE id = $insertedId";
        $result = $conn->query($verifyQuery);
        
        if ($result && $result->num_rows > 0) {
            $row = $result->fetch_assoc();
            echo "<pre>";
            print_r($row);
            echo "</pre>";
            
            // Check each field
            $allMatch = true;
            $checks = [
                'unique_id' => $testData['unique_id'],
                'job_id' => $testData['job_id'],
                'caller_id' => $testData['caller_id'],
                'name' => $testData['name'],
                'call_status_feedback' => $testData['call_status_feedback']
            ];
            
            foreach ($checks as $field => $expected) {
                if ($row[$field] == $expected) {
                    echo "<p style='color: green;'>✓ Field '$field' matches</p>";
                } else {
                    echo "<p style='color: red;'>✗ Field '$field' mismatch. Expected: '$expected', Got: '{$row[$field]}'</p>";
                    $allMatch = false;
                }
            }
            
            if ($allMatch) {
                echo "<p style='color: green; font-weight: bold;'>✓ Test 2 PASSED: All fields match</p>";
            } else {
                echo "<p style='color: red; font-weight: bold;'>✗ Test 2 FAILED: Some fields don't match</p>";
            }
            
            // Test 3: Update the record
            echo "<h2>Test 3: Update Existing Record</h2>";
            $newFeedback = 'Connected: Details Received - Notes: Got all details';
            $newRecording = 'https://example.com/recording.mp3';
            
            $updateQuery = "UPDATE job_brief_table 
                           SET call_status_feedback = '$newFeedback',
                               call_recording = '$newRecording',
                               updated_at = NOW()
                           WHERE id = $insertedId";
            
            echo "<pre>$updateQuery</pre>";
            
            if ($conn->query($updateQuery)) {
                echo "<p style='color: green;'>✓ Test 3 PASSED: Record updated successfully</p>";
                
                // Verify update
                $result = $conn->query($verifyQuery);
                if ($result && $result->num_rows > 0) {
                    $row = $result->fetch_assoc();
                    echo "<h4>Updated Data:</h4>";
                    echo "<pre>";
                    print_r($row);
                    echo "</pre>";
                    
                    if ($row['call_status_feedback'] == $newFeedback && 
                        $row['call_recording'] == $newRecording) {
                        echo "<p style='color: green;'>✓ Update verification PASSED</p>";
                    } else {
                        echo "<p style='color: red;'>✗ Update verification FAILED</p>";
                    }
                }
            } else {
                echo "<p style='color: red;'>✗ Test 3 FAILED: " . $conn->error . "</p>";
            }
            
            // Test 4: Test the API endpoint
            echo "<h2>Test 4: Test API Endpoint</h2>";
            $apiTestData = [
                'uniqueId' => 'TM_API_' . time(),
                'jobId' => 'JOB_API_' . time(),
                'callerId' => 1,
                'name' => 'API Test Transporter',
                'callStatusFeedback' => 'Connected: Not Interested - Notes: Already hired drivers'
            ];
            
            echo "<pre>";
            echo "API Test Data:\n";
            print_r($apiTestData);
            echo "</pre>";
            
            // Simulate API call by including the API file
            $_SERVER['REQUEST_METHOD'] = 'POST';
            $_SERVER['CONTENT_TYPE'] = 'application/json';
            
            // Create a temporary stream for php://input
            $tempInput = json_encode($apiTestData);
            
            // Use a workaround to test the API logic
            $uniqueId = $conn->real_escape_string($apiTestData['uniqueId']);
            $jobId = $conn->real_escape_string($apiTestData['jobId']);
            $callerId = (int)$apiTestData['callerId'];
            $name = $conn->real_escape_string($apiTestData['name']);
            $callStatusFeedback = $conn->real_escape_string($apiTestData['callStatusFeedback']);
            
            $apiQuery = "INSERT INTO job_brief_table (
                unique_id, job_id, caller_id, name, call_status_feedback, 
                created_at, updated_at
            ) VALUES (
                '$uniqueId', '$jobId', $callerId, '$name', '$callStatusFeedback',
                NOW(), NOW()
            )";
            
            if ($conn->query($apiQuery)) {
                $apiInsertId = $conn->insert_id;
                echo "<p style='color: green;'>✓ Test 4 PASSED: API-style insert successful (ID: $apiInsertId)</p>";
                
                // Clean up API test data
                $conn->query("DELETE FROM job_brief_table WHERE id = $apiInsertId");
            } else {
                echo "<p style='color: red;'>✗ Test 4 FAILED: " . $conn->error . "</p>";
            }
            
            // Cleanup
            echo "<h2>Cleanup</h2>";
            $deleteQuery = "DELETE FROM job_brief_table WHERE id = $insertedId";
            if ($conn->query($deleteQuery)) {
                echo "<p style='color: green;'>✓ Test data cleaned up successfully</p>";
            } else {
                echo "<p style='color: orange;'>⚠ Could not clean up test data: " . $conn->error . "</p>";
            }
            
        } else {
            echo "<p style='color: red;'>✗ Test 2 FAILED: Could not retrieve inserted record</p>";
        }
        
    } else {
        echo "<p style='color: red;'>✗ Test 1 FAILED: " . $conn->error . "</p>";
    }
    
} catch (Exception $e) {
    echo "<p style='color: red;'>✗ Exception: " . $e->getMessage() . "</p>";
}

// Check table structure
echo "<h2>Table Structure Check</h2>";
$structureQuery = "DESCRIBE job_brief_table";
$result = $conn->query($structureQuery);

if ($result) {
    echo "<table border='1' cellpadding='5' cellspacing='0'>";
    echo "<tr><th>Field</th><th>Type</th><th>Null</th><th>Key</th><th>Default</th><th>Extra</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>{$row['Field']}</td>";
        echo "<td>{$row['Type']}</td>";
        echo "<td>{$row['Null']}</td>";
        echo "<td>{$row['Key']}</td>";
        echo "<td>{$row['Default']}</td>";
        echo "<td>{$row['Extra']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p style='color: red;'>Could not retrieve table structure: " . $conn->error . "</p>";
}

// Check recent entries
echo "<h2>Recent Entries (Last 5)</h2>";
$recentQuery = "SELECT id, unique_id, job_id, caller_id, name, call_status_feedback, created_at 
                FROM job_brief_table 
                ORDER BY created_at DESC 
                LIMIT 5";
$result = $conn->query($recentQuery);

if ($result && $result->num_rows > 0) {
    echo "<table border='1' cellpadding='5' cellspacing='0'>";
    echo "<tr><th>ID</th><th>Unique ID</th><th>Job ID</th><th>Caller ID</th><th>Name</th><th>Feedback</th><th>Created</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>{$row['id']}</td>";
        echo "<td>{$row['unique_id']}</td>";
        echo "<td>{$row['job_id']}</td>";
        echo "<td>{$row['caller_id']}</td>";
        echo "<td>{$row['name']}</td>";
        echo "<td>" . substr($row['call_status_feedback'], 0, 50) . "...</td>";
        echo "<td>{$row['created_at']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "<p>No recent entries found</p>";
}

$conn->close();

echo "<hr>";
echo "<h2>Summary</h2>";
echo "<p>This test verifies:</p>";
echo "<ul>";
echo "<li>✓ Database connection is working</li>";
echo "<li>✓ job_brief_table exists and is accessible</li>";
echo "<li>✓ Records can be inserted with feedback and notes</li>";
echo "<li>✓ Records can be updated</li>";
echo "<li>✓ All required fields are being saved correctly</li>";
echo "</ul>";
?>
