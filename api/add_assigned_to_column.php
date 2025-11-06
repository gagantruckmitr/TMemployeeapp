<?php
/**
 * Add assigned_to column to jobs table
 */

require_once 'config.php';

header('Content-Type: application/json');

try {
    if (!$conn) {
        throw new Exception('Database connection failed');
    }
    
    // Check if column already exists
    $checkQuery = "SHOW COLUMNS FROM jobs LIKE 'assigned_to'";
    $result = $conn->query($checkQuery);
    
    if ($result && $result->num_rows > 0) {
        echo json_encode([
            'success' => true,
            'message' => 'Column assigned_to already exists',
            'action' => 'none'
        ], JSON_PRETTY_PRINT);
        exit;
    }
    
    // Add the column
    $alterQuery = "ALTER TABLE jobs 
                   ADD COLUMN assigned_to INT(11) DEFAULT NULL COMMENT 'Telecaller ID assigned to this job',
                   ADD INDEX idx_assigned_to (assigned_to)";
    
    if ($conn->query($alterQuery)) {
        echo json_encode([
            'success' => true,
            'message' => 'Column assigned_to added successfully with index',
            'action' => 'added',
            'next_step' => 'Run api/assign_jobs_round_robin.php to assign existing jobs'
        ], JSON_PRETTY_PRINT);
    } else {
        throw new Exception('Failed to add column: ' . $conn->error);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ], JSON_PRETTY_PRINT);
}

if ($conn) {
    $conn->close();
}
?>
