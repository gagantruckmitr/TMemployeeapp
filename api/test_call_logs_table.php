<?php
/**
 * Test script to check call_logs table structure
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
    
    // Check if call_logs table exists
    $result = $conn->query("SHOW TABLES LIKE 'call_logs'");
    
    if ($result->num_rows === 0) {
        echo json_encode([
            'success' => false,
            'message' => 'call_logs table does not exist',
            'suggestion' => 'Table needs to be created'
        ]);
        exit;
    }
    
    // Get table structure
    $columns = $conn->query("DESCRIBE call_logs");
    $columnList = [];
    
    while ($row = $columns->fetch_assoc()) {
        $columnList[] = $row;
    }
    
    // Check if required columns exist
    $requiredColumns = ['id', 'caller_id', 'tc_for', 'name', 'mobile', 'source', 'role', 'feedback', 'remarks', 'created_at', 'updated_at'];
    $existingColumns = array_column($columnList, 'Field');
    $missingColumns = array_diff($requiredColumns, $existingColumns);
    
    // Get sample data
    $sampleData = $conn->query("SELECT * FROM call_logs ORDER BY id DESC LIMIT 3");
    $samples = [];
    while ($row = $sampleData->fetch_assoc()) {
        $samples[] = $row;
    }
    
    echo json_encode([
        'success' => true,
        'table_exists' => true,
        'columns' => $columnList,
        'existing_columns' => $existingColumns,
        'missing_columns' => $missingColumns,
        'sample_data' => $samples,
        'total_rows' => $conn->query("SELECT COUNT(*) as count FROM call_logs")->fetch_assoc()['count']
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'message' => $e->getMessage()
    ]);
}
?>
