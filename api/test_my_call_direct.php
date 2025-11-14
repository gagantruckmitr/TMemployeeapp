<?php
/**
 * Direct Test - Call to Your Number (Bypassing Driver Check)
 * This will directly insert and test with your number
 */

require_once 'config.php';

echo "<h1>📞 Direct Call Test to Your Number</h1>";
echo "<p><strong>Number: +916394756798</strong></p>";
echo "<hr>";

// Test data
$callerId = 3; // Pooja
$yourNumber = '6394756798';
$yourName = 'Test User (Your Number)';
$driverId = 99999; // Numeric ID for testing

echo "<h2>Step 1: Insert Test Call Directly to Database</h2>";

// Get Pooja's number
$stmt = $conn->prepare("SELECT mobile FROM admins WHERE id = 3");
$stmt->execute();
$result = $stmt->get_result();
$pooja = $result->fetch_assoc();
$stmt->close();

$callerNumber = $pooja['mobile'] ?? '7678361210';

// Format numbers
$formattedYourNumber = '+91' . $yourNumber;
$formattedCallerNumber = '+91' . $callerNumber;

// Generate call ID
$callId = 'telecmi_' . uniqid();

// API response
$apiResponse = json_encode([
    'type' => 'telecmi',
    'status' => 'initiated',
    'message' => 'Test call to your number',
    'timestamp' => date('Y-m-d H:i:s')
]);

// IP
$ipAddress = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';

echo "<p><strong>Call Details:</strong></p>";
echo "<ul>";
echo "<li><strong>Call ID:</strong> $callId</li>";
echo "<li><strong>Caller:</strong> Pooja (ID: 3, Mobile: $formattedCallerNumber)</li>";
echo "<li><strong>Your Number:</strong> $formattedYourNumber</li>";
echo "<li><strong>Driver ID:</strong> $driverId</li>";
echo "</ul>";

// Insert directly
$stmt = $conn->prepare("
    INSERT INTO call_logs (
        caller_id, tc_for, user_id, driver_name,
        call_status, feedback, remarks, notes,
        call_duration, caller_number, user_number,
        call_time, reference_id, api_response,
        created_at, updated_at,
        call_initiated_at, call_completed_at,
        ip_address, recording_url, manual_call_recording_url,
        myoperator_unique_id, webhook_data,
        call_start_time, call_end_time
    ) VALUES (
        ?, 'TeleCMI', ?, ?,
        'pending', NULL, NULL, NULL,
        0, ?, ?,
        NOW(), ?, ?,
        NOW(), NOW(),
        NOW(), NULL,
        ?, NULL, NULL,
        NULL, NULL,
        NOW(), NULL
    )
");

$stmt->bind_param(
    'iisssss',
    $callerId,
    $driverId,
    $yourName,
    $formattedCallerNumber,
    $formattedYourNumber,
    $callId,
    $apiResponse,
    $ipAddress
);

if ($stmt->execute()) {
    $insertId = $stmt->insert_id;
    echo "<p style='color: green;'><strong>✅ Call logged to database! Insert ID: $insertId</strong></p>";
    $stmt->close();
    
    // Show the record
    echo "<hr>";
    echo "<h2>Step 2: Database Record</h2>";
    
    $stmt2 = $conn->prepare("SELECT * FROM call_logs WHERE id = ?");
    $stmt2->bind_param('i', $insertId);
    $stmt2->execute();
    $result2 = $stmt2->get_result();
    $callLog = $result2->fetch_assoc();
    $stmt2->close();
    
    if ($callLog) {
        echo "<table border='1' cellpadding='8' style='border-collapse: collapse; width: 100%;'>";
        echo "<tr style='background: #f0f0f0;'><th style='width: 30%;'>Field</th><th>Value</th></tr>";
        
        foreach ($callLog as $key => $value) {
            $highlight = in_array($key, ['reference_id', 'caller_id', 'user_number', 'call_status', 'tc_for', 'driver_name']) ? 'background: #ffffcc;' : '';
            echo "<tr style='$highlight'>";
            echo "<td><strong>$key</strong></td>";
            echo "<td>" . htmlspecialchars($value ?? 'NULL') . "</td>";
            echo "</tr>";
        }
        
        echo "</table>";
        
        // Feedback form
        echo "<hr>";
        echo "<h2>Step 3: Submit Feedback (Manual)</h2>";
        echo "<p>Fill this form as if you just completed a call:</p>";
        
        echo "<form method='POST' action='?submit=1'>";
        echo "<input type='hidden' name='reference_id' value='$callId'>";
        echo "<table cellpadding='5'>";
        
        echo "<tr><td><strong>Call Status:</strong></td><td>";
        echo "<select name='call_status' style='padding: 5px;'>";
        echo "<option value='completed'>Completed</option>";
        echo "<option value='connected'>Connected</option>";
        echo "<option value='not_connected'>Not Connected</option>";
        echo "<option value='busy'>Busy</option>";
        echo "<option value='no_answer'>No Answer</option>";
        echo "<option value='callback'>Callback</option>";
        echo "<option value='not_reachable'>Not Reachable</option>";
        echo "</select>";
        echo "</td></tr>";
        
        echo "<tr><td><strong>Feedback:</strong></td><td>";
        echo "<input type='text' name='feedback' value='Test call successful' style='width: 400px; padding: 5px;'>";
        echo "</td></tr>";
        
        echo "<tr><td><strong>Remarks:</strong></td><td>";
        echo "<textarea name='remarks' rows='3' style='width: 400px; padding: 5px;'>This was a test call to verify TeleCMI integration with my number</textarea>";
        echo "</td></tr>";
        
        echo "<tr><td><strong>Notes:</strong></td><td>";
        echo "<textarea name='notes' rows='2' style='width: 400px; padding: 5px;'>All fields are being saved correctly in call_logs table</textarea>";
        echo "</td></tr>";
        
        echo "<tr><td><strong>Call Duration (seconds):</strong></td><td>";
        echo "<input type='number' name='call_duration' value='45' style='width: 100px; padding: 5px;'>";
        echo "</td></tr>";
        
        echo "<tr><td colspan='2' style='padding-top: 15px;'>";
        echo "<button type='submit' style='padding: 12px 30px; background: #4CAF50; color: white; border: none; cursor: pointer; font-size: 16px; border-radius: 5px;'>";
        echo "✅ Submit Feedback";
        echo "</button>";
        echo "</td></tr>";
        
        echo "</table>";
        echo "</form>";
    }
    
} else {
    echo "<p style='color: red;'>❌ Failed to insert: " . $stmt->error . "</p>";
    echo "<p><strong>Error Code:</strong> " . $stmt->errno . "</p>";
    echo "<p><strong>SQL State:</strong> " . $conn->sqlstate . "</p>";
    $stmt->close();
    exit;
}

// Handle feedback submission
if (isset($_GET['submit']) && $_POST) {
    echo "<hr>";
    echo "<h2>Step 4: Feedback Update Result</h2>";
    
    $referenceId = $_POST['reference_id'];
    $callStatus = $_POST['call_status'];
    $feedback = $_POST['feedback'];
    $remarks = $_POST['remarks'];
    $notes = $_POST['notes'];
    $callDuration = (int)$_POST['call_duration'];
    
    echo "<p><strong>Updating with:</strong></p>";
    echo "<ul>";
    echo "<li><strong>Call Status:</strong> $callStatus</li>";
    echo "<li><strong>Feedback:</strong> $feedback</li>";
    echo "<li><strong>Remarks:</strong> $remarks</li>";
    echo "<li><strong>Notes:</strong> $notes</li>";
    echo "<li><strong>Duration:</strong> $callDuration seconds</li>";
    echo "</ul>";
    
    $stmt3 = $conn->prepare("
        UPDATE call_logs 
        SET call_status = ?, 
            feedback = ?, 
            remarks = ?, 
            notes = ?,
            call_duration = ?, 
            call_completed_at = NOW(),
            call_end_time = NOW(),
            updated_at = NOW()
        WHERE reference_id = ?
    ");
    
    $stmt3->bind_param('ssssis', $callStatus, $feedback, $remarks, $notes, $callDuration, $referenceId);
    
    if ($stmt3->execute() && $stmt3->affected_rows > 0) {
        echo "<p style='color: green;'><strong>✅ Feedback Updated Successfully!</strong></p>";
        $stmt3->close();
        
        // Show updated record
        $stmt4 = $conn->prepare("SELECT * FROM call_logs WHERE reference_id = ?");
        $stmt4->bind_param('s', $referenceId);
        $stmt4->execute();
        $result4 = $stmt4->get_result();
        $updatedLog = $result4->fetch_assoc();
        $stmt4->close();
        
        if ($updatedLog) {
            echo "<p><strong>Updated Database Record:</strong></p>";
            echo "<table border='1' cellpadding='8' style='border-collapse: collapse; width: 100%;'>";
            echo "<tr style='background: #f0f0f0;'><th style='width: 30%;'>Field</th><th>Value</th></tr>";
            
            foreach ($updatedLog as $key => $value) {
                $highlight = in_array($key, ['call_status', 'feedback', 'remarks', 'notes', 'call_duration', 'call_completed_at', 'call_end_time', 'updated_at']) ? 'background: #ccffcc;' : '';
                echo "<tr style='$highlight'>";
                echo "<td><strong>$key</strong></td>";
                echo "<td>" . htmlspecialchars($value ?? 'NULL') . "</td>";
                echo "</tr>";
            }
            
            echo "</table>";
            
            echo "<hr>";
            echo "<h2 style='color: green;'>🎉 SUCCESS!</h2>";
            echo "<p><strong>All data has been saved correctly to the call_logs table!</strong></p>";
            echo "<ul>";
            echo "<li>✅ Call initiated and logged</li>";
            echo "<li>✅ All automatic fields filled</li>";
            echo "<li>✅ Manual feedback fields updated</li>";
            echo "<li>✅ Timestamps recorded</li>";
            echo "<li>✅ Complete audit trail created</li>";
            echo "</ul>";
        }
        
    } else {
        echo "<p style='color: red;'>❌ Update failed: " . $stmt3->error . "</p>";
        $stmt3->close();
    }
}

// Show all TeleCMI calls
echo "<hr>";
echo "<h2>All TeleCMI Calls in Database</h2>";

$stmt5 = $conn->prepare("
    SELECT 
        id, reference_id, caller_id, user_number, driver_name,
        call_status, feedback, remarks, call_duration,
        created_at, updated_at
    FROM call_logs 
    WHERE tc_for = 'TeleCMI' 
    ORDER BY created_at DESC 
    LIMIT 10
");
$stmt5->execute();
$result5 = $stmt5->get_result();

if ($result5->num_rows > 0) {
    echo "<table border='1' cellpadding='8' style='border-collapse: collapse; width: 100%; font-size: 12px;'>";
    echo "<tr style='background: #f0f0f0;'>";
    echo "<th>ID</th><th>Reference ID</th><th>Number</th><th>Name</th><th>Status</th><th>Feedback</th><th>Duration</th><th>Created</th>";
    echo "</tr>";
    
    while ($row = $result5->fetch_assoc()) {
        $rowHighlight = ($row['user_number'] == $formattedYourNumber) ? 'background: #ffffcc;' : '';
        echo "<tr style='$rowHighlight'>";
        echo "<td>" . $row['id'] . "</td>";
        echo "<td style='font-size: 10px;'>" . htmlspecialchars($row['reference_id']) . "</td>";
        echo "<td>" . htmlspecialchars($row['user_number']) . "</td>";
        echo "<td>" . htmlspecialchars($row['driver_name']) . "</td>";
        echo "<td>" . $row['call_status'] . "</td>";
        echo "<td>" . htmlspecialchars($row['feedback'] ?? '-') . "</td>";
        echo "<td>" . $row['call_duration'] . "s</td>";
        echo "<td style='font-size: 10px;'>" . $row['created_at'] . "</td>";
        echo "</tr>";
    }
    
    echo "</table>";
    echo "<p><em>Your test calls are highlighted in yellow</em></p>";
} else {
    echo "<p>No TeleCMI calls found yet.</p>";
}

$stmt5->close();

echo "<hr>";
echo "<p><strong>✅ Test Complete!</strong></p>";
echo "<p>This test demonstrates the complete flow of data being saved to the call_logs table.</p>";
?>
