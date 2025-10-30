<?php
require_once 'config.php';

header('Content-Type: text/plain');

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "=== Checking drivers table structure ===\n\n";
    
    $stmt = $pdo->query("DESCRIBE drivers");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "Columns in drivers table:\n";
    foreach ($columns as $column) {
        echo "- {$column['Field']} ({$column['Type']})\n";
    }
    
    echo "\n=== Looking for assignment-related columns ===\n";
    foreach ($columns as $column) {
        if (stripos($column['Field'], 'assign') !== false || 
            stripos($column['Field'], 'telecaller') !== false) {
            echo "Found: {$column['Field']}\n";
        }
    }
    
} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
