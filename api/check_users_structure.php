<?php
require_once 'config.php';

header('Content-Type: text/plain');

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "=== Checking users table structure ===\n\n";
    
    $stmt = $pdo->query("DESCRIBE users");
    $columns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "Columns in users table:\n";
    foreach ($columns as $column) {
        echo "- {$column['Field']} ({$column['Type']})\n";
    }
    
    echo "\n=== Sample data ===\n";
    $stmt = $pdo->query("SELECT * FROM users LIMIT 3");
    $samples = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    foreach ($samples as $i => $sample) {
        echo "\nRecord " . ($i + 1) . ":\n";
        foreach ($sample as $key => $value) {
            echo "  $key: $value\n";
        }
    }
    
} catch (Exception $e) {
    echo "ERROR: " . $e->getMessage() . "\n";
}
