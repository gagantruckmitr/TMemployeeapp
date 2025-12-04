<?php
/**
 * Setup Auto-Assign Fresh Leads Triggers
 * 
 * This script creates database triggers to automatically assign:
 * - Fresh driver leads (last 1 day) → welcome-call telecallers (round-robin)
 * - Transporter leads → NO assignment (use API round-robin instead)
 * 
 * Run this script once to set up the triggers.
 */

require_once 'config.php';

try {
    $pdo = new PDO("mysql:host=" . DB_HOST . ";dbname=" . DB_NAME . ";charset=utf8mb4", DB_USER, DB_PASS);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    
    echo "=== AUTO-ASSIGN FRESH LEADS TRIGGER SETUP ===\n\n";
    
    // Step 1: Drop existing triggers
    echo "Step 1: Dropping existing triggers...\n";
    $triggers = ['auto_assign_driver_on_insert', 'auto_assign_driver_on_update', 
                 'prevent_transporter_assignment', 'prevent_transporter_assignment_insert'];
    
    foreach ($triggers as $trigger) {
        try {
            $pdo->exec("DROP TRIGGER IF EXISTS $trigger");
            echo "  ✅ Dropped trigger: $trigger\n";
        } catch (PDOException $e) {
            // Ignore if doesn't exist
        }
    }
    
    echo "\nStep 2: Creating new triggers...\n";
    
    // Trigger 1: Auto-assign on INSERT
    $trigger1 = "
    CREATE TRIGGER auto_assign_driver_on_insert
    BEFORE INSERT ON users
    FOR EACH ROW
    BEGIN
        DECLARE next_telecaller_id INT;
        DECLARE telecaller_count INT;
        DECLARE last_assigned_id INT;
        DECLARE current_time DATETIME;
        DECLARE one_day_ago DATETIME;
        
        SET current_time = NOW();
        SET one_day_ago = DATE_SUB(current_time, INTERVAL 1 DAY);
        
        IF NEW.role = 'driver' AND NEW.Created_at >= one_day_ago THEN
            SELECT COUNT(*) INTO telecaller_count
            FROM admins
            WHERE role = 'telecaller' 
            AND tc_for = 'welcome-call';
            
            IF telecaller_count > 0 THEN
                SELECT COALESCE(MAX(u.assigned_to), 0) INTO last_assigned_id
                FROM users u
                INNER JOIN admins a ON u.assigned_to = a.id
                WHERE u.role = 'driver'
                AND u.assigned_to IS NOT NULL
                AND a.role = 'telecaller'
                AND a.tc_for = 'welcome-call'
                ORDER BY u.id DESC
                LIMIT 1;
                
                SELECT id INTO next_telecaller_id
                FROM admins
                WHERE role = 'telecaller'
                AND tc_for = 'welcome-call'
                AND id > last_assigned_id
                ORDER BY id ASC
                LIMIT 1;
                
                IF next_telecaller_id IS NULL THEN
                    SELECT id INTO next_telecaller_id
                    FROM admins
                    WHERE role = 'telecaller'
                    AND tc_for = 'welcome-call'
                    ORDER BY id ASC
                    LIMIT 1;
                END IF;
                
                IF next_telecaller_id IS NOT NULL THEN
                    SET NEW.assigned_to = next_telecaller_id;
                END IF;
            END IF;
        ELSEIF NEW.role = 'transporter' THEN
            SET NEW.assigned_to = NULL;
        END IF;
    END";
    
    $pdo->exec($trigger1);
    echo "  ✅ Created trigger: auto_assign_driver_on_insert\n";
    
    // Trigger 2: Auto-assign on UPDATE
    $trigger2 = "
    CREATE TRIGGER auto_assign_driver_on_update
    BEFORE UPDATE ON users
    FOR EACH ROW
    BEGIN
        DECLARE next_telecaller_id INT;
        DECLARE telecaller_count INT;
        DECLARE last_assigned_id INT;
        DECLARE current_time DATETIME;
        DECLARE one_day_ago DATETIME;
        
        SET current_time = NOW();
        SET one_day_ago = DATE_SUB(current_time, INTERVAL 1 DAY);
        
        IF (NEW.role = 'driver' AND OLD.role != 'driver' AND NEW.Created_at >= one_day_ago) OR
           (NEW.role = 'driver' AND (NEW.assigned_to IS NULL OR NEW.assigned_to = 0) AND 
            NEW.Created_at >= one_day_ago) THEN
            
            SELECT COUNT(*) INTO telecaller_count
            FROM admins
            WHERE role = 'telecaller' 
            AND tc_for = 'welcome-call';
            
            IF telecaller_count > 0 THEN
                SELECT COALESCE(MAX(u.assigned_to), 0) INTO last_assigned_id
                FROM users u
                INNER JOIN admins a ON u.assigned_to = a.id
                WHERE u.role = 'driver'
                AND u.assigned_to IS NOT NULL
                AND a.role = 'telecaller'
                AND a.tc_for = 'welcome-call'
                ORDER BY u.id DESC
                LIMIT 1;
                
                SELECT id INTO next_telecaller_id
                FROM admins
                WHERE role = 'telecaller'
                AND tc_for = 'welcome-call'
                AND id > last_assigned_id
                ORDER BY id ASC
                LIMIT 1;
                
                IF next_telecaller_id IS NULL THEN
                    SELECT id INTO next_telecaller_id
                    FROM admins
                    WHERE role = 'telecaller'
                    AND tc_for = 'welcome-call'
                    ORDER BY id ASC
                    LIMIT 1;
                END IF;
                
                IF next_telecaller_id IS NOT NULL THEN
                    SET NEW.assigned_to = next_telecaller_id;
                END IF;
            END IF;
        ELSEIF NEW.role = 'transporter' THEN
            SET NEW.assigned_to = NULL;
        END IF;
    END";
    
    $pdo->exec($trigger2);
    echo "  ✅ Created trigger: auto_assign_driver_on_update\n";
    
    echo "\nStep 3: Clearing transporter assignments...\n";
    $stmt = $pdo->exec("UPDATE users SET assigned_to = NULL WHERE role = 'transporter' AND assigned_to IS NOT NULL");
    echo "  ✅ Cleared $stmt transporter assignments\n";
    
    echo "\nStep 4: Assigning fresh drivers (last 1 day)...\n";
    
    // Get telecallers
    $stmt = $pdo->query("
        SELECT id, name 
        FROM admins 
        WHERE role = 'telecaller' 
        AND tc_for = 'welcome-call'
        ORDER BY id ASC
    ");
    $telecallers = $stmt->fetchAll();
    $telecallerIds = array_column($telecallers, 'id');
    $telecallerCount = count($telecallerIds);
    
    if ($telecallerCount > 0) {
        // Get unassigned fresh drivers
        $stmt = $pdo->query("
            SELECT id 
            FROM users
            WHERE role = 'driver'
            AND (assigned_to IS NULL OR assigned_to = 0)
            AND Created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)
            ORDER BY Created_at DESC
        ");
        $drivers = $stmt->fetchAll();
        
        $updateStmt = $pdo->prepare("UPDATE users SET assigned_to = ? WHERE id = ?");
        $assignedCount = 0;
        
        foreach ($drivers as $index => $driver) {
            $telecallerIndex = $index % $telecallerCount;
            $assignedTelecallerId = $telecallerIds[$telecallerIndex];
            $updateStmt->execute([$assignedTelecallerId, $driver['id']]);
            $assignedCount++;
        }
        
        echo "  ✅ Assigned $assignedCount fresh drivers\n";
    } else {
        echo "  ⚠️  No welcome-call telecallers found!\n";
    }
    
    echo "\n=== VERIFICATION ===\n\n";
    
    // Verify triggers were created
    $stmt = $pdo->query("SHOW TRIGGERS LIKE 'users'");
    $allTriggers = $stmt->fetchAll();
    $triggers = array_filter($allTriggers, function($t) {
        return stripos($t['Trigger'], 'assign') !== false;
    });
    
    if (empty($triggers)) {
        echo "❌ No triggers found! Something went wrong.\n";
    } else {
        echo "✅ Active Triggers:\n";
        foreach ($triggers as $trigger) {
            echo "   - {$trigger['Trigger']} ({$trigger['Timing']} {$trigger['Event']})\n";
        }
    }
    
    echo "\n";
    
    // Check fresh driver assignments
    $stmt = $pdo->query("
        SELECT 
            COUNT(*) AS total_count,
            SUM(CASE WHEN assigned_to IS NOT NULL THEN 1 ELSE 0 END) AS assigned_count,
            SUM(CASE WHEN assigned_to IS NULL THEN 1 ELSE 0 END) AS unassigned_count
        FROM users
        WHERE role = 'driver'
        AND Created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)
    ");
    
    $freshDrivers = $stmt->fetch();
    
    echo "📊 Fresh Drivers (Last 1 Day):\n";
    echo "   - Total: {$freshDrivers['total_count']}\n";
    echo "   - Assigned: {$freshDrivers['assigned_count']}\n";
    echo "   - Unassigned: {$freshDrivers['unassigned_count']}\n\n";
    
    // Check transporter assignments (should be 0)
    $stmt = $pdo->query("
        SELECT 
            COUNT(*) AS total_count,
            SUM(CASE WHEN assigned_to IS NOT NULL THEN 1 ELSE 0 END) AS assigned_count
        FROM users
        WHERE role = 'transporter'
    ");
    
    $transporters = $stmt->fetch();
    
    echo "📊 Transporters:\n";
    echo "   - Total: {$transporters['total_count']}\n";
    echo "   - Assigned: {$transporters['assigned_count']} (should be 0)\n";
    
    if ($transporters['assigned_count'] > 0) {
        echo "   ⚠️  WARNING: Transporters should NOT be assigned!\n";
    } else {
        echo "   ✅ Correct: No transporters assigned\n";
    }
    
    echo "\n";
    
    // Show distribution among telecallers
    $stmt = $pdo->query("
        SELECT 
            a.id AS telecaller_id,
            a.name AS telecaller_name,
            a.tc_for,
            COUNT(u.id) AS assigned_fresh_drivers
        FROM admins a
        LEFT JOIN users u ON u.assigned_to = a.id 
            AND u.role = 'driver'
            AND u.Created_at >= DATE_SUB(NOW(), INTERVAL 1 DAY)
        WHERE a.role = 'telecaller'
        AND a.tc_for = 'welcome-call'
        GROUP BY a.id, a.name, a.tc_for
        ORDER BY a.id ASC
    ");
    
    $distribution = $stmt->fetchAll();
    
    if (empty($distribution)) {
        echo "⚠️  No welcome-call telecallers found!\n";
        echo "   Please ensure telecallers have tc_for = 'welcome-call' in admins table.\n";
    } else {
        echo "📊 Distribution Among Welcome-Call Telecallers:\n";
        $totalAssigned = 0;
        foreach ($distribution as $tc) {
            echo "   - TC #{$tc['telecaller_id']} ({$tc['telecaller_name']}): {$tc['assigned_fresh_drivers']} fresh drivers\n";
            $totalAssigned += $tc['assigned_fresh_drivers'];
        }
        echo "   Total: $totalAssigned fresh drivers assigned\n";
    }
    
    echo "\n=== SETUP COMPLETE ===\n\n";
    
    echo "✅ Triggers are now active!\n\n";
    
    echo "📝 What happens now:\n";
    echo "   1. New driver registrations → Auto-assigned to welcome-call telecallers (round-robin)\n";
    echo "   2. Fresh drivers (last 1 day) → Already assigned in round-robin\n";
    echo "   3. Old drivers (>1 day) → Remain unchanged\n";
    echo "   4. Transporters → NEVER assigned (use transporter_leads_api.php)\n\n";
    
    echo "🧪 Test the trigger:\n";
    echo "   Run: php api/test_auto_assign_trigger.php\n\n";
    
} catch(PDOException $e) {
    echo "❌ Database Error: " . $e->getMessage() . "\n";
    exit(1);
} catch(Exception $e) {
    echo "❌ Error: " . $e->getMessage() . "\n";
    exit(1);
}
