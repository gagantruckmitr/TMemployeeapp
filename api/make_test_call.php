<?php
/**
 * ONE-CLICK TEST CALL
 * Telecaller: Gagan (6394756798)
 * Transporter: Tarun Test Transport (8383971722)
 * 
 * This will make a REAL IVR call via MyOperator
 */

header('Content-Type: text/html; charset=utf-8');

echo "<h1>📞 Making Test IVR Call...</h1>";
echo "<hr>";

// Call the IVR API
$url = 'http://192.168.29.149/api/ivr_call_api.php?action=initiate_call';

$data = [
    'driver_mobile' => '8383971722',  // Tarun
    'caller_id' => 1,                  // Gagan's ID (will be created if doesn't exist)
    'driver_id' => 1                   // Tarun's ID (will be created if doesn't exist)
];

echo "<h2>📋 Call Details</h2>";
echo "<ul>";
echo "<li><strong>Telecaller:</strong> Gagan (6394756798)</li>";
echo "<li><strong>Transporter:</strong> Tarun Test Transport (8383971722)</li>";
echo "<li><strong>API URL:</strong> $url</li>";
echo "</ul>";

echo "<hr>";
echo "<h2>🚀 Initiating Call...</h2>";

$ch = curl_init($url);
curl_setopt_array($ch, [
    CURLOPT_POST => true,
    CURLOPT_RETURNTRANSFER => true,
    CURLOPT_HTTPHEADER => ['Content-Type: application/json'],
    CURLOPT_POSTFIELDS => json_encode($data),
    CURLOPT_TIMEOUT => 30
]);

$response = curl_exec($ch);
$httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
$error = curl_error($ch);
curl_close($ch);

if ($error) {
    echo "<div style='background: #f8d7da; padding: 20px; border-radius: 5px; border-left: 5px solid #dc3545;'>";
    echo "<h3 style='color: #721c24; margin-top: 0;'>❌ Error</h3>";
    echo "<p>$error</p>";
    echo "</div>";
} else {
    $result = json_decode($response, true);
    
    if ($result && isset($result['success']) && $result['success']) {
        echo "<div style='background: #d4edda; padding: 20px; border-radius: 5px; border-left: 5px solid #28a745;'>";
        echo "<h3 style='color: #155724; margin-top: 0;'>✅ Call Initiated Successfully!</h3>";
        echo "<p><strong>Message:</strong> " . ($result['message'] ?? 'Call initiated') . "</p>";
        
        if (isset($result['data'])) {
            $callData = $result['data'];
            echo "<h4>Call Information:</h4>";
            echo "<ul>";
            echo "<li><strong>Reference ID:</strong> " . ($callData['reference_id'] ?? 'N/A') . "</li>";
            echo "<li><strong>Status:</strong> " . ($callData['status'] ?? 'N/A') . "</li>";
            echo "<li><strong>Driver:</strong> " . ($callData['driver_name'] ?? 'N/A') . " (" . ($callData['driver_number'] ?? 'N/A') . ")</li>";
            echo "<li><strong>Telecaller:</strong> " . ($callData['telecaller_name'] ?? 'N/A') . " (" . ($callData['telecaller_number'] ?? 'N/A') . ")</li>";
            echo "</ul>";
            
            if (isset($callData['call_flow'])) {
                echo "<h4>📱 What Happens Next:</h4>";
                echo "<ol>";
                foreach ($callData['call_flow'] as $step) {
                    echo "<li>$step</li>";
                }
                echo "</ol>";
            }
            
            // Show simulation mode warning if applicable
            if (isset($result['simulation_mode']) && $result['simulation_mode']) {
                echo "<div style='background: #fff3cd; padding: 15px; border-radius: 5px; margin-top: 15px;'>";
                echo "<p><strong>⚠️ Note:</strong> This is a simulated call for testing. Configure MyOperator credentials in .env for real calls.</p>";
                echo "</div>";
            } else {
                echo "<div style='background: #d1ecf1; padding: 15px; border-radius: 5px; margin-top: 15px;'>";
                echo "<p><strong>📞 REAL CALL IN PROGRESS!</strong></p>";
                echo "<p>Tarun's phone (8383971722) should be ringing now...</p>";
                echo "<p>When Tarun picks up, Gagan's phone (6394756798) will ring to connect them.</p>";
                echo "</div>";
            }
        }
        
        echo "</div>";
    } else {
        echo "<div style='background: #f8d7da; padding: 20px; border-radius: 5px; border-left: 5px solid #dc3545;'>";
        echo "<h3 style='color: #721c24; margin-top: 0;'>❌ Call Failed</h3>";
        echo "<p><strong>Error:</strong> " . ($result['error'] ?? 'Unknown error') . "</p>";
        echo "<h4>Response Details:</h4>";
        echo "<pre style='background: #f0f0f0; padding: 10px; border-radius: 5px; overflow-x: auto;'>";
        echo json_encode($result, JSON_PRETTY_PRINT);
        echo "</pre>";
        echo "</div>";
    }
}

echo "<hr>";
echo "<h2>📊 Full API Response</h2>";
echo "<p><strong>HTTP Status:</strong> $httpCode</p>";
echo "<pre style='background: #f0f0f0; padding: 10px; border-radius: 5px; overflow-x: auto;'>";
echo htmlspecialchars($response);
echo "</pre>";

echo "<hr>";
echo "<div style='text-align: center; margin: 20px 0;'>";
echo "<a href='make_test_call.php' style='background: #28a745; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-size: 18px;'>📞 Make Another Test Call</a>";
echo " ";
echo "<a href='check_myoperator_config.php' style='background: #007bff; color: white; padding: 15px 30px; text-decoration: none; border-radius: 5px; display: inline-block; font-size: 18px;'>🔧 Check Configuration</a>";
echo "</div>";

echo "<hr>";
echo "<h2>💡 Tips</h2>";
echo "<ul>";
echo "<li>Make sure both phones (6394756798 and 8383971722) are available</li>";
echo "<li>Check your MyOperator account balance</li>";
echo "<li>Monitor the call in MyOperator dashboard</li>";
echo "<li>Check call_logs table in database for call records</li>";
echo "</ul>";
?>
