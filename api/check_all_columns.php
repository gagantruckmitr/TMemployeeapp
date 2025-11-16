<?php
/**
 * Check All Database Columns
 * Lists all tables and their columns with data types
 */

require_once 'config.php';

header('Content-Type: text/html; charset=utf-8');

echo "<html><head><title>Database Structure - All Columns</title>";
echo "<style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    h1 { color: #333; }
    h2 { color: #0066cc; margin-top: 30px; border-bottom: 2px solid #0066cc; padding-bottom: 5px; }
    table { width: 100%; border-collapse: collapse; margin: 20px 0; background: white; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    th { background: #0066cc; color: white; padding: 12px; text-align: left; font-weight: bold; }
    td { padding: 10px; border-bottom: 1px solid #ddd; }
    tr:hover { background: #f9f9f9; }
    .type { color: #666; font-style: italic; }
    .null { color: #999; }
    .key { color: #ff6600; font-weight: bold; }
    .default { color: #009900; }
    .extra { color: #9900cc; font-size: 0.9em; }
    .summary { background: #e8f4f8; padding: 15px; border-radius: 5px; margin: 20px 0; }
    .error { background: #ffebee; color: #c62828; padding: 15px; border-radius: 5px; margin: 20px 0; }
</style></head><body>";

echo "<h1>📊 Database Structure: All Tables & Columns</h1>";
echo "<div class='summary'><strong>Database:</strong> " . DB_NAME . " | <strong>Host:</strong> " . DB_HOST . "</div>";

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
    
    echo "<div class='summary'><strong>Total Tables:</strong> " . count($tables) . "</div>";
    
    // Loop through each table
    foreach ($tables as $tableName) {
        echo "<h2>📋 Table: $tableName</h2>";
        
        // Get column information
        $columnsQuery = "SHOW FULL COLUMNS FROM `$tableName`";
        $columnsResult = $conn->query($columnsQuery);
        
        if (!$columnsResult) {
            echo "<div class='error'>Error fetching columns: " . $conn->error . "</div>";
            continue;
        }
        
        // Get row count
        $countQuery = "SELECT COUNT(*) as count FROM `$tableName`";
        $countResult = $conn->query($countQuery);
        $rowCount = $countResult ? $countResult->fetch_assoc()['count'] : 'N/A';
        
        echo "<p><strong>Rows:</strong> $rowCount</p>";
        
        echo "<table>";
        echo "<tr>
                <th>#</th>
                <th>Column Name</th>
                <th>Data Type</th>
                <th>Null</th>
                <th>Key</th>
                <th>Default</th>
                <th>Extra</th>
                <th>Comment</th>
              </tr>";
        
        $columnNumber = 1;
        while ($column = $columnsResult->fetch_assoc()) {
            echo "<tr>";
            echo "<td>" . $columnNumber++ . "</td>";
            echo "<td><strong>" . htmlspecialchars($column['Field']) . "</strong></td>";
            echo "<td class='type'>" . htmlspecialchars($column['Type']) . "</td>";
            echo "<td class='null'>" . htmlspecialchars($column['Null']) . "</td>";
            echo "<td class='key'>" . htmlspecialchars($column['Key']) . "</td>";
            echo "<td class='default'>" . htmlspecialchars($column['Default'] ?? 'NULL') . "</td>";
            echo "<td class='extra'>" . htmlspecialchars($column['Extra']) . "</td>";
            echo "<td>" . htmlspecialchars($column['Comment']) . "</td>";
            echo "</tr>";
        }
        
        echo "</table>";
    }
    
    echo "<div class='summary'>✅ <strong>Complete!</strong> Displayed all columns from " . count($tables) . " tables.</div>";
    
} catch (Exception $e) {
    echo "<div class='error'>❌ <strong>Error:</strong> " . htmlspecialchars($e->getMessage()) . "</div>";
}

$conn->close();

echo "</body></html>";
?>
