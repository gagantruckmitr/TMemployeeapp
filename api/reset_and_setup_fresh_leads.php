<?php
/**
 * Reset Old Leads and Setup Fresh Lead System
 * 
 * Step 1: Set all existing leads assigned_to = NULL (unassign them)
 * Step 2: Setup trigger for NEW leads only
 * 
 * Result:
 * - All old 5000+ leads: assigned_to = NULL (won't show to telecallers)
 * - Only NEW registrations from now: Auto-assigned based on role
 * - Drivers → TC 3 & 4
 * - Transporters → TC 6 & 7
 */

header('Content-Type: application/json');
require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "🔧 Resetting old leads and setting up fresh lead system...\n\n";
    
    // Step 1: Unassign all existing leads
    echo "Step 1: Unassigning all existing leads...\n";
    
    $stmt = $pdo->prepare("
        UPDATE users 
        SET assigned_to = NULL 
        WHERE role IN ('driver', 'transporter')
        AND assigned_to IS NOT NULL
    ");
    $stmt->execute();
    $unassignedCount = $stmt->rowCount();
    
    echo "✅ Unassigned $unassignedCount existing leads (set assigned_to = NULL)\n\n";
    
    // Step 2: Drop old trigger
    echo "Step 2: Removing old assignment trigger...\n";
    $pdo->exec("DROP TRIGGER IF EXISTS assign_user_by_role");
    echo "✅ Old trigger removed\n\n";
    
    // Step 3: Create new trigger for role-based assignment
    echo "Step 3: Creating new role-based assignment trigger...\n";
    
    $trigger = "
    CREATE TRIGGER assign_user_by_role
    BEFORE INSERT ON users
    FOR EACH ROW
    BEGIN
        DECLARE driver_count_3 INT;
        DECLARE driver_count_4 INT;
        DECLARE transporter_count_6 INT;
        DECLARE transporter_count_7 INT;
        
        -- Only auto-assign if not already assigned
        IF NEW.assigned_to IS NULL THEN
            
            -- For DRIVERS: Assign to telecallers 3 or 4
            IF NEW.role = 'driver' THEN
                -- Count drivers on telecaller 3
                SELECT COUNT(*) INTO driver_count_3
                FROM users
                WHERE assigned_to = 3 AND role = 'driver';
                
                -- Count drivers on telecaller 4
                SELECT COUNT(*) INTO driver_count_4
                FROM users
                WHERE assigned_to = 4 AND role = 'driver';
                
                -- Assign to telecaller with fewer drivers
                IF driver_count_3 <= driver_count_4 THEN
                    SET NEW.assigned_to = 3;
                ELSE
                    SET NEW.assigned_to = 4;
                END IF;
                
            -- For TRANSPORTERS: Assign to telecallers 6 or 7
            ELSEIF NEW.role = 'transporter' THEN
                -- Count transporters on telecaller 6
                SELECT COUNT(*) INTO transporter_count_6
                FROM users
                WHERE assigned_to = 6 AND role = 'transporter';
                
                -- Count transporters on telecaller 7
                SELECT COUNT(*) INTO transporter_count_7
                FROM users
                WHERE assigned_to = 7 AND role = 'transporter';
                
                -- Assign to telecaller with fewer transporters
                IF transporter_count_6 <= transporter_count_7 THEN
                    SET NEW.assigned_to = 6;
                ELSE
                    SET NEW.assigned_to = 7;
                END IF;
            END IF;
        END IF;
    END;
    ";
    
    $pdo->exec($trigger);
    echo "✅ Role-based assignment trigger created!\n\n";
    
    // Step 4: Verify current state
    echo "Step 4: Verifying current state...\n";
    
    // Count unassigned leads
    $stmt = $pdo->query("
        SELECT COUNT(*) as count
        FROM users
        WHERE role IN ('driver', 'transporter')
        AND assigned_to IS NULL
    ");
    $unassignedTotal = $stmt->fetch()['count'];
    echo "  Unassigned leads (old data): $unassignedTotal\n";
    
    // Count assigned leads (should be 0 right now)
    $stmt = $pdo->query("
        SELECT COUNT(*) as count
        FROM users
        WHERE role IN ('driver', 'transporter')
        AND assigned_to IS NOT NULL
    ");
    $assignedTotal = $stmt->fetch()['count'];
    echo "  Assigned leads (new data): $assignedTotal\n\n";
    
    // Check what each telecaller will see
    echo "Step 5: Fresh leads per telecaller (should be 0 for all):\n";
    
    $telecallers = [3, 4, 6, 7];
    foreach ($telecallers as $tc) {
        $stmt = $pdo->prepare("
            SELECT COUNT(*) as count
            FROM users
            WHERE assigned_to = ?
            AND role IN ('driver', 'transporter')
        ");
        $stmt->execute([$tc]);
        $count = $stmt->fetch()['count'];
        echo "  Telecaller $tc: $count fresh leads\n";
    }
    
    echo "\n✅ Setup completed!\n\n";
    echo "📋 Summary:\n";
    echo "  ✅ All old leads: assigned_to = NULL (hidden from telecallers)\n";
    echo "  ✅ Telecallers currently see: 0 fresh leads\n";
    echo "  ✅ NEW drivers from now → Telecallers 3 & 4 (round-robin)\n";
    echo "  ✅ NEW transporters from now → Telecallers 6 & 7 (round-robin)\n";
    echo "  ✅ Only NEW registrations will appear as fresh leads\n";
    
    echo json_encode([
        'success' => true,
        'message' => 'Fresh lead system setup completed',
        'stats' => [
            'old_leads_unassigned' => $unassignedCount,
            'current_unassigned' => $unassignedTotal,
            'current_assigned' => $assignedTotal,
            'fresh_leads_visible' => 0
        ],
        'note' => 'Only NEW registrations from now will be assigned and visible to telecallers'
    ], JSON_PRETTY_PRINT);
    
} catch (Exception $e) {
    echo json_encode([
        'success' => false,
        'error' => $e->getMessage()
    ], JSON_PRETTY_PRINT);
}
?>
