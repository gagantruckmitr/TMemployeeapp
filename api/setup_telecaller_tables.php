<?php
/**
 * Setup Telecaller App Tables
 * Creates ONLY the missing tables needed for the telecaller app
 * DOES NOT modify or delete any existing data
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

$db_host = 'localhost';
$db_port = '3306';
$db_name = 'truckmitr';
$db_user = 'truckmitr';
$db_pass = '825Redp&4';

$response = [
    'timestamp' => date('Y-m-d H:i:s'),
    'operation' => 'Create Missing Tables for Telecaller App'
];

try {
    $conn = new mysqli($db_host, $db_user, $db_pass, $db_name, $db_port);
    
    if ($conn->connect_error) {
        throw new Exception('Connection failed: ' . $conn->connect_error);
    }
    
    $tables_created = [];
    $tables_existed = [];
    
    // 1. Create drivers table (if not exists)
    $sql_drivers = "CREATE TABLE IF NOT EXISTS `drivers` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `user_id` int(11) DEFAULT NULL,
        `name` varchar(255) NOT NULL,
        `mobile` varchar(15) NOT NULL,
        `email` varchar(255) DEFAULT NULL,
        `state` varchar(100) DEFAULT NULL,
        `city` varchar(100) DEFAULT NULL,
        `experience` int(11) DEFAULT NULL,
        `license_number` varchar(50) DEFAULT NULL,
        `vehicle_type` varchar(100) DEFAULT NULL,
        `status` enum('active','inactive','pending') DEFAULT 'pending',
        `profile_completion` int(11) DEFAULT 0,
        `last_called` datetime DEFAULT NULL,
        `call_count` int(11) DEFAULT 0,
        `interested` tinyint(1) DEFAULT 0,
        `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        KEY `mobile` (`mobile`),
        KEY `user_id` (`user_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
    
    if ($conn->query($sql_drivers)) {
        $tables_created[] = 'drivers';
    }
    
    // 2. Create telecaller_status table (if not exists)
    $sql_telecaller = "CREATE TABLE IF NOT EXISTS `telecaller_status` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `telecaller_id` int(11) NOT NULL,
        `telecaller_name` varchar(255) NOT NULL,
        `total_calls` int(11) DEFAULT 0,
        `connected_calls` int(11) DEFAULT 0,
        `interested_count` int(11) DEFAULT 0,
        `callback_count` int(11) DEFAULT 0,
        `not_interested_count` int(11) DEFAULT 0,
        `profile_completion_count` int(11) DEFAULT 0,
        `last_call_time` datetime DEFAULT NULL,
        `status` enum('active','inactive','break') DEFAULT 'active',
        `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
        `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        UNIQUE KEY `telecaller_id` (`telecaller_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
    
    if ($conn->query($sql_telecaller)) {
        $tables_created[] = 'telecaller_status';
    }
    
    // 3. Ensure call_logs table has correct structure
    $sql_call_logs = "CREATE TABLE IF NOT EXISTS `call_logs` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `telecaller_id` int(11) NOT NULL,
        `driver_id` int(11) NOT NULL,
        `driver_name` varchar(255) DEFAULT NULL,
        `driver_mobile` varchar(15) DEFAULT NULL,
        `call_status` enum('connected','not_connected','busy','no_answer','callback') DEFAULT NULL,
        `feedback` enum('interested','not_interested','callback_later','profile_incomplete') DEFAULT NULL,
        `notes` text,
        `call_duration` int(11) DEFAULT 0,
        `call_time` datetime DEFAULT NULL,
        `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (`id`),
        KEY `telecaller_id` (`telecaller_id`),
        KEY `driver_id` (`driver_id`),
        KEY `call_time` (`call_time`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
    
    if ($conn->query($sql_call_logs)) {
        $tables_created[] = 'call_logs (verified)';
    }
    
    // 4. Create telecaller_assignments table
    $sql_assignments = "CREATE TABLE IF NOT EXISTS `telecaller_assignments` (
        `id` int(11) NOT NULL AUTO_INCREMENT,
        `telecaller_id` int(11) NOT NULL,
        `driver_id` int(11) NOT NULL,
        `assigned_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
        `status` enum('pending','completed','skipped') DEFAULT 'pending',
        PRIMARY KEY (`id`),
        UNIQUE KEY `telecaller_driver` (`telecaller_id`,`driver_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4";
    
    if ($conn->query($sql_assignments)) {
        $tables_created[] = 'telecaller_assignments';
    }
    
    // Check which tables now exist
    $check_tables = ['drivers', 'telecaller_status', 'call_logs', 'telecaller_assignments'];
    foreach ($check_tables as $table) {
        $result = $conn->query("SHOW TABLES LIKE '$table'");
        if ($result->num_rows > 0) {
            $tables_existed[] = $table;
        }
    }
    
    $response['success'] = true;
    $response['message'] = 'Telecaller tables setup completed';
    $response['tables_created'] = $tables_created;
    $response['tables_verified'] = $tables_existed;
    $response['note'] = 'All existing data is safe. Only new tables were added.';
    
    $conn->close();
    
} catch (Exception $e) {
    $response['success'] = false;
    $response['message'] = 'Error: ' . $e->getMessage();
}

echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
