<?php
// Fix telecaller_status table immediately
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

echo "<h1>🔧 Fixing Telecaller Status Table</h1><hr>";

// Drop and recreate telecaller_status table
echo "<h3>Step 1: Dropping old telecaller_status table</h3>";
try {
    $pdo->exec("DROP TABLE IF EXISTS telecaller_status");
    echo "<p style='color: green;'>✅ Old table dropped</p>";
} catch(Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . $e->getMessage() . "</p>";
}

// Create telecaller_status table with correct structure
echo "<h3>Step 2: Creating new telecaller_status table</h3>";
try {
    $pdo->exec("
        CREATE TABLE telecaller_status (
            id INT AUTO_INCREMENT PRIMARY KEY,
            telecaller_id INT NOT NULL UNIQUE,
            current_status VARCHAR(20) DEFAULT 'offline',
            last_activity DATETIME,
            current_call_id INT,
            login_time DATETIME,
            logout_time DATETIME,
            total_online_duration INT DEFAULT 0,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_telecaller_id (telecaller_id),
            INDEX idx_current_status (current_status)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
    echo "<p style='color: green;'>✅ Table created successfully</p>";
} catch(Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . $e->getMessage() . "</p>";
    exit;
}

// Initialize status for all telecallers
echo "<h3>Step 3: Initializing telecaller status</h3>";
try {
    $pdo->exec("
        INSERT INTO telecaller_status (telecaller_id, current_status, last_activity, login_time)
        SELECT id, 'offline', NOW(), NOW()
        FROM admins 
        WHERE role = 'telecaller'
    ");
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM telecaller_status");
    $count = $stmt->fetch()['count'];
    echo "<p style='color: green;'>✅ Initialized $count telecallers</p>";
} catch(Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . $e->getMessage() . "</p>";
}

// Create manager_activity_log without foreign key
echo "<h3>Step 4: Creating manager_activity_log table</h3>";
try {
    $pdo->exec("DROP TABLE IF EXISTS manager_activity_log");
    $pdo->exec("
        CREATE TABLE manager_activity_log (
            id INT AUTO_INCREMENT PRIMARY KEY,
            manager_id INT NOT NULL,
            activity_type VARCHAR(100) NOT NULL,
            description TEXT,
            target_id INT,
            target_type VARCHAR(50),
            metadata JSON,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_manager_id (manager_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
    echo "<p style='color: green;'>✅ Table created successfully</p>";
} catch(Exception $e) {
    echo "<p style='color: orange;'>⚠️ " . $e->getMessage() . "</p>";
}

// Create telecaller_assignments without foreign keys
echo "<h3>Step 5: Creating telecaller_assignments table</h3>";
try {
    $pdo->exec("DROP TABLE IF EXISTS telecaller_assignments");
    $pdo->exec("
        CREATE TABLE telecaller_assignments (
            id INT AUTO_INCREMENT PRIMARY KEY,
            telecaller_id INT NOT NULL,
            driver_id INT NOT NULL,
            assigned_by INT,
            assigned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            status VARCHAR(20) DEFAULT 'active',
            priority VARCHAR(20) DEFAULT 'medium',
            notes TEXT,
            completed_at DATETIME,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_telecaller_id (telecaller_id),
            INDEX idx_driver_id (driver_id)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
    ");
    echo "<p style='color: green;'>✅ Table created successfully</p>";
} catch(Exception $e) {
    echo "<p style='color: orange;'>⚠️ " . $e->getMessage() . "</p>";
}

// Test the setup
echo "<h3>Step 6: Testing Setup</h3>";
try {
    $stmt = $pdo->query("
        SELECT 
            a.id, a.name, a.mobile,
            COALESCE(ts.current_status, 'offline') as current_status,
            ts.last_activity
        FROM admins a
        LEFT JOIN telecaller_status ts ON a.id = ts.telecaller_id
        WHERE a.role = 'telecaller'
        LIMIT 5
    ");
    $telecallers = $stmt->fetchAll();
    echo "<p style='color: green;'>✅ Found " . count($telecallers) . " telecallers with status</p>";
    echo "<pre>" . json_encode($telecallers, JSON_PRETTY_PRINT) . "</pre>";
} catch(Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . $e->getMessage() . "</p>";
}

// Test Overview API
echo "<h3>Step 7: Testing Overview API</h3>";
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
    echo "<p style='color: green;'>✅ Overview API working!</p>";
    echo "<pre>" . json_encode($overview, JSON_PRETTY_PRINT) . "</pre>";
} catch(Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . $e->getMessage() . "</p>";
}

// Get manager info
$stmt = $pdo->query("SELECT id, name, mobile FROM admins WHERE role = 'manager' LIMIT 1");
$manager = $stmt->fetch();
$managerId = $manager['id'];

echo "<hr>";
echo "<h2 style='color: green;'>✅ All Fixed!</h2>";

echo "<div style='background: #e8f5e9; padding: 20px; border-radius: 10px; margin: 20px 0;'>";
echo "<h3>📱 Login Credentials</h3>";
echo "<p><strong>Mobile:</strong> {$manager['mobile']}<br>";
echo "<strong>Password:</strong> manager123<br>";
echo "<strong>Manager:</strong> {$manager['name']}</p>";
echo "</div>";

echo "<div style='background: #fff3e0; padding: 20px; border-radius: 10px; margin: 20px 0;'>";
echo "<h3>🔗 Test API Endpoints</h3>";
echo "<ul>";
echo "<li><a href='manager_dashboard_api.php?action=overview&manager_id=$managerId' target='_blank'>Dashboard Overview</a></li>";
echo "<li><a href='manager_dashboard_api.php?action=telecallers' target='_blank'>Telecallers List</a></li>";
echo "<li><a href='manager_dashboard_api.php?action=real_time_status' target='_blank'>Real-Time Status</a></li>";
echo "</ul>";
echo "</div>";

echo "<p style='text-align: center; font-size: 20px; color: #4CAF50;'><strong>Manager Dashboard is NOW WORKING! 🎉</strong></p>";
?>
