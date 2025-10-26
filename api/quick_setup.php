<?php
/**
 * Quick Setup Script
 * Automatically fixes common issues
 */
header('Content-Type: text/html; charset=utf-8');

echo "<h1>TruckMitr Quick Setup</h1>";
echo "<style>
    body { font-family: Arial, sans-serif; padding: 20px; background: #f5f5f5; }
    .step { background: white; padding: 20px; margin: 15px 0; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    .success { color: #10b981; font-weight: bold; }
    .error { color: #ef4444; font-weight: bold; }
    .warning { color: #f59e0b; font-weight: bold; }
    .info { color: #3b82f6; font-weight: bold; }
    pre { background: #f9fafb; padding: 10px; border-radius: 4px; overflow-x: auto; }
    h2 { color: #1f2937; border-bottom: 2px solid #4f46e5; padding-bottom: 5px; margin-top: 0; }
    .btn { display: inline-block; padding: 10px 20px; background: #4f46e5; color: white; text-decoration: none; border-radius: 6px; margin: 5px; }
    .progress { background: #e5e7eb; height: 20px; border-radius: 10px; overflow: hidden; margin: 10px 0; }
    .progress-bar { background: linear-gradient(90deg, #4f46e5, #7c3aed); height: 100%; transition: width 0.3s; }
</style>";

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

$steps = [];
$totalSteps = 5;
$completedSteps = 0;

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Step 1: Ensure call_logs table exists
    echo "<div class='step'><h2>Step 1: Database Tables</h2>";
    try {
        $sql = "CREATE TABLE IF NOT EXISTS `call_logs` (
            `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
            `job_id` varchar(255) DEFAULT NULL,
            `job_name` varchar(255) DEFAULT NULL,
            `caller_id` bigint(20) UNSIGNED NOT NULL,
            `user_id` bigint(20) UNSIGNED NOT NULL,
            `caller_number` varchar(20) DEFAULT NULL,
            `user_number` varchar(20) NOT NULL,
            `transporter_id` bigint(20) UNSIGNED DEFAULT NULL,
            `transporter_tm_id` varchar(255) DEFAULT NULL,
            `transporter_name` varchar(255) DEFAULT NULL,
            `transporter_mobile` varchar(20) DEFAULT NULL,
            `driver_id` bigint(20) UNSIGNED DEFAULT NULL,
            `driver_tm_id` varchar(255) DEFAULT NULL,
            `driver_name` varchar(255) DEFAULT NULL,
            `driver_mobile` varchar(20) DEFAULT NULL,
            `call_status` enum('pending','connected','callback','callback_later','not_reachable','not_interested','invalid','completed','failed','cancelled') DEFAULT 'pending',
            `call_type` varchar(50) DEFAULT 'telecaller',
            `call_count` int(11) DEFAULT 1,
            `call_initiated_by` varchar(50) DEFAULT NULL,
            `feedback` text DEFAULT NULL,
            `remarks` text DEFAULT NULL,
            `notes` text DEFAULT NULL,
            `reference_id` varchar(100) DEFAULT NULL,
            `api_response` text DEFAULT NULL,
            `call_duration` int(11) DEFAULT 0,
            `call_time` timestamp NULL DEFAULT NULL,
            `call_initiated_at` timestamp NULL DEFAULT NULL,
            `call_completed_at` timestamp NULL DEFAULT NULL,
            `ip_address` varchar(45) DEFAULT NULL,
            `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
            `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `idx_user_id` (`user_id`),
            KEY `idx_caller_id` (`caller_id`),
            KEY `idx_caller_user` (`caller_id`, `user_id`),
            KEY `idx_reference_id` (`reference_id`),
            KEY `idx_call_status` (`call_status`),
            KEY `idx_call_time` (`call_time`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci";
        
        $pdo->exec($sql);
        echo "<span class='success'>✓ call_logs table ready</span><br>";
        $completedSteps++;
    } catch(Exception $e) {
        echo "<span class='error'>✗ Failed to create call_logs table: " . $e->getMessage() . "</span><br>";
    }
    echo "</div>";
    
    // Step 2: Check users and telecallers
    echo "<div class='step'><h2>Step 2: Users & Telecallers</h2>";
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM users WHERE role = 'driver'");
    $driverCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    
    $stmt = $pdo->query("SELECT COUNT(*) as count FROM admins WHERE role = 'telecaller'");
    $telecallerCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    
    if ($driverCount > 0) {
        echo "<span class='success'>✓ Drivers: $driverCount</span><br>";
    } else {
        echo "<span class='warning'>⚠ No drivers found - Import driver data</span><br>";
    }
    
    if ($telecallerCount > 0) {
        echo "<span class='success'>✓ Telecallers: $telecallerCount</span><br>";
        $completedSteps++;
    } else {
        echo "<span class='warning'>⚠ No telecallers found - Create telecaller accounts</span><br>";
    }
    echo "</div>";
    
    // Step 3: Add sample call data if none exists
    echo "<div class='step'><h2>Step 3: Sample Call Data</h2>";
    $today = date('Y-m-d');
    $stmt = $pdo->prepare("SELECT COUNT(*) as count FROM call_logs WHERE DATE(call_time) = ?");
    $stmt->execute([$today]);
    $todayCount = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
    
    if ($todayCount > 0) {
        echo "<span class='success'>✓ Today's calls: $todayCount</span><br>";
        $completedSteps++;
    } else {
        echo "<span class='info'>ℹ No calls for today - Adding sample data...</span><br>";
        
        if ($telecallerCount > 0 && $driverCount > 0) {
            // Add sample data
            $stmt = $pdo->query("SELECT id FROM admins WHERE role = 'telecaller' LIMIT 1");
            $telecaller = $stmt->fetch(PDO::FETCH_ASSOC);
            $callerId = $telecaller['id'];
            
            $stmt = $pdo->query("SELECT id, mobile FROM users WHERE role = 'driver' LIMIT 10");
            $drivers = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            $statuses = ['connected', 'callback', 'callback_later', 'not_reachable', 'pending'];
            $feedbacks = [
                'connected' => ['Interested in subscription', 'Wants demo', 'Will call back'],
                'callback' => ['Call back in 1 hour', 'Busy right now'],
                'callback_later' => ['Call tomorrow', 'Call next week'],
                'not_reachable' => ['Phone switched off', 'Not answering'],
                'pending' => ['Call initiated']
            ];
            
            $inserted = 0;
            foreach ($drivers as $index => $driver) {
                $status = $statuses[$index % count($statuses)];
                $feedback = $feedbacks[$status][array_rand($feedbacks[$status])];
                
                $hour = rand(9, 17);
                $minute = rand(0, 59);
                $callTime = "$today $hour:$minute:00";
                
                $sql = "INSERT INTO call_logs 
                        (caller_id, user_id, caller_number, user_number, call_status, feedback, call_time, call_duration, created_at, updated_at) 
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?, NOW(), NOW())";
                
                $stmt = $pdo->prepare($sql);
                $stmt->execute([
                    $callerId,
                    $driver['id'],
                    '+919876543210',
                    $driver['mobile'],
                    $status,
                    $feedback,
                    $callTime,
                    rand(30, 300)
                ]);
                
                $inserted++;
            }
            
            echo "<span class='success'>✓ Added $inserted sample call logs</span><br>";
            $completedSteps++;
        } else {
            echo "<span class='warning'>⚠ Cannot add sample data - need telecallers and drivers</span><br>";
        }
    }
    echo "</div>";
    
    // Step 4: Test Dashboard API
    echo "<div class='step'><h2>Step 4: Dashboard API</h2>";
    if ($telecallerCount > 0) {
        $stmt = $pdo->query("SELECT id FROM admins WHERE role = 'telecaller' LIMIT 1");
        $telecaller = $stmt->fetch(PDO::FETCH_ASSOC);
        $callerId = $telecaller['id'];
        
        $apiUrl = "http://" . $_SERVER['HTTP_HOST'] . dirname($_SERVER['PHP_SELF']) . "/dashboard_stats_api.php?caller_id=$callerId";
        $response = @file_get_contents($apiUrl);
        
        if ($response) {
            $data = json_decode($response, true);
            if ($data['success']) {
                echo "<span class='success'>✓ Dashboard API working</span><br>";
                echo "Stats: " . $data['data']['total_calls'] . " calls, " . 
                     $data['data']['connected_calls'] . " connected<br>";
                $completedSteps++;
            } else {
                echo "<span class='error'>✗ Dashboard API error</span><br>";
            }
        } else {
            echo "<span class='error'>✗ Cannot reach Dashboard API</span><br>";
        }
    } else {
        echo "<span class='warning'>⚠ Cannot test - no telecallers</span><br>";
    }
    echo "</div>";
    
    // Step 5: Check MyOperator Configuration
    echo "<div class='step'><h2>Step 5: IVR Configuration</h2>";
    $envFile = __DIR__ . '/../.env';
    if (file_exists($envFile)) {
        $envContent = file_get_contents($envFile);
        preg_match('/MYOPERATOR_COMPANY_ID=(.+)/', $envContent, $matches);
        $companyId = trim($matches[1] ?? '');
        
        if ($companyId && $companyId !== 'your_company_id') {
            echo "<span class='success'>✓ MyOperator configured</span><br>";
            echo "IVR calls will work with real voice<br>";
            $completedSteps++;
        } else {
            echo "<span class='warning'>⚠ MyOperator not configured</span><br>";
            echo "IVR will run in SIMULATION MODE (no real calls)<br>";
            echo "To enable: Update .env with MyOperator credentials<br>";
        }
    } else {
        echo "<span class='warning'>⚠ .env file not found</span><br>";
    }
    echo "</div>";
    
} catch(PDOException $e) {
    echo "<div class='step'><span class='error'>✗ Database Error: " . $e->getMessage() . "</span></div>";
}

// Progress bar
$progress = ($completedSteps / $totalSteps) * 100;
echo "<div class='step'>";
echo "<h2>Setup Progress</h2>";
echo "<div class='progress'><div class='progress-bar' style='width: {$progress}%'></div></div>";
echo "<p><strong>$completedSteps of $totalSteps steps completed ({$progress}%)</strong></p>";

if ($completedSteps == $totalSteps) {
    echo "<div style='background:#d1fae5; padding:15px; border-radius:6px; margin-top:10px;'>";
    echo "<span class='success'>✓ Setup Complete!</span><br>";
    echo "Your system is ready to use. You can now:<br>";
    echo "• Login to the Flutter app<br>";
    echo "• View dashboard with real data<br>";
    echo "• Make IVR calls (simulation mode if MyOperator not configured)<br>";
    echo "</div>";
} else {
    echo "<div style='background:#fef3c7; padding:15px; border-radius:6px; margin-top:10px;'>";
    echo "<span class='warning'>⚠ Setup Incomplete</span><br>";
    echo "Some steps need attention. Review the steps above and fix any issues.<br>";
    echo "</div>";
}

echo "<div style='margin-top:20px;'>";
echo "<a href='comprehensive_test.php' class='btn'>Full System Test</a>";
echo "<a href='test_ivr_complete.php' class='btn' style='background:#10b981;'>Test IVR</a>";
echo "<button class='btn' style='background:#f59e0b;' onclick='location.reload()'>Run Setup Again</button>";
echo "</div>";

echo "</div>";

?>
