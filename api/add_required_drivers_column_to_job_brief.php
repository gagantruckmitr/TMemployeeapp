<?php
/**
 * Add required_drivers column to job_brief_table
 * Run this once to add the missing column
 */

require_once 'config.php';

header('Content-Type: application/json');

if (!$conn) {
    echo json_encode([
        'success' => false,
        'message' => 'Database connection failed',
        'error' => mysqli_connect_error()
    ], JSON_PRETTY_PRINT);
    exit;
}

try {
    // Check if column already exists
    $checkQuery = "SHOW COLUMNS FROM job_brief_table LIKE 'required_drivers'";
    $result = $conn->query($checkQuery);

    if ($result && $result->num_rows > 0) {
        echo json_encode([
            'success' => true,
            'message' => 'Column already exists',
            'column' => 'required_drivers',
            'action' => 'none'
        ], JSON_PRETTY_PRINT);
    } else {
        // Add the column
        $alterQuery = "ALTER TABLE job_brief_table 
                       ADD COLUMN required_drivers VARCHAR(255) NULL 
                       AFTER call_recording";
        
        if ($conn->query($alterQuery)) {
            echo json_encode([
                'success' => true,
                'message' => 'Column added successfully',
                'column' => 'required_drivers',
                'action' => 'added'
            ], JSON_PRETTY_PRINT);
        } else {
            echo json_encode([
                'success' => false,
                'message' => 'Failed to add column',
                'error' => $conn->error
            ], JSON_PRETTY_PRINT);
        }
    }
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => 'Exception occurred',
        'error' => $e->getMessage()
    ], JSON_PRETTY_PRINT);
}

$conn->close();
?>
