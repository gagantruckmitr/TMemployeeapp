<?php
/**
 * Setup Automatic Telecaller Assignment Trigger
 * Creates a MySQL trigger that automatically assigns new users to telecallers
 */

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');

require_once 'config.php';

$response = [
    'timestamp' => date('Y-m-d H:i:s'),
    'operation' => 'Setup automatic telecaller assignment'
];

try {
    // Step 1: Add assigned_to column if not exists
    $stmt = $pdo->query("SHOW COLUMNS FROM users LIKE 'assigned_to'");
    if ($stmt->rowCount() == 0) {
        $pdo->exec("ALTER TABLE users ADD COLUMN assigned_to INT(11) DEFAULT NULL AFTER id");
        $pdo->exec("ALTER TABLE users ADD INDEX idx_assigned_to (assigned_to)");
        $response['column_added'] = true;
    }
    
    // Step 2: Drop existing trigger if exists
    $pdo->exec("DROP TRIGGER IF EXISTS auto_assign_telecaller");
    
    // Step 3: Create trigger for automatic assignment
    $triggerSQL = "
    CREATE TRIGGER auto_assign_telecaller
    BEFORE INSERT ON users
    FOR EACH ROW
    BEGIN
        DECLARE next_telecaller INT;
        DECLARE telecaller_count INT;
        
        -- Only assign if role is driver and assigned_to is NULL
        IF NEW.role = 'driver' AND (NEW.assigned_to IS NULL OR NEW.assigned_to = 0) THEN
            
            -- Get count of active telecallers
            SELECT COUNT(*) INTO telecaller_count 
            FROM admins 
            WHERE role = 'telecaller';
            
            -- Only proceed if telecallers exist
            IF telecaller_count > 0 THEN
                -- Get telecaller with least assignments using round-robin
                SELECT a.id INTO next_telecaller
                FROM admins a
                LEFT JOIN (
                    SELECT assigned_to, COUNT(*) as count 
                    FROM users 
                    WHERE role = 'driver' AND assigned_to IS NOT NULL
                    GROUP BY assigned_to
                ) u ON a.id = u.assigned_to
                WHERE a.role = 'telecaller'
                ORDER BY COALESCE(u.count, 0) ASC, a.id ASC
                LIMIT 1;
                
                -- Assign the telecaller
                SET NEW.assigned_to = next_telecaller;
            END IF;
        END IF;
    END
    ";
    
    $pdo->exec($triggerSQL);
    
    // Step 4: Test the trigger by checking if it exists
    $stmt = $pdo->query("SHOW TRIGGERS LIKE 'users'");
    $triggers = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $triggerExists = false;
    foreach ($triggers as $trigger) {
        if ($trigger['Trigger'] === 'auto_assign_telecaller') {
            $triggerExists = true;
            break;
        }
    }
    
    if ($triggerExists) {
        $response['success'] = true;
        $response['message'] = 'Automatic assignment trigger created successfully';
        $response['trigger_name'] = 'auto_assign_telecaller';
        $response['how_it_works'] = [
            '1. When a new driver registers, trigger fires automatically',
            '2. Finds telecaller with least assigned users',
            '3. Assigns new user to that telecaller',
            '4. Keeps distribution balanced across all telecallers'
        ];
    } else {
        throw new Exception('Trigger creation failed');
    }
    
    // Step 5: Get current distribution
    $stmt = $pdo->query("
        SELECT 
            a.id as telecaller_id,
            a.name as telecaller_name,
            COUNT(u.id) as assigned_count
        FROM admins a
        LEFT JOIN users u ON a.id = u.assigned_to AND u.role = 'driver'
        WHERE a.role = 'telecaller'
        GROUP BY a.id, a.name
        ORDER BY a.id
    ");
    $distribution = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    $response['current_distribution'] = $distribution;
    
} catch (Exception $e) {
    $response['success'] = false;
    $response['error'] = $e->getMessage();
}

echo json_encode($response, JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES);
