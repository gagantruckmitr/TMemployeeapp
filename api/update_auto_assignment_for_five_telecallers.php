<?php
require_once 'config.php';

header('Content-Type: application/json');

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME, DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "Updating auto-assignment trigger for 5 telecallers...\n\n";
    
    // Drop existing trigger if exists
    $pdo->exec("DROP TRIGGER IF EXISTS auto_assign_driver");
    
    // Create new trigger with round-robin for telecallers 3, 4, 8, 9, 10
    $triggerSQL = "
    CREATE TRIGGER auto_assign_driver
    AFTER INSERT ON drivers
    FOR EACH ROW
    BEGIN
        DECLARE next_telecaller INT;
        DECLARE telecaller_list VARCHAR(50) DEFAULT '3,4,8,9,10';
        DECLARE telecaller_count INT DEFAULT 5;
        DECLARE last_assigned INT;
        DECLARE position_in_list INT;
        
        -- Get the last assigned telecaller from the round-robin pool
        SELECT assigned_to INTO last_assigned
        FROM drivers
        WHERE assigned_to IN (3, 4, 8, 9, 10)
        AND id < NEW.id
        ORDER BY id DESC
        LIMIT 1;
        
        -- Determine next telecaller in round-robin
        IF last_assigned IS NULL OR last_assigned = 10 THEN
            SET next_telecaller = 3;
        ELSEIF last_assigned = 3 THEN
            SET next_telecaller = 4;
        ELSEIF last_assigned = 4 THEN
            SET next_telecaller = 8;
        ELSEIF last_assigned = 8 THEN
            SET next_telecaller = 9;
        ELSEIF last_assigned = 9 THEN
            SET next_telecaller = 10;
        ELSE
            SET next_telecaller = 3;
        END IF;
        
        -- Assign the driver to the next telecaller
        UPDATE drivers 
        SET assigned_to = next_telecaller 
        WHERE id = NEW.id;
    END;
    ";
    
    $pdo->exec($triggerSQL);
    
    echo "Trigger created successfully!\n\n";
    echo "Auto-assignment pattern: 3 → 4 → 8 → 9 → 10 → 3 (round-robin)\n";
    echo "Telecallers 6 and 7 are excluded from auto-assignment.\n\n";
    
    // Verify trigger exists
    $stmt = $pdo->query("SHOW TRIGGERS LIKE 'drivers'");
    $triggers = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    echo json_encode([
        'success' => true,
        'message' => 'Auto-assignment trigger updated for 5 telecallers',
        'pattern' => '3 → 4 → 8 → 9 → 10 → 3',
        'triggers' => $triggers
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ], JSON_PRETTY_PRINT);
}
