<?php
// Create match_making table in truckmitr database
header('Content-Type: application/json');

require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    // Create match_making table
    $sql = "CREATE TABLE IF NOT EXISTS `match_making` (
      `id` INT(11) NOT NULL AUTO_INCREMENT,
      `caller_id` INT(11) NOT NULL COMMENT 'Telecaller ID who made the match',
      `tele_caller_name` VARCHAR(255) NOT NULL COMMENT 'Name of the telecaller',
      `unique_id_transporter` VARCHAR(50) NOT NULL COMMENT 'Transporter unique ID (TMID)',
      `unique_id_driver` VARCHAR(50) NOT NULL COMMENT 'Driver unique ID (TMID)',
      `transporter_name` VARCHAR(255) NOT NULL COMMENT 'Name of the transporter',
      `driver_name` VARCHAR(255) NOT NULL COMMENT 'Name of the driver',
      `application_id` VARCHAR(100) NULL COMMENT 'Application/Job application ID',
      `job_id` VARCHAR(100) NULL COMMENT 'Job posting ID',
      `feed_back` TEXT NULL COMMENT 'Feedback about the match',
      `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Record creation timestamp',
      `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Record update timestamp',
      PRIMARY KEY (`id`),
      INDEX `idx_caller_id` (`caller_id`),
      INDEX `idx_transporter` (`unique_id_transporter`),
      INDEX `idx_driver` (`unique_id_driver`),
      INDEX `idx_application` (`application_id`),
      INDEX `idx_job` (`job_id`),
      INDEX `idx_created_at` (`created_at`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Tracks driver-transporter matchmaking by telecallers'";
    
    $pdo->exec($sql);
    
    // Get table structure
    $stmt = $pdo->query("DESCRIBE match_making");
    $structure = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get table info
    $stmt = $pdo->query("SHOW TABLE STATUS LIKE 'match_making'");
    $tableInfo = $stmt->fetch(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'success' => true,
        'message' => 'match_making table created successfully!',
        'table_structure' => $structure,
        'table_info' => [
            'name' => $tableInfo['Name'],
            'engine' => $tableInfo['Engine'],
            'rows' => $tableInfo['Rows'],
            'collation' => $tableInfo['Collation'],
            'comment' => $tableInfo['Comment']
        ],
        'timestamp' => date('Y-m-d H:i:s')
    ], JSON_PRETTY_PRINT);
    
} catch(PDOException $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => 'Database error: ' . $e->getMessage()
    ], JSON_PRETTY_PRINT);
}
?>
