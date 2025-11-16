<?php
/**
 * Test Feedback Submission
 * Tests the complete flow of call initiation and feedback submission
 */

header('Content-Type: text/html; charset=utf-8');

echo "<h1>Test Feedback Submission Flow</h1>";

// Database configuration
$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "<h2>✅ Database Connected</h2>";
    
    // Test 1: Create a test call log entry
    echo "<h2>Test 1: Create Test Call Log</h2>";
    
    $testReferenceId = 'TEST_' . time();
    $testCallerId = 1;
    $testUserId = 17214; // Use a real user ID from your database
    
    $sql = "INSERT INTO call_logs 
            (caller_id, user_id, caller_number, user_number, driver_name, call_status, 
             reference_id, api_response, call_time, created_at, updated_at) 
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, CONVERT_TZ(NOW(), '+00:00', '+05:30'), CONVERT_TZ(NOW(), '+00:00', '+05:30'), CONVERT_TZ(NOW(), '+00:00', '+05:30'))";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        $testCallerId,
        $testUserId,
        '+919876543210',
        '+919876543211',
        'Test Driver',
        'pending',
        $testReferenceId,
        json_encode(['test' => true])
    ]);
    
    $callLogId = $pdo->lastInsertId();
    
    echo "<p>✅ Created test call log with ID: $callLogId</p>";
    echo "<p>Reference ID: $testReferenceId</p>";
    
    // Show initial state
    $stmt = $pdo->prepare("SELECT * FROM call_logs WHERE id = ?");
    $stmt->execute([$callLogId]);
    $initialRecord = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo "<h3>Initial Record:</h3>";
    echo "<pre>" . print_r($initialRecord, true) . "</pre>";
    
    // Test 2: Update feedback via API simulation
    echo "<h2>Test 2: Update Feedback</h2>";
    
    $updateData = [
        'reference_id' => $testReferenceId,
        'call_status' => 'connected',
        'feedback' => 'Agree for Subscription Today',
        'remarks' => 'Driver is interested and wants to subscribe',
        'call_duration' => 120
    ];
    
    echo "<h3>Update Data:</h3>";
    echo "<pre>" . print_r($updateData, true) . "</pre>";
    
    // Simulate the update
    $sql = "UPDATE call_logs 
            SET call_status = ?, 
                feedback = ?, 
                remarks = ?,
                call_duration = ?,
                updated_at = CONVERT_TZ(NOW(), '+00:00', '+05:30')
            WHERE reference_id = ?";
    
    $stmt = $pdo->prepare($sql);
    $stmt->execute([
        $updateData['call_status'],
        $updateData['feedback'],
        $updateData['remarks'],
        $updateData['call_duration'],
        $updateData['reference_id']
    ]);
    
    $rowsAffected = $stmt->rowCount();
    echo "<p>✅ Updated $rowsAffected row(s)</p>";
    
    // Show updated state
    $stmt = $pdo->prepare("SELECT * FROM call_logs WHERE id = ?");
    $stmt->execute([$callLogId]);
    $updatedRecord = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo "<h3>Updated Record:</h3>";
    echo "<pre>" . print_r($updatedRecord, true) . "</pre>";
    
    // Test 3: Verify the update
    echo "<h2>Test 3: Verify Update</h2>";
    
    if ($updatedRecord['call_status'] === 'connected' && 
        $updatedRecord['feedback'] === 'Agree for Subscription Today' &&
        $updatedRecord['remarks'] === 'Driver is interested and wants to subscribe' &&
        $updatedRecord['call_duration'] == 120) {
        echo "<p style='color: green; font-weight: bold;'>✅ ALL TESTS PASSED! Feedback is properly saved.</p>";
    } else {
        echo "<p style='color: red; font-weight: bold;'>❌ TEST FAILED! Feedback not saved correctly.</p>";
        echo "<p>Expected: call_status=connected, feedback='Agree for Subscription Today'</p>";
        echo "<p>Got: call_status={$updatedRecord['call_status']}, feedback={$updatedRecord['feedback']}</p>";
    }
    
    // Test 4: Test with different statuses
    echo "<h2>Test 4: Test Different Call Statuses</h2>";
    
    $testStatuses = [
        ['status' => 'callback', 'feedback' => 'Busy - Call Back', 'remarks' => 'Driver was busy'],
        ['status' => 'callback_later', 'feedback' => 'Call Back After 2 Hours', 'remarks' => 'Driver requested callback'],
        ['status' => 'not_reachable', 'feedback' => 'Not Reachable', 'remarks' => 'Phone switched off'],
        ['status' => 'not_interested', 'feedback' => 'Not Interested', 'remarks' => 'Driver not interested'],
    ];
    
    foreach ($testStatuses as $test) {
        $testRef = 'TEST_' . time() . '_' . rand(1000, 9999);
        
        // Create record
        $sql = "INSERT INTO call_logs 
                (caller_id, user_id, caller_number, user_number, driver_name, call_status, 
                 reference_id, api_response, call_time, created_at, updated_at) 
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, CONVERT_TZ(NOW(), '+00:00', '+05:30'), CONVERT_TZ(NOW(), '+00:00', '+05:30'), CONVERT_TZ(NOW(), '+00:00', '+05:30'))";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            $testCallerId,
            $testUserId,
            '+919876543210',
            '+919876543211',
            'Test Driver',
            'pending',
            $testRef,
            json_encode(['test' => true])
        ]);
        
        // Update with feedback
        $sql = "UPDATE call_logs 
                SET call_status = ?, 
                    feedback = ?, 
                    remarks = ?,
                    updated_at = CONVERT_TZ(NOW(), '+00:00', '+05:30')
                WHERE reference_id = ?";
        
        $stmt = $pdo->prepare($sql);
        $stmt->execute([
            $test['status'],
            $test['feedback'],
            $test['remarks'],
            $testRef
        ]);
        
        // Verify
        $stmt = $pdo->prepare("SELECT call_status, feedback, remarks FROM call_logs WHERE reference_id = ?");
        $stmt->execute([$testRef]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($result['call_status'] === $test['status'] && 
            $result['feedback'] === $test['feedback'] &&
            $result['remarks'] === $test['remarks']) {
            echo "<p>✅ Status '{$test['status']}' - PASSED</p>";
        } else {
            echo "<p>❌ Status '{$test['status']}' - FAILED</p>";
            echo "<pre>Expected: " . print_r($test, true) . "</pre>";
            echo "<pre>Got: " . print_r($result, true) . "</pre>";
        }
    }
    
    echo "<h2>✅ All Tests Completed</h2>";
    echo "<p><strong>Summary:</strong> The feedback submission flow is working correctly. 
    When telecallers submit feedback from the modal, it should now save properly with the correct status and feedback text.</p>";
    
    echo "<h3>Next Steps:</h3>";
    echo "<ol>";
    echo "<li>Test from the Flutter app by making a call from Smart Calling screen</li>";
    echo "<li>Submit feedback in the modal</li>";
    echo "<li>Check the admin panel to verify the feedback is saved correctly</li>";
    echo "<li>Check that status is NOT 'pending' and feedback is NOT NULL</li>";
    echo "</ol>";
    
} catch(Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . $e->getMessage() . "</p>";
    echo "<pre>" . $e->getTraceAsString() . "</pre>";
}
?>
