<?php
/**
 * Seed Test Data - Add sample call logs for testing
 */
header('Content-Type: application/json');

$host = '127.0.0.1';
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$dbname;charset=utf8mb4", $username, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Ensure call_logs table exists
    $createTableSql = "CREATE TABLE IF NOT EXISTS `call_logs` (
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
    
    $pdo->exec($createTableSql);
    
    // Get first telecaller
    $stmt = $pdo->query("SELECT id FROM admins WHERE role = 'telecaller' LIMIT 1");
    $telecaller = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$telecaller) {
        echo json_encode(['error' => 'No telecaller found. Please create a telecaller first.']);
        exit;
    }
    
    $callerId = $telecaller['id'];
    
    // Get some drivers
    $stmt = $pdo->query("SELECT id, mobile FROM users WHERE role = 'driver' LIMIT 20");
    $drivers = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (empty($drivers)) {
        echo json_encode(['error' => 'No drivers found. Please add drivers first.']);
        exit;
    }
    
    $inserted = 0;
    $today = date('Y-m-d');
    
    // Insert sample call logs for TODAY
    $statuses = ['connected', 'callback', 'callback_later', 'not_reachable', 'pending'];
    $feedbacks = [
        'connected' => ['Interested in subscription', 'Wants demo', 'Will call back', 'Agreed to payment'],
        'callback' => ['Call back in 1 hour', 'Busy right now', 'In meeting'],
        'callback_later' => ['Call tomorrow', 'Call next week', 'Call after 3 days'],
        'not_reachable' => ['Phone switched off', 'Not answering', 'Invalid number'],
        'pending' => ['Call initiated', 'Waiting for response']
    ];
    
    foreach ($drivers as $index => $driver) {
        $status = $statuses[$index % count($statuses)];
        $feedback = $feedbacks[$status][array_rand($feedbacks[$status])];
        
        // Random time today
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
            rand(30, 300) // Random duration 30-300 seconds
        ]);
        
        $inserted++;
    }
    
    echo json_encode([
        'success' => true,
        'message' => "Inserted $inserted test call logs for today",
        'caller_id' => $callerId,
        'date' => $today
    ]);
    
} catch(Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
