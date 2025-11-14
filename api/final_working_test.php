<?php
/**
 * Final Working Test - Complete TeleCMI Call Flow
 * Shows exactly how data is saved to call_logs table
 */

ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once 'config.php';

echo "<h1>✅ Final Working Test - TeleCMI Call Flow</h1>";
echo "<p><strong>Your Number: +916394756798</strong></p>";
echo "<hr>";

// Step 1: Insert TeleCMI Call
if (!isset($_GET['step']) || $_GET['step'] == '1') {
    echo "<h2>Step 1: Insert TeleCMI Call (Automatic Fields)</h2>";
    
    $callId = 'telecmi_' . uniqid();
    $callerId = 3; // Pooja
    $driverId = 99999; // Test driver ID
    $driverName = 'Test User (Your Number)';
    $yourNumber = '+916394756798';
    $callerNumber = '+917678361210'; // Pooja's number
    $apiResponse = json_encode([
        'type' => 'telecmi',
        'status' => 'initiated',
        'message' => 'Test call',
        'timestamp' => date('Y-m-d H:i:s')
    ]);
    $ipAddress = $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
    
    $sql = "INSERT INTO call_logs (
        caller_id, tc_for, user_id, driver_name,
        call_status, caller_number, user_number,
        call_time, reference_id, api_response,
        created_at, updated_at, call_initiated_at,
        ip_address, call_start_time, call_duration
    ) VALUES (
        $callerId, 'TeleCMI', $driverId, '$driverName',
        'pending', '$callerNumber', '$yourNumber',
        NOW(), '$callId', '$apiResponse',
        NOW(), NOW(), NOW(),
        '$ipAddress', NOW(), 0
    )";
    
    if ($conn->query($sql)) {
        $insertId = $conn->insert_id;
        echo "<p style='color: green;'><strong>✅ Call Logged! Insert ID: $insertId</strong></p>";
        echo "<p><strong>Reference ID:</strong> $callId</p>";
        
        // Show what was inserted
        $result = $conn->query("SELECT * FROM call_logs WHERE id = $insertId");
        $record = $result->fetch_assoc();
        
        echo "<h3>Automatic Fields (Filled by System):</h3>";
        echo "<table border='1' cellpadding='8' style='border-collapse: collapse; width: 100%;'>";
        echo "<tr style='background: #e8f5e9;'><th style='width: 30%;'>Field</th><th>Value</th><th>Source</th></tr>";
        
        $autoFields = [
            'id' => 'Database auto-increment',
            'caller_id' => 'Pooja\'s ID (3)',
            'tc_for' => 'TeleCMI identifier',
            'user_id' => 'Driver ID',
            'driver_name' => 'Driver name',
            'call_status' => 'Initial status (pending)',
            'caller_number' => 'Pooja\'s phone',
            'user_number' => 'Your phone',
            'call_time' => 'Current timestamp',
            'reference_id' => 'TeleCMI call ID',
            'api_response' => 'TeleCMI API response',
            'created_at' => 'Record creation time',
            'updated_at' => 'Last update time',
            'call_initiated_at' => 'When call started',
            'ip_address' => 'Caller IP address',
            'call_start_time' => 'Call start time',
            'call_duration' => 'Initial duration (0)'
        ];
        
        foreach ($autoFields as $field => $source) {
            $value = $record[$field] ?? 'NULL';
            echo "<tr>";
            echo "<td><strong>$field</strong></td>";
            echo "<td>" . htmlspecialchars($value) . "</td>";
            echo "<td><em>$source</em></td>";
            echo "</tr>";
        }
        echo "</table>";
        
        echo "<h3>Manual Fields (Will be filled by user via feedback modal):</h3>";
        echo "<table border='1' cellpadding='8' style='border-collapse: collapse; width: 100%;'>";
        echo "<tr style='background: #fff3e0;'><th style='width: 30%;'>Field</th><th>Current Value</th><th>Will be filled by</th></tr>";
        
        $manualFields = [
            'feedback' => 'User selection (Interested, Not Interested, etc.)',
            'remarks' => 'User typed comments',
            'notes' => 'User additional notes',
            'call_completed_at' => 'When user submits feedback',
            'call_end_time' => 'When user submits feedback'
        ];
        
        foreach ($manualFields as $field => $description) {
            $value = $record[$field] ?? 'NULL';
            echo "<tr>";
            echo "<td><strong>$field</strong></td>";
            echo "<td>" . htmlspecialchars($value) . "</td>";
            echo "<td><em>$description</em></td>";
            echo "</tr>";
        }
        echo "</table>";
        
        echo "<hr>";
        echo "<h2>Step 2: Submit Feedback (Manual)</h2>";
        echo "<p>Now simulate submitting feedback after the call:</p>";
        
        echo "<form method='GET' action='?step=2'>";
        echo "<input type='hidden' name='step' value='2'>";
        echo "<input type='hidden' name='call_id' value='$insertId'>";
        echo "<input type='hidden' name='reference_id' value='$callId'>";
        
        echo "<table cellpadding='8'>";
        echo "<tr><td><strong>Call Status:</strong></td><td>";
        echo "<select name='call_status' style='padding: 8px; width: 200px;'>";
        echo "<option value='completed'>Completed</option>";
        echo "<option value='connected'>Connected</option>";
        echo "<option value='not_connected'>Not Connected</option>";
        echo "<option value='busy'>Busy</option>";
        echo "<option value='no_answer'>No Answer</option>";
        echo "</select></td></tr>";
        
        echo "<tr><td><strong>Feedback:</strong></td><td>";
        echo "<input type='text' name='feedback' value='Test call successful' style='padding: 8px; width: 400px;'>";
        echo "</td></tr>";
        
        echo "<tr><td><strong>Remarks:</strong></td><td>";
        echo "<textarea name='remarks' rows='3' style='padding: 8px; width: 400px;'>This was a test call to verify TeleCMI integration</textarea>";
        echo "</td></tr>";
        
        echo "<tr><td><strong>Notes:</strong></td><td>";
        echo "<textarea name='notes' rows='2' style='padding: 8px; width: 400px;'>All data is being saved correctly</textarea>";
        echo "</td></tr>";
        
        echo "<tr><td><strong>Call Duration (seconds):</strong></td><td>";
        echo "<input type='number' name='call_duration' value='60' style='padding: 8px; width: 100px;'>";
        echo "</td></tr>";
        
        echo "<tr><td colspan='2' style='padding-top: 15px;'>";
        echo "<button type='submit' style='padding: 15px 40px; background: #4CAF50; color: white; border: none; cursor: pointer; font-size: 16px; border-radius: 5px;'>";
        echo "✅ Submit Feedback";
        echo "</button>";
        echo "</td></tr>";
        echo "</table>";
        echo "</form>";
        
    } else {
        echo "<p style='color: red;'>❌ Insert failed: " . $conn->error . "</p>";
    }
}

// Step 2: Update with feedback
if (isset($_GET['step']) && $_GET['step'] == '2') {
    echo "<h2>Step 2: Feedback Submitted!</h2>";
    
    $callId = (int)$_GET['call_id'];
    $referenceId = $_GET['reference_id'];
    $callStatus = $_GET['call_status'];
    $feedback = $conn->real_escape_string($_GET['feedback']);
    $remarks = $conn->real_escape_string($_GET['remarks']);
    $notes = $conn->real_escape_string($_GET['notes']);
    $callDuration = (int)$_GET['call_duration'];
    
    $sql = "UPDATE call_logs SET
        call_status = '$callStatus',
        feedback = '$feedback',
        remarks = '$remarks',
        notes = '$notes',
        call_duration = $callDuration,
        call_completed_at = NOW(),
        call_end_time = NOW(),
        updated_at = NOW()
        WHERE id = $callId";
    
    if ($conn->query($sql)) {
        echo "<p style='color: green;'><strong>✅ Feedback Updated Successfully!</strong></p>";
        
        // Show complete record
        $result = $conn->query("SELECT * FROM call_logs WHERE id = $callId");
        $record = $result->fetch_assoc();
        
        echo "<h3>Complete Call Record (All Fields):</h3>";
        echo "<table border='1' cellpadding='8' style='border-collapse: collapse; width: 100%; font-size: 14px;'>";
        echo "<tr style='background: #f0f0f0;'><th style='width: 25%;'>Field</th><th>Value</th></tr>";
        
        foreach ($record as $key => $value) {
            $highlight = in_array($key, ['call_status', 'feedback', 'remarks', 'notes', 'call_duration', 'call_completed_at', 'call_end_time', 'updated_at']) ? 'background: #c8e6c9;' : '';
            echo "<tr style='$highlight'>";
            echo "<td><strong>$key</strong></td>";
            echo "<td>" . htmlspecialchars($value ?? 'NULL') . "</td>";
            echo "</tr>";
        }
        echo "</table>";
        
        echo "<p><em>Green highlighted fields were updated by user feedback</em></p>";
        
        echo "<hr>";
        echo "<h2 style='color: green;'>🎉 SUCCESS!</h2>";
        echo "<p><strong>Complete call flow demonstrated:</strong></p>";
        echo "<ul style='font-size: 16px;'>";
        echo "<li>✅ Call initiated with automatic fields</li>";
        echo "<li>✅ User feedback submitted manually</li>";
        echo "<li>✅ All data saved to call_logs table</li>";
        echo "<li>✅ Complete audit trail created</li>";
        echo "</ul>";
        
        echo "<p><a href='?step=1' style='padding: 10px 20px; background: #2196F3; color: white; text-decoration: none; border-radius: 5px;'>Run Test Again</a></p>";
    } else {
        echo "<p style='color: red;'>❌ Update failed: " . $conn->error . "</p>";
    }
}

// Show recent TeleCMI calls
echo "<hr>";
echo "<h2>Recent TeleCMI Calls</h2>";
$result = $conn->query("SELECT id, reference_id, user_number, driver_name, call_status, feedback, call_duration, created_at FROM call_logs WHERE tc_for = 'TeleCMI' ORDER BY created_at DESC LIMIT 5");

if ($result && $result->num_rows > 0) {
    echo "<table border='1' cellpadding='8' style='border-collapse: collapse; width: 100%; font-size: 12px;'>";
    echo "<tr style='background: #f0f0f0;'><th>ID</th><th>Reference ID</th><th>Number</th><th>Name</th><th>Status</th><th>Feedback</th><th>Duration</th><th>Created</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
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
} else {
    echo "<p>No TeleCMI calls found yet.</p>";
}

echo "<hr>";
echo "<p><strong>✅ Test Complete!</strong> This demonstrates exactly how data flows into the call_logs table.</p>";
?>
