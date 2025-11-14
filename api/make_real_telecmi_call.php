<?php
/**
 * Make Real TeleCMI Call to Your Number
 * This will actually call the TeleCMI API and your phone will ring!
 */

ini_set('display_errors', 1);
error_reporting(E_ALL);

require_once 'config.php';

echo "<h1>📞 Make Real TeleCMI Call</h1>";
echo "<p><strong>This will make an ACTUAL call to your number: +916394756798</strong></p>";
echo "<hr>";

if (!isset($_POST['confirm'])) {
    // Show confirmation form
    echo "<div style='background: #fff3cd; padding: 20px; border: 2px solid #ffc107; border-radius: 10px; margin: 20px 0;'>";
    echo "<h2>⚠️ Important Information</h2>";
    echo "<ul style='font-size: 16px;'>";
    echo "<li><strong>Your phone (+916394756798) will actually ring</strong></li>";
    echo "<li>This uses your TeleCMI account credits</li>";
    echo "<li>The call will be logged to the database</li>";
    echo "<li>You can submit feedback after the call</li>";
    echo "</ul>";
    echo "</div>";
    
    echo "<form method='POST'>";
    echo "<input type='hidden' name='confirm' value='yes'>";
    echo "<div style='text-align: center; margin: 30px 0;'>";
    echo "<button type='submit' style='padding: 20px 50px; background: #4CAF50; color: white; border: none; cursor: pointer; font-size: 20px; border-radius: 10px; box-shadow: 0 4px 6px rgba(0,0,0,0.1);'>";
    echo "📞 YES, MAKE THE CALL NOW";
    echo "</button>";
    echo "</div>";
    echo "</form>";
    
    echo "<p style='text-align: center; color: #666;'><em>Click the button above to initiate the call</em></p>";
    
} else {
    // Make the actual call
    echo "<h2>Initiating TeleCMI Call...</h2>";
    
    $url = 'http://truckmitr.com/api/telecmi_production_api.php?action=click_to_call';
    
    $postData = [
        'caller_id' => 3, // Pooja
        'driver_id' => 99999, // Test driver
        'driver_mobile' => '6394756798' // Your number
    ];
    
    echo "<p><strong>Request Data:</strong></p>";
    echo "<pre>";
    print_r($postData);
    echo "</pre>";
    
    echo "<p>Calling TeleCMI API...</p>";
    
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
    
    echo "<hr>";
    echo "<h2>Response from API</h2>";
    echo "<p><strong>HTTP Code:</strong> $httpCode</p>";
    
    if ($curlError) {
        echo "<p style='color: red;'><strong>❌ cURL Error:</strong> $curlError</p>";
    } else {
        echo "<pre>";
        $responseData = json_decode($response, true);
        echo json_encode($responseData, JSON_PRETTY_PRINT);
        echo "</pre>";
        
        if ($httpCode == 200 && isset($responseData['success']) && $responseData['success']) {
            $callId = $responseData['data']['call_id'] ?? null;
            
            echo "<div style='background: #d4edda; padding: 20px; border: 2px solid #28a745; border-radius: 10px; margin: 20px 0;'>";
            echo "<h2 style='color: #155724;'>✅ CALL INITIATED SUCCESSFULLY!</h2>";
            echo "<p style='font-size: 18px;'><strong>Call ID:</strong> $callId</p>";
            echo "<p style='font-size: 20px; font-weight: bold;'>📱 YOUR PHONE SHOULD BE RINGING NOW!</p>";
            echo "<p>Number: +916394756798</p>";
            echo "<p><em>Answer the call to test the connection</em></p>";
            echo "</div>";
            
            // Check database
            if ($callId) {
                echo "<hr>";
                echo "<h2>Database Entry</h2>";
                
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
                    
                    // Feedback form
                    echo "<hr>";
                    echo "<h2>Submit Feedback After Call</h2>";
                    echo "<p>After the call ends, fill this form:</p>";
                    
                    echo "<form method='POST' action='?feedback=1'>";
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
                    echo "<input type='text' name='feedback' value='Call successful' style='padding: 8px; width: 400px;'>";
                    echo "</td></tr>";
                    
                    echo "<tr><td><strong>Remarks:</strong></td><td>";
                    echo "<textarea name='remarks' rows='3' style='padding: 8px; width: 400px;'>Real TeleCMI call test completed successfully</textarea>";
                    echo "</td></tr>";
                    
                    echo "<tr><td><strong>Notes:</strong></td><td>";
                    echo "<textarea name='notes' rows='2' style='padding: 8px; width: 400px;'>Live call test - all systems working</textarea>";
                    echo "</td></tr>";
                    
                    echo "<tr><td><strong>Call Duration (seconds):</strong></td><td>";
                    echo "<input type='number' name='call_duration' value='30' style='padding: 8px; width: 100px;'>";
                    echo "</td></tr>";
                    
                    echo "<tr><td colspan='2' style='padding-top: 15px;'>";
                    echo "<button type='submit' style='padding: 15px 40px; background: #4CAF50; color: white; border: none; cursor: pointer; font-size: 16px; border-radius: 5px;'>";
                    echo "✅ Submit Feedback";
                    echo "</button>";
                    echo "</td></tr>";
                    echo "</table>";
                    echo "</form>";
                }
            }
            
        } else {
            echo "<div style='background: #f8d7da; padding: 20px; border: 2px solid #dc3545; border-radius: 10px; margin: 20px 0;'>";
            echo "<h2 style='color: #721c24;'>❌ CALL FAILED</h2>";
            echo "<p><strong>Error:</strong> " . ($responseData['message'] ?? 'Unknown error') . "</p>";
            echo "</div>";
        }
    }
    
    echo "<hr>";
    echo "<p><a href='?' style='padding: 10px 20px; background: #2196F3; color: white; text-decoration: none; border-radius: 5px;'>Make Another Call</a></p>";
}

// Handle feedback submission
if (isset($_GET['feedback']) && $_POST) {
    echo "<hr>";
    echo "<h2>Feedback Submitted!</h2>";
    
    $referenceId = $_POST['reference_id'];
    $callStatus = $_POST['call_status'];
    $feedback = $conn->real_escape_string($_POST['feedback']);
    $remarks = $conn->real_escape_string($_POST['remarks']);
    $notes = $conn->real_escape_string($_POST['notes']);
    $callDuration = (int)$_POST['call_duration'];
    
    $sql = "UPDATE call_logs SET
        call_status = '$callStatus',
        feedback = '$feedback',
        remarks = '$remarks',
        notes = '$notes',
        call_duration = $callDuration,
        call_completed_at = NOW(),
        call_end_time = NOW(),
        updated_at = NOW()
        WHERE reference_id = '$referenceId'";
    
    if ($conn->query($sql)) {
        echo "<p style='color: green;'><strong>✅ Feedback Saved Successfully!</strong></p>";
        
        // Show updated record
        $result = $conn->query("SELECT * FROM call_logs WHERE reference_id = '$referenceId'");
        $record = $result->fetch_assoc();
        
        echo "<table border='1' cellpadding='8' style='border-collapse: collapse; width: 100%;'>";
        echo "<tr style='background: #f0f0f0;'><th style='width: 30%;'>Field</th><th>Value</th></tr>";
        foreach ($record as $key => $value) {
            $highlight = in_array($key, ['call_status', 'feedback', 'remarks', 'notes', 'call_duration']) ? 'background: #c8e6c9;' : '';
            echo "<tr style='$highlight'>";
            echo "<td><strong>$key</strong></td>";
            echo "<td>" . htmlspecialchars($value ?? 'NULL') . "</td>";
            echo "</tr>";
        }
        echo "</table>";
        
        echo "<div style='background: #d4edda; padding: 20px; border: 2px solid #28a745; border-radius: 10px; margin: 20px 0;'>";
        echo "<h2 style='color: #155724;'>🎉 COMPLETE SUCCESS!</h2>";
        echo "<p><strong>Live TeleCMI call test completed successfully!</strong></p>";
        echo "<ul>";
        echo "<li>✅ Real call made to your number</li>";
        echo "<li>✅ Call logged to database</li>";
        echo "<li>✅ Feedback submitted</li>";
        echo "<li>✅ All data saved correctly</li>";
        echo "</ul>";
        echo "</div>";
    } else {
        echo "<p style='color: red;'>❌ Failed to save feedback: " . $conn->error . "</p>";
    }
    
    echo "<p><a href='?' style='padding: 10px 20px; background: #2196F3; color: white; text-decoration: none; border-radius: 5px;'>Make Another Call</a></p>";
}

?>
