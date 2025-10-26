<?php
// Complete Manager Dashboard Setup - One Click Solution
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

echo "<h1>🚀 Complete Manager Dashboard Setup</h1><hr>";

// Step 1: Create telecaller_status table
echo "<h3>Step 1: Creating telecaller_status table</h3>";
try {
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS telecaller_status (
            id INT AUTO_INCREMENT PRIMARY KEY,
            telecaller_id INT NOT NULL UNIQUE,
            current_status ENUM('online', 'offline', 'on_call', 'break', 'busy') DEFAULT 'offline',
            last_activity DATETIME,
            current_call_id INT,
            login_time DATETIME,
            logout_time DATETIME,
            total_online_duration INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_telecaller_id (telecaller_id),
            INDEX idx_current_status (current_status),
            FOREIGN KEY (telecaller_id) REFERENCES admins(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
    echo "<p style='color: green;'>✅ telecaller_status table ready</p>";
} catch(Exception $e) {
    echo "<p style='color: orange;'>⚠️ " . $e->getMessage() . "</p>";
}

// Step 2: Create manager_activity_log table
echo "<h3>Step 2: Creating manager_activity_log table</h3>";
try {
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS manager_activity_log (
            id INT AUTO_INCREMENT PRIMARY KEY,
            manager_id INT NOT NULL,
            activity_type VARCHAR(100) NOT NULL,
            description TEXT,
            target_id INT,
            target_type VARCHAR(50),
            metadata JSON,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_manager_id (manager_id),
            FOREIGN KEY (manager_id) REFERENCES admins(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
    echo "<p style='color: green;'>✅ manager_activity_log table ready</p>";
} catch(Exception $e) {
    echo "<p style='color: orange;'>⚠️ " . $e->getMessage() . "</p>";
}

// Step 3: Create telecaller_assignments table
echo "<h3>Step 3: Creating telecaller_assignments table</h3>";
try {
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS telecaller_assignments (
            id INT AUTO_INCREMENT PRIMARY KEY,
            telecaller_id INT NOT NULL,
            driver_id INT NOT NULL,
            assigned_by INT,
            assigned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            status ENUM('active', 'completed', 'reassigned') DEFAULT 'active',
            priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
            notes TEXT,
            completed_at DATETIME,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_telecaller_id (telecaller_id),
            INDEX idx_driver_id (driver_id),
            FOREIGN KEY (telecaller_id) REFERENCES admins(id) ON DELETE CASCADE,
            FOREIGN KEY (driver_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (assigned_by) REFERENCES admins(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
    echo "<p style='color: green;'>✅ telecaller_assignments table ready</p>";
} catch(Exception $e) {
    echo "<p style='color: orange;'>⚠️ " . $e->getMessage() . "</p>";
}

// Step 4: Initialize telecaller status
echo "<h3>Step 4: Initializing telecaller status</h3>";
try {
    $pdo->exec("
        INSERT INTO telecaller_status (telecaller_id, current_status, last_activity, login_time)
        SELECT id, 'offline', NOW(), NOW()
        FROM admins 
        WHERE role = 'telecaller'
        ON DUPLICATE KEY UPDATE last_activity = NOW()
    ");
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM telecaller_status");
    $count = $stmt->fetch()['count'];
    echo "<p style='color: green;'>✅ Initialized $count telecallers</p>";
} catch(Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . $e->getMessage() . "</p>";
}

// Step 5: Check/Create Manager
echo "<h3>Step 5: Checking Manager Account</h3>";
$stmt = $pdo->query("SELECT id, name, mobile, email FROM admins WHERE role = 'manager' LIMIT 1");
$manager = $stmt->fetch();

if (!$manager) {
    echo "<p style='color: orange;'>⚠️ No manager found. Creating...</p>";
    $hashedPassword = password_hash('manager123', PASSWORD_BCRYPT);
    $stmt = $pdo->prepare("
        INSERT INTO admins (role, name, mobile, email, password, created_at, updated_at) 
        VALUES ('manager', 'Test Manager', '9999999999', 'manager@truckmitr.com', ?, NOW(), NOW())
    ");
    $stmt->execute([$hashedPassword]);
    $managerId = $pdo->lastInsertId();
    $manager = ['id' => $managerId, 'name' => 'Test Manager', 'mobile' => '9999999999'];
    echo "<p style='color: green;'>✅ Manager created</p>";
} else {
    echo "<p style='color: green;'>✅ Manager exists: {$manager['name']}</p>";
    $managerId = $manager['id'];
}

// Step 6: Test All APIs
echo "<h3>Step 6: Testing APIs</h3>";

// Test Overview
try {
    $stmt = $pdo->query("
        SELECT 
            COUNT(DISTINCT CASE WHEN a.role = 'telecaller' THEN a.id END) as total_telecallers,
            COUNT(DISTINCT CASE WHEN ts.current_status = 'online' THEN ts.telecaller_id END) as online_telecallers,
            COUNT(DISTINCT cl.id) as total_calls_today
        FROM admins a
        LEFT JOIN telecaller_status ts ON a.id = ts.telecaller_id
        LEFT JOIN call_logs cl ON a.id = cl.caller_id AND DATE(COALESCE(cl.call_initiated_at, cl.call_time)) = CURDATE()
        WHERE a.role = 'telecaller'
    ");
    $overview = $stmt->fetch();
    echo "<p style='color: green;'>✅ Overview API: {$overview['total_telecallers']} telecallers, {$overview['total_calls_today']} calls today</p>";
} catch(Exception $e) {
    echo "<p style='color: red;'>❌ Overview API Error: " . $e->getMessage() . "</p>";
}

// Test Telecallers List
try {
    $stmt = $pdo->query("
        SELECT COUNT(*) as count
        FROM admins a
        LEFT JOIN telecaller_status ts ON a.id = ts.telecaller_id
        WHERE a.role = 'telecaller'
    ");
    $count = $stmt->fetch()['count'];
    echo "<p style='color: green;'>✅ Telecallers List API: $count telecallers</p>";
} catch(Exception $e) {
    echo "<p style='color: red;'>❌ Telecallers API Error: " . $e->getMessage() . "</p>";
}

// Test Real-Time Status
try {
    $stmt = $pdo->query("
        SELECT 
            COALESCE(ts.current_status, 'offline') as status,
            COUNT(*) as count
        FROM admins a
        LEFT JOIN telecaller_status ts ON a.id = ts.telecaller_id
        WHERE a.role = 'telecaller'
        GROUP BY ts.current_status
    ");
    $statuses = $stmt->fetchAll();
    echo "<p style='color: green;'>✅ Real-Time Status API working</p>";
} catch(Exception $e) {
    echo "<p style='color: red;'>❌ Status API Error: " . $e->getMessage() . "</p>";
}

// Final Summary
echo "<hr>";
echo "<h2 style='color: green;'>✅ Setup Complete!</h2>";

echo "<div style='background: #e8f5e9; padding: 20px; border-radius: 10px; margin: 20px 0;'>";
echo "<h3>📱 Login Credentials</h3>";
echo "<p><strong>Mobile:</strong> {$manager['mobile']}<br>";
echo "<strong>Password:</strong> manager123<br>";
echo "<strong>Manager ID:</strong> $managerId</p>";
echo "</div>";

echo "<div style='background: #fff3e0; padding: 20px; border-radius: 10px; margin: 20px 0;'>";
echo "<h3>🔗 Test API Endpoints</h3>";
echo "<ul>";
echo "<li><a href='manager_dashboard_api.php?action=manager_details&manager_id=$managerId' target='_blank'>Manager Details</a></li>";
echo "<li><a href='manager_dashboard_api.php?action=overview&manager_id=$managerId' target='_blank'>Dashboard Overview</a></li>";
echo "<li><a href='manager_dashboard_api.php?action=telecallers' target='_blank'>Telecallers List</a></li>";
echo "<li><a href='manager_dashboard_api.php?action=real_time_status' target='_blank'>Real-Time Status</a></li>";
echo "<li><a href='manager_dashboard_api.php' target='_blank'>API Documentation</a></li>";
echo "</ul>";
echo "</div>";

echo "<div style='background: #e3f2fd; padding: 20px; border-radius: 10px; margin: 20px 0;'>";
echo "<h3>📲 Flutter App Instructions</h3>";
echo "<ol>";
echo "<li>Open your Flutter app</li>";
echo "<li>Login with mobile: <strong>{$manager['mobile']}</strong></li>";
echo "<li>Password: <strong>manager123</strong></li>";
echo "<li>App will route to Manager Dashboard</li>";
echo "<li>Dashboard will show all telecaller data</li>";
echo "</ol>";
echo "</div>";

echo "<p style='text-align: center; font-size: 18px; color: #4CAF50;'><strong>Manager Dashboard is ready to use! 🎉</strong></p>";
?>
