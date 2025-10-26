<?php
/**
 * Fix: Add assigned_to column to users table
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once 'config.php';

$response = [
    'timestamp' => date('Y-m-d H:i:s'),
    'operation' => 'Add assigned_to column'
];

try {
    // Check if column exists
    $stmt = $pdo->query("SHOW COLUMNS FROM users LIKE 'assigned_to'");
    
    if ($stmt->rowCount() > 0) {
        $response['success'] = true;
        $response['message'] = 'Column already exists';
    } else {
        // Add the column
        $pdo->exec("ALTER TABLE users ADD COLUMN assigned_to INT(11) DEFAULT NULL AFTER id");
        $pdo->exec("ALTER TABLE users ADD INDEX idx_assigned_to (assigned_to)");
        
        $response['success'] = true;
        $response['message'] = 'Column added successfully';
    }
    
    // Verify column exists now
    $stmt = $pdo->query("DESCRIBE users");
    $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    $response['column_exists'] = in_array('assigned_to', $columns);
    $response['all_columns'] = $columns;
    
} catch (Exception $e) {
    $response['success'] = false;
    $response['error'] = $e->getMessage();
}

echo json_encode($response, JSON_PRETTY_PRINT);
