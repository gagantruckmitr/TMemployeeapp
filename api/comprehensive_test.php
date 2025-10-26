<?php
/**
 * Comprehensive System Test
 * Tests all critical components
 */
header('Content-Type: text/html; charset=utf-8');

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

echo "<h1>TruckMitr System Comprehensive Test</h1>";
echo "<style>
    body { font-family: Arial, sans-serif; padding: 20px; background: #f5f5f5; }
    .test { background: white; padding: 15px; margin: 10px 0; border-radius: 8px; box-shadow: 0 2 px 4px rgba(0,0,0,0.1); }
    .success { color: #10b981; font-weight: bold; }
    .error { color: #ef4444; font-weight: bold; }
    .warning { color: #f59e0b; font-weight: bold; }
    pre { background: #f9fafb; padding: 10px; border-radius: 4px; overflow-x: auto; }
    h2 { color: #1f2937; border-bottom: 2px solid #4f46e5; padding-bottom: 5px; }
</style>";

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "<div class='test'><span class='success'>✓ Database Connection: SUCCESS</span></div>";
} catch(PDOException $e) {
    echo "<div class='test'><span class='error'>✗ Database Connection: FAILED</span><br>";
    echo "Error: " . $e->getMessage() . "</div>";
    exit;
}

// Test 1: Check Tables
echo "<div class='test'><h2>1. Database Tables</h2>";
$tables = ['users', 'admins', 'call_logs', 'payments'];
foreach ($tables as $table) {
    $stmt = $pdo->query("SHOW TABLES LIKE '$table'");
    if ($stmt->rowCount() > 0) {
        $countStmt = $pdo->query("SELECT COUNT(*) as count FROM $table");
        $count = $countStmt->fetch(PDO::FETCH_ASSOC)['count'];
        echo "<span class='success'>✓ $table</span> - $count records<br>";
    } else {
        echo "<span class='warning'>⚠ $table</span> - Table does not exist<br>";
    }
}
echo "</div>";

// Test 2: Check Users
echo "<div class='test'><h2>2. Users & Telecallers</h2>";
$stmt = $pdo->query("SELECT COUNT(*) as count FROM users WHERE role = 'driver'");
$driverCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
echo "Drivers: <strong>$driverCount</strong><br>";

$stmt = $pdo->query("SELECT COUNT(*) as count FROM admins WHERE role = 'telecaller'");
$telecallerCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
echo "Telecallers: <strong>$telecallerCount</strong><br>";

if ($telecallerCount > 0) {
    $stmt = $pdo->query("SELECT id, name, mobile FROM admins WHERE role = 'telecaller' LIMIT 5");
    $telecallers = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo "<pre>";
    print_r($telecallers);
    echo "</pre>";
}
echo "</div>";

// Test 3: Check Call Logs
echo "<div class='test'><h2>3. Call Logs</h2>";
$stmt = $pdo->query("SELECT COUNT(*) as count FROM call_logs");
$callLogCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
echo "Total Call Logs: <strong>$callLogCount</strong><br>";

$today = date('Y-m-d');
$stmt = $pdo->prepare("SELECT COUNT(*) as count FROM call_logs WHERE DATE(call_time) = ?");
$stmt->execute([$today]);
$todayCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
echo "Today's Calls: <strong>$todayCount</strong><br>";

if ($todayCount > 0) {
    $stmt = $pdo->prepare("SELECT call_status, COUNT(*) as count FROM call_logs WHERE DATE(call_time) = ? GROUP BY call_status");
    $stmt->execute([$today]);
    $statusBreakdown = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo "<strong>Today's Status Breakdown:</strong><br>";
    echo "<pre>";
    print_r($statusBreakdown);
    echo "</pre>";
} else {
    echo "<span class='warning'>⚠ No calls logged today. Run seed_test_data.php to add sample data.</span><br>";
}
echo "</div>";

// Test 4: Dashboard API
echo "<div class='test'><h2>4. Dashboard API Test</h2>";
if ($telecallerCount > 0) {
    $stmt = $pdo->query("SELECT id FROM admins WHERE role = 'telecaller' LIMIT 1");
    $telecaller = $stmt->fetch(PDO::FETCH_ASSOC);
    $callerId = $telecaller['id'];
    
    $apiUrl = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/dashboard_stats_api.php?caller_id=$callerId";
    echo "Testing: <a href='$apiUrl' target='_blank'>$apiUrl</a><br>";
    
    $response = @file_get_contents($apiUrl);
    if ($response) {
        $data = json_decode($response, true);
        if ($data['success']) {
            echo "<span class='success'>✓ Dashboard API: SUCCESS</span><br>";
            echo "<pre>";
            print_r($data['data']);
            echo "</pre>";
        } else {
            echo "<span class='error'>✗ Dashboard API returned error</span><br>";
            echo "<pre>$response</pre>";
        }
    } else {
        echo "<span class='error'>✗ Could not reach Dashboard API</span><br>";
    }
} else {
    echo "<span class='warning'>⚠ No telecaller found to test</span><br>";
}
echo "</div>";

// Test 5: Fresh Leads API
echo "<div class='test'><h2>5. Fresh Leads API Test</h2>";
if ($telecallerCount > 0 && $driverCount > 0) {
    $apiUrl = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/fresh_leads_api.php?action=fresh_leads&caller_id=$callerId&limit=5";
    echo "Testing: <a href='$apiUrl' target='_blank'>$apiUrl</a><br>";
    
    $response = @file_get_contents($apiUrl);
    if ($response) {
        $data = json_decode($response, true);
        if ($data['success']) {
            echo "<span class='success'>✓ Fresh Leads API: SUCCESS</span><br>";
            echo "Found <strong>" . $data['count'] . "</strong> fresh leads<br>";
            if ($data['count'] > 0) {
                echo "<pre>";
                print_r(array_slice($data['data'], 0, 2)); // Show first 2
                echo "</pre>";
            }
        } else {
            echo "<span class='error'>✗ Fresh Leads API returned error</span><br>";
            echo "<pre>$response</pre>";
        }
    } else {
        echo "<span class='error'>✗ Could not reach Fresh Leads API</span><br>";
    }
} else {
    echo "<span class='warning'>⚠ Need both telecallers and drivers to test</span><br>";
}
echo "</div>";

// Test 6: MyOperator Configuration
echo "<div class='test'><h2>6. MyOperator IVR Configuration</h2>";
$envFile = __DIR__ . '/../.env';
if (file_exists($envFile)) {
    $envContent = file_get_contents($envFile);
    $hasMyOperator = strpos($envContent, 'MYOPERATOR_COMPANY_ID') !== false;
    
    if ($hasMyOperator) {
        preg_match('/MYOPERATOR_COMPANY_ID=(.+)/', $envContent, $matches);
        $companyId = trim($matches[1] ?? '');
        
        if ($companyId && $companyId !== 'your_company_id') {
            echo "<span class='success'>✓ MyOperator Configured</span><br>";
            echo "Company ID: <strong>" . substr($companyId, 0, 8) . "...</strong><br>";
        } else {
            echo "<span class='warning'>⚠ MyOperator Not Configured</span><br>";
            echo "IVR calls will run in SIMULATION MODE<br>";
            echo "To enable real calls, update .env file with your MyOperator credentials<br>";
        }
    } else {
        echo "<span class='warning'>⚠ MyOperator settings not found in .env</span><br>";
    }
} else {
    echo "<span class='warning'>⚠ .env file not found</span><br>";
}
echo "</div>";

// Test 7: Recommendations
echo "<div class='test'><h2>7. Recommendations</h2>";
if ($todayCount == 0) {
    echo "<span class='warning'>⚠ No call data for today</span><br>";
    echo "→ Run <a href='seed_test_data.php' target='_blank'>seed_test_data.php</a> to add sample call logs<br>";
}

if ($driverCount < 10) {
    echo "<span class='warning'>⚠ Low number of drivers ($driverCount)</span><br>";
    echo "→ Import more driver data for better testing<br>";
}

if ($telecallerCount == 0) {
    echo "<span class='error'>✗ No telecallers found</span><br>";
    echo "→ Create telecaller accounts in admins table<br>";
}

echo "</div>";

echo "<div class='test'>";
echo "<h2>Quick Actions</h2>";
echo "<a href='seed_test_data.php' style='display:inline-block; padding:10px 20px; background:#4f46e5; color:white; text-decoration:none; border-radius:6px; margin:5px;'>Add Sample Call Data</a>";
echo "<a href='test_dashboard_debug.php?caller_id=$callerId' style='display:inline-block; padding:10px 20px; background:#10b981; color:white; text-decoration:none; border-radius:6px; margin:5px;'>Debug Dashboard</a>";
echo "<a href='dashboard_stats_api.php?caller_id=$callerId' style='display:inline-block; padding:10px 20px; background:#f59e0b; color:white; text-decoration:none; border-radius:6px; margin:5px;'>View Dashboard API</a>";
echo "</div>";

?>
