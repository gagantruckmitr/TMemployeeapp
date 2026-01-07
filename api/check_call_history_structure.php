<?php
header('Content-Type: application/json');

require_once 'config.php';

try {
    // Check if call_history table exists
    $tableCheck = $conn->query("SHOW TABLES LIKE 'call_history'");
    
    if ($tableCheck->num_rows === 0) {
        echo json_encode([
            'success' => false,
            'error' => 'call_history table does not exist',
            'note' => 'Using call_logs table instead'
        ]);
        exit;
    }
    
    // Get table structure
    $result = $conn->query("DESCRIBE call_history");
    
    $fields = [];
    while ($row = $result->fetch_assoc()) {
        $fields[] = [
            'Field' => $row['Field'],
            'Type' => $row['Type'],
            'Null' => $row['Null'],
            'Key' => $row['Key'],
            'Default' => $row['Default'],
            'Extra' => $row['Extra']
        ];
    }
    
    // Get sample data
    $sampleResult = $conn->query("SELECT * FROM call_history LIMIT 1");
    $sampleData = $sampleResult->fetch_assoc();
    
    // Get row count
    $countResult = $conn->query("SELECT COUNT(*) as total FROM call_history");
    $count = $countResult->fetch_assoc()['total'];
    
    echo json_encode([
        'success' => true,
        'table' => 'call_history',
        'total_rows' => (int)$count,
        'fields' => $fields,
        'sample_data' => $sampleData,
        'field_names' => array_column($fields, 'Field')
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ]);
}
?>
