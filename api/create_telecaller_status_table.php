<?php
// Create telecaller_status table
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

echo "<h1>Creating Telecaller Status Table</h1><hr>";

// Create telecaller_status table
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
            total_online_duration INT DEFAULT 0 COMMENT 'Duration in seconds',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_telecaller_id (telecaller_id),
            INDEX idx_current_status (current_status),
            FOREIGN KEY (telecaller_id) REFERENCES admins(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
    echo "<p style='color: green;'>✅ Table created successfully</p>";
} catch(Exception $e) {
    echo "<p style='color: orange;'>⚠️ " . $e->getMessage() . "</p>";
}

// Initialize status for all telecallers
echo "<h3>Step 2: Initializing status for all telecallers</h3>";
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
    echo "<p style='color: green;'>✅ Initialized status for $count telecallers</p>";
} catch(Exception $e) {
    echo "<p style='color: red;'>❌ Error: " . $e->getMessage() . "</p>";
}

// Create manager_activity_log table if not exists
echo "<h3>Step 3: Creating manager_activity_log table</h3>";
try {
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS manager_activity_log (
            id INT AUTO_INCREMENT PRIMARY KEY,
            manager_id INT NOT NULL,
            activity_type VARCHAR(100) NOT NULL,
            description TEXT,
            target_id INT COMMENT 'ID of affected entity',
            target_type VARCHAR(50) COMMENT 'Type of entity',
            metadata JSON COMMENT 'Additional activity data',
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            INDEX idx_manager_id (manager_id),
            INDEX idx_activity_type (activity_type),
            INDEX idx_created_at (created_at),
            FOREIGN KEY (manager_id) REFERENCES admins(id) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
    echo "<p style='color: green;'>✅ Table created successfully</p>";
} catch(Exception $e) {
    echo "<p style='color: orange;'>⚠️ " . $e->getMessage() . "</p>";
}

// Create telecaller_assignments table if not exists
echo "<h3>Step 4: Creating telecaller_assignments table</h3>";
try {
    $pdo->exec("
        CREATE TABLE IF NOT EXISTS telecaller_assignments (
            id INT AUTO_INCREMENT PRIMARY KEY,
            telecaller_id INT NOT NULL,
            driver_id INT NOT NULL,
            assigned_by INT COMMENT 'Manager ID who assigned',
            assigned_at DATETIME DEFAULT CURRENT_TIMESTAMP,
            status ENUM('active', 'completed', 'reassigned') DEFAULT 'active',
            priority ENUM('low', 'medium', 'high', 'urgent') DEFAULT 'medium',
            notes TEXT,
            completed_at DATETIME,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            INDEX idx_telecaller_id (telecaller_id),
            INDEX idx_driver_id (driver_id),
            INDEX idx_status (status),
            FOREIGN KEY (telecaller_id) REFERENCES admins(id) ON DELETE CASCADE,
            FOREIGN KEY (driver_id) REFERENCES users(id) ON DELETE CASCADE,
            FOREIGN KEY (assigned_by) REFERENCES admins(id) ON DELETE SET NULL
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ");
    echo "<p style='color: green;'>✅ Table created successfully</p>";
} catch(Exception $e) {
    echo "<p style='color: orange;'>⚠️ " . $e->getMessage() . "</p>";
}

// Test the setup
echo "<h3>Step 5: Testing Setup</h3>";
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

echo "<hr>";
echo "<h2 style='color: green;'>✅ Setup Complete!</h2>";
echo "<p><a href='fix_manager_dashboard.php'>Run Manager Dashboard Fix Again</a></p>";
?>
