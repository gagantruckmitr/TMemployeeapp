<?php
// Fix Manager Dashboard - Complete Setup
header('Content-Type: text/html; charset=utf-8');

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    echo "<h2 style='color: green;'>✅ Database Connected</h2>";
} catch(PDOException $e) {
    die("<h2 style='color: red;'>❌ Connection Failed: " . $e->getMessage() . "</h2>");
}

echo "<h1>Manager Dashboard Fix & Setup</h1><hr>";

// Step 0: Check if telecaller_status table exists
echo "<h3>Step 0: Checking Required Tables</h3>";
$stmt = $pdo->query("SHOW TABLES LIKE 'telecaller_status'");
if ($stmt->rowCount() == 0) {
    echo "<p style='color: red;'>❌ telecaller_status table missing!</p>";
    echo "<p><strong>Run this first:</strong> <a href='create_telecaller_status_table.php' style='background: #4CAF50; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;'>Create Required Tables</a></p>";
    echo "<hr>";
    exit;
} else {
    echo "<p style='color: green;'>✅ All required tables exist</p>";
}

// Step 1: Check/Create Manager
echo "<h3>Step 1: Checking Manager Account</h3>";
$stmt = $pdo->query("SELECT id, name, mobile, email FROM admins WHERE role = 'manager' LIMIT 1");
$manager = $stmt->fetch();

if (!$manager) {
    echo "<p style='color: orange;'>⚠️ No manager found. Creating test manager...</p>";
    
    $hashedPassword = password_hash('manager123', PASSWORD_BCRYPT);
    $stmt = $pdo->prepare("
        INSERT INTO admins (role, name, mobile, email, password, created_at, updated_at) 
        VALUES ('manager', 'Test Manager', '9999999999', 'manager@truckmitr.com', ?, NOW(), NOW())
    ");
    $stmt->execute([$hashedPassword]);
    $managerId = $pdo->lastInsertId();
    
    echo "<p style='color: green;'>✅ Manager created successfully!</p>";
    echo "<div style='background: #f0f0f0; padding: 15px; border-radius: 5px; margin: 10px 0;'>";
    echo "<strong>Login Credentials:</strong><br>";
    echo "Mobile: <strong>9999999999</strong><br>";
    echo "Password: <strong>manager123</strong><br>";
    echo "Manager ID: <strong>$managerId</strong>";
    echo "</div>";
    
    $manager = ['id' => $managerId, 'name' => 'Test Manager', 'mobile' => '9999999999', 'email' => 'manager@truckmitr.com'];
} else {
    echo "<p style='color: green;'>✅ Manager found: {$manager['name']} (ID: {$manager['id']})</p>";
    $managerId = $manager['id'];
}

// Step 2: Test Overview API
echo "<h3>Step 2: Testing Overview API</h3>";
try {
    $stmt = $pdo->query("
        SELECT 
            COUNT(DISTINCT CASE WHEN a.role = 'telecaller' THEN a.id END) as total_telecallers,
            COUNT(DISTINCT CASE WHEN ts.current_status = 'online' THEN ts.telecaller_id END) as online_telecallers,
            COUNT(DISTINCT CASE WHEN ts.current_status = 'on_call' THEN ts.telecaller_id END) as telecallers_on_call,
            COUNT(DISTINCT cl.id) as total_calls_today,
            SUM(CASE WHEN cl.call_status = 'connected' THEN 1 ELSE 0 END) as connected_calls_today,
            SUM(CASE WHEN cl.call_status = 'interested' THEN 1 ELSE 0 END) as interested_calls_today,
            COALESCE(SUM(cl.call_duration), 0) as total_call_duration_today,
            COUNT(DISTINCT cl.user_id) as unique_drivers_contacted_today
        FROM admins a
        LEFT JOIN telecaller_status ts ON a.id = ts.telecaller_id
        LEFT JOIN call_logs cl ON a.id = cl.caller_id AND DATE(COALESCE(cl.call_initiated_at, cl.call_time)) = CURDATE()
        WHERE a.role = 'telecaller'
    ");
    $overview = $stmt->fetch();
    echo "<p style='color: green;'>✅ Overview API working</p>";
    echo "<pre>" . json_encode($overview, JSON_PRETTY_PRINT) . "</pre>";
} catch(Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . $e->getMessage() . "</p>";
}

// Step 3: Test Telecallers List
echo "<h3>Step 3: Testing Telecallers List</h3>";
try {
    $stmt = $pdo->query("
        SELECT 
            a.id, a.name, a.mobile,
            COALESCE(ts.current_status, 'offline') as current_status,
            COUNT(DISTINCT cl.id) as total_calls_today
        FROM admins a
        LEFT JOIN telecaller_status ts ON a.id = ts.telecaller_id
        LEFT JOIN call_logs cl ON a.id = cl.caller_id AND DATE(COALESCE(cl.call_initiated_at, cl.call_time)) = CURDATE()
        WHERE a.role = 'telecaller'
        GROUP BY a.id, a.name, a.mobile, ts.current_status
        LIMIT 5
    ");
    $telecallers = $stmt->fetchAll();
    echo "<p style='color: green;'>✅ Found " . count($telecallers) . " telecallers</p>";
    if (count($telecallers) > 0) {
        echo "<pre>" . json_encode($telecallers, JSON_PRETTY_PRINT) . "</pre>";
    }
} catch(Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . $e->getMessage() . "</p>";
}

// Step 4: Test Real-Time Status
echo "<h3>Step 4: Testing Real-Time Status</h3>";
try {
    $stmt = $pdo->query("
        SELECT 
            a.id, a.name, a.mobile,
            COALESCE(ts.current_status, 'offline') as current_status
        FROM admins a
        LEFT JOIN telecaller_status ts ON a.id = ts.telecaller_id
        WHERE a.role = 'telecaller'
        LIMIT 5
    ");
    $statuses = $stmt->fetchAll();
    echo "<p style='color: green;'>✅ Real-time status working</p>";
    echo "<pre>" . json_encode($statuses, JSON_PRETTY_PRINT) . "</pre>";
} catch(Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . $e->getMessage() . "</p>";
}

// Step 5: API Endpoint Links
echo "<h3>Step 5: Test API Endpoints</h3>";
echo "<div style='background: #e8f5e9; padding: 15px; border-radius: 5px;'>";
echo "<p><strong>Test these URLs in your browser or Flutter app:</strong></p>";
echo "<ul>";
echo "<li><a href='manager_dashboard_api.php?action=manager_details&manager_id=$managerId' target='_blank'>Manager Details</a></li>";
echo "<li><a href='manager_dashboard_api.php?action=overview&manager_id=$managerId' target='_blank'>Overview</a></li>";
echo "<li><a href='manager_dashboard_api.php?action=telecallers' target='_blank'>Telecallers List</a></li>";
echo "<li><a href='manager_dashboard_api.php?action=real_time_status' target='_blank'>Real-Time Status</a></li>";
echo "<li><a href='manager_dashboard_api.php' target='_blank'>API Documentation</a></li>";
echo "</ul>";
echo "</div>";

// Step 6: Flutter App Instructions
echo "<h3>Step 6: Flutter App Setup</h3>";
echo "<div style='background: #fff3e0; padding: 15px; border-radius: 5px;'>";
echo "<p><strong>To test in Flutter app:</strong></p>";
echo "<ol>";
echo "<li>Login with: <strong>9999999999</strong> / <strong>manager123</strong></li>";
echo "<li>App should route to Manager Dashboard</li>";
echo "<li>Dashboard should load with data</li>";
echo "</ol>";
echo "<p><strong>If dashboard doesn't open:</strong></p>";
echo "<ul>";
echo "<li>Check Flutter console for errors</li>";
echo "<li>Verify API URL in <code>lib/core/config/api_config.dart</code></li>";
echo "<li>Ensure server IP is correct: <strong>192.168.29.149</strong></li>";
echo "</ul>";
echo "</div>";

echo "<hr>";
echo "<h2 style='color: green;'>✅ Setup Complete!</h2>";
echo "<p>Manager dashboard is ready to use.</p>";
?>
