<?php
// Test Manager Details from Admins Table
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

echo "<h1>Manager Details Test</h1><hr>";

// Test 1: Check if managers exist in admins table
echo "<h3>Test 1: Checking Managers in Admins Table</h3>";
try {
    $stmt = $pdo->query("SELECT id, name, mobile, email, role, created_at FROM admins WHERE role = 'manager'");
    $managers = $stmt->fetchAll();
    
    if (empty($managers)) {
        echo "<p style='color: orange;'>⚠️ No managers found. Creating a test manager...</p>";
        
        // Create a test manager
        $stmt = $pdo->prepare("
            INSERT INTO admins (role, name, mobile, email, password, created_at, updated_at) 
            VALUES ('manager', 'Test Manager', '9999999999', 'manager@truckmitr.com', ?, NOW(), NOW())
        ");
        $hashedPassword = password_hash('password123', PASSWORD_BCRYPT);
        $stmt->execute([$hashedPassword]);
        
        echo "<p style='color: green;'>✅ Test manager created!</p>";
        echo "<p><strong>Login Credentials:</strong></p>";
        echo "<ul>";
        echo "<li>Mobile: 9999999999</li>";
        echo "<li>Password: password123</li>";
        echo "</ul>";
        
        // Fetch again
        $stmt = $pdo->query("SELECT id, name, mobile, email, role, created_at FROM admins WHERE role = 'manager'");
        $managers = $stmt->fetchAll();
    }
    
    echo "<p>✅ Found " . count($managers) . " manager(s)</p>";
    echo "<table border='1' cellpadding='10' style='border-collapse: collapse;'>";
    echo "<tr><th>ID</th><th>Name</th><th>Mobile</th><th>Email</th><th>Role</th><th>Created</th></tr>";
    foreach($managers as $manager) {
        echo "<tr>";
        echo "<td>{$manager['id']}</td>";
        echo "<td>{$manager['name']}</td>";
        echo "<td>{$manager['mobile']}</td>";
        echo "<td>{$manager['email']}</td>";
        echo "<td><strong>{$manager['role']}</strong></td>";
        echo "<td>{$manager['created_at']}</td>";
        echo "</tr>";
    }
    echo "</table>";
    
    // Store first manager ID for testing
    $testManagerId = $managers[0]['id'];
    
} catch(Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . $e->getMessage() . "</p>";
    exit;
}

// Test 2: Test Manager Details API
echo "<h3>Test 2: Testing Manager Details API</h3>";
if (isset($testManagerId)) {
    echo "<p>Testing with Manager ID: <strong>$testManagerId</strong></p>";
    
    try {
        // Simulate API call
        $stmt = $pdo->prepare("
            SELECT 
                id,
                name,
                mobile,
                email,
                role,
                created_at,
                updated_at
            FROM admins 
            WHERE id = ? AND role = 'manager'
        ");
        $stmt->execute([$testManagerId]);
        $manager = $stmt->fetch();
        
        if ($manager) {
            echo "<p style='color: green;'>✅ Manager Details Retrieved Successfully</p>";
            echo "<pre>" . json_encode($manager, JSON_PRETTY_PRINT) . "</pre>";
            
            // Get team stats
            $stmt = $pdo->query("
                SELECT 
                    COUNT(DISTINCT a.id) as total_telecallers,
                    COUNT(DISTINCT CASE WHEN ts.current_status = 'online' THEN a.id END) as online_telecallers,
                    COUNT(DISTINCT cl.id) as total_calls_today,
                    SUM(CASE WHEN cl.call_status = 'interested' THEN 1 ELSE 0 END) as conversions_today
                FROM admins a
                LEFT JOIN telecaller_status ts ON a.id = ts.telecaller_id
                LEFT JOIN call_logs cl ON a.id = cl.caller_id 
                    AND DATE(COALESCE(cl.call_initiated_at, cl.call_time)) = CURDATE()
                WHERE a.role = 'telecaller'
            ");
            $teamStats = $stmt->fetch();
            
            echo "<p style='color: green;'>✅ Team Statistics Retrieved</p>";
            echo "<pre>" . json_encode($teamStats, JSON_PRETTY_PRINT) . "</pre>";
            
        } else {
            echo "<p style='color: red;'>❌ Manager not found</p>";
        }
        
    } catch(Exception $e) {
        echo "<p style='color: red;'>❌ Error: " . $e->getMessage() . "</p>";
    }
    
    // Test 3: Test Full API Endpoint
    echo "<h3>Test 3: Test Full API Endpoint</h3>";
    echo "<p><a href='manager_dashboard_api.php?action=manager_details&manager_id=$testManagerId' target='_blank'>
        Click here to test: manager_dashboard_api.php?action=manager_details&manager_id=$testManagerId
    </a></p>";
}

echo "<hr>";
echo "<h2 style='color: green;'>✅ All Tests Completed!</h2>";
echo "<h3>Quick Links:</h3>";
echo "<ul>";
echo "<li><a href='manager_dashboard_api.php'>Manager Dashboard API Documentation</a></li>";
echo "<li><a href='test_manager_dashboard.php'>Test Manager Dashboard</a></li>";
echo "<li><a href='auth_api.php'>Authentication API</a></li>";
echo "</ul>";
?>
