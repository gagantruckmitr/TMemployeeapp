<?php
/**
 * Add Unique Constraint to job_brief_table
 * This ensures that the combination of unique_id + job_id is unique
 * preventing duplicate entries at the database level
 */

require_once 'config.php';

header('Content-Type: application/json');

if (!$conn) {
    die(json_encode([
        'success' => false,
        'message' => 'Database connection not available'
    ]));
}

try {
    // First, check if the constraint already exists
    $checkQuery = "
        SELECT COUNT(*) as count
        FROM information_schema.statistics
        WHERE table_schema = DATABASE()
        AND table_name = 'job_brief_table'
        AND index_name = 'unique_transporter_job'
    ";
    
    $result = $conn->query($checkQuery);
    $row = $result->fetch_assoc();
    
    if ($row['count'] > 0) {
        echo json_encode([
            'success' => true,
            'message' => 'Unique constraint already exists',
            'data' => [
                'constraint_name' => 'unique_transporter_job',
                'already_exists' => true
            ]
        ], JSON_PRETTY_PRINT);
        exit;
    }
    
    // Add the unique constraint
    $alterQuery = "
        ALTER TABLE job_brief_table
        ADD UNIQUE KEY unique_transporter_job (unique_id, job_id)
    ";
    
    if ($conn->query($alterQuery)) {
        echo json_encode([
            'success' => true,
            'message' => 'Unique constraint added successfully',
            'data' => [
                'constraint_name' => 'unique_transporter_job',
                'columns' => ['unique_id', 'job_id']
            ]
        ], JSON_PRETTY_PRINT);
    } else {
        throw new Exception('Failed to add constraint: ' . $conn->error);
    }
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Error: ' . $e->getMessage()
    ]);
}

$conn->close();
?>
