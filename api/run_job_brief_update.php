<?php
/**
 * Run this file once to add caller_id column to job_brief_table
 * Access via: https://truckmitr.com/truckmitr-app/api/run_job_brief_update.php
 */

require_once 'config.php';

header('Content-Type: application/json');

if (!$conn) {
    die(json_encode(['success' => false, 'message' => 'Database connection failed']));
}

try {
    // Add caller_id column
    $sql = "ALTER TABLE `job_brief_table` 
            ADD COLUMN `caller_id` int(11) DEFAULT NULL COMMENT 'Telecaller ID who made the call' AFTER `job_id`,
            ADD KEY `caller_id` (`caller_id`)";
    
    if ($conn->query($sql)) {
        echo json_encode([
            'success' => true,
            'message' => 'Successfully added caller_id column to job_brief_table'
        ]);
    } else {
        // Check if column already exists
        if (strpos($conn->error, 'Duplicate column name') !== false) {
            echo json_encode([
                'success' => true,
                'message' => 'Column caller_id already exists in job_brief_table'
            ]);
        } else {
            throw new Exception($conn->error);
        }
    }
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}

$conn->close();
?>
