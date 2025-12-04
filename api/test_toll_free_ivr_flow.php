<?php
/**
 * Test Toll-Free IVR Flow
 * Tests the complete flow: IVR call -> Feedback -> History
 */

echo "<h2>Testing Toll-Free IVR Flow</h2>";

// Test 1: Initiate IVR Call with toll-free source
echo "<h3>Test 1: Initiate IVR Call</h3>";
$callData = [
    'exten' => '9082091492',  // Telecaller number
    'number' => '9876543210', // User number
    'caller_id' => '3',       // Telecaller ID
    'contact_id' => 'TM000001', // User TMID
    'contact_type' => 'driver',
    'driver_name' => 'Test Driver',
    'call_source' => 'toll-free'  // This is the key!
];

$ch = curl_init('http://localhost/api/easygo_ivr_api.php?action=initiate_call');
curl_setopt($ch, CURLOPT_POST, true);
curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($callData));
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

$response = curl_exec($ch);
curl_close($ch);

echo "<pre>";
echo "Request: " . json_encode($callData, JSON_PRETTY_PRINT) . "\n\n";
echo "Response: " . json_encode(json_decode($response), JSON_PRETTY_PRINT);
echo "</pre>";

$callResult = json_decode($response, true);
$callLogId = $callResult['call_log_id'] ?? null;

// Test 2: Submit Feedback
if ($callLogId) {
    echo "<h3>Test 2: Submit Feedback</h3>";
    $feedbackData = [
        'caller_id' => 3,
        'lead_id' => 1,  // User ID
        'name' => 'Test Driver',
        'mobile' => '9876543210',
        'feedback' => 'Connected - Interested',
        'remarks' => 'Test feedback from toll-free IVR'
    ];

    $ch = curl_init('http://localhost/api/toll_free_feedback_api.php?action=submit_feedback');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($feedbackData));
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, ['Content-Type: application/json']);

    $response = curl_exec($ch);
    curl_close($ch);

    echo "<pre>";
    echo "Request: " . json_encode($feedbackData, JSON_PRETTY_PRINT) . "\n\n";
    echo "Response: " . json_encode(json_decode($response), JSON_PRETTY_PRINT);
    echo "</pre>";
}

// Test 3: Fetch History
echo "<h3>Test 3: Fetch Toll-Free History</h3>";
$ch = curl_init('http://localhost/api/toll_free_feedback_api.php?action=get_history&caller_id=3&limit=10');
curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);

$response = curl_exec($ch);
curl_close($ch);

echo "<pre>";
echo "Response: " . json_encode(json_decode($response), JSON_PRETTY_PRINT);
echo "</pre>";

// Test 4: Check call_logs table directly
echo "<h3>Test 4: Check call_logs Table</h3>";
require_once 'config.php';

$sql = "SELECT id, caller_id, tc_for, call_source, driver_name, feedback, call_status, call_time 
        FROM call_logs 
        WHERE tc_for = 'toll-free' 
        ORDER BY call_time DESC 
        LIMIT 5";

$result = $conn->query($sql);
if ($result) {
    echo "<table border='1' cellpadding='5'>";
    echo "<tr><th>ID</th><th>Caller ID</th><th>tc_for</th><th>call_source</th><th>Driver Name</th><th>Feedback</th><th>Status</th><th>Time</th></tr>";
    while ($row = $result->fetch_assoc()) {
        echo "<tr>";
        echo "<td>{$row['id']}</td>";
        echo "<td>{$row['caller_id']}</td>";
        echo "<td>{$row['tc_for']}</td>";
        echo "<td>{$row['call_source']}</td>";
        echo "<td>{$row['driver_name']}</td>";
        echo "<td>{$row['feedback']}</td>";
        echo "<td>{$row['call_status']}</td>";
        echo "<td>{$row['call_time']}</td>";
        echo "</tr>";
    }
    echo "</table>";
} else {
    echo "Error: " . $conn->error;
}

echo "<hr>";
echo "<h3>Summary</h3>";
echo "<ul>";
echo "<li>✅ IVR calls with call_source='toll-free' should have tc_for='toll-free'</li>";
echo "<li>✅ Feedback should be saved to call_logs with tc_for='toll-free'</li>";
echo "<li>✅ History API should return only toll-free calls</li>";
echo "<li>✅ All toll-free calls should appear in the toll-free history screen</li>";
echo "</ul>";
?>
