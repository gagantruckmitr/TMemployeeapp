<?php
// ONE-TIME SETUP: Auto round-robin system that works forever
header('Content-Type: application/json');
require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    $steps = [];
    
    // STEP 1: Assign existing latest 100 drivers in round-robin
    $steps[] = "Step 1: Assigning existing drivers...";
    
    $telecallersStmt = $pdo->query("SELECT id FROM admins WHERE role = 'telecaller' ORDER BY id ASC");
    $telecallers = $telecallersStmt->fetchAll(PDO::FETCH_COLUMN);
    $telecallerCount = count($telecallers);
    
    if ($telecallerCount == 0) {
        echo json_encode(['error' => 'No telecallers found']);
        exit;
    }
    
    // Clear old assignments
    $pdo->exec("UPDATE users SET assigned_to = NULL WHERE role = 'driver'");
    
    // Get latest drivers (50 per telecaller)
    $totalNeeded = $telecallerCount * 50;
    $stmt = $pdo->prepare("SELECT id FROM users WHERE role = 'driver' ORDER BY Created_at DESC LIMIT :limit");
    $stmt->bindValue(':limit', $totalNeeded, PDO::PARAM_INT);
    $stmt->execute();
    $drivers = $stmt->fetchAll(PDO::FETCH_COLUMN);
    
    // Assign in alternating fashion
    $updateStmt = $pdo->prepare("UPDATE users SET assigned_to = ? WHERE id = ?");
    foreach ($drivers as $index => $driverId) {
        $telecallerIndex = $index % $telecallerCount;
        $telecallerId = $telecallers[$telecallerIndex];
        $updateStmt->execute([$telecallerId, $driverId]);
    }
    
    $steps[] = "✓ Assigned " . count($drivers) . " drivers to $telecallerCount telecallers";
    
    // STEP 2: Create trigger for automatic assignment of NEW drivers
    $steps[] = "Step 2: Creating automatic assignment trigger...";
    
    // Drop old trigger if exists
    $pdo->exec("DROP TRIGGER IF EXISTS auto_assign_driver_to_telecaller");
    
    // Create new trigger that assigns EVERY new driver automatically
    $triggerSQL = "
    CREATE TRIGGER auto_assign_driver_to_telecaller
    BEFORE INSERT ON users
    FOR EACH ROW
    BEGIN
        DECLARE telecaller_count INT;
        DECLARE next_telecaller_id INT;
        DECLARE last_assigned_count INT;
        DECLARE offset_value INT;
        
        IF NEW.role = 'driver' THEN
            SELECT COUNT(*) INTO telecaller_count 
            FROM admins 
            WHERE role = 'telecaller';
            
            IF telecaller_count > 0 THEN
                SELECT COUNT(*) INTO last_assigned_count
                FROM users
                WHERE role = 'driver' AND assigned_to IS NOT NULL;
                
                SET offset_value = last_assigned_count % telecaller_count;
                
                SELECT id INTO next_telecaller_id
                FROM (
                    SELECT id, @row := @row + 1 as row_num
                    FROM admins, (SELECT @row := 0) r
                    WHERE role = 'telecaller'
                    ORDER BY id ASC
                ) ranked
                WHERE row_num = offset_value + 1
                LIMIT 1;
                
                SET NEW.assigned_to = next_telecaller_id;
            END IF;
        END IF;
    END";
    
    $pdo->exec($triggerSQL);
    $steps[] = "✓ Trigger created - NEW drivers will auto-assign in round-robin";
    
    // STEP 3: Verify setup
    $steps[] = "Step 3: Verifying setup...";
    
    $verifyStmt = $pdo->query("
        SELECT 
            a.id,
            a.name,
            COUNT(u.id) as assigned_count
        FROM admins a
        LEFT JOIN users u ON u.assigned_to = a.id AND u.role = 'driver'
        WHERE a.role = 'telecaller'
        GROUP BY a.id, a.name
        ORDER BY a.id
    ");
    $verification = $verifyStmt->fetchAll(PDO::FETCH_ASSOC);
    
    $steps[] = "✓ Current distribution:";
    foreach ($verification as $tc) {
        $steps[] = "  - {$tc['name']} (ID {$tc['id']}): {$tc['assigned_count']} leads";
    }
    
    echo json_encode([
        'success' => true,
        'message' => 'Auto round-robin system setup complete!',
        'steps' => $steps,
        'note' => 'This is a ONE-TIME setup. New drivers will automatically assign in round-robin forever.',
        'scales_to' => 'Works for any number of telecallers (2, 20, 100+)',
        'timestamp' => date('Y-m-d H:i:s')
    ], JSON_PRETTY_PRINT);
    
} catch(Exception $e) {
    echo json_encode([
        'error' => $e->getMessage(),
        'trace' => $e->getTraceAsString()
    ]);
}
?>
