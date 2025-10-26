<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

header('Content-Type: text/html; charset=utf-8');

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

$conn = new mysqli($host, $username, $password, $dbname);

echo "<h1>Testing Leads System - Final Check</h1>";

// 1. Check users registered in last 5 days
echo "<h2>1. Users (Drivers) Registered in Last 5 Days</h2>";
$result = $conn->query("
    SELECT COUNT(*) as count 
    FROM users 
    WHERE role = 'driver' 
    AND Created_at >= DATE_SUB(NOW(), INTERVAL 5 DAY)
");
$row = $result->fetch_assoc();
echo "<p><strong>Total:</strong> {$row['count']} drivers</p>";

// 2. Check assignment distribution
echo "<h2>2. Assignment Distribution</h2>";
$result = $conn->query("
    SELECT 
        u.assigned_to,
        a.name as telecaller_name,
        COUNT(*) as count
    FROM users u
    LEFT JOIN admins a ON u.assigned_to = a.id
    WHERE u.role = 'driver'
    AND u.Created_at >= DATE_SUB(NOW(), INTERVAL 5 DAY)
    GROUP BY u.assigned_to, a.name
");
echo "<table border='1'><tr><th>Telecaller ID</th><th>Telecaller Name</th><th>Assigned Leads</th></tr>";
while ($row = $result->fetch_assoc()) {
    $tcId = $row['assigned_to'] ?: 'NULL';
    $tcName = $row['telecaller_name'] ?: 'Unassigned';
    echo "<tr><td>{$tcId}</td><td>{$tcName}</td><td>{$row['count']}</td></tr>";
}
echo "</table>";

// 3. Check telecallers
echo "<h2>3. Available Telecallers</h2>";
$result = $conn->query("SELECT id, name, email FROM admins WHERE role = 'telecaller'");
echo "<table border='1'><tr><th>ID</th><th>Name</th><th>Email</th></tr>";
while ($row = $result->fetch_assoc()) {
    echo "<tr><td>{$row['id']}</td><td>{$row['name']}</td><td>{$row['email']}</td></tr>";
}
echo "</table>";

// 4. Sample leads data
echo "<h2>4. Sample Leads (First 5 from last 5 days)</h2>";
$result = $conn->query("
    SELECT 
        u.id,
        u.name,
        u.mobile,
        u.assigned_to,
        a.name as telecaller_name,
        u.Created_at
    FROM users u
    LEFT JOIN admins a ON u.assigned_to = a.id
    WHERE u.role = 'driver'
    AND u.Created_at >= DATE_SUB(NOW(), INTERVAL 5 DAY)
    ORDER BY u.Created_at DESC
    LIMIT 5
");
echo "<table border='1'><tr><th>ID</th><th>Name</th><th>Mobile</th><th>Assigned To ID</th><th>Telecaller</th><th>Registered</th></tr>";
while ($row = $result->fetch_assoc()) {
    $tcName = $row['telecaller_name'] ?: 'Unassigned';
    $tcId = $row['assigned_to'] ?: 'NULL';
    echo "<tr><td>{$row['id']}</td><td>{$row['name']}</td><td>{$row['mobile']}</td><td>{$tcId}</td><td>{$tcName}</td><td>{$row['Created_at']}</td></tr>";
}
echo "</table>";

// 5. Test API endpoint
echo "<h2>5. Testing API Endpoint</h2>";
$apiUrl = "http://localhost/api/admin_leads_api.php?status=all";
$response = @file_get_contents($apiUrl);
if ($response) {
    $data = json_decode($response, true);
    if ($data['success']) {
        echo "<p style='color: green;'>✓ API Working!</p>";
        echo "<p><strong>Total Leads:</strong> {$data['total']}</p>";
        echo "<p><strong>Summary:</strong></p>";
        echo "<pre>" . print_r($data['summary'], true) . "</pre>";
        
        if (!empty($data['data'])) {
            echo "<p><strong>First Lead Sample:</strong></p>";
            echo "<pre>" . print_r($data['data'][0], true) . "</pre>";
        }
    } else {
        echo "<p style='color: red;'>✗ API Error: {$data['message']}</p>";
    }
} else {
    echo "<p style='color: red;'>✗ Failed to connect to API</p>";
}

// 6. Check call logs
echo "<h2>6. Call Logs Statistics</h2>";
$result = $conn->query("
    SELECT 
        call_status,
        COUNT(*) as count
    FROM call_logs
    GROUP BY call_status
");
echo "<table border='1'><tr><th>Status</th><th>Count</th></tr>";
while ($row = $result->fetch_assoc()) {
    echo "<tr><td>{$row['call_status']}</td><td>{$row['count']}</td></tr>";
}
echo "</table>";

$conn->close();

echo "<hr><p><strong>Test completed at:</strong> " . date('Y-m-d H:i:s') . "</p>";
?>
