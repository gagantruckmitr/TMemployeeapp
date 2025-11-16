<?php
/**
 * Check All Database Columns - Plain Text Version
 * Lists all tables and their columns in a clean text format
 */

require_once 'config.php';

header('Content-Type: text/plain; charset=utf-8');

echo "================================================================================\n";
echo "DATABASE STRUCTURE: ALL TABLES & COLUMNS\n";
echo "================================================================================\n";
echo "Database: " . DB_NAME . "\n";
echo "Host: " . DB_HOST . "\n";
echo "================================================================================\n\n";

try {
    // Get all tables
    $tablesQuery = "SHOW TABLES";
    $tablesResult = $conn->query($tablesQuery);
    
    if (!$tablesResult) {
        throw new Exception("Error fetching tables: " . $conn->error);
    }
    
    $tables = [];
    while ($row = $tablesResult->fetch_array()) {
        $tables[] = $row[0];
    }
    
    echo "Total Tables: " . count($tables) . "\n\n";
    
    // Loop through each table
    foreach ($tables as $tableName) {
        echo "================================================================================\n";
        echo "TABLE: $tableName\n";
        echo "================================================================================\n";
        
        // Get column information
        $columnsQuery = "SHOW FULL COLUMNS FROM `$tableName`";
        $columnsResult = $conn->query($columnsQuery);
        
        if (!$columnsResult) {
            echo "Error fetching columns: " . $conn->error . "\n\n";
            continue;
        }
        
        // Get row count
        $countQuery = "SELECT COUNT(*) as count FROM `$tableName`";
        $countResult = $conn->query($countQuery);
        $rowCount = $countResult ? $countResult->fetch_assoc()['count'] : 'N/A';
        
        echo "Rows: $rowCount\n\n";
        
        // Print column headers
        printf("%-4s %-35s %-25s %-8s %-8s %-15s %-20s\n", 
            "#", "Column Name", "Data Type", "Null", "Key", "Default", "Extra");
        echo str_repeat("-", 120) . "\n";
        
        $columnNumber = 1;
        while ($column = $columnsResult->fetch_assoc()) {
            printf("%-4d %-35s %-25s %-8s %-8s %-15s %-20s\n",
                $columnNumber++,
                $column['Field'],
                $column['Type'],
                $column['Null'],
                $column['Key'],
                substr($column['Default'] ?? 'NULL', 0, 15),
                substr($column['Extra'], 0, 20)
            );
        }
        
        echo "\n";
    }
    
    echo "================================================================================\n";
    echo "COMPLETE! Displayed all columns from " . count($tables) . " tables.\n";
    echo "================================================================================\n";
    
} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}

$conn->close();
?>
