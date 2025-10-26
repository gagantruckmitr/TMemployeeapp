<?php
// Fix call_logs table structure - Add missing columns
header('Content-Type: text/plain');
header('Access-Control-Allow-Origin: *');

require_once __DIR__ . '/config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "Fixing call_logs table structure...\n\n";
    
    // Step 1: Check current table structure
    echo "Step 1: Checking current table structure\n";
    $stmt = $pdo->query("DESCRIBE call_logs");
    $columns = $stmt->fetchAll(PDO::FETCH_COLUMN);
    echo "Current columns: " . implode(", ", $columns) . "\n\n";
    
    // Step 2: Add missing columns if they don't exist
    $columnsToAdd = [
        'call_initiated_at' => "DATETIME NULL COMMENT 'When the call was initiated'",
        'call_completed_at' => "DATETIME NULL COMMENT 'When the call was completed'",
        'ip_address' => "VARCHAR(45) NULL COMMENT 'IP address of the caller'"
    ];
    
    foreach ($columnsToAdd as $column => $definition) {
        if (!in_array($column, $columns)) {
            echo "Adding column: $column\n";
            try {
                $pdo->exec("ALTER TABLE call_logs ADD COLUMN $column $definition");
                echo "✅ Added $column\n";
            } catch (PDOException $e) {
                echo "❌ Error adding $column: " . $e->getMessage() . "\n";
            }
        } else {
            echo "✓ Column $column already exists\n";
        }
    }
    
    echo "\n";
    
    // Step 3: Migrate data from call_time to call_initiated_at if needed
    if (!in_array('call_initiated_at', $columns)) {
        echo "Step 3: Migrating data from call_time to call_initiated_at\n";
        try {
            $pdo->exec("UPDATE call_logs SET call_initiated_at = call_time WHERE call_initiated_at IS NULL");
            $affected = $pdo->query("SELECT ROW_COUNT()")->fetchColumn();
            echo "✅ Migrated $affected records\n";
        } catch (PDOException $e) {
            echo "❌ Error migrating data: " . $e->getMessage() . "\n";
        }
    }
    
    echo "\n";
    
    // Step 4: Verify final structure
    echo "Step 4: Verifying final table structure\n";
    $stmt = $pdo->query("DESCRIBE call_logs");
    $finalColumns = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo "\nKey columns in call_logs table:\n";
    echo str_pad("Column", 30) . str_pad("Type", 25) . str_pad("Null", 10) . "Default\n";
    echo str_repeat("-", 85) . "\n";
    
    $keyColumns = ['id', 'caller_id', 'user_id', 'call_status', 'call_time', 'call_initiated_at', 'call_completed_at', 'call_duration'];
    foreach ($finalColumns as $col) {
        if (in_array($col['Field'], $keyColumns)) {
            echo str_pad($col['Field'], 30) . 
                 str_pad($col['Type'], 25) . 
                 str_pad($col['Null'], 10) . 
                 ($col['Default'] ?? 'NULL') . "\n";
        }
    }
    
    // Step 5: Show sample data
    echo "\n\nStep 5: Sample data (last 3 records)\n";
    $stmt = $pdo->query("
        SELECT id, caller_id, user_id, call_status, call_time, call_initiated_at, call_duration 
        FROM call_logs 
        ORDER BY id DESC 
        LIMIT 3
    ");
    $samples = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    if (count($samples) > 0) {
        foreach ($samples as $sample) {
            echo "ID: {$sample['id']}, Caller: {$sample['caller_id']}, Status: {$sample['call_status']}, ";
            echo "Time: {$sample['call_time']}, Initiated: {$sample['call_initiated_at']}\n";
        }
    } else {
        echo "No call logs found\n";
    }
    
    echo "\n✅ Table structure fixed successfully!\n";
    
} catch(PDOException $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
}
