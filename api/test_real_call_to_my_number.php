<?php
/**
 * Manual Test - Real TeleCMI Call to Your Number
 * This will make an actual call to 916394756798
 */

require_once 'config.php';

echo "<h1>📞 Real TeleCMI Call Test</h1>";
echo "<p><strong>Testing with your number: 916394756798</strong></p>";
echo "<hr>";

// Your test data
$testDriverMobile = '6394756798'; // Your number (without +91)
$testDriverName = 'Test User (Your Number)';
$callerId = 3; // Pooja

echo "<h2>Step 1: Prepare Test Data</h2>";
echo "<ul>";
echo "<li><strong>Caller:</strong> Pooja (ID: 3)</li>";
echo "<li><strong>Your Number:</strong> +91$testDriverMobile</li>";
echo "<li><strong>Driver Name:</strong> $testDriverName</li>";
echo "</ul>";

// Step 2: Make the API call
echo "<hr>";
echo "<h2>Step 2: Initiate TeleCMI Call</h2>";

$url = 'http://truckmitr.com/api/telecmi_production_api.php?action=click_to_call';

$postData = [
    'caller_id' => $callerId,
    'driver_id' => 'test_' . time(), // Temporary driver ID
    'driver_mobile' => $testDriverMobile
];

echo "<p><strong>Request Data:</strong></p>";
echo "<pre>";
print_r($postData);
echo "</pre>";

$ch = curl_init();
curl_setopt($ch, CURLOPT_URL, $url);
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($postData));
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
curl_setopt($ch, CURLOPT_TIMEOUT, 30);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$curlError = curl_error($ch);
curl_close($ch);

echo "<p><strong>Response (HTTP $httpCode):</strong></p>";

if ($curlError) {
    echo "<p style='color: red;'>❌ cURL Error: $curlError</p>";
} else {
    echo "<pre>";
    $responseData = json_decode($response, true);
    echo json_encode($responseData, JSON_PRETTY_PRINT);
    echo "</pre>";
    
    if ($httpCode == 200 && isset($responseData['success']) && $responseData['success']) {
        $callId = $responseData['data']['call_id'] ?? null;
        
        echo "<p style='color: green;'><strong>✅ Call Initiated Successfully!</strong></p>";
        echo "<p><strong>Call ID:</strong> $callId</p>";
        echo "<p style='background: #ffffcc; padding: 10px; border: 2px solid #ffcc00;'>";
        echo "<strong>📱 YOUR PHONE SHOULD RING NOW!</strong><br>";
        echo "Number: +91$testDriverMobile<br>";
        echo "Answer the call to test the connection.";
        echo "</p>";
        
        // Step 3: Check database entry
        echo "<hr>";
        echo "<h2>Step 3: Verify Database Entry</h2>";
        
        if ($callId) {
            $stmt = $conn->prepare("SELECT * FROM call_logs WHERE reference_id = ?");
            $stmt->bind_param('s', $callId);
            $stmt->execute();
            $result = $stmt->get_result();
            $callLog = $result->fetch_assoc();
            $stmt->close();
            
            if ($callLog) {
                echo "<p style='color: green;'><strong>✅ Call logged to database!</strong></p>";
                echo "<table border='1' cellpadding='8' style='border-collapse: collapse; width: 100%;'>";
                echo "<tr style='background: #f0f0f0;'><th style='width: 30%;'>Field</th><th>Value</th></tr>";
                
                foreach ($callLog as $key => $value) {
                    $highlight = in_array($key, ['reference_id', 'caller_id', 'user_number', 'call_status', 'tc_for']) ? 'background: #ffffcc;' : '';
                    echo "<tr style='$highlight'>";
                    echo "<td><strong>$key</strong></td>";
                    echo "<td>" . htmlspecialchars($value ?? 'NULL') . "</td>";
                    echo "</tr>";
                }
                
                echo "</table>";
                
                // Step 4: Simulate feedback update
                echo "<hr>";
                echo "<h2>Step 4: Simulate Feedback Update</h2>";
                echo "<p>After the call ends, you would submit feedback. Let's simulate that:</p>";
                
                echo "<form method='POST' action='?submit_feedback=1'>";
                echo "<input type='hidden' name='reference_id' value='$callId'>";
                echo "<table>";
                echo "<tr><td><strong>Call Status:</strong></td><td>";
                echo "<select name='call_status'>";
                echo "<option value='completed'>Completed</option>";
                echo "<option value='connected'>Connected</option>";
                echo "<option value='not_connected'>Not Connected</option>";
                echo "<option value='busy'>Busy</option>";
                echo "<option value='no_answer'>No Answer</option>";
                echo "</select>";
                echo "</td></tr>";
                echo "<tr><td><strong>Feedback:</strong></td><td>";
                echo "<input type='text' name='feedback' value='Test call successful' style='width: 300px;'>";
                echo "</td></tr>";
                echo "<tr><td><strong>Remarks:</strong></td><td>";
                echo "<textarea name='remarks' rows='3' style='width: 300px;'>This was a test call to verify TeleCMI integration</textarea>";
                echo "</td></tr>";
                echo "<tr><td><strong>Notes:</strong></td><td>";
                echo "<textarea name='notes' rows='2' style='width: 300px;'>All systems working correctly</textarea>";
                echo "</td></tr>";
                echo "<tr><td><strong>Call Duration (seconds):</strong></td><td>";
                echo "<input type='number' name='call_duration' value='30' style='width: 100px;'>";
                echo "</td></tr>";
                echo "<tr><td colspan='2'>";
                echo "<button type='submit' style='padding: 10px 20px; background: #4CAF50; color: white; border: none; cursor: pointer;'>Submit Feedback</button>";
                echo "</td></tr>";
                echo "</table>";
                echo "</form>";
                
            } else {
                echo "<p style='color: red;'>❌ Call not found in database!</p>";
            }
        }
        
    } else {
        echo "<p style='color: red;'><strong>❌ Call Failed</strong></p>";
        echo "<p>Error: " . ($responseData['message'] ?? 'Unknown error') . "</p>";
    }
}

// Handle feedback submission
if (isset($_GET['submit_feedback']) && $_POST) {
    echo "<hr>";
    echo "<h2>Step 5: Update Feedback</h2>";
    
    $referenceId = $_POST['reference_id'];
    $callStatus = $_POST['call_status'];
    $feedback = $_POST['feedback'];
    $remarks = $_POST['remarks'];
    $notes = $_POST['notes'];
    $callDuration = (int)$_POST['call_duration'];
    
    $updateUrl = 'http://truckmitr.com/api/telecmi_production_api.php?action=update_feedback';
    
    $updateData = [
        'reference_id' => $referenceId,
        'status' => $callStatus,
        'feedback' => $feedback,
        'remarks' => $remarks,
        'notes' => $notes,
        'call_duration' => $callDuration
    ];
    
    echo "<p><strong>Updating with:</strong></p>";
    echo "<pre>";
    print_r($updateData);
    echo "</pre>";
    
    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $updateUrl);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($updateData));
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_FOLLOWLOCATION, true);
    
    $updateResponse = curl_exec($ch);
    $updateHttpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    
    echo "<p><strong>Update Response (HTTP $updateHttpCode):</strong></p>";
    echo "<pre>";
    $updateResponseData = json_decode($updateResponse, true);
    echo json_encode($updateResponseData, JSON_PRETTY_PRINT);
    echo "</pre>";
    
    if ($updateHttpCode == 200 && isset($updateResponseData['success']) && $updateResponseData['success']) {
        echo "<p style='color: green;'><strong>✅ Feedback Updated Successfully!</strong></p>";
        
        // Show updated record
        $stmt = $conn->prepare("SELECT * FROM call_logs WHERE reference_id = ?");
        $stmt->bind_param('s', $referenceId);
        $stmt->execute();
        $result = $stmt->get_result();
        $updatedLog = $result->fetch_assoc();
        $stmt->close();
        
        if ($updatedLog) {
            echo "<p><strong>Updated Database Record:</strong></p>";
            echo "<table border='1' cellpadding='8' style='border-collapse: collapse; width: 100%;'>";
            echo "<tr style='background: #f0f0f0;'><th style='width: 30%;'>Field</th><th>Value</th></tr>";
            
            foreach ($updatedLog as $key => $value) {
                $highlight = in_array($key, ['call_status', 'feedback', 'remarks', 'notes', 'call_duration', 'updated_at']) ? 'background: #ccffcc;' : '';
                echo "<tr style='$highlight'>";
                echo "<td><strong>$key</strong></td>";
                echo "<td>" . htmlspecialchars($value ?? 'NULL') . "</td>";
                echo "</tr>";
            }
            
            echo "</table>";
        }
    } else {
        echo "<p style='color: red;'><strong>❌ Feedback Update Failed</strong></p>";
    }
}

// Show recent TeleCMI calls
echo "<hr>";
echo "<h2>Recent TeleCMI Calls</h2>";

$stmt = $conn->prepare("
    SELECT 
        id, reference_id, caller_id, user_number, driver_name,
        call_status, feedback, remarks, call_duration,
        created_at, updated_at
    FROM call_logs 
    WHERE tc_for = 'TeleCMI' 
    ORDER BY created_at DESC 
    LIMIT 5
");
$stmt->execute();
$result = $stmt->get_result();

if ($result->num_rows > 0) {
    echo "<table border='1' cellpadding='8' style='border-collapse: collapse; width: 100%; font-size: 12px;'>";
    echo "<tr style='background: #f0f0f0;'>";
    echo "<th>ID</th><th>Reference ID</th><th>Number</th><th>Status</th><th>Feedback</th><th>Duration</th><th>Created</th>";
    echo "</tr>";
    
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>" . $row['id'] . "</td>";
        echo "<td>" . htmlspecialchars($row['reference_id']) . "</td>";
        echo "<td>" . htmlspecialchars($row['user_number']) . "</td>";
        echo "<td>" . $row['call_status'] . "</td>";
        echo "<td>" . htmlspecialchars($row['feedback'] ?? '-') . "</td>";
        echo "<td>" . $row['call_duration'] . "s</td>";
        echo "<td>" . $row['created_at'] . "</td>";
        echo "</tr>";
    }
    
    echo "</table>";
} else {
    echo "<p>No TeleCMI calls found yet.</p>";
}

$stmt->close();

echo "<hr>";
echo "<h2>📋 Instructions</h2>";
echo "<ol>";
echo "<li><strong>Click the button above</strong> to initiate the call</li>";
echo "<li><strong>Your phone (+91$testDriverMobile) will ring</strong></li>";
echo "<li><strong>Answer the call</strong> to test the connection</li>";
echo "<li><strong>After the call ends</strong>, fill the feedback form above</li>";
echo "<li><strong>Submit feedback</strong> to see the complete data flow</li>";
echo "<li><strong>Check the database table</strong> to verify all fields are saved</li>";
echo "</ol>";

echo "<hr>";
echo "<p><strong>Test URL:</strong> <code>http://truckmitr.com/api/test_real_call_to_my_number.php</code></p>";
?>
