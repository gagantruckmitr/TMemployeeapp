<?php
/**
 * Setup call_logs_match_making table
 * Run this once to create the table
 */

require_once 'config.php';

header('Content-Type: application/json');

try {
    // Read SQL file
    $sql = file_get_contents(__DIR__ . '/create_call_logs_match_making_table.sql');
    
    if ($sql === false) {
        throw new Exception('Could not read SQL file');
    }
    
    // Execute SQL
    if ($conn->query($sql)) {
        echo json_encode([
            'success' => true,
            'message' => 'Table call_logs_match_making created successfully'
        ]);
    } else {
        throw new Exception('SQL execution failed: ' . $conn->error);
    }
    
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}

$conn->close();
