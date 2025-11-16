<?php
/**
 * Check All Database Columns - JSON Version
 * Returns all tables and their columns as JSON
 */

require_once 'config.php';

try {
    // Get all tables
    $tablesQuery = "SHOW TABLES";
    $tablesResult = $conn->query($tablesQuery);
    
    if (!$tablesResult) {
        throw new Exception("Error fetching tables: " . $conn->error);
    }
    
    $database = [
        'database_name' => DB_NAME,
        'host' => DB_HOST,
        'total_tables' => 0,
        'tables' => []
    ];
    
    // Loop through each table
    while ($row = $tablesResult->fetch_array()) {
        $tableName = $row[0];
        
        // Get column information
        $columnsQuery = "SHOW FULL COLUMNS FROM `$tableName`";
        $columnsResult = $conn->query($columnsQuery);
        
        if (!$columnsResult) {
            continue;
        }
        
        // Get row count
        $countQuery = "SELECT COUNT(*) as count FROM `$tableName`";
        $countResult = $conn->query($countQuery);
        $rowCount = $countResult ? $countResult->fetch_assoc()['count'] : 0;
        
        $columns = [];
        while ($column = $columnsResult->fetch_assoc()) {
            $columns[] = [
                'name' => $column['Field'],
                'type' => $column['Type'],
                'null' => $column['Null'],
                'key' => $column['Key'],
                'default' => $column['Default'],
                'extra' => $column['Extra'],
                'comment' => $column['Comment']
            ];
        }
        
        $database['tables'][] = [
            'name' => $tableName,
            'row_count' => (int)$rowCount,
            'column_count' => count($columns),
            'columns' => $columns
        ];
    }
    
    $database['total_tables'] = count($database['tables']);
    
    sendSuccess($database, 'Database structure retrieved successfully');
    
} catch (Exception $e) {
    sendError($e->getMessage(), 500);
}

$conn->close();
?>
