<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'config.php';

echo "<h2>Testing Admin Dashboard API</h2>";

try {
    // Test telecallers count
    $telecallersQuery = "SELECT COUNT(*) as count FROM admins WHERE role = 'telecaller'";
    $result = $conn->query($telecallersQuery);
    $totalTelecallers = $result->fetch_assoc()['count'];
    echo "<p><strong>Total Telecallers:</strong> $totalTelecallers</p>";
    
    // Test managers count
    $managersQuery = "SELECT COUNT(*) as count FROM admins WHERE role = 'manager'";
    $result = $conn->query($managersQuery);
    $totalManagers = $result->fetch_assoc()['count'];
    echo "<p><strong>Total Managers:</strong> $totalManagers</p>";
    
    // Test drivers count
    $driversQuery = "SELECT COUNT(*) as count FROM drivers";
    $result = $conn->query($driversQuery);
    $totalDrivers = $result->fetch_assoc()['count'];
    echo "<p><strong>Total Drivers:</strong> $totalDrivers</p>";
    
    // Test call logs
    $callLogsQuery = "SELECT COUNT(*) as count FROM call_logs";
    $result = $conn->query($callLogsQuery);
    $totalCalls = $result->fetch_assoc()['count'];
    echo "<p><strong>Total Calls:</strong> $totalCalls</p>";
    
    echo "<hr>";
    echo "<h3>Full API Response:</h3>";
    
    // Now test the actual API
    $apiUrl = 'http://localhost/api/admin_dashboard_stats.php';
    $response = file_get_contents($apiUrl);
    echo "<pre>" . htmlspecialchars($response) . "</pre>";
    
    $data = json_decode($response, true);
    if ($data && isset($data['data'])) {
        echo "<h3>Parsed Data:</h3>";
        echo "<pre>" . print_r($data['data'], true) . "</pre>";
    }
    
} catch (Exception $e) {
    echo "<p style='color: red;'>Error: " . $e->getMessage() . "</p>";
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Test Admin Dashboard</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 1000px;
            margin: 50px auto;
            padding: 20px;
            background: #f5f5f5;
        }
        h2, h3 {
            color: #333;
            border-bottom: 2px solid #007bff;
            padding-bottom: 10px;
        }
        pre {
            background: white;
            padding: 15px;
            border-radius: 8px;
            overflow-x: auto;
        }
    </style>
</head>
</html>
