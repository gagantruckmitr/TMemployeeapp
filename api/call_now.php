<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>TeleCMI Live Call Test</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        .container {
            background: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        h1 {
            color: #333;
            text-align: center;
        }
        .warning {
            background: #fff3cd;
            border: 2px solid #ffc107;
            padding: 20px;
            border-radius: 5px;
            margin: 20px 0;
        }
        .success {
            background: #d4edda;
            border: 2px solid #28a745;
            padding: 20px;
            border-radius: 5px;
            margin: 20px 0;
        }
        .error {
            background: #f8d7da;
            border: 2px solid #dc3545;
            padding: 20px;
            border-radius: 5px;
            margin: 20px 0;
        }
        .btn {
            display: inline-block;
            padding: 15px 40px;
            background: #4CAF50;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            font-size: 18px;
            text-align: center;
            cursor: pointer;
            border: none;
        }
        .btn:hover {
            background: #45a049;
        }
        .center {
            text-align: center;
            margin: 30px 0;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
        }
        table td, table th {
            padding: 10px;
            border: 1px solid #ddd;
            text-align: left;
        }
        table th {
            background: #f0f0f0;
            font-weight: bold;
        }
        pre {
            background: #f4f4f4;
            padding: 15px;
            border-radius: 5px;
            overflow-x: auto;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>📞 TeleCMI Live Call Test</h1>
        
        <?php
        require_once 'config.php';
        
        if (!isset($_GET['action'])) {
            // Show start button
            ?>
            <div class="warning">
                <h2>⚠️ Ready to Make Real Call</h2>
                <ul>
                    <li><strong>Your phone (+916394756798) will actually ring</strong></li>
                    <li>This uses TeleCMI API with your credentials</li>
                    <li>Call will be logged to database</li>
                    <li>You can submit feedback after</li>
                </ul>
            </div>
            
            <div class="center">
                <a href="?action=call" class="btn">📞 MAKE CALL NOW</a>
            </div>
            <?php
        } elseif ($_GET['action'] == 'call') {
            // Make the actual call
            echo "<h2>Initiating TeleCMI Call...</h2>";
            
            $url = 'http://truckmitr.com/api/telecmi_production_api.php?action=click_to_call';
            
            $postData = [
                'caller_id' => 3,
                'driver_id' => 99999,
                'driver_mobile' => '6394756798'
            ];
            
            echo "<p><strong>Calling TeleCMI API...</strong></p>";
            
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
            
            if ($curlError) {
                echo "<div class='error'>";
                echo "<h2>❌ Error</h2>";
                echo "<p><strong>cURL Error:</strong> " . htmlspecialchars($curlError) . "</p>";
                echo "</div>";
            } else {
                $responseData = json_decode($response, true);
                
                if ($httpCode == 200 && isset($responseData['success']) && $responseData['success']) {
                    $callId = $responseData['data']['call_id'] ?? 'unknown';
                    
                    echo "<div class='success'>";
                    echo "<h2>✅ CALL INITIATED!</h2>";
                    echo "<p style='font-size: 20px; font-weight: bold;'>📱 YOUR PHONE SHOULD BE RINGING NOW!</p>";
                    echo "<p><strong>Call ID:</strong> " . htmlspecialchars($callId) . "</p>";
                    echo "<p><strong>Number:</strong> +916394756798</p>";
                    echo "</div>";
                    
                    // Check database
                    $stmt = $conn->prepare("SELECT * FROM call_logs WHERE reference_id = ? LIMIT 1");
                    $stmt->bind_param('s', $callId);
                    $stmt->execute();
                    $result = $stmt->get_result();
                    $callLog = $result->fetch_assoc();
                    $stmt->close();
                    
                    if ($callLog) {
                        echo "<h3>✅ Call Logged to Database</h3>";
                        echo "<table>";
                        echo "<tr><th>Field</th><th>Value</th></tr>";
                        echo "<tr><td>ID</td><td>" . $callLog['id'] . "</td></tr>";
                        echo "<tr><td>Reference ID</td><td>" . htmlspecialchars($callLog['reference_id']) . "</td></tr>";
                        echo "<tr><td>Caller ID</td><td>" . $callLog['caller_id'] . "</td></tr>";
                        echo "<tr><td>User Number</td><td>" . htmlspecialchars($callLog['user_number']) . "</td></tr>";
                        echo "<tr><td>Call Status</td><td>" . $callLog['call_status'] . "</td></tr>";
                        echo "<tr><td>TC For</td><td>" . htmlspecialchars($callLog['tc_for']) . "</td></tr>";
                        echo "<tr><td>Created At</td><td>" . $callLog['created_at'] . "</td></tr>";
                        echo "</table>";
                        
                        echo "<div class='center'>";
                        echo "<a href='?action=feedback&call_id=" . urlencode($callId) . "' class='btn'>Submit Feedback</a>";
                        echo "</div>";
                    }
                    
                } else {
                    echo "<div class='error'>";
                    echo "<h2>❌ Call Failed</h2>";
                    echo "<p><strong>HTTP Code:</strong> " . $httpCode . "</p>";
                    echo "<p><strong>Error:</strong> " . htmlspecialchars($responseData['message'] ?? 'Unknown error') . "</p>";
                    echo "<pre>" . htmlspecialchars(json_encode($responseData, JSON_PRETTY_PRINT)) . "</pre>";
                    echo "</div>";
                }
            }
            
            echo "<div class='center'>";
            echo "<a href='?' class='btn'>Back</a>";
            echo "</div>";
            
        } elseif ($_GET['action'] == 'feedback') {
            $callId = $_GET['call_id'] ?? '';
            
            if ($_SERVER['REQUEST_METHOD'] == 'POST') {
                // Save feedback
                $status = $_POST['status'];
                $feedback = $conn->real_escape_string($_POST['feedback']);
                $remarks = $conn->real_escape_string($_POST['remarks']);
                $duration = (int)$_POST['duration'];
                
                $sql = "UPDATE call_logs SET 
                    call_status = '$status',
                    feedback = '$feedback',
                    remarks = '$remarks',
                    call_duration = $duration,
                    call_completed_at = NOW(),
                    updated_at = NOW()
                    WHERE reference_id = '$callId'";
                
                if ($conn->query($sql)) {
                    echo "<div class='success'>";
                    echo "<h2>✅ Feedback Saved!</h2>";
                    echo "<p>Call feedback has been saved successfully.</p>";
                    echo "</div>";
                    
                    echo "<div class='center'>";
                    echo "<a href='?' class='btn'>Make Another Call</a>";
                    echo "</div>";
                } else {
                    echo "<div class='error'>";
                    echo "<h2>❌ Error</h2>";
                    echo "<p>Failed to save feedback: " . $conn->error . "</p>";
                    echo "</div>";
                }
            } else {
                // Show feedback form
                ?>
                <h2>Submit Call Feedback</h2>
                <form method="POST">
                    <table>
                        <tr>
                            <td><strong>Call Status:</strong></td>
                            <td>
                                <select name="status" style="padding: 8px; width: 200px;">
                                    <option value="completed">Completed</option>
                                    <option value="connected">Connected</option>
                                    <option value="not_connected">Not Connected</option>
                                    <option value="busy">Busy</option>
                                    <option value="no_answer">No Answer</option>
                                </select>
                            </td>
                        </tr>
                        <tr>
                            <td><strong>Feedback:</strong></td>
                            <td><input type="text" name="feedback" value="Call successful" style="padding: 8px; width: 100%;"></td>
                        </tr>
                        <tr>
                            <td><strong>Remarks:</strong></td>
                            <td><textarea name="remarks" rows="3" style="padding: 8px; width: 100%;">Real TeleCMI call test completed</textarea></td>
                        </tr>
                        <tr>
                            <td><strong>Duration (seconds):</strong></td>
                            <td><input type="number" name="duration" value="30" style="padding: 8px; width: 100px;"></td>
                        </tr>
                    </table>
                    
                    <div class="center">
                        <button type="submit" class="btn">✅ Save Feedback</button>
                    </div>
                </form>
                <?php
            }
        }
        ?>
    </div>
</body>
</html>
