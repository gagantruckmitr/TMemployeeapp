<?php
/**
 * Add status column to social_media_leads table
 */

header('Content-Type: application/json');

$host = '127.0.0.1';
$port = 3306;
$dbname = 'truckmitr';
$username = 'truckmitr';
$password = '825Redp&4';

try {
    $conn = new mysqli($host, $username, $password, $dbname, $port);
    
    if ($conn->connect_error) {
        throw new Exception('Connection failed: ' . $conn->connect_error);
    }
    
    // Check if table exists
    $tableCheck = $conn->query("SHOW TABLES LIKE 'social_media_leads'");
    
    if ($tableCheck->num_rows === 0) {
        echo json_encode([
            'success' => false,
            'message' => 'social_media_leads table does not exist'
        ]);
        exit;
    }
    
    // Check if status column exists
    $columnCheck = $conn->query("SHOW COLUMNS FROM social_media_leads LIKE 'status'");
    
    if ($columnCheck->num_rows > 0) {
        echo json_encode([
            'success' => true,
            'message' => 'Status column already exists',
            'action' => 'none'
        ]);
        exit;
    }
    
    // Add status column
    $sql = "ALTER TABLE social_media_leads 
            ADD COLUMN status VARCHAR(50) DEFAULT 'pending' AFTER role";
    
    if ($conn->query($sql)) {
        echo json_encode([
            'success' => true,
            'message' => 'Status column added successfully',
            'action' => 'added'
        ]);
    } else {
        throw new Exception('Failed to add column: ' . $conn->error);
    }
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
