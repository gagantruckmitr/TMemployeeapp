<?php
/**
 * Simple Test - Just Insert and Show
 */

// Enable error display
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

require_once 'config.php';

echo "<h1>Simple Insert Test</h1>";
echo "<hr>";

// Test data
$callerId = 3;
$driverId = 99999;
$yourNumber = '+916394756798';
$callerNumber = '+917678361210';
$yourName = 'Test User';
$callId = 'telecmi_' . uniqid();
$apiResponse = '{"test":"data"}';
$ipAddress = '127.0.0.1';

echo "<p><strong>Attempting to insert:</strong></p>";
echo "<ul>";
echo "<li>caller_id: $callerId</li>";
echo "<li>user_id: $driverId</li>";
echo "<li>user_number: $yourNumber</li>";
echo "<li>reference_id: $callId</li>";
echo "</ul>";

try {
    $sql = "
        INSERT INTO call_logs (
            caller_id, tc_for, user_id, driver_name,
            call_status, call_duration, 
            caller_number, user_number,
            call_time, reference_id, api_response,
            created_at, updated_at,
            call_initiated_at,
            ip_address,
            call_start_time
        ) VALUES (
            ?, 'TeleCMI', ?, ?,
            'pending', 0,
            ?, ?,
            NOW(), ?, ?,
            NOW(), NOW(),
            NOW(),
            ?,
            NOW()
        )
    ";
    
    $stmt = $conn->prepare($sql);
    
    if (!$stmt) {
        throw new Exception("Prepare failed: " . $conn->error);
    }
    
    $stmt->bind_param(
        'iisssss',
        $callerId,
        $driverId,
        $yourName,
        $callerNumber,
        $yourNumber,
        $callId,
        $apiResponse,
        $ipAddress
    );
    
    if ($stmt->execute()) {
        $insertId = $stmt->insert_id;
        echo "<p style='color: green;'><strong>✅ SUCCESS! Insert ID: $insertId</strong></p>";
        
        // Show the record
        $stmt2 = $conn->prepare("SELECT * FROM call_logs WHERE id = ?");
        $stmt2->bind_param('i', $insertId);
        $stmt2->execute();
        $result = $stmt2->get_result();
        $record = $result->fetch_assoc();
        
        echo "<h2>Inserted Record:</h2>";
        echo "<table border='1' cellpadding='5' style='border-collapse: collapse;'>";
        foreach ($record as $key => $value) {
            echo "<tr>";
            echo "<td><strong>$key</strong></td>";
            echo "<td>" . htmlspecialchars($value ?? 'NULL') . "</td>";
            echo "</tr>";
        }
        echo "</table>";
        
        $stmt2->close();
    } else {
        throw new Exception("Execute failed: " . $stmt->error);
    }
    
    $stmt->close();
    
} catch (Exception $e) {
    echo "<p style='color: red;'><strong>❌ ERROR:</strong></p>";
    echo "<pre>" . $e->getMessage() . "</pre>";
    echo "<p><strong>SQL State:</strong> " . $conn->sqlstate . "</p>";
}

echo "<hr>";
echo "<p>Test complete</p>";
?>
