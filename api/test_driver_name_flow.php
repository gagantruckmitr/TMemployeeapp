<?php
/**
 * Test Complete Driver Name Flow
 * Simulates the exact flow from Flutter app
 */

// Simulate the API request
$_SERVER['REQUEST_METHOD'] = 'POST';
$_GET['action'] = 'initiate_call';

// Simulate Flutter request body
$requestBody = [
    'exten' => '9876543210',
    'number' => '9123456789',
    'caller_id' => '1',
    'contact_id' => '123',
    'contact_type' => 'driver',
    'driver_name' => 'Rajesh Kumar',  // This should be saved
    'duration' => ''
];

// Set the input stream
$GLOBALS['HTTP_RAW_POST_DATA'] = json_encode($requestBody);

echo "=== Testing Driver Name Flow ===\n\n";
echo "Request Body:\n";
echo json_encode($requestBody, JSON_PRETTY_PRINT) . "\n\n";

// Capture the API response
ob_start();
include 'easygo_ivr_api.php';
$response = ob_get_clean();

echo "API Response:\n";
echo $response . "\n\n";

$result = json_decode($response, true);

if ($result && $result['success']) {
    $referenceId = $result['reference_id'];
    $callLogId = $result['call_log_id'];
    
    echo "✅ Call initiated successfully!\n";
    echo "   Reference ID: $referenceId\n";
    echo "   Call Log ID: $callLogId\n\n";
    
    // Now check the database
    require_once 'config.php';
    
    $stmt = $conn->prepare("SELECT driver_name, caller_number, user_number, call_status FROM call_logs WHERE id = ?");
    $stmt->bind_param('i', $callLogId);
    $stmt->execute();
    $result = $stmt->get_result();
    $log = $result->fetch_assoc();
    $stmt->close();
    
    if ($log) {
        echo "Database Record:\n";
        echo "   Driver Name: " . ($log['driver_name'] ?? 'NULL') . "\n";
        echo "   Caller Number: " . $log['caller_number'] . "\n";
        echo "   User Number: " . $log['user_number'] . "\n";
        echo "   Call Status: " . $log['call_status'] . "\n\n";
        
        if ($log['driver_name'] === 'Rajesh Kumar') {
            echo "✅✅✅ SUCCESS! Driver name is saved correctly!\n";
        } else {
            echo "❌ FAILED! Driver name is: " . ($log['driver_name'] ?? 'NULL') . "\n";
            echo "   Expected: Rajesh Kumar\n";
        }
    } else {
        echo "❌ Call log not found in database!\n";
    }
    
    $conn->close();
} else {
    echo "❌ Call initiation failed!\n";
    if (isset($result['error'])) {
        echo "   Error: " . $result['error'] . "\n";
    }
}
?>
