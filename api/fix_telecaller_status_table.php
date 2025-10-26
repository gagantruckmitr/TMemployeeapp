<?php
// Fix telecaller_status table structure on Plesk server
header('Content-Type: text/plain');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "Fixing telecaller_status table structure...\n\n";
    
    // Step 1: Check current table structure
    echo "Step 1: Checking current table structure\n";
    $stmt = $pdo->query("DESCRIBE telecaller_status");
    $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    echo "Current columns: " . implode(", ", $columns) . "\n\n";
    
    // Step 2: Add missing columns if they don't exist
    $columnsToAdd = [
        'current_status' => "VARCHAR(50) DEFAULT 'offline'",
        'last_activity' => "DATETIME NULL",
        'login_time' => "DATETIME NULL",
        'logout_time' => "DATETIME NULL",
        'total_online_duration' => "INT DEFAULT 0",
        'current_call_id' => "INT NULL",
        'break_start_time' => "DATETIME NULL",
        'total_break_duration' => "INT DEFAULT 0"
    ];
    
    foreach ($columnsToAdd as $column => $definition) {
        if (!in_array($column, $columns)) {
            echo "Adding column: $column\n";
            try {
                $pdo->exec("ALTER TABLE telecaller_status ADD COLUMN $column $definition");
                echo "✅ Added $column\n";
            } catch (PDOException $e) {
                echo "❌ Error adding $column: " . $e->getMessage() . "\n";
            }
        } else {
            echo "✓ Column $column already exists\n";
        }
    }
    
    echo "\n";
    
    // Step 3: Verify final structure
    echo "Step 3: Verifying final table structure\n";
    $stmt = $pdo->query("DESCRIBE telecaller_status");
    $finalColumns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "\nFinal table structure:\n";
    echo str_pad("Column", 30) . str_pad("Type", 20) . str_pad("Null", 10) . "Default\n";
    echo str_repeat("-", 80) . "\n";
    foreach ($finalColumns as $col) {
        echo str_pad($col['Field'], 30) . 
             str_pad($col['Type'], 20) . 
             str_pad($col['Null'], 10) . 
             ($col['Default'] ?? 'NULL') . "\n";
    }
    
    // Step 4: Initialize data for existing telecallers
    echo "\n\nStep 4: Initializing data for existing telecallers\n";
    $stmt = $pdo->query("
        SELECT a.id, a.name 
        FROM admins a 
        LEFT JOIN telecaller_status ts ON a.id = ts.telecaller_id 
        WHERE a.role = 'telecaller' AND ts.telecaller_id IS NULL
    ");
    $telecallers = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($telecallers) > 0) {
        echo "Found " . count($telecallers) . " telecallers without status records\n";
        $insertStmt = $pdo->prepare("
            INSERT INTO telecaller_status (telecaller_id, current_status, last_activity) 
            VALUES (?, 'offline', NOW())
        ");
        
        foreach ($telecallers as $tc) {
            $insertStmt->execute([$tc['id']]);
            echo "✅ Initialized status for: {$tc['name']}\n";
        }
    } else {
        echo "All telecallers already have status records\n";
    }
    
    echo "\n✅ Table structure fixed successfully!\n";
    
} catch(PDOException $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
}
